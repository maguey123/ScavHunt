import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/game_service.dart';
import 'tabs/overview_tab.dart';
import 'tabs/challenges_tab.dart';
import 'tabs/leaderboard_tab.dart';
import 'tabs/submissions_tab.dart';

class AdminShell extends StatefulWidget {
  final String gameId;
  final String joinCode;

  const AdminShell({super.key, required this.gameId, required this.joinCode});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;
  final _gameService = GameService();

  final _tabItems = const [
    BottomNavigationBarItem(icon: Text('📊', style: TextStyle(fontSize: 20)), label: 'Overview'),
    BottomNavigationBarItem(icon: Text('🎯', style: TextStyle(fontSize: 20)), label: 'Challenges'),
    BottomNavigationBarItem(icon: Text('🏆', style: TextStyle(fontSize: 20)), label: 'Scores'),
    BottomNavigationBarItem(icon: Text('📸', style: TextStyle(fontSize: 20)), label: 'Subs'),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _gameService.watchGame(widget.gameId),
      builder: (context, snap) {
        final gameData = snap.hasData && snap.data!.exists
            ? snap.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};
        final isActive  = gameData['isActive']  ?? false;
        final title     = gameData['title']      ?? 'Game';
        final isPublished = (gameData['isPublished'] ?? false) || (gameData['published'] ?? false);

        return Scaffold(
          backgroundColor: ScavColors.bg,
          appBar: _buildAppBar(title, isActive, isPublished, gameData),
          body: IndexedStack(index: _tab, children: [
            OverviewTab(gameId: widget.gameId, gameData: gameData),
            ChallengesTab(gameId: widget.gameId, gameData: gameData),
            LeaderboardTab(gameId: widget.gameId),
            SubmissionsTab(gameId: widget.gameId, gameTitle: title),
          ]),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: ScavColors.border)),
            ),
            child: BottomNavigationBar(
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              backgroundColor: ScavColors.bg,
              selectedItemColor: ScavColors.accent,
              unselectedItemColor: ScavColors.textMuted,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: _tabItems,
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    String title, bool isActive, bool isPublished, Map<String, dynamic> gameData) {
    return AppBar(
      backgroundColor: ScavColors.bg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const ScavLogo(size: 18),
          const SizedBox(width: 6),
          Text(widget.joinCode, style: const TextStyle(
            color: ScavColors.accent, fontSize: 15,
            fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(width: 10),
          ScavChip(isActive ? 'LIVE' : 'Inactive',
            color: isActive ? ScavColors.green : ScavColors.textMuted, dot: true),
        ]),
        Text(title, style: const TextStyle(color: ScavColors.textSecondary, fontSize: 11)),
      ]),
      actions: [
        PopupMenuButton<String>(
          color: ScavColors.surfaceHi,
          icon: const Icon(Icons.more_horiz, color: ScavColors.textSecondary),
          onSelected: (v) async {
            if (v == 'publish') {
              await _gameService.setPublished(widget.gameId, !isPublished);
            } else if (v == 'delete') {
              _confirmDelete();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'publish', child: Text(
              isPublished ? 'Unpublish game' : '🌍  Publish game',
              style: const TextStyle(color: ScavColors.textPrimary))),
            const PopupMenuItem(value: 'delete', child: Text('Delete game…',
              style: TextStyle(color: ScavColors.red))),
          ],
        ),
      ],
    );
  }

  void _confirmDelete() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: ScavColors.surfaceHi,
      title: const Text('Delete game?', style: TextStyle(color: ScavColors.textPrimary)),
      content: const Text('This is permanent and cannot be undone.',
        style: TextStyle(color: ScavColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: ScavColors.textMuted))),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _gameService.deleteGame(widget.gameId);
            if (!mounted) return;
            Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: const Text('Delete', style: TextStyle(color: ScavColors.red)),
        ),
      ],
    ));
  }
}