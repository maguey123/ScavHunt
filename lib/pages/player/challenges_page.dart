import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import 'challenge_detail_page.dart';

class PlayerChallengesPage extends StatelessWidget {
  final String gameId;
  final String teamName;
  final String playerId;
  final List<QueryDocumentSnapshot> challenges;
  final Future<void> Function() onRefresh;

  const PlayerChallengesPage({
    super.key,
    required this.gameId,
    required this.teamName,
    required this.playerId,
    required this.challenges,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to this player's submissions in real-time
    final subsRef = FirebaseFirestore.instance
        .collection('games').doc(gameId)
        .collection('submissions')
        .where('playerId', isEqualTo: playerId)
        .snapshots();

    // Live points
    final playerRef = FirebaseFirestore.instance
        .collection('games').doc(gameId)
        .collection('players').doc(playerId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: playerRef,
      builder: (context, playerSnap) {
        final playerData = playerSnap.hasData && playerSnap.data!.exists
            ? playerSnap.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};
        final points = playerData['points'] ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: subsRef,
          builder: (context, subSnap) {
            final subs = subSnap.data?.docs ?? [];

            final sorted = [...challenges];
            sorted.sort((a, b) {
              final aDone = subs.any((s) => (s.data() as Map)['challengeId'] == a.id);
              final bDone = subs.any((s) => (s.data() as Map)['challengeId'] == b.id);
              if (aDone == bDone) return 0;
              return aDone ? 1 : -1; // incomplete first
            });

            final completedCount = subs.length;
            final totalCount     = challenges.length;
            final progress       = totalCount > 0 ? completedCount / totalCount : 0.0;

            return RefreshIndicator(
              color: ScavColors.accent,
              backgroundColor: ScavColors.surface,
              onRefresh: onRefresh,
              child: CustomScrollView(slivers: [
                // ── Points + Progress header ──────────────────
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(children: [
                    // Points card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: ScavColors.accentLo,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ScavColors.accent.withOpacity(0.3))),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Your Points', style: TextStyle(
                            color: ScavColors.textMuted, fontSize: 11,
                            fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                          const SizedBox(height: 2),
                          Text('$points', style: const TextStyle(
                            color: ScavColors.textPrimary, fontSize: 28,
                            fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        ])),
                        // Completion pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: ScavColors.accentMid, borderRadius: BorderRadius.circular(20)),
                          child: Text('$completedCount / $totalCount done',
                            style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Progress', style: TextStyle(
                          color: ScavColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('${(progress * 100).round()}%', style: const TextStyle(
                          color: ScavColors.textMuted, fontSize: 11)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress, backgroundColor: ScavColors.border,
                          color: ScavColors.accent, minHeight: 6)),
                    ]),
                  ]),
                )),

                // ── Pull-to-refresh hint ──────────────────────
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(children: [
                    const Text('CHALLENGES', style: TextStyle(
                      color: ScavColors.textMuted, fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    const Spacer(),
                    const Text('↓ pull to refresh', style: TextStyle(
                      color: ScavColors.textMuted, fontSize: 10)),
                  ]),
                )),

                // ── Challenge list ────────────────────────────
                challenges.isEmpty
                    ? SliverFillRemaining(child: Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, children: const [
                          Text('⏳', style: TextStyle(fontSize: 36)),
                          SizedBox(height: 12),
                          Text('No challenges available yet',
                            style: TextStyle(color: ScavColors.textSecondary, fontSize: 15)),
                          SizedBox(height: 4),
                          Text('Check back soon — new ones may unlock!',
                            style: TextStyle(color: ScavColors.textMuted, fontSize: 12)),
                        ])))
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        sliver: SliverList(delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final doc  = sorted[i];
                            final data = doc.data() as Map<String, dynamic>;
                            final title  = data['title'] ?? '';
                            final desc   = data['description'] ?? '';
                            final type   = data['type'] ?? '';
                            final points = data['points'] ?? 0;

                            QueryDocumentSnapshot? sub;
                            try {
                              sub = subs.firstWhere(
                                  (s) => (s.data() as Map)['challengeId'] == doc.id);
                            } catch (_) { sub = null; }

                            final subData    = sub?.data() as Map<String, dynamic>?;
                            final isDone     = sub != null;
                            final mediaUrl   = subData?['mediaUrl'];
                            final textResp   = subData?['textResponse'];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: isDone ? null : () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ChallengeDetailPage(
                                    gameId:      gameId,
                                    challengeId: doc.id,
                                    data:        data,
                                    teamName:    teamName,
                                    playerId:    playerId,
                                  ))),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDone ? ScavColors.greenLo : ScavColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDone ? ScavColors.green.withOpacity(0.3) : ScavColors.border)),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Text(challengeTypeEmoji(type),
                                        style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(title, style: TextStyle(
                                        color: isDone ? ScavColors.green : ScavColors.textPrimary,
                                        fontWeight: FontWeight.w700, fontSize: 14))),
                                      if (isDone)
                                        const Icon(Icons.check_circle, color: ScavColors.green, size: 18)
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: ScavColors.accentLo,
                                            borderRadius: BorderRadius.circular(20)),
                                          child: Text('+$points', style: const TextStyle(
                                            color: ScavColors.accent, fontSize: 12,
                                            fontWeight: FontWeight.w700))),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(desc, style: const TextStyle(
                                      color: ScavColors.textSecondary, fontSize: 13, height: 1.4),
                                      maxLines: isDone ? 1 : 2, overflow: TextOverflow.ellipsis),

                                    // Submission preview
                                    if (isDone && (mediaUrl != null || (textResp != null && textResp.toString().isNotEmpty))) ...[
                                      const SizedBox(height: 10),
                                      if (mediaUrl != null)
                                        ClipRRect(borderRadius: BorderRadius.circular(8),
                                          child: Image.network(mediaUrl, height: 140,
                                            width: double.infinity, fit: BoxFit.cover))
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(color: ScavColors.surfaceHi,
                                            borderRadius: BorderRadius.circular(8)),
                                          child: Text('"$textResp"', style: const TextStyle(
                                            color: ScavColors.textSecondary, fontStyle: FontStyle.italic,
                                            fontSize: 12))),
                                    ],

                                    if (!isDone) ...[
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        ScavChip(challengeTypeLabel(type), color: ScavColors.textSecondary),
                                        const Spacer(),
                                        const Text('Tap to start →', style: TextStyle(
                                          color: ScavColors.textMuted, fontSize: 11)),
                                      ]),
                                    ],
                                  ]),
                                ),
                              ),
                            );
                          },
                          childCount: sorted.length,
                        )),
                      ),
              ]),
            );
          },
        );
      },
    );
  }
}
