import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';
import '../../../services/game_service.dart';

class OverviewTab extends StatelessWidget {
  final String gameId;
  final Map<String, dynamic> gameData;

  const OverviewTab({super.key, required this.gameId, required this.gameData});

  @override
  Widget build(BuildContext context) {
    final isActive  = gameData['isActive'] ?? false;
    final gs        = GameService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Game state banner ──────────────────────────────
        if (!isActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ScavColors.amberLo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScavColors.amber.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Game is inactive', style: TextStyle(
                color: ScavColors.amber, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Start the game to let teams join using the code in the header.',
                style: TextStyle(color: ScavColors.textSecondary, fontSize: 12, height: 1.4)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Start Game'),
                  style: ElevatedButton.styleFrom(backgroundColor: ScavColors.amber,
                    foregroundColor: Colors.black),
                  onPressed: () => gs.startGame(gameId),
                ),
              ),
            ]),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ScavColors.greenLo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScavColors.green.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: ScavColors.green, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              const Expanded(child: Text('Game is LIVE — players can join now',
                style: TextStyle(color: ScavColors.green, fontWeight: FontWeight.w600, fontSize: 13))),
              TextButton(
                onPressed: () => gs.endGame(gameId),
                child: const Text('End', style: TextStyle(color: ScavColors.red, fontSize: 12)),
              ),
            ]),
          ),

        const SizedBox(height: 24),
        Row(children: [
          const Text('LIVE DATA', style: TextStyle(
            color: ScavColors.textMuted, fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(width: 6),
          const Text('· refreshes every 5s', style: TextStyle(
            color: ScavColors.textMuted, fontSize: 10)),
        ]),
        const SizedBox(height: 12),

        // ── Live stats grid ────────────────────────────────
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('games').doc(gameId).collection('challenges').snapshots(),
          builder: (context, cSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('games').doc(gameId).collection('players').snapshots(),
              builder: (context, pSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('games').doc(gameId).collection('submissions').snapshots(),
                  builder: (context, sSnap) {
                    final cCount = cSnap.data?.docs.length ?? 0;
                    final pCount = pSnap.data?.docs.length ?? 0;
                    final sCount = sSnap.data?.docs.length ?? 0;
                    final possible = cCount * (pCount == 0 ? 1 : pCount);
                    final pct = possible > 0 ? (sCount / possible * 100).round() : 0;

                    return Column(children: [
                      Row(children: [
                        Expanded(child: _StatTile('🎯', '$cCount', 'challenges')),
                        const SizedBox(width: 8),
                        Expanded(child: _StatTile('👥', '$pCount', 'teams joined')),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _StatTile('📸', '$sCount', 'submissions')),
                        const SizedBox(width: 8),
                        Expanded(child: _StatTile('✅', '$pct%', 'completion')),
                      ]),

                      // Team progress bars
                      if (pSnap.hasData && pSnap.data!.docs.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const ScavSectionLabel('Team Progress', padding: EdgeInsets.zero),
                        const SizedBox(height: 8),
                        ...pSnap.data!.docs.map((p) {
                          final pd = p.data() as Map<String, dynamic>;
                          final name = pd['teamName'] ?? 'Team';
                          final teamSubs = sSnap.data?.docs
                              .where((s) => (s.data() as Map)['playerId'] == p.id)
                              .length ?? 0;
                          final pct2 = cCount > 0 ? teamSubs / cCount : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(name, style: const TextStyle(
                                  color: ScavColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                Text('$teamSubs / $cCount', style: const TextStyle(
                                  color: ScavColors.textMuted, fontSize: 12)),
                              ]),
                              const SizedBox(height: 4),
                              ClipRRect(borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct2.toDouble(),
                                  backgroundColor: ScavColors.border,
                                  color: ScavColors.accent,
                                  minHeight: 5,
                                )),
                            ]),
                          );
                        }),
                      ],
                    ]);
                  },
                );
              },
            );
          },
        ),

        // ── Quick tips ─────────────────────────────────────
        const SizedBox(height: 28),
        const ScavSectionLabel('Quick Tips', padding: EdgeInsets.zero),
        const SizedBox(height: 8),
        ScavCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          _Tip('Start Game to make it joinable for players'),
          SizedBox(height: 6),
          _Tip('Share the join code — players enter it in the app'),
          SizedBox(height: 6),
          _Tip('Head to Challenges to add or edit tasks'),
          SizedBox(height: 6),
          _Tip('View real-time scores in Leaderboard'),
          SizedBox(height: 6),
          _Tip('Review team photos & answers in Submissions'),
        ])),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji, value, label;
  const _StatTile(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: ScavColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ScavColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: ScavColors.textPrimary,
        fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      Text(label, style: const TextStyle(color: ScavColors.textMuted, fontSize: 11)),
    ]),
  );
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('•  ', style: TextStyle(color: ScavColors.accent, fontSize: 14)),
    Expanded(child: Text(text, style: const TextStyle(
      color: ScavColors.textSecondary, fontSize: 13, height: 1.4))),
  ]);
}
