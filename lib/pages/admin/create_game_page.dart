import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/game_service.dart';
import 'admin_shell.dart';

class CreateGamePage extends StatefulWidget {
  const CreateGamePage({super.key});

  @override
  State<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends State<CreateGamePage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _isLoading    = false;
  bool _obsPass      = true;
  bool _hasDuration  = false;
  bool _isPublished  = false;
  int  _durationHrs  = 1;
  int  _durationMins = 0;

  String? _joinCode;
  String? _gameId;

  final _auth        = AuthService();
  final _gameService = GameService();

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and password are required')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await _auth.getOrCreateUser();
      final durationMins = _hasDuration
          ? (_durationHrs * 60 + _durationMins)
          : null;
      final result = await _gameService.createGame(
        user.uid,
        _titleCtrl.text.trim(),
        _descCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        durationMinutes: durationMins,
        isPublished: _isPublished,
      );
      setState(() {
        _isLoading = false;
        _joinCode  = result['code'];
        _gameId    = result['id'];
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScavColors.bg,
      appBar: AppBar(
        title: const Text('New Game'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _joinCode == null ? _buildForm() : _buildSuccess(),
      ),
    );
  }

  Widget _buildForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    // Icon + heading
    Container(width: 52, height: 52,
      decoration: BoxDecoration(color: ScavColors.accentLo, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ScavColors.accent.withOpacity(0.4))),
      child: const Center(child: Text('✨', style: TextStyle(fontSize: 26)))),
    const SizedBox(height: 16),
    const Text('New Game', style: TextStyle(color: ScavColors.textPrimary,
      fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
    const SizedBox(height: 4),
    const Text('Set up a new scavenger hunt. A join code will be generated automatically.',
      style: TextStyle(color: ScavColors.textSecondary, fontSize: 13, height: 1.5)),
    const SizedBox(height: 32),

    _label('Game Title *'),
    const SizedBox(height: 6),
    TextField(controller: _titleCtrl,
      style: const TextStyle(color: ScavColors.textPrimary),
      decoration: const InputDecoration(hintText: 'e.g. Bondi Scav Hunt')),
    const SizedBox(height: 14),

    _label('Description'),
    const SizedBox(height: 6),
    TextField(controller: _descCtrl, maxLines: 2,
      style: const TextStyle(color: ScavColors.textPrimary),
      decoration: const InputDecoration(hintText: 'Optional — shown to players')),
    const SizedBox(height: 14),

    _label('Admin Password *'),
    const SizedBox(height: 6),
    TextField(
      controller: _passCtrl,
      obscureText: _obsPass,
      style: const TextStyle(color: ScavColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Save this to manage the game later',
        suffixIcon: IconButton(
          icon: Icon(_obsPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: ScavColors.textMuted, size: 18),
          onPressed: () => setState(() => _obsPass = !_obsPass),
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Row(children: const [
        Icon(Icons.info_outline, size: 12, color: ScavColors.textMuted),
        SizedBox(width: 4),
        Text('Save this — you\'ll need it to manage the game',
          style: TextStyle(fontSize: 11, color: ScavColors.textMuted)),
      ]),
    ),
    const SizedBox(height: 20),

    // Duration toggle
    ScavCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Max Game Duration', style: TextStyle(color: ScavColors.textPrimary,
              fontWeight: FontWeight.w600, fontSize: 14)),
            SizedBox(height: 2),
            Text('Game ends automatically', style: TextStyle(color: ScavColors.textMuted, fontSize: 12)),
          ])),
          Switch(
            value: _hasDuration,
            onChanged: (v) => setState(() => _hasDuration = v),
            activeColor: ScavColors.accent,
            inactiveTrackColor: ScavColors.border,
          ),
        ]),
        if (_hasDuration) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Hours', style: TextStyle(color: ScavColors.textMuted, fontSize: 11)),
              const SizedBox(height: 4),
              _NumberField(
                value: _durationHrs,
                onChanged: (v) => setState(() => _durationHrs = v.clamp(0, 24)),
                max: 24,
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Minutes', style: TextStyle(color: ScavColors.textMuted, fontSize: 11)),
              const SizedBox(height: 4),
              _NumberField(
                value: _durationMins,
                onChanged: (v) => setState(() => _durationMins = v.clamp(0, 59)),
                max: 59,
              ),
            ])),
          ]),
        ],
      ]),
    ),
    const SizedBox(height: 10),

    // Publish toggle
    ScavCard(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🌍  Publish to Browse Games', style: TextStyle(color: ScavColors.textPrimary,
            fontWeight: FontWeight.w600, fontSize: 14)),
          SizedBox(height: 2),
          Text('Others can discover and preview this game', style: TextStyle(
            color: ScavColors.textMuted, fontSize: 12)),
        ])),
        Switch(
          value: _isPublished,
          onChanged: (v) => setState(() => _isPublished = v),
          activeColor: ScavColors.accent,
          inactiveTrackColor: ScavColors.border,
        ),
      ]),
    ),
    const SizedBox(height: 28),

    ScavPrimaryButton(label: 'Create Game', isLoading: _isLoading, onPressed: _create),
  ]);

  Widget _buildSuccess() => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
    const SizedBox(height: 20),
    Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: ScavColors.accentLo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ScavColors.accent.withOpacity(0.4)),
      ),
      child: Column(children: [
        const Text('Game created! Share this code\nwith your players:',
          textAlign: TextAlign.center,
          style: TextStyle(color: ScavColors.textSecondary, fontSize: 14, height: 1.5)),
        const SizedBox(height: 20),
        SelectableText(_joinCode!, style: const TextStyle(
          color: ScavColors.accent, fontSize: 56,
          fontWeight: FontWeight.w900, letterSpacing: 8)),
        const SizedBox(height: 6),
        const Text('5-letter join code', style: TextStyle(color: ScavColors.textMuted, fontSize: 12)),
      ]),
    ),
    const SizedBox(height: 24),
    ScavPrimaryButton(
      label: 'Open Dashboard',
      onPressed: () {
        if (_gameId == null || _joinCode == null) return;
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => AdminShell(gameId: _gameId!, joinCode: _joinCode!)));
      },
    ),
    const SizedBox(height: 12),
    ScavSecondaryButton(
      label: 'Create another',
      onPressed: () => setState(() {
        _joinCode = null; _gameId = null;
        _titleCtrl.clear(); _descCtrl.clear(); _passCtrl.clear();
      }),
    ),
  ]);

  Widget _label(String t) => Text(t, style: const TextStyle(
    color: ScavColors.textSecondary, fontSize: 12,
    fontWeight: FontWeight.w600, letterSpacing: 0.3));
}

class _NumberField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int max;

  const _NumberField({required this.value, required this.onChanged, required this.max});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: value.toString());
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(color: ScavColors.textPrimary, fontWeight: FontWeight.w700),
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(vertical: 10)),
      onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
    );
  }
}
