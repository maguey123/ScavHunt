import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'admin/create_game_page.dart';
import 'admin/manage_login_page.dart';
import 'player/join_game_page.dart';
import 'browse_games_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
              const ScavLogo(size: 34),
              const SizedBox(width: 10),
              const Text('ScavHunt', style: TextStyle(
                color: ScavColors.textPrimary, fontSize: 18,
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ]),
          )),

          // ── Hero ─────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Run a hunt.\nWatch teams go.', style: TextStyle(
                color: ScavColors.textPrimary, fontSize: 36,
                fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1.2)),
              const SizedBox(height: 12),
              const Text(
                'Set challenges, share a 5-letter join code,\nand review submissions in real time.',
                style: TextStyle(color: ScavColors.textSecondary, fontSize: 14, height: 1.5)),
            ]),
          )),

          // ── Primary CTAs ──────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
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
                emoji: '▶️',
                title: 'Join a game',
                subtitle: 'Enter a code and play with your team',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const JoinGamePage())),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                emoji: '🌍',
                title: 'Browse public games',
                subtitle: 'Find a pre-made hunt and host it yourself',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const BrowseGamesPage())),
              ),
            ]),
          )),

          // ── Admin section ─────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: const ScavSectionLabel('Admin', padding: EdgeInsets.zero),
          )),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
            child: _ActionCard(
              emoji: '🔑',
              title: 'Manage a game',
              subtitle: 'Password-protected dashboard for organisers',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ManageLoginPage())),
            ),
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
          color: accent ? ScavColors.accent.withOpacity(0.5) : ScavColors.border),
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