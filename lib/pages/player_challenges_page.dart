import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'player_challenge_detail.dart';

class PlayerChallengesPage extends StatefulWidget {
  final String gameId;
  final String teamName;

  const PlayerChallengesPage({
    super.key,
    required this.gameId,
    required this.teamName,
  });

  @override
  State<PlayerChallengesPage> createState() => _PlayerChallengesPageState();
}

class _PlayerChallengesPageState extends State<PlayerChallengesPage> {
  final _auth = AuthService();
  final _firestore = FirebaseFirestore.instance;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _auth.getOrCreateUser();
    setState(() => _userId = user.uid);
  }

  /// 🏆 Builds live team score + placing banner
  Widget _buildPointsHeader() {
    if (_userId == null) return const SizedBox();

    final playerDocId = '${_userId!}_${widget.teamName}';

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('games')
          .doc(widget.gameId)
          .collection('players')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final players = snapshot.data!.docs;
        if (players.isEmpty) return const SizedBox();

        // Get all player points safely
        final sorted = players
            .map((p) => {
                  'id': p.id,
                  'points': (() {
  final data = p.data() as Map<String, dynamic>;
  final raw = data['points'];
  if (raw is int) return raw;
  if (raw is double) return raw.toInt(); // ✅ convert safely
  return 0;
})(),

                })
            .toList()
          ..sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

        final totalTeams = sorted.length;
        final myIndex = sorted.indexWhere((p) => p['id'] == playerDocId);
        if (myIndex == -1) return const SizedBox();

        final myPoints = sorted[myIndex]['points'] ?? 0;
        final myRank = myIndex + 1;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepOrangeAccent, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🏅 Points: $myPoints',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                'Place: $myRank / $totalTeams',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: myRank == 1
                      ? Colors.amber[800]
                      : (myRank == 2
                          ? Colors.grey[700]
                          : (myRank == 3
                              ? Colors.brown[600]
                              : Colors.blueGrey)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team: ${widget.teamName}'),
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder(
        future: _auth.getOrCreateUser(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userSnap.data!;
          final teamPlayerId = '${user.uid}_${widget.teamName}'; // ✅ single definition

          final challengesRef = _firestore
              .collection('games')
              .doc(widget.gameId)
              .collection('challenges')
              .snapshots();

          // ✅ Only show submissions for this team
          final submissionsRef = _firestore
              .collection('games')
              .doc(widget.gameId)
              .collection('submissions')
              .where('playerId', isEqualTo: teamPlayerId)
              .snapshots();

          return StreamBuilder<QuerySnapshot>(
            stream: challengesRef,
            builder: (context, challengeSnap) {
              if (!challengeSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final challenges = challengeSnap.data!.docs;

              return StreamBuilder<QuerySnapshot>(
                stream: submissionsRef,
                builder: (context, subSnap) {
                  if (!subSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final playerSubs = subSnap.data!.docs;

                  // Sort incomplete first
                  challenges.sort((a, b) {
                    final aDone =
                        playerSubs.any((s) => s['challengeId'] == a.id);
                    final bDone =
                        playerSubs.any((s) => s['challengeId'] == b.id);
                    if (aDone == bDone) return 0;
                    return aDone ? 1 : -1;
                  });

                  final completedCount = playerSubs.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🏆 Live points + placing banner
                      _buildPointsHeader(),

                      // Progress counter
                      Container(
                        width: double.infinity,
                        color: Colors.deepOrange.shade100,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Progress: $completedCount / ${challenges.length} completed',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // List of challenges
                      Expanded(
                        child: ListView.builder(
                          itemCount: challenges.length,
                          itemBuilder: (context, index) {
                            final doc = challenges[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final title = data['title'] ?? '';
                            final desc = data['description'] ?? '';
                            final type = data['type'] ?? '';

                            // Find if player has completed it
                            QueryDocumentSnapshot? sub;
                            try {
                              sub = playerSubs.firstWhere(
                                  (d) => d['challengeId'] == doc.id);
                            } catch (e) {
                              sub = null;
                            }

                            Map<String, dynamic>? subData = sub != null
                                ? sub.data() as Map<String, dynamic>
                                : null;

                            final isCompleted = sub != null;
                            final mediaUrl = subData?['mediaUrl'];
                            final textResponse = subData?['textResponse'];

                            return Card(
                              color: isCompleted
                                  ? Colors.green.shade100
                                  : Colors.white,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted
                                        ? Colors.green.shade900
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(desc),
                                    if (isCompleted &&
                                        (mediaUrl != null ||
                                            textResponse != null))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: mediaUrl != null
                                            ? Image.network(
                                                mediaUrl,
                                                height: 150,
                                                fit: BoxFit.cover,
                                              )
                                            : Text(
                                                'Your Answer: $textResponse',
                                                style: const TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                      ),
                                  ],
                                ),
                                trailing: isCompleted
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PlayerChallengeDetailPage(
                                        gameId: widget.gameId,
                                        challengeId: doc.id,
                                        data: data,
                                        teamName: widget.teamName, // ✅ ensures isolation
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
