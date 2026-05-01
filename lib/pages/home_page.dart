import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../services/auth_service.dart';
import 'admin_create_game.dart';
import 'admin_dashboard.dart';
import 'player_join_game.dart';
import 'manage_game_page.dart'; // 👈 new import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _adminCodeCtrl = TextEditingController();
  final _auth = AuthService();
  final _gameService = GameService();
  bool _isLoading = false;

  /// 🧬 Clone an existing game
  void _cloneGame(String oldCode) async {
    setState(() => _isLoading = true);
    try {
      final user = await _auth.getOrCreateUser();
      final result = await _gameService.cloneGame(oldCode, user.uid);

      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardPage(
            gameId: result['id']!,
            joinCode: result['code']!,
            title: 'Cloned Game',
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// 🔐 Popup dialog for admin cloning
  void _showAdminDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Old Game Code'),
        content: TextField(
          controller: _adminCodeCtrl,
          decoration: const InputDecoration(hintText: 'e.g. X7F9Q'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cloneGame(_adminCodeCtrl.text.trim().toUpperCase());
            },
            child: const Text('Clone Game'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scav Hunt')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome to Scav Hunt!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 🆕 Create Game
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Game'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(220, 50),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminCreateGamePage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),

                    // ▶️ Join Game
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Join Game'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(220, 50),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JoinGamePage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),

                    // ⚙️ Admin Existing Game (Clone)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.settings),
                      label: const Text('Admin Existing Game'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(220, 50),
                      ),
                      onPressed: _showAdminDialog,
                    ),
                    const SizedBox(height: 15),

                    // 🧩 Manage Game (Password protected view-only)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('Manage Game'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(220, 50),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageGamePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
