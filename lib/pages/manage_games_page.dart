import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'admin/create_game_page.dart';
import 'admin/manage_login_page.dart';
import 'browse_games_page.dart';

class ManageGamesPage extends StatelessWidget {
  const ManageGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScavColors.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          // ── Nav bar ───────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: ScavColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 12),
              const ScavLogo(size: 28),
              const SizedBox(width: 8),
              const Text('ScavHunt', style: TextStyle(
                color: ScavColors.textPrimary, fontSize: 16,
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ]),
          )),

          // ── Hero ─────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Manage games', style: TextStyle(
                color: ScavColors.textPrimary, fontSize: 32,
                fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1.0)),
              const SizedBox(height: 10),
              const Text(
                'Create a new hunt, browse public games,\nor access your organiser dashboard.',
                style: TextStyle(color: ScavColors.textSecondary, fontSize: 14, height: 1.5)),
            ]),
          )),

          // ── Options ───────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
            child: Column(children: [
              _ActionCard(
                emoji: '✨',
                title: 'Create a new game',
                subtitle: 'Set up challenges, get a 5-letter join code',
                accent: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CreateGamePage())),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                emoji: '🌍',
                title: 'Browse public games',
                subtitle: 'Find a pre-made hunt and host it yourself',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const BrowseGamesPage())),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                emoji: '🔑',
                title: 'Manage a game',
                subtitle: 'Password-protected dashboard for organisers',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ManageLoginPage())),
              ),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final VoidCallback onTap;
  final bool accent;

  const _ActionCard({
    required this.emoji, required this.title,
    required this.subtitle, required this.onTap, this.accent = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent ? ScavColors.accentLo : ScavColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent ? ScavColors.accent.withValues(alpha: 0.5) : ScavColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: accent ? ScavColors.accentMid : ScavColors.surfaceHi,
            borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(
            color: accent ? ScavColors.accent : ScavColors.textPrimary,
            fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: ScavColors.textSecondary, fontSize: 12)),
        ])),
        const SizedBox(width: 8),
        const Text('→', style: TextStyle(color: ScavColors.textMuted, fontSize: 18)),
      ]),
    ),
  );
}
