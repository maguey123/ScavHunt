import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class PlayerLeaderboardPage extends StatelessWidget {
  final String gameId;
  final String playerId;

  const PlayerLeaderboardPage({super.key, required this.gameId, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games').doc(gameId).collection('players').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(
          child: CircularProgressIndicator(color: ScavColors.accent));

        final players = snap.data!.docs;
        players.sort((a, b) {
          final ap = ((a.data() as Map)['points'] ?? 0).toDouble();
          final bp = ((b.data() as Map)['points'] ?? 0).toDouble();
          return bp.compareTo(ap);
        });

        final myIndex = players.indexWhere((p) => p.id == playerId);
        final myRank  = myIndex >= 0 ? myIndex + 1 : null;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: players.length + 1, // +1 for header
          itemBuilder: (_, i) {
            if (i == 0) {
              // My rank header
              if (myIndex < 0) return const SizedBox();
              final myData   = players[myIndex].data() as Map<String, dynamic>;
              final myName   = myData['teamName'] ?? 'You';
              final myPoints = myData['points'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ScavColors.accentLo, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ScavColors.accent.withOpacity(0.3))),
                child: Row(children: [
                  Text(myRank == 1 ? '🥇' : myRank == 2 ? '🥈' : myRank == 3 ? '🥉' : '#$myRank',
                    style: TextStyle(fontSize: myRank! <= 3 ? 24 : 16,
                      color: myRank <= 3 ? null : ScavColors.accent, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(myName, style: const TextStyle(color: ScavColors.textPrimary,
                      fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('Your team · $myPoints pts', style: const TextStyle(
                      color: ScavColors.textMuted, fontSize: 12)),
                  ])),
                  const Text('You', style: TextStyle(color: ScavColors.accent,
                    fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              );
            }

            final idx  = i - 1;
            final data = players[idx].data() as Map<String, dynamic>;
            final name = data['teamName'] ?? 'Team';
            final pts  = (data['points'] ?? 0).toDouble();
            final isMe = players[idx].id == playerId;
            final medal = idx == 0 ? '🥇' : idx == 1 ? '🥈' : idx == 2 ? '🥉' : '${idx + 1}';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? ScavColors.accentLo : idx == 0 ? ScavColors.amberLo : ScavColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isMe
                    ? ScavColors.accent.withOpacity(0.4)
                    : idx == 0 ? ScavColors.amber.withOpacity(0.3) : ScavColors.border)),
              child: Row(children: [
                SizedBox(width: 32, child: Text(medal, style: TextStyle(
                  fontSize: idx < 3 ? 20 : 13,
                  color: idx < 3 ? null : ScavColors.textMuted, fontWeight: FontWeight.w700))),
                const SizedBox(width: 10),
                Expanded(child: Row(children: [
                  Text(name, style: TextStyle(
                    color: isMe ? ScavColors.accent : ScavColors.textPrimary,
                    fontWeight: FontWeight.w700, fontSize: 14)),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    const ScavChip('You', color: ScavColors.accent),
                  ],
                ])),
                Text('${pts.toStringAsFixed(0)} pts', style: TextStyle(
                  color: idx == 0 ? ScavColors.amber : ScavColors.textSecondary,
                  fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            );
          },
        );
      },
    );
  }
}
