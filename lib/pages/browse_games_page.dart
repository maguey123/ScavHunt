import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/game_service.dart';
import '../pages/admin/admin_shell.dart';

class BrowseGamesPage extends StatefulWidget {
  const BrowseGamesPage({super.key});

  @override
  State<BrowseGamesPage> createState() => _BrowseGamesPageState();
}

class _BrowseGamesPageState extends State<BrowseGamesPage> {
  final _db          = FirebaseFirestore.instance;
  final _auth        = AuthService();
  final _gameService = GameService();
  final _searchCtrl  = TextEditingController();

  List<QueryDocumentSnapshot> _allGames    = [];
  List<QueryDocumentSnapshot> _filtered    = [];
  bool _loading  = false;
  bool _hosting  = false;
  String _query  = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _db
          .collection('games')
          .where('published', isEqualTo: true)
          .get();
      // Sort client-side newest-first (avoids needing a composite Firestore index)
      final sorted = snap.docs.toList()
        ..sort((a, b) {
          final at = (a.data() as Map<String, dynamic>)['createdAt'];
          final bt = (b.data() as Map<String, dynamic>)['createdAt'];
          if (at == null) return 1;
          if (bt == null) return -1;
          return (bt as Comparable).compareTo(at);
        });
      setState(() {
        _allGames = sorted;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _applyFilter() {
    final q = _query.toLowerCase().trim();
    _filtered = q.isEmpty
        ? List.from(_allGames)
        : _allGames.where((doc) {
            final d     = doc.data() as Map<String, dynamic>;
            final title = (d['title'] ?? '').toString().toLowerCase();
            final desc  = (d['description'] ?? '').toString().toLowerCase();
            return title.contains(q) || desc.contains(q);
          }).toList();
  }

  void _onSearch(String v) {
    setState(() { _query = v; _applyFilter(); });
  }

  Future<void> _hostGame(String gameId, String gameTitle) async {
    setState(() => _hosting = true);
    try {
      // Get the join code of the source game
      final gameDoc = await _db.collection('games').doc(gameId).get();
      final joinCode = gameDoc['joinCode'] as String;

      final user   = await _auth.getOrCreateUser();
      final result = await _gameService.cloneGame(joinCode, user.uid);

      if (!mounted) return;
      setState(() => _hosting = false);

      Navigator.push(context, MaterialPageRoute(
        builder: (_) => AdminShell(gameId: result['id']!, joinCode: result['code']!),
      ));
    } catch (e) {
      setState(() => _hosting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _openPreview(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _GamePreviewPage(
        gameId:    doc.id,
        gameData:  data,
        onHost:    () => _hostGame(doc.id, data['title'] ?? 'Game'),
        isHosting: _hosting,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScavColors.bg,
      appBar: AppBar(
        title: const Text('Browse Games'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(children: [

        // ── Search bar ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            style: const TextStyle(color: ScavColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search games...',
              prefixIcon: const Icon(Icons.search, color: ScavColors.textMuted),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: ScavColors.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      })
                  : null,
            ),
          ),
        ),

        // ── Count label ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            Text(
              _loading
                  ? 'Loading...'
                  : '${_filtered.length} public game${_filtered.length == 1 ? '' : 's'}',
              style: const TextStyle(color: ScavColors.textMuted, fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
          ]),
        ),

        const Divider(height: 1, color: ScavColors.border),

        // ── Game list ───────────────────────────────────────
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: ScavColors.accent))
            : _filtered.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final doc  = _filtered[i];
                      final data = doc.data() as Map<String, dynamic>;
                      return _GameCard(
                        data: data,
                        onTap: () => _openPreview(doc),
                      );
                    },
                  )),
      ]),
    );
  }

  Widget _empty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('🌍', style: TextStyle(fontSize: 40)),
    const SizedBox(height: 12),
    Text(
      _query.isNotEmpty ? 'No games match "$_query"' : 'No public games yet',
      style: const TextStyle(color: ScavColors.textSecondary, fontSize: 15,
        fontWeight: FontWeight.w600)),
    const SizedBox(height: 4),
    const Text('Games marked as published will appear here.',
      style: TextStyle(color: ScavColors.textMuted, fontSize: 12)),
    const SizedBox(height: 20),
    TextButton.icon(
      icon: const Icon(Icons.refresh, color: ScavColors.accent, size: 16),
      label: const Text('Refresh', style: TextStyle(color: ScavColors.accent)),
      onPressed: _load,
    ),
  ]));
}

// ─────────────────────────────────────────────
//  Game card in browse list
// ─────────────────────────────────────────────
class _GameCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _GameCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final desc  = data['description'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ScavColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ScavColors.border),
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: ScavColors.accentLo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScavColors.accent.withOpacity(0.3)),
            ),
            child: const Center(child: Text('🌍', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(
              color: ScavColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(color: ScavColors.textSecondary, fontSize: 12),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ])),
          const SizedBox(width: 8),
          const Text('→', style: TextStyle(color: ScavColors.textMuted, fontSize: 18)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Game preview page - challenges list + Host button
// ─────────────────────────────────────────────
class _GamePreviewPage extends StatefulWidget {
  final String gameId;
  final Map<String, dynamic> gameData;
  final VoidCallback onHost;
  final bool isHosting;

  const _GamePreviewPage({
    required this.gameId,
    required this.gameData,
    required this.onHost,
    required this.isHosting,
  });

  @override
  State<_GamePreviewPage> createState() => _GamePreviewPageState();
}

class _GamePreviewPageState extends State<_GamePreviewPage> {
  bool _hosting = false;

  Future<void> _host() async {
    setState(() => _hosting = true);
    widget.onHost();
    // hosting navigates away — no need to reset
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.gameData['title'] ?? 'Game';
    final desc  = widget.gameData['description'] ?? '';

    return Scaffold(
      backgroundColor: ScavColors.bg,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        Expanded(child: CustomScrollView(slivers: [

          // ── Game info header ──────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Icon + title
              Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: ScavColors.accentLo,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ScavColors.accent.withOpacity(0.3)),
                  ),
                  child: const Center(child: Text('🌍', style: TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(
                    color: ScavColors.textPrimary, fontSize: 20,
                    fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(desc, style: const TextStyle(
                      color: ScavColors.textSecondary, fontSize: 13, height: 1.4)),
                  ],
                ])),
              ]),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ScavColors.surfaceHi,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ScavColors.border),
                ),
                child: Row(children: const [
                  Icon(Icons.info_outline, size: 14, color: ScavColors.textMuted),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Hosting creates a private copy of this game for you to run — it won\'t be published.',
                    style: TextStyle(color: ScavColors.textMuted, fontSize: 12, height: 1.4))),
                ]),
              ),

              const SizedBox(height: 20),
              const Text('CHALLENGES', style: TextStyle(
                color: ScavColors.textMuted, fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              const SizedBox(height: 8),
            ]),
          )),

          // ── Challenge list ────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('games').doc(widget.gameId)
                .collection('challenges')
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: ScavColors.accent))));

              final docs = snap.data!.docs;
              if (docs.isEmpty) return SliverToBoxAdapter(
                child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: ScavColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ScavColors.border)),
                    child: const Center(child: Text('No challenges in this game yet.',
                      style: TextStyle(color: ScavColors.textMuted, fontSize: 13))))));

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final data   = docs[i].data() as Map<String, dynamic>;
                    final cTitle = data['title'] ?? '';
                    final cDesc  = data['description'] ?? '';
                    final type   = data['type'] ?? '';
                    final points = data['points'] ?? 0;
                    final hasTimer = data['releaseAfterMinutes'] != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ScavColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ScavColors.border),
                      ),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: ScavColors.surfaceHi,
                            borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text(challengeTypeEmoji(type),
                            style: const TextStyle(fontSize: 16))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(cTitle, style: const TextStyle(
                            color: ScavColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                          if (cDesc.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(cDesc, style: const TextStyle(
                              color: ScavColors.textSecondary, fontSize: 12),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, children: [
                            ScavChip('+$points', color: ScavColors.accent),
                            ScavChip(challengeTypeLabel(type), color: ScavColors.textSecondary),
                            if (hasTimer)
                              ScavChip('⏱ Timed', color: ScavColors.purple),
                          ]),
                        ])),
                      ]),
                    );
                  },
                  childCount: docs.length,
                )),
              );
            },
          ),
        ])),

        // ── Sticky host button ────────────────────────────
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: ScavColors.border))),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: ScavPrimaryButton(
            label: '🚀  Host this Game',
            isLoading: _hosting,
            onPressed: _host,
          ),
        ),
      ]),
    );
  }
}