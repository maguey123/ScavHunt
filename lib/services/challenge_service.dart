import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeService {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getChallenges(String gameId) => _db
      .collection('games')
      .doc(gameId)
      .collection('challenges')
      .orderBy('createdAt', descending: false)
      .snapshots();

  Future<void> addChallenge({
    required String gameId,
    required String title,
    required String description,
    required String type,
    required int points,
    Map<String, dynamic>? location,
    String? extraChallenge,
    bool released = true,
    int? releaseAfterMinutes, // null = immediate
  }) async {
    await _db
        .collection('games')
        .doc(gameId)
        .collection('challenges')
        .add({
      'title': title,
      'description': description,
      'type': type,
      'points': points,
      'location': location,
      'extraChallenge': extraChallenge,
      'released': released,
      'releaseAfterMinutes': releaseAfterMinutes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateChallenge({
    required String gameId,
    required String challengeId,
    required Map<String, dynamic> data,
  }) async {
    await _db
        .collection('games')
        .doc(gameId)
        .collection('challenges')
        .doc(challengeId)
        .update(data);
  }

  Future<void> deleteChallenge(String gameId, String challengeId) async {
    await _db
        .collection('games')
        .doc(gameId)
        .collection('challenges')
        .doc(challengeId)
        .delete();
  }

  /// Returns only challenges visible to players right now.
  /// A challenge is visible if:
  ///   - released == true AND releaseAfterMinutes == null, OR
  ///   - startedAt + releaseAfterMinutes <= now
  static List<QueryDocumentSnapshot> filterVisibleChallenges(
    List<QueryDocumentSnapshot> all,
    DateTime? gameStartedAt,
  ) {
    final now = DateTime.now();
    return all.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final released = data['released'] ?? true;
      if (!released) return false;

      final releaseAfter = data['releaseAfterMinutes'];
      if (releaseAfter == null) return true; // immediately available

      if (gameStartedAt == null) return false;
      final unlockTime = gameStartedAt.add(Duration(minutes: releaseAfter as int));
      return now.isAfter(unlockTime);
    }).toList();
  }
}
