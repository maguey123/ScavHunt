import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'player_challenges_page.dart';

class JoinGamePage extends StatefulWidget {
  const JoinGamePage({super.key});

  @override
  State<JoinGamePage> createState() => _JoinGamePageState();
}

class _JoinGamePageState extends State<JoinGamePage> {
  final _auth = AuthService();
  final _firestore = FirebaseFirestore.instance;

  final _joinCodeCtrl = TextEditingController();
  final _teamNameCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _joinGame() async {
    final joinCode = _joinCodeCtrl.text.trim().toUpperCase();
    final teamName = _teamNameCtrl.text.trim();

    if (joinCode.isEmpty || teamName.isEmpty) {
      setState(() => _errorMsg = 'Please enter both fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // 🔎 Find game by code
      final gameQuery = await _firestore
          .collection('games')
          .where('joinCode', isEqualTo: joinCode)
          .limit(1)
          .get();

      if (gameQuery.docs.isEmpty) {
        setState(() {
          _errorMsg = 'Game code not found!';
          _isLoading = false;
        });
        return;
      }

      final gameDoc = gameQuery.docs.first;
      final gameId = gameDoc.id;
      final gameData = gameDoc.data();

      if (!(gameData['isActive'] ?? true)) {
        setState(() {
          _errorMsg = 'Game has not started yet!';
          _isLoading = false;
        });
        return;
      }

      // 🔑 Get or create user
      final user = await _auth.getOrCreateUser();
      final playerDocId = '${user.uid}_$teamName';
      final playerRef = _firestore
          .collection('games')
          .doc(gameId)
          .collection('players')
          .doc(playerDocId);

      // 👀 Check if this team already exists
      final existing = await playerRef.get();

      if (existing.exists) {
        // ✅ Keep their points and just refresh metadata
        await playerRef.set({
          'teamName': teamName,
          'joinedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // 🆕 New team joins game
        await playerRef.set({
          'teamName': teamName,
          'points': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      // ✅ Navigate to challenge list
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerChallengesPage(
            gameId: gameId,
            teamName: teamName,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMsg = 'Error joining game: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Game')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _joinCodeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Game Code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teamNameCtrl,
              decoration: const InputDecoration(labelText: 'Team Name'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Game'),
                    onPressed: _joinGame,
                  ),
            const SizedBox(height: 12),
            if (_errorMsg != null)
              Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
