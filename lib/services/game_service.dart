import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class GameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔤 Generate 5-character join code
  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// 🆕 Create a new game with password protection
  Future<Map<String, String>> createGame(
    String hostId,
    String title,
    String description, {
    required String password, // ✅ Added password parameter
  }) async {
    final code = _generateJoinCode();
    final doc = await _db.collection('games').add({
      'hostId': hostId,
      'title': title,
      'description': description,
      'joinCode': code,
      'password': password, // ✅ Store admin-only password
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': false, // default inactive
    });
    return {'id': doc.id, 'code': code};
  }

  /// 🧬 Clone an existing game (with all its challenges)
  Future<Map<String, String>> cloneGame(String oldCode, String newHostId) async {
    // Find the old game by joinCode
    final oldGameSnap = await _db
        .collection('games')
        .where('joinCode', isEqualTo: oldCode)
        .limit(1)
        .get();

    if (oldGameSnap.docs.isEmpty) {
      throw Exception('No game found with that code');
    }

    final oldGame = oldGameSnap.docs.first;
    final oldGameId = oldGame.id;
    final oldData = oldGame.data();

    // Create new game entry
    final newCode = _generateJoinCode();
    final newGameRef = await _db.collection('games').add({
      'hostId': newHostId,
      'title': oldData['title'] ?? 'Untitled Game',
      'description': oldData['description'] ?? '',
      'joinCode': newCode,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': false,
      'clonedFrom': oldCode,
      'password': oldData['password'] ?? '', // ✅ carry over password if it exists
    });

    // Copy all challenges from old to new
    final challenges = await _db
        .collection('games')
        .doc(oldGameId)
        .collection('challenges')
        .get();

    for (var doc in challenges.docs) {
      await newGameRef.collection('challenges').add(doc.data());
    }

    return {'id': newGameRef.id, 'code': newCode};
  }
}
