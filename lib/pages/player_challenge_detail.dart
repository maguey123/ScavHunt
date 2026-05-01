import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';

class PlayerChallengeDetailPage extends StatefulWidget {
  final String gameId;
  final String challengeId;
  final Map<String, dynamic> data;
  final String teamName; // 👈 add this

  const PlayerChallengeDetailPage({
    super.key,
    required this.gameId,
    required this.challengeId,
    required this.data,
  required this.teamName, // 👈 add this
  });

  @override
  State<PlayerChallengeDetailPage> createState() =>
      _PlayerChallengeDetailPageState();
}

class _PlayerChallengeDetailPageState extends State<PlayerChallengeDetailPage> {
  final _auth = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  File? _selectedImage;
  String? _textResponse;
  bool _isSubmitting = false;
  bool _isCompleted = false;
  bool _atCorrectLocation = false;
  bool _checkingLocation = false;
  String? _locationMsg;
  String? _submissionMsg;

  @override
  void initState() {
    super.initState();
    _checkIfCompleted();
  }

  Future<void> _checkIfCompleted() async {
    final user = await _auth.getOrCreateUser();
    final doc = await _firestore
        .collection('games')
        .doc(widget.gameId)
        .collection('players')
.doc('${user.uid}_${widget.teamName}')

        .collection('completed')
        .doc(widget.challengeId)
        .get();

    if (doc.exists) {
      setState(() {
        _isCompleted = true;
        _submissionMsg = '✅ You already completed this challenge.';
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _confirmLocation() async {
    setState(() {
      _checkingLocation = true;
      _locationMsg = null;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final playerLat = position.latitude;
      final playerLng = position.longitude;

      double targetLat = 0.0;
      double targetLng = 0.0;
      double radius = 20.0;

      final locVal = widget.data['location'];
      if (locVal is GeoPoint) {
        targetLat = locVal.latitude;
        targetLng = locVal.longitude;
      } else if (locVal is Map) {
        final lat = locVal['lat'];
        final lng = locVal['lng'];
        if (lat is num && lng is num) {
          targetLat = lat.toDouble();
          targetLng = lng.toDouble();
        }
        if (locVal['radius'] is num) {
          radius = (locVal['radius'] as num).toDouble();
        }
      }

      if (targetLat == 0.0 && targetLng == 0.0) {
        setState(() {
          _locationMsg =
              "⚠️ Challenge location not set correctly in Firestore.";
          _checkingLocation = false;
        });
        return;
      }

      final distance = Geolocator.distanceBetween(
        playerLat,
        playerLng,
        targetLat,
        targetLng,
      );

      if (distance <= radius) {
        setState(() {
          _atCorrectLocation = true;
          _locationMsg =
              "✅ You’re within range! (${distance.toStringAsFixed(1)} m)";
        });
      } else {
        setState(() {
          _atCorrectLocation = false;
          _locationMsg =
              "❌ Too far — ${distance.toStringAsFixed(1)} m away. Move closer!";
        });
      }
    } catch (e) {
      setState(() {
        _locationMsg = "Error checking location: $e";
      });
    } finally {
      setState(() {
        _checkingLocation = false;
      });
    }
  }

Future<void> _submitChallenge() async {
  if (_isCompleted) {
    if (!mounted) return;
    setState(() {
      _submissionMsg = '✅ Already submitted!';
    });
    return;
  }

  if (!mounted) return;
  setState(() {
    _isSubmitting = true;
    _submissionMsg = null;
  });

  try {
    final user = await _auth.getOrCreateUser();
    final challengeType = widget.data['type'];
    String? imageUrl;

    // Prevent duplicate submission
    final subRef = _firestore
        .collection('games')
        .doc(widget.gameId)
        .collection('submissions');
final teamPlayerId = '${user.uid}_${widget.teamName}';
final existing = await subRef
    .where('playerId', isEqualTo: teamPlayerId)
    .where('challengeId', isEqualTo: widget.challengeId)
    .get();


    if (existing.docs.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _isCompleted = true;
        _isSubmitting = false;
        _submissionMsg = '✅ Already completed!';
      });
      return;
    }

    // 📸 Upload photo (photo or location_photo)
    if ((challengeType == 'photo' || challengeType == 'location_photo') &&
        _selectedImage != null) {
      final ref = _storage.ref().child(
          'games/${widget.gameId}/submissions/${user.uid}_${widget.challengeId}.jpg');
      await ref.putFile(_selectedImage!);
      imageUrl = await ref.getDownloadURL();
    }

    // 📝 Text response
    final textResp = _textResponse?.trim();

await subRef.add({
  'playerId': '${user.uid}_${widget.teamName}', // ✅ use team-based ID
  'challengeId': widget.challengeId,
  'challengeTitle': widget.data['title'],
  'type': challengeType,
  'mediaUrl': imageUrl,
  'textResponse': textResp,
  'submittedAt': FieldValue.serverTimestamp(),
});


    // ✅ Mark completed
    await _firestore
        .collection('games')
        .doc(widget.gameId)
        .collection('players')
        .doc('${user.uid}_${widget.teamName}')
        .collection('completed')
        .doc(widget.challengeId)
        .set({
      'completedAt': FieldValue.serverTimestamp(),
    });

    // 🏆 Add challenge points to player total
    final challengePoints = (widget.data['points'] ?? 0) as int;
    final playerRef = _firestore
        .collection('games')
        .doc(widget.gameId)
        .collection('players')
        .doc('${user.uid}_${widget.teamName}'); // ✅ fixed syntax

    await playerRef.set({
      'points': FieldValue.increment(challengePoints),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _isCompleted = true;
      _submissionMsg = '✅ Challenge submitted! +$challengePoints points';
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _submissionMsg = 'Error: $e';
    });
  }
}



  @override
  Widget build(BuildContext context) {
    final type = widget.data['type'];
    final title = widget.data['title'] ?? '';
    final desc = widget.data['description'] ?? '';
    final extraChallenge = widget.data['extraChallenge'];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(desc, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),

            // 📍 LOCATION or LOCATION+PHOTO button
            if (type == 'location' || type == 'location_photo')
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isCompleted || _checkingLocation
                        ? null
                        : _confirmLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Confirm Location'),
                  ),
                  if (_checkingLocation)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (_locationMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _locationMsg!,
                        style: TextStyle(
                          color: _locationMsg!.contains('✅')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                ],
              ),

            // 📜 Show follow-up challenge text after location confirm (for location_photo)
            if (type == 'location_photo' && _atCorrectLocation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  Text(
                    extraChallenge ?? 'Take a photo to complete this task!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),

            // 📸 PHOTO challenge (unlocked only after location confirm for location_photo)
            if (type == 'photo' ||
                (type == 'location_photo' && _atCorrectLocation))
              Column(
                children: [
                  _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          height: 250,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 250,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child:
                              const Center(child: Text('No image selected yet')),
                        ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isCompleted ? null : _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ],
              ),

            // 📝 TEXT RESPONSE CHALLENGE
            if (type == 'text')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Response:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    enabled: !_isCompleted,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type your answer here...',
                    ),
                    maxLines: 4,
                    onChanged: (value) => _textResponse = value,
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // 🟢 Submit button
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: (_isCompleted ||
                        (type == 'location' && !_atCorrectLocation) ||
                        (type == 'location_photo' &&
                            (!_atCorrectLocation || _selectedImage == null)))
                    ? null
                    : _submitChallenge,
                icon: const Icon(Icons.check),
                label: Text(_isCompleted
                    ? 'Completed'
                    : 'Submit Challenge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isCompleted ? Colors.grey : Colors.green,
                ),
              ),

            const SizedBox(height: 10),
            if (_submissionMsg != null)
              Text(
                _submissionMsg!,
                style: TextStyle(
                  color: _submissionMsg!.startsWith('✅')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
