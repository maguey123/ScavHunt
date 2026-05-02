import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScavColors.bg,
      appBar: AppBar(
        backgroundColor: ScavColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: ScavColors.textMuted),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('How it works', style: TextStyle(
          color: ScavColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        children: [

          // ── Intro ─────────────────────────────────────────────
          _IntroCard(),
          const SizedBox(height: 24),

          // ── Playing section ───────────────────────────────────
          _SectionHeader(emoji: '▶️', title: 'Playing a game'),
          const SizedBox(height: 10),
          const _Step(
            number: '1',
            title: 'Get the game code',
            body: 'Your organiser will give you a 5-letter code (e.g. XKTR2). You\'ll need it to join.',
          ),
          const _Step(
            number: '2',
            title: 'Join & pick your team name',
            body: 'Tap "Join a game" on the home screen, enter the code and a unique team name. You\'ll be placed in the lobby straight away.',
          ),
          const _Step(
            number: '3',
            title: 'Wait in the lobby',
            body: 'Once you\'ve joined, you\'ll see a waiting screen. Challenges are hidden until the host starts the game — so stay on this screen!',
          ),
          const _Step(
            number: '4',
            title: 'Complete challenges',
            body: 'When the game starts, challenges appear. Tap one to open it and follow the instructions. Complete as many as you can before time runs out.',
          ),
          const _Step(
            number: '5',
            title: 'Earn points & check the leaderboard',
            body: 'Points are added to your score automatically after each submission. Switch to the Leaderboard tab to see how your team ranks.',
            isLast: true,
          ),

          const SizedBox(height: 24),

          // ── Challenge types ───────────────────────────────────
          _SectionHeader(emoji: '🎯', title: 'Challenge types'),
          const SizedBox(height: 10),
          _ChallengeTypeRow(
            emoji: '📸',
            label: 'Photo',
            desc: 'Open the camera and take a photo to complete the challenge.',
          ),
          _ChallengeTypeRow(
            emoji: '📍',
            label: 'Location',
            desc: 'Physically travel to a specific spot and confirm you\'re there.',
          ),
          _ChallengeTypeRow(
            emoji: '📍📸',
            label: 'Location + Photo',
            desc: 'Be at the right location AND take a photo — two steps in one.',
          ),
          _ChallengeTypeRow(
            emoji: '💬',
            label: 'Text',
            desc: 'Type a written answer to the prompt.',
            isLast: true,
          ),

          const SizedBox(height: 24),

          // ── Hosting section ───────────────────────────────────
          _SectionHeader(emoji: '🛠️', title: 'Hosting a game'),
          const SizedBox(height: 10),
          const _Step(
            number: '1',
            title: 'Create or browse a game',
            body: 'Tap "Manage games" → "Create a new game" to build from scratch, or browse public games and host a copy of one you like.',
          ),
          const _Step(
            number: '2',
            title: 'Set it up',
            body: 'Give your game a title, optional description, time limit, and an admin password to protect your dashboard.',
          ),
          const _Step(
            number: '3',
            title: 'Add challenges',
            body: 'Add as many challenges as you like. Set a title, description, type, point value, and optionally a release delay so challenges unlock over time.',
          ),
          const _Step(
            number: '4',
            title: 'Share the code',
            body: 'Players can join as soon as the game is created — you\'ll see a 5-letter code on your dashboard. Share it with your players.',
          ),
          const _Step(
            number: '5',
            title: 'Start the game',
            body: 'When everyone is in the lobby, tap "Start game" in your dashboard. Challenges become visible to players immediately.',
          ),
          const _Step(
            number: '6',
            title: 'Review submissions',
            body: 'Switch to the Submissions tab to see photos your players have uploaded. You can approve or review them there.',
          ),
          const _Step(
            number: '7',
            title: 'End the game',
            body: 'Tap "End game" to close submissions. Players will see a game-over screen with their final score.',
            isLast: true,
          ),

          const SizedBox(height: 24),

          // ── Tips ──────────────────────────────────────────────
          _SectionHeader(emoji: '💡', title: 'Tips'),
          const SizedBox(height: 10),
          _TipCard(
            title: 'Grant permissions early',
            body: 'When you join a game, allow camera and location access when prompted — you\'ll need both for certain challenges.',
          ),
          _TipCard(
            title: 'Lost connection? Rejoin',
            body: 'If you close the app mid-game, tap "Join a game" again — a "Rejoin last game" button will appear at the bottom so you can jump back in.',
          ),
          _TipCard(
            title: 'Timed releases',
            body: 'Organisers can set challenges to unlock after a delay (e.g. 10 minutes in). Keep checking — new challenges may appear during the game.',
          ),
        ],
      ),
    );
  }
}

// ── Intro card ────────────────────────────────────────────────────────────────

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ScavColors.accentLo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ScavColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🗺️', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome to ScavHunt', style: TextStyle(
            color: ScavColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text(
            'ScavHunt is a real-time scavenger hunt app. Organisers set up challenges and share a code; players join, complete tasks, and earn points.',
            style: TextStyle(color: ScavColors.textSecondary, fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String emoji, title;
  const _SectionHeader({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 8),
      Text(title.toUpperCase(), style: const TextStyle(
        color: ScavColors.textMuted, fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    ]);
  }
}

// ── Numbered step ─────────────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  final String number, title, body;
  final bool isLast;
  const _Step({required this.number, required this.title, required this.body, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: ScavColors.accentMid,
              shape: BoxShape.circle),
            child: Center(child: Text(number, style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900))),
          ),
          if (!isLast)
            Expanded(child: Container(
              width: 1.5, color: ScavColors.border,
              margin: const EdgeInsets.symmetric(vertical: 4))),
        ]),
        const SizedBox(width: 14),
        Expanded(child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(
              color: ScavColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(body, style: const TextStyle(
              color: ScavColors.textSecondary, fontSize: 13, height: 1.5)),
          ]),
        )),
      ]),
    );
  }
}

// ── Challenge type row ────────────────────────────────────────────────────────

class _ChallengeTypeRow extends StatelessWidget {
  final String emoji, label, desc;
  final bool isLast;
  const _ChallengeTypeRow({required this.emoji, required this.label, required this.desc, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScavColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScavColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
            color: ScavColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(
            color: ScavColors.textSecondary, fontSize: 12, height: 1.4)),
        ])),
      ]),
    );
  }
}

// ── Tip card ──────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final String title, body;
  const _TipCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ScavColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScavColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lightbulb_outline, color: ScavColors.amber, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
            color: ScavColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(
            color: ScavColors.textSecondary, fontSize: 12, height: 1.5)),
        ])),
      ]),
    );
  }
}
