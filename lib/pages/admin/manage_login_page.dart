import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import 'admin_shell.dart';

class ManageLoginPage extends StatefulWidget {
  const ManageLoginPage({super.key});
  @override State<ManageLoginPage> createState() => _ManageLoginPageState();
}

class _ManageLoginPageState extends State<ManageLoginPage> {
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false, _obsPass = true;

  Future<void> _enter() async {
    setState(() => _loading = true);
    final q = await FirebaseFirestore.instance.collection('games')
        .where('joinCode', isEqualTo: _codeCtrl.text.trim().toUpperCase())
        .limit(1).get();
    setState(() => _loading = false);

    if (q.docs.isEmpty) {
      _snack('Game not found'); return;
    }
    final game = q.docs.first;
    if ((game['password'] ?? '') == _passCtrl.text.trim()) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          AdminShell(gameId: game.id, joinCode: game['joinCode'])));
    } else {
      _snack('Incorrect password');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ScavColors.bg,
    appBar: AppBar(title: const Text('Manage Game'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => Navigator.pop(context))),
    body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: ScavColors.surface,
            borderRadius: BorderRadius.circular(14), border: Border.all(color: ScavColors.border)),
          child: const Center(child: Text('🔑', style: TextStyle(fontSize: 26)))),
        const SizedBox(height: 16),
        const Text('Manage Game', style: TextStyle(color: ScavColors.textPrimary,
          fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
        const SizedBox(height: 4),
        const Text('Enter your game code and admin password to continue.',
          style: TextStyle(color: ScavColors.textSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 32),
        _label('Game Code'),
        const SizedBox(height: 6),
        TextField(controller: _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: ScavColors.textPrimary,
            fontWeight: FontWeight.w800, letterSpacing: 4, fontSize: 20),
          decoration: const InputDecoration(hintText: 'XXXXX',
            prefixIcon: Icon(Icons.tag, color: ScavColors.textMuted))),
        const SizedBox(height: 14),
        _label('Admin Password'),
        const SizedBox(height: 6),
        TextField(controller: _passCtrl, obscureText: _obsPass,
          style: const TextStyle(color: ScavColors.textPrimary),
          decoration: InputDecoration(hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, color: ScavColors.textMuted),
            suffixIcon: IconButton(
              icon: Icon(_obsPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: ScavColors.textMuted, size: 18),
              onPressed: () => setState(() => _obsPass = !_obsPass)))),
        const SizedBox(height: 32),
        ScavPrimaryButton(label: 'Enter Dashboard', isLoading: _loading, onPressed: _enter),
      ],
    )),
  );

  Widget _label(String t) => Text(t, style: const TextStyle(
    color: ScavColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600));
}
