import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';

class GameService {
  final _db = FirebaseFirestore.instance;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(5, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<Map<String, String>> createGame(
    String uid,
    String title,
    String description, {
    String password = '',
    int? durationMinutes,
    bool isPublished = false,
    bool positionMultiplierEnabled = false,
    double? firstMultiplier,
    double? secondMultiplier,
    double? thirdMultiplier,
  }) async {
    final code = _generateCode();
    final ref = await _db.collection('games').add({
      'title': title,
      'description': description,
      'joinCode': code,
      'password': password,
      'ownerId': uid,
      'isActive': false,
      'isPublished': isPublished,
      'published': isPublished,
      'durationMinutes': durationMinutes,
      'positionMultiplierEnabled': positionMultiplierEnabled,
      'firstMultiplier':  positionMultiplierEnabled ? (firstMultiplier  ?? 2.0)  : null,
      'secondMultiplier': positionMultiplierEnabled ? (secondMultiplier ?? 1.5)  : null,
      'thirdMultiplier':  positionMultiplierEnabled ? (thirdMultiplier  ?? 1.25) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
    });
    return {'id': ref.id, 'code': code};
  }

  Future<Map<String, String>> cloneGame(String oldCode, String uid) async {
    final query = await _db
        .collection('games')
        .where('joinCode', isEqualTo: oldCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw Exception('Game not found: $oldCode');

    final oldGame = query.docs.first;
    final oldData = oldGame.data();
    final code = _generateCode();

    final newRef = await _db.collection('games').add({
      'title': oldData['title'],
      'description': oldData['description'] ?? '',
      'joinCode': code,
      'password': oldData['password'] ?? '',
      'ownerId': uid,
      'isActive': false,
      'isPublished': false,
      'published': false,
      'durationMinutes': oldData['durationMinutes'],
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
    });

    // Copy challenges
    final challenges = await _db
        .collection('games')
        .doc(oldGame.id)
        .collection('challenges')
        .get();

    for (final doc in challenges.docs) {
      await newRef.collection('challenges').add(doc.data());
    }

    return {'id': newRef.id, 'code': code};
  }

  Future<void> startGame(String gameId) async {
    await _db.collection('games').doc(gameId).update({
      'isActive': true,
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endGame(String gameId) async {
    await _db.collection('games').doc(gameId).update({'isActive': false});
  }

  Future<void> setPublished(String gameId, bool published) async {
    await _db.collection('games').doc(gameId).update({
      'isPublished': published,  // app field
      'published': published,    // website field
    });
  }

  Future<void> deleteGame(String gameId) async {
    final storage = FirebaseStorage.instance;
    final gameRef = _db.collection('games').doc(gameId);

    final submissions = await gameRef.collection('submissions').get();
    for (final d in submissions.docs) {
      final url = (d.data())['mediaUrl'] as String?;
      if (url != null && url.isNotEmpty) {
        try { await storage.refFromURL(url).delete(); } catch (_) {}
      }
    }

    final batch = _db.batch();
    for (final d in submissions.docs) { batch.delete(d.reference); }
    final challenges = await gameRef.collection('challenges').get();
    for (final d in challenges.docs) { batch.delete(d.reference); }
    final players = await gameRef.collection('players').get();
    for (final d in players.docs) { batch.delete(d.reference); }
    await batch.commit();
    await gameRef.delete();
  }

  Stream<DocumentSnapshot> watchGame(String gameId) =>
      _db.collection('games').doc(gameId).snapshots();

  Stream<QuerySnapshot> watchPlayers(String gameId) =>
      _db.collection('games').doc(gameId).collection('players').snapshots();

  Stream<QuerySnapshot> watchSubmissions(String gameId) =>
      _db.collection('games').doc(gameId).collection('submissions').snapshots();

  Stream<QuerySnapshot> watchPublicGames() =>
      _db.collection('games').where('published', isEqualTo: true).snapshots();
}