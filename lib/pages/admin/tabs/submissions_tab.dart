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

  // null = team list, non-null = viewing one team's submissions
  String? _selectedTeamId;

  static String _teamName(String playerId) {
    final idx = playerId.indexOf('_');
    return idx == -1 ? playerId : playerId.substring(idx + 1);
  }

  Future<void> _download(List<QueryDocumentSnapshot> subs) async {
    final withPhotos = subs.where((s) =>
      (s.data() as Map)['mediaUrl']?.toString().isNotEmpty == true).toList();

    if (withPhotos.isEmpty) {
      setState(() => _status = 'No photos to download.');
      return;
    }
    setState(() { _downloading = true; _status = 'Fetching...'; });

    try {
      final base   = await getApplicationDocumentsDirectory();
      final folder = Directory('${base.path}/ScavHunt_${widget.gameTitle}');
      if (!await folder.exists()) await folder.create(recursive: true);

      final dio = Dio();
      int count = 0;
      for (final sub in withPhotos) {
        final d      = sub.data() as Map;
        final url    = d['mediaUrl'];
        final teamId = (d['playerId'] ?? 'team').toString();
        final cTitle = (d['challengeTitle'] ?? 'unknown').toString()
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
    await SharePlus.instance.share(
      ShareParams(
        files: files.map((f) => XFile(f.path)).toList(),
        text: '📸 Photos from ${widget.gameTitle}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games').doc(widget.gameId).collection('submissions')
          .orderBy('submittedAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: ScavColors.accent));
        }

        final subs = snap.data!.docs;

        // Group by playerId
        final grouped = <String, List<QueryDocumentSnapshot>>{};
        for (final sub in subs) {
          final pid = (sub.data() as Map)['playerId'] as String? ?? '';
          grouped.putIfAbsent(pid, () => []).add(sub);
        }

        if (_selectedTeamId != null) {
          final teamSubs = grouped[_selectedTeamId] ?? [];
          return _buildTeamDetail(teamSubs);
        }

        return _buildTeamList(subs, grouped);
      },
    );
  }

  // ── Team list ──────────────────────────────────────────────────────────────

  Widget _buildTeamList(
    List<QueryDocumentSnapshot> allSubs,
    Map<String, List<QueryDocumentSnapshot>> grouped,
  ) {
    return Column(children: [
      // Action bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Text('${grouped.length} team${grouped.length == 1 ? '' : 's'} · ${allSubs.length} submissions',
            style: const TextStyle(color: ScavColors.textSecondary, fontSize: 13)),
          const Spacer(),
          if (_status != null)
            Text(_status!, style: TextStyle(
              fontSize: 11,
              color: _status!.startsWith('✅') ? ScavColors.green
                  : _status!.startsWith('❌') ? ScavColors.red
                  : ScavColors.textMuted)),
          IconButton(
            icon: _downloading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ScavColors.accent))
                : const Icon(Icons.download_outlined, color: ScavColors.textSecondary),
            tooltip: 'Download all photos',
            onPressed: _downloading ? null : () => _download(allSubs),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: ScavColors.textSecondary),
            tooltip: 'Share photos',
            onPressed: _lastFolder != null ? _share : null,
          ),
        ]),
      ),
      const Divider(height: 1, color: ScavColors.border),
      Expanded(child: grouped.isEmpty
          ? _empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: grouped.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final teamId   = grouped.keys.elementAt(i);
                final teamSubs = grouped[teamId]!;
                final name     = _teamName(teamId);
                final photos   = teamSubs.where(
                    (s) => (s.data() as Map)['mediaUrl'] != null).length;

                return GestureDetector(
                  onTap: () => setState(() => _selectedTeamId = teamId),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ScavColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ScavColors.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: ScavColors.accentLo,
                          borderRadius: BorderRadius.circular(10)),
                        child: const Center(child: Text('👥',
                          style: TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(
                          color: ScavColors.textPrimary,
                          fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(children: [
                          ScavChip('${teamSubs.length} submitted', color: ScavColors.textSecondary),
                          if (photos > 0) ...[
                            const SizedBox(width: 6),
                            ScavChip('📸 $photos photo${photos == 1 ? '' : 's'}',
                              color: ScavColors.accent),
                          ],
                        ]),
                      ])),
                      const Icon(Icons.chevron_right, color: ScavColors.textMuted, size: 20),
                    ]),
                  ),
                );
              },
            )),
    ]);
  }

  // ── Team detail ────────────────────────────────────────────────────────────

  Widget _buildTeamDetail(List<QueryDocumentSnapshot> teamSubs) {
    final name = _teamName(_selectedTeamId!);

    return Column(children: [
      // Header with back button
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ScavColors.border))),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: ScavColors.textMuted),
            onPressed: () => setState(() => _selectedTeamId = null),
          ),
          const SizedBox(width: 4),
          const Text('👥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(
            color: ScavColors.textPrimary,
            fontSize: 15, fontWeight: FontWeight.w700))),
          ScavChip('${teamSubs.length} submission${teamSubs.length == 1 ? '' : 's'}',
            color: ScavColors.textSecondary),
          const SizedBox(width: 8),
        ]),
      ),
      Expanded(child: teamSubs.isEmpty
          ? _empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: teamSubs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _submissionCard(teamSubs[i]),
            )),
    ]);
  }

  Widget _submissionCard(QueryDocumentSnapshot sub) {
    final d        = sub.data() as Map<String, dynamic>;
    final cTitle   = d['challengeTitle'] ?? '—';
    final mediaUrl = d['mediaUrl'];
    final textResp = d['textResponse'];
    final type     = d['type'] ?? '';

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
        if (mediaUrl != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(mediaUrl, height: 200, width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, prog) => prog == null ? child
                  : Container(height: 200, color: ScavColors.surfaceHi,
                      child: const Center(child: CircularProgressIndicator(
                        strokeWidth: 2, color: ScavColors.accent)))),
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
  }

  Widget _empty() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('📸', style: TextStyle(fontSize: 40)),
      SizedBox(height: 12),
      Text('No submissions yet', style: TextStyle(color: ScavColors.textSecondary, fontSize: 15)),
    ]));
}
