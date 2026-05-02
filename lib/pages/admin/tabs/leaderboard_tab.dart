import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';

class LeaderboardTab extends StatelessWidget {
  final String gameId;
  const LeaderboardTab({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games').doc(gameId).collection('players').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(
          child: CircularProgressIndicator(color: ScavColors.accent));

        final players = snap.data!.docs;
        if (players.isEmpty) return _empty();

        players.sort((a, b) {
          final ap = ((a.data() as Map)['points'] ?? 0).toDouble();
          final bp = ((b.data() as Map)['points'] ?? 0).toDouble();
          return bp.compareTo(ap);
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: players.length,
          itemBuilder: (_, i) {
            final data   = players[i].data() as Map<String, dynamic>;
            final name   = data['teamName'] ?? 'Team';
            final points = (data['points'] ?? 0).toDouble();
            final medal  = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: i == 0 ? ScavColors.amberLo : ScavColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: i == 0
                    ? ScavColors.amber.withOpacity(0.4) : ScavColors.border),
              ),
              child: Row(children: [
                SizedBox(width: 32, child: Text(medal, style: TextStyle(
                  fontSize: i < 3 ? 22 : 14, color: i < 3 ? null : ScavColors.textMuted,
                  fontWeight: FontWeight.w700))),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: const TextStyle(
                  color: ScavColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: i == 0 ? ScavColors.amber.withOpacity(0.2) : ScavColors.surfaceHi,
                    borderRadius: BorderRadius.circular(20)),
                  child: Text('${points.toStringAsFixed(0)} pts', style: TextStyle(
                    color: i == 0 ? ScavColors.amber : ScavColors.textSecondary,
                    fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _empty() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('🏆', style: TextStyle(fontSize: 40)),
      SizedBox(height: 12),
      Text('No teams yet', style: TextStyle(color: ScavColors.textSecondary, fontSize: 15)),
    ]));
}
