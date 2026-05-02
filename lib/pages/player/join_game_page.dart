import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import 'game_shell.dart';

class JoinGamePage extends StatefulWidget {
  const JoinGamePage({super.key});
  @override State<JoinGamePage> createState() => _JoinGamePageState();
}

class _JoinGamePageState extends State<JoinGamePage> {
  final _auth     = AuthService();
  final _db       = FirebaseFirestore.instance;
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading      = false;
  bool _rejoinLoading = false;
  String? _error;
  Map<String, String>? _savedSession;

  @override
  void initState() {
    super.initState();
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    final session = await SessionService.load();
    if (mounted) setState(() => _savedSession = session);
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final name = _nameCtrl.text.trim();
    if (code.isEmpty || name.isEmpty) {
      setState(() => _error = 'Please fill in both fields'); return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final q = await _db.collection('games')
          .where('joinCode', isEqualTo: code).limit(1).get();

      if (q.docs.isEmpty) {
        setState(() { _error = 'Game code not found'; _loading = false; }); return;
      }

      final game     = q.docs.first;
      final gameId   = game.id;
      final gameData = game.data();

      // Reject only if game has already ended (was started but is now inactive)
      final isActive  = gameData['isActive'] ?? false;
      final startedAt = gameData['startedAt'];
      if (!isActive && startedAt != null) {
        setState(() { _error = 'This game has already ended'; _loading = false; }); return;
      }

      final user        = await _auth.getOrCreateUser();
      final playerDocId = '${user.uid}_$name';
      final playerRef   = _db.collection('games').doc(gameId).collection('players').doc(playerDocId);
      final existing    = await playerRef.get();

      if (existing.exists) {
        await playerRef.set({'teamName': name, 'joinedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
      } else {
        await playerRef.set({'teamName': name, 'points': 0,
          'joinedAt': FieldValue.serverTimestamp()});
      }

      await SessionService.save(gameId: gameId, teamName: name, playerId: playerDocId);

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          GameShell(gameId: gameId, teamName: name, playerId: playerDocId)));
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  Future<void> _rejoinLastGame() async {
    final session = _savedSession;
    if (session == null) return;

    setState(() { _rejoinLoading = true; _error = null; });

    try {
      final gameDoc = await _db.collection('games').doc(session['gameId']).get();

      if (!gameDoc.exists || !(gameDoc.data()?['isActive'] ?? false)) {
        await SessionService.clear();
        setState(() {
          _savedSession = null;
          _error = 'That game has ended or no longer exists.';
          _rejoinLoading = false;
        });
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          GameShell(
            gameId:   session['gameId']!,
            teamName: session['teamName']!,
            playerId: session['playerId']!,
          )));
    } catch (e) {
      setState(() { _error = 'Error: $e'; _rejoinLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ScavColors.bg,
    appBar: AppBar(title: const Text('Join Game'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => Navigator.pop(context))),
    body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: ScavColors.surface,
            borderRadius: BorderRadius.circular(14), border: Border.all(color: ScavColors.border)),
          child: const Center(child: Text('▶️', style: TextStyle(fontSize: 26)))),
        const SizedBox(height: 16),
        const Text('Join a game', style: TextStyle(color: ScavColors.textPrimary,
          fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
        const SizedBox(height: 4),
        const Text('Enter the game code and your team name.',
          style: TextStyle(color: ScavColors.textSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 32),
        _label('Game Code'),
        const SizedBox(height: 6),
        TextField(
          controller: _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: ScavColors.textPrimary,
            fontWeight: FontWeight.w900, letterSpacing: 6, fontSize: 24),
          decoration: const InputDecoration(
            hintText: 'XXXXX',
            hintStyle: TextStyle(letterSpacing: 4, fontSize: 22, color: ScavColors.textMuted),
            prefixIcon: Icon(Icons.tag, color: ScavColors.textMuted))),
        const SizedBox(height: 14),
        _label('Team Name'),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: ScavColors.textPrimary, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'e.g. The Wildcards',
            prefixIcon: Icon(Icons.group_outlined, color: ScavColors.textMuted))),
        if (_error != null) ...[
          const SizedBox(height: 12),
          ScavStatusBanner(_error!, color: ScavColors.red, icon: Icons.error_outline),
        ],
        const SizedBox(height: 32),
        ScavPrimaryButton(label: 'Join Game', isLoading: _loading, onPressed: _join),

        // ── Rejoin last game ──────────────────────────────
        if (_savedSession != null) ...[
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: Divider(color: ScavColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: ScavColors.textMuted, fontSize: 12))),
            Expanded(child: Divider(color: ScavColors.border)),
          ]),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _rejoinLoading ? null : _rejoinLastGame,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ScavColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ScavColors.border)),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: ScavColors.surfaceHi,
                    borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('🔄', style: TextStyle(fontSize: 18)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Rejoin last game', style: TextStyle(
                    color: ScavColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Team: ${_savedSession!['teamName']}', style: const TextStyle(
                    color: ScavColors.textSecondary, fontSize: 12)),
                ])),
                _rejoinLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: ScavColors.accent))
                    : const Text('→', style: TextStyle(color: ScavColors.textMuted, fontSize: 18)),
              ]),
            ),
          ),
        ],
      ],
    )),
  );

  Widget _label(String t) => Text(t, style: const TextStyle(
    color: ScavColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600));
}
