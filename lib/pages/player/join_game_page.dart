import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
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
  bool _loading = false;
  String? _error;

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

      if (!(gameData['isActive'] ?? false)) {
        setState(() { _error = 'This game hasn\'t started yet'; _loading = false; }); return;
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

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          GameShell(gameId: gameId, teamName: name, playerId: playerDocId)));
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
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
        ScavPrimaryButton(label: 'Start Game', isLoading: _loading, onPressed: _join),
      ],
    )),
  );

  Widget _label(String t) => Text(t, style: const TextStyle(
    color: ScavColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600));
}
