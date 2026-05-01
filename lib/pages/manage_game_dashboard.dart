import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // ✅ NEW
import 'manage_team_detail.dart';

class ManageGameDashboard extends StatefulWidget {
  final String gameId;
  final String gameTitle;

  const ManageGameDashboard({
    super.key,
    required this.gameId,
    required this.gameTitle,
  });

  @override
  State<ManageGameDashboard> createState() => _ManageGameDashboardState();
}

class _ManageGameDashboardState extends State<ManageGameDashboard> {
  bool _downloading = false;
  String? _downloadStatus;
  Directory? _lastDownloadFolder; // ✅ store folder for sharing
  final _firestore = FirebaseFirestore.instance;

  Future<void> _downloadAllPhotos() async {
    setState(() {
      _downloading = true;
      _downloadStatus = 'Fetching submissions...';
    });

    try {
      final subsSnap = await _firestore
          .collection('games')
          .doc(widget.gameId)
          .collection('submissions')
          .get();

      final subsWithPhotos = subsSnap.docs
          .where((d) => (d.data()['mediaUrl'] ?? '').toString().isNotEmpty)
          .toList();

      if (subsWithPhotos.isEmpty) {
        setState(() {
          _downloading = false;
          _downloadStatus = 'No photos found.';
        });
        return;
      }

      Directory? baseDir;
      try {
        baseDir = await getDownloadsDirectory();
      } catch (_) {
        try {
          baseDir = await getApplicationDocumentsDirectory();
        } catch (_) {
          baseDir = Directory.systemTemp;
        }
      }

      if (baseDir == null) {
        setState(() {
          _downloading = false;
          _downloadStatus = '❌ Could not resolve storage directory.';
        });
        return;
      }

      final folder = Directory('${baseDir.path}/ScavHunt_${widget.gameTitle}');
      if (!await folder.exists()) await folder.create(recursive: true);

      final dio = Dio();
      int count = 0;

      for (var sub in subsWithPhotos) {
        final data = sub.data();
        final url = data['mediaUrl'];
        final challengeTitle = (data['challengeTitle'] ?? 'unknown')
            .toString()
            .replaceAll(RegExp(r'[^\w\s-]'), '_');
        final playerId = (data['playerId'] ?? 'team').toString();
        final filename =
            '${playerId}_${challengeTitle}_${count + 1}.jpg'.replaceAll(' ', '_');
        final savePath = '${folder.path}/$filename';
        await dio.download(url, savePath);
        count++;

        setState(() {
          _downloadStatus = 'Downloaded $count / ${subsWithPhotos.length}';
        });
      }

      setState(() {
        _downloading = false;
        _lastDownloadFolder = folder; // ✅ save for sharing
        _downloadStatus =
            '✅ Downloaded ${subsWithPhotos.length} photos to:\n${folder.path}';
      });
    } catch (e) {
      setState(() {
        _downloading = false;
        _downloadStatus = '❌ Error: $e';
      });
    }
  }

  Future<void> _shareDownloadedPhotos() async {
    if (_lastDownloadFolder == null ||
        !(await _lastDownloadFolder!.exists())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No downloaded photos to share yet.'),
        ),
      );
      return;
    }

    try {
      final files = _lastDownloadFolder!
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'))
          .toList();

      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No photo files found to share.')),
        );
        return;
      }

      await Share.shareXFiles(
        files.map((f) => XFile(f.path)).toList(),
        text: '📸 Photos from ${widget.gameTitle}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing files: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsRef = _firestore
        .collection('games')
        .doc(widget.gameId)
        .collection('players')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage: ${widget.gameTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download all photos',
            onPressed: _downloading ? null : _downloadAllPhotos,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share downloaded photos',
            onPressed: _shareDownloadedPhotos,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_downloading || _downloadStatus != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _downloadStatus ?? '',
                style: TextStyle(
                  color: _downloadStatus?.startsWith('❌') == true
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: teamsRef,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teams = snap.data!.docs;

                if (teams.isEmpty) {
                  return const Center(
                      child: Text('No teams have joined this game yet.'));
                }

                // Sort teams by points descending
                teams.sort((a, b) {
                  final ap =
                      ((a.data() as Map<String, dynamic>)['points'] ?? 0)
                          .toDouble();
                  final bp =
                      ((b.data() as Map<String, dynamic>)['points'] ?? 0)
                          .toDouble();
                  return bp.compareTo(ap);
                });

                return ListView.builder(
                  itemCount: teams.length,
                  itemBuilder: (context, i) {
                    final data = teams[i].data() as Map<String, dynamic>;
                    final name = data['teamName'] ?? 'Unnamed';
                    final points = (data['points'] ?? 0).toDouble();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              i == 0 ? Colors.amber : Colors.grey[400],
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Points: ${points.toStringAsFixed(0)}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageTeamDetail(
                                gameId: widget.gameId,
                                teamId: teams[i].id,
                                teamName: name,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
