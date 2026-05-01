import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeService {
  final _db = FirebaseFirestore.instance;

  Future<void> addChallenge({
    required String gameId,
    required String title,
    required String description,
    required String type,
    required int points,
    Map<String, dynamic>? location, // ✅ Optional location data
    String? extraChallenge,         // ✅ NEW for location_photo
  }) async {
    final challengeData = {
      'title': title,
      'description': description,
      'type': type,
      'points': points,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // ✅ Add location data if provided
    if (location != null) {
      challengeData['location'] = {
        'lat': location['lat'],
        'lng': location['lng'],
        'radius': location['radius'],
      };
    }

    // ✅ Add follow-up challenge text if provided
    if (extraChallenge != null && extraChallenge.isNotEmpty) {
      challengeData['extraChallenge'] = extraChallenge;
    }

    await _db
        .collection('games')
        .doc(gameId)
        .collection('challenges')
        .add(challengeData);
  }

  Stream<QuerySnapshot> getChallenges(String gameId) {
    return _db
        .collection('games')
        .doc(gameId)
        .collection('challenges')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
