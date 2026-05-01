import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_game_dashboard.dart';

class ManageGamePage extends StatefulWidget {
  const ManageGamePage({super.key});

  @override
  State<ManageGamePage> createState() => _ManageGamePageState();
}

class _ManageGamePageState extends State<ManageGamePage> {
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _verifyAndContinue() async {
    setState(() => _loading = true);

    final query = await FirebaseFirestore.instance
        .collection('games')
        .where('joinCode', isEqualTo: _codeCtrl.text.trim().toUpperCase())
        .limit(1)
        .get();

    setState(() => _loading = false);

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game not found')),
      );
      return;
    }

    final game = query.docs.first;
    final storedPass = game['password'] ?? '';

    if (storedPass == _passCtrl.text.trim()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManageGameDashboard(
            gameId: game.id,
            gameTitle: game['title'] ?? 'Untitled Game',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Game')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Game Code',
                hintText: 'Enter game code (e.g. ABC12)',
              ),
            ),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Admin Password',
                hintText: 'Enter game password',
              ),
            ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyAndContinue,
                    child: const Text('View Game'),
                  ),
          ],
        ),
      ),
    );
  }
}
