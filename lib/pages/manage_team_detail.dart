import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTeamDetail extends StatelessWidget {
  final String gameId;
  final String teamId;
  final String teamName;

  const ManageTeamDetail({
    super.key,
    required this.gameId,
    required this.teamId,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    final challengesRef = FirebaseFirestore.instance
        .collection('games')
        .doc(gameId)
        .collection('challenges')
        .snapshots();

    final subsRef = FirebaseFirestore.instance
        .collection('games')
        .doc(gameId)
        .collection('submissions')
        .where('playerId', isEqualTo: teamId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text('Team: $teamName')),
      body: StreamBuilder<QuerySnapshot>(
        stream: challengesRef,
        builder: (context, challengeSnap) {
          if (!challengeSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final challenges = challengeSnap.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: subsRef,
            builder: (context, subSnap) {
              if (!subSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final submissions = subSnap.data!.docs;

              return ListView.builder(
                itemCount: challenges.length,
                itemBuilder: (context, i) {
                  final challenge = challenges[i];
                  final title = challenge['title'] ?? '';
                  final desc = challenge['description'] ?? '';

                  // ✅ Use try-catch instead of orElse returning null
                  QueryDocumentSnapshot? sub;
                  try {
                    sub = submissions.firstWhere(
                      (s) => s['challengeId'] == challenge.id,
                    );
                  } catch (e) {
                    sub = null;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(desc),
                          if (sub != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: sub['mediaUrl'] != null
                                  ? Image.network(
                                      sub['mediaUrl'],
                                      height: 150,
                                      fit: BoxFit.cover,
                                    )
                                  : Text(
                                      'Response: ${sub['textResponse'] ?? '—'}',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                            ),
                        ],
                      ),
                      trailing: sub != null
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.hourglass_empty),
                    ),
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
