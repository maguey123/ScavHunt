import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../theme/app_theme.dart';

class SubmissionsTab extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  const SubmissionsTab({super.key, required this.gameId, required this.gameTitle});

  @override
  State<SubmissionsTab> createState() => _SubmissionsTabState();
}

class _SubmissionsTabState extends State<SubmissionsTab> {
  bool _downloading = false;
  String? _status;
  Directory? _lastFolder;

  Future<void> _download(List<QueryDocumentSnapshot> subs) async {
    final withPhotos = subs.where((s) =>
      (s.data() as Map)['mediaUrl']?.toString().isNotEmpty == true).toList();

    if (withPhotos.isEmpty) {
      setState(() => _status = 'No photos to download.');
      return;
    }
    setState(() { _downloading = true; _status = 'Fetching...'; });

    try {
      final base = await getApplicationDocumentsDirectory();
      final folder = Directory('${base.path}/ScavHunt_${widget.gameTitle}');
      if (!await folder.exists()) await folder.create(recursive: true);

      final dio = Dio();
      int count = 0;
      for (final sub in withPhotos) {
        final d        = sub.data() as Map;
        final url      = d['mediaUrl'];
        final teamId   = (d['playerId'] ?? 'team').toString();
        final cTitle   = (d['challengeTitle'] ?? 'unknown').toString()
            .replaceAll(RegExp(r'[^\w]'), '_');
        final filename = '${teamId}_${cTitle}_${++count}.jpg';
        await dio.download(url, '${folder.path}/$filename');
        setState(() => _status = 'Downloaded $count / ${withPhotos.length}');
      }
      setState(() {
        _downloading = false;
        _lastFolder  = folder;
        _status      = '✅ ${withPhotos.length} photos downloaded';
      });
    } catch (e) {
      setState(() { _downloading = false; _status = '❌ $e'; });
    }
  }

  Future<void> _share() async {
    if (_lastFolder == null) return;
    final files = _lastFolder!.listSync().whereType<File>()
        .where((f) => f.path.endsWith('.jpg')).toList();
    if (files.isEmpty) return;
    await Share.shareXFiles(files.map((f) => XFile(f.path)).toList(),
        text: '📸 Photos from ${widget.gameTitle}');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games').doc(widget.gameId).collection('submissions')
          .orderBy('submittedAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(
          child: CircularProgressIndicator(color: ScavColors.accent));

        final subs = snap.data!.docs;
        final photoSubs = subs.where((s) =>
          (s.data() as Map)['mediaUrl']?.toString().isNotEmpty == true).toList();

        return Column(children: [
          // Action bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Text('${subs.length} submissions',
                style: const TextStyle(color: ScavColors.textSecondary, fontSize: 13)),
              const Spacer(),
              if (_status != null)
                Expanded(child: Text(_status!, style: TextStyle(
                  fontSize: 11,
                  color: _status!.startsWith('✅') ? ScavColors.green
                      : _status!.startsWith('❌') ? ScavColors.red
                      : ScavColors.textMuted))),
              IconButton(
                icon: _downloading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: ScavColors.accent))
                    : const Icon(Icons.download_outlined, color: ScavColors.textSecondary),
                tooltip: 'Download all photos',
                onPressed: _downloading ? null : () => _download(subs),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: ScavColors.textSecondary),
                tooltip: 'Share photos',
                onPressed: _lastFolder != null ? _share : null,
              ),
            ]),
          ),
          const Divider(height: 1, color: ScavColors.border),
          Expanded(child: subs.isEmpty ? _empty() : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: subs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = subs[i].data() as Map<String, dynamic>;
              final teamId      = d['playerId'] ?? '—';
              final cTitle      = d['challengeTitle'] ?? '—';
              final mediaUrl    = d['mediaUrl'];
              final textResp    = d['textResponse'];
              final type        = d['type'] ?? '';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ScavColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ScavColors.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(challengeTypeEmoji(type), style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(cTitle, style: const TextStyle(
                      color: ScavColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
                  ]),
                  const SizedBox(height: 4),
                  Text(teamId, style: const TextStyle(color: ScavColors.textMuted, fontSize: 11)),
                  if (mediaUrl != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(mediaUrl, height: 200, width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, prog) => prog == null ? child
                            : Container(height: 200, color: ScavColors.surfaceHi,
                                child: const Center(child: CircularProgressIndicator(
                                  strokeWidth: 2, color: ScavColors.accent))),
                      ),
                    ),
                  ],
                  if (textResp != null && textResp.toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: ScavColors.surfaceHi,
                        borderRadius: BorderRadius.circular(8)),
                      child: Text('"$textResp"', style: const TextStyle(
                        color: ScavColors.textSecondary, fontStyle: FontStyle.italic, fontSize: 13)),
                    ),
                  ],
                ]),
              );
            },
          )),
        ]);
      },
    );
  }

  Widget _empty() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('📸', style: TextStyle(fontSize: 40)),
      SizedBox(height: 12),
      Text('No submissions yet', style: TextStyle(color: ScavColors.textSecondary, fontSize: 15)),
    ]));
}
