import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class ChallengeDetailPage extends StatefulWidget {
  final String gameId;
  final String challengeId;
  final Map<String, dynamic> data;
  final String teamName;
  final String playerId;

  const ChallengeDetailPage({
    super.key,
    required this.gameId,
    required this.challengeId,
    required this.data,
    required this.teamName,
    required this.playerId,
  });

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  final _auth    = AuthService();
  final _db      = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker  = ImagePicker();

  File?   _image;
  String? _textResponse;
  bool    _submitting       = false;
  bool    _completed        = false;
  bool    _atLocation       = false;
  bool    _checkingLocation = false;
  String? _locationMsg;
  String? _resultMsg;

  // Live game state
  StreamSubscription<DocumentSnapshot>? _gameSub;
  Timer? _tickTimer;
  bool     _gameActive      = true;
  DateTime? _gameStartedAt;
  int?      _gameDuration;   // minutes

  // Position multiplier
  bool   _posMultEnabled = false;
  double _firstMult      = 2.0;
  double _secondMult     = 1.5;
  double _thirdMult      = 1.25;
  String? _bonusMsg;

  @override
  void initState() {
    super.initState();
    _checkCompleted();
    _watchGame();
  }

  @override
  void dispose() {
    _gameSub?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  void _watchGame() {
    _gameSub = _db.collection('games').doc(widget.gameId)
        .snapshots()
        .listen((snap) {
      if (!mounted || !snap.exists) return;
      final d = snap.data() as Map<String, dynamic>;
      final startedTs = d['startedAt'];
      setState(() {
        _gameActive      = d['isActive'] ?? true;
        _gameStartedAt   = startedTs is Timestamp ? startedTs.toDate() : null;
        _gameDuration    = d['durationMinutes'] as int?;
        _posMultEnabled  = d['positionMultiplierEnabled'] ?? false;
        _firstMult       = (d['firstMultiplier']  as num?)?.toDouble() ?? 2.0;
        _secondMult      = (d['secondMultiplier'] as num?)?.toDouble() ?? 1.5;
        _thirdMult       = (d['thirdMultiplier']  as num?)?.toDouble() ?? 1.25;
      });

      // Start a 1-second tick so the timer expiry is caught in real time
      if (_gameStartedAt != null && _gameDuration != null && _gameDuration! > 0) {
        _tickTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  bool get _timerExpired {
    if (_gameStartedAt == null || _gameDuration == null || _gameDuration! <= 0) return false;
    final end = _gameStartedAt!.add(Duration(minutes: _gameDuration!));
    return DateTime.now().isAfter(end);
  }

  // Returns a human-readable reason submissions are blocked, or null if allowed.
  String? get _blockedReason {
    if (!_gameActive) return 'The host has ended this game.';
    if (_timerExpired) return 'Time is up — submissions are now closed.';
    return null;
  }

  Future<void> _checkCompleted() async {
    await _auth.getOrCreateUser();
    final doc = await _db
        .collection('games').doc(widget.gameId)
        .collection('players').doc(widget.playerId)
        .collection('completed').doc(widget.challengeId).get();
    if (doc.exists && mounted) setState(() { _completed = true; _resultMsg = 'Already completed!'; });
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _confirmLocation() async {
    setState(() { _checkingLocation = true; _locationMsg = null; });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() { _locationMsg = 'Location permission denied. Enable in Settings.'; _checkingLocation = false; });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double targetLat = 0, targetLng = 0, radius = 20;

      final loc = widget.data['location'];
      if (loc is GeoPoint) {
        targetLat = loc.latitude; targetLng = loc.longitude;
      } else if (loc is Map) {
        targetLat = (loc['lat'] as num?)?.toDouble() ?? 0;
        targetLng = (loc['lng'] as num?)?.toDouble() ?? 0;
        radius    = (loc['radius'] as num?)?.toDouble() ?? 20;
      }

      if (targetLat == 0 && targetLng == 0) {
        setState(() { _locationMsg = '⚠️ Location not set for this challenge.'; _checkingLocation = false; });
        return;
      }

      final dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, targetLat, targetLng);
      setState(() {
        _atLocation  = dist <= radius;
        _locationMsg = dist <= radius
            ? 'You\'re here! (${dist.toStringAsFixed(0)} m)'
            : '${dist.toStringAsFixed(0)} m away — get closer!';
      });
    } catch (e) {
      setState(() => _locationMsg = 'Location error: $e');
    } finally {
      setState(() => _checkingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (_completed) return;

    // Re-check game state immediately before writing
    final gameSnap = await _db.collection('games').doc(widget.gameId).get();
    final gData    = gameSnap.data() ?? {};
    final stillActive = gData['isActive'] ?? false;
    final startedTs   = gData['startedAt'];
    bool expired = false;
    if (startedTs is Timestamp) {
      final dur = gData['durationMinutes'] as int?;
      if (dur != null && dur > 0) {
        expired = DateTime.now().isAfter(startedTs.toDate().add(Duration(minutes: dur)));
      }
    }
    if (!stillActive || expired) {
      setState(() => _resultMsg = !stillActive
          ? 'The game has ended — submission rejected.'
          : 'Time is up — submission rejected.');
      return;
    }

    setState(() { _submitting = true; _resultMsg = null; });

    try {
      final type     = widget.data['type'];
      final playerId = widget.playerId;
      String? imageUrl;

      // Count ALL submissions for this challenge to determine position and detect duplicates
      final allChallSubs = await _db
          .collection('games').doc(widget.gameId).collection('submissions')
          .where('challengeId', isEqualTo: widget.challengeId)
          .get();
      if (allChallSubs.docs.any((d) => (d.data())['playerId'] == playerId)) {
        setState(() { _completed = true; _submitting = false; _resultMsg = 'Already completed!'; });
        return;
      }
      final completionPosition = allChallSubs.docs.length + 1; // 1 = 1st, 2 = 2nd, 3 = 3rd

      if ((type == 'photo' || type == 'location_photo') && _image != null) {
        final ref = _storage.ref().child(
            'games/${widget.gameId}/submissions/${playerId}_${widget.challengeId}.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      await _db.collection('games').doc(widget.gameId).collection('submissions').add({
        'playerId':       playerId,
        'challengeId':    widget.challengeId,
        'challengeTitle': widget.data['title'],
        'type':           type,
        'mediaUrl':       imageUrl,
        'textResponse':   _textResponse?.trim(),
        'submittedAt':    FieldValue.serverTimestamp(),
      });

      await _db.collection('games').doc(widget.gameId)
          .collection('players').doc(playerId)
          .collection('completed').doc(widget.challengeId)
          .set({'completedAt': FieldValue.serverTimestamp()});

      final basePoints = (widget.data['points'] ?? 0) as int;
      int finalPts = basePoints;
      String? bonusMsg;
      if (_posMultEnabled && completionPosition <= 3) {
        final mult = completionPosition == 1 ? _firstMult
            : completionPosition == 2 ? _secondMult
            : _thirdMult;
        finalPts = (basePoints * mult).round();
        final ordinal = completionPosition == 1 ? '1st'
            : completionPosition == 2 ? '2nd' : '3rd';
        final medal = completionPosition == 1 ? '🥇'
            : completionPosition == 2 ? '🥈' : '🥉';
        bonusMsg = '$medal $mult× multiplier applied — $ordinal team to complete this!';
      }

      await _db.collection('games').doc(widget.gameId)
          .collection('players').doc(playerId)
          .set({'points': FieldValue.increment(finalPts)}, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _submitting = false; _completed = true;
        _resultMsg  = '+$finalPts points earned! 🎉';
        _bonusMsg   = bonusMsg;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      setState(() { _submitting = false; _resultMsg = 'Error: $e'; });
    }
  }

  bool get _canSubmit {
    if (_completed || _submitting) return false;
    if (_blockedReason != null) return false;
    final type = widget.data['type'];
    if (type == 'location')       return _atLocation;
    if (type == 'location_photo') return _atLocation && _image != null;
    if (type == 'photo')          return _image != null;
    if (type == 'text')           return (_textResponse?.trim().isNotEmpty ?? false);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final type   = widget.data['type'] ?? '';
    final title  = widget.data['title'] ?? '';
    final desc   = widget.data['description'] ?? '';
    final points = widget.data['points'] ?? 0;
    final extra  = widget.data['extraChallenge'];
    final blocked = _blockedReason;

    return Scaffold(
      backgroundColor: ScavColors.bg,
      appBar: AppBar(
        title: const Text('Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Game closed banner ──────────────────────────────
          if (blocked != null && !_completed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: ScavColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ScavColors.red.withValues(alpha: 0.35))),
              child: Row(children: [
                const Icon(Icons.lock_outline, color: ScavColors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(blocked,
                  style: const TextStyle(color: ScavColors.red, fontSize: 13,
                    fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── Challenge header card ───────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ScavColors.surface, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ScavColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(challengeTypeEmoji(type), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                ScavChip('+$points pts', color: ScavColors.accent),
                const Spacer(),
                if (_completed) ScavChip('✓ Done', color: ScavColors.green),
              ]),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: ScavColors.textPrimary,
                fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(desc, style: const TextStyle(
                color: ScavColors.textSecondary, fontSize: 14, height: 1.5)),
            ]),
          ),

          const SizedBox(height: 20),

          // ── LOCATION check ──────────────────────────────────
          if (type == 'location' || type == 'location_photo') ...[
            _stepLabel('Step 1 — Confirm you\'re at the right spot'),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              icon: _checkingLocation
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ScavColors.accent))
                  : Icon(
                      _atLocation ? Icons.check_circle_outline : Icons.my_location_outlined,
                      color: _atLocation ? ScavColors.green : ScavColors.accent),
              label: Text(
                _checkingLocation ? 'Checking...' : _atLocation ? 'At location ✓' : 'Confirm Location',
                style: TextStyle(color: _atLocation ? ScavColors.green : ScavColors.accent)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _atLocation
                    ? ScavColors.green.withValues(alpha: 0.5)
                    : ScavColors.accent.withValues(alpha: 0.4)),
                backgroundColor: _atLocation ? ScavColors.greenLo : ScavColors.accentLo,
                padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _completed || _checkingLocation || _atLocation || blocked != null
                  ? null : _confirmLocation,
            )),
            if (_locationMsg != null) ...[
              const SizedBox(height: 8),
              ScavStatusBanner(_locationMsg!,
                color: _atLocation ? ScavColors.green : ScavColors.red,
                icon: _atLocation ? Icons.check_circle_outline : Icons.location_off_outlined),
            ],
            const SizedBox(height: 20),
          ],

          // ── Extra challenge text (location_photo) ───────────
          if (type == 'location_photo' && _atLocation && extra != null) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: ScavColors.accentLo,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ScavColors.accent.withValues(alpha: 0.3))),
              child: Text(extra, style: const TextStyle(
                color: ScavColors.textPrimary, fontSize: 15,
                fontWeight: FontWeight.w600, height: 1.4)),
            ),
            const SizedBox(height: 20),
          ],

          // ── PHOTO section ───────────────────────────────────
          if (type == 'photo' || (type == 'location_photo' && _atLocation)) ...[
            _stepLabel(type == 'location_photo' ? 'Step 2 — Take a photo' : 'Take a photo'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: (_completed || blocked != null) ? null : _pickImage,
              child: Container(
                width: double.infinity, height: 220,
                decoration: BoxDecoration(
                  color: ScavColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _image != null
                      ? ScavColors.accent.withValues(alpha: 0.5) : ScavColors.border)),
                clipBehavior: Clip.antiAlias,
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(color: ScavColors.accentLo,
                            borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.camera_alt_outlined,
                            color: ScavColors.accent, size: 24)),
                        const SizedBox(height: 10),
                        const Text('Tap to take a photo', style: TextStyle(
                          color: ScavColors.textSecondary, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Camera will open', style: TextStyle(
                          color: ScavColors.textMuted, fontSize: 11)),
                      ]),
              ),
            ),
            if (_image != null && !_completed && blocked == null) ...[
              const SizedBox(height: 8),
              Center(child: TextButton.icon(
                icon: const Icon(Icons.camera_alt_outlined, size: 16, color: ScavColors.textMuted),
                label: const Text('Retake', style: TextStyle(color: ScavColors.textMuted, fontSize: 12)),
                onPressed: _pickImage,
              )),
            ],
            const SizedBox(height: 20),
          ],

          // ── TEXT response ───────────────────────────────────
          if (type == 'text') ...[
            _stepLabel('Your Answer'),
            const SizedBox(height: 8),
            TextField(
              enabled: !_completed && blocked == null,
              maxLines: 5,
              onChanged: (v) => setState(() => _textResponse = v),
              style: const TextStyle(color: ScavColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Type your answer here...'),
            ),
            const SizedBox(height: 20),
          ],

          // ── Result message ──────────────────────────────────
          if (_resultMsg != null) ...[
            ScavStatusBanner(
              _resultMsg!,
              color: _resultMsg!.contains('points') ? ScavColors.green
                  : _resultMsg!.startsWith('Error') ? ScavColors.red
                  : ScavColors.textSecondary,
              icon: _resultMsg!.contains('points') ? Icons.celebration_outlined : null,
            ),
            if (_bonusMsg != null) ...[
              const SizedBox(height: 8),
              ScavStatusBanner(
                _bonusMsg!,
                color: ScavColors.amber,
                icon: Icons.star_rounded,
              ),
            ],
            const SizedBox(height: 16),
          ],

          // ── Submit button ───────────────────────────────────
          if (_submitting)
            const Center(child: CircularProgressIndicator(color: ScavColors.accent))
          else
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _completed ? ScavColors.surfaceHi : ScavColors.green,
                foregroundColor: _completed ? ScavColors.textMuted : Colors.white,
                disabledBackgroundColor: ScavColors.surfaceHi,
                disabledForegroundColor: ScavColors.textMuted,
              ),
              child: Text(
                _completed     ? '✓  Challenge Completed'
                    : blocked != null ? '🔒  Submissions Closed'
                    : _canSubmit     ? 'Submit Challenge →'
                    : _buildDisabledLabel(type),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            )),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  String _buildDisabledLabel(String type) {
    if (type == 'location' && !_atLocation) return 'Confirm location first';
    if (type == 'location_photo') {
      if (!_atLocation) return 'Confirm location first';
      if (_image == null) return 'Take a photo to continue';
    }
    if (type == 'photo' && _image == null) return 'Take a photo to continue';
    if (type == 'text') return 'Write an answer first';
    return 'Submit Challenge';
  }

  Widget _stepLabel(String t) => Text(t.toUpperCase(), style: const TextStyle(
    color: ScavColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2));
}
