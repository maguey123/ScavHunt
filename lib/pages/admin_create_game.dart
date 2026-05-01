import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import 'admin_dashboard.dart';

class AdminCreateGamePage extends StatefulWidget {
  const AdminCreateGamePage({super.key});

  @override
  State<AdminCreateGamePage> createState() => _AdminCreateGamePageState();
}

class _AdminCreateGamePageState extends State<AdminCreateGamePage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(); // 🔐 Password controller
  bool _isLoading = false;
  String? _joinCode;
  String? _gameId;

  final _auth = AuthService();
  final _gameService = GameService();

  Future<void> _createGame() async {
    if (_titleCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _auth.getOrCreateUser();
      final result = await _gameService.createGame(
        user.uid,
        _titleCtrl.text.trim(),
        _descCtrl.text.trim(),
        password: _passwordCtrl.text.trim(), // ✅ pass the password to service
      );

      setState(() {
        _isLoading = false;
        _joinCode = result['code'];
        _gameId = result['id'];
      });
    } catch (e, st) {
      setState(() => _isLoading = false);
      debugPrint('🔥 Error creating game: $e');
      debugPrintStack(stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating game: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Game')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Game Title'),
            ),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _passwordCtrl,
              obscureText: false,
              decoration: const InputDecoration(
                labelText: 'Admin Password',
                hintText: 'Password required to view results later',
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createGame,
                    child: const Text('Create Game'),
                  ),
            const SizedBox(height: 30),
            if (_joinCode != null)
              Column(
                children: [
                  const Text(
                    'Game Created! Share this code with players:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    _joinCode!,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue to Dashboard'),
                    onPressed: () {
                      if (_gameId == null || _joinCode == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminDashboardPage(
                            gameId: _gameId!,
                            joinCode: _joinCode!,
                            title: _titleCtrl.text.trim(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
