import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/challenge_service.dart';
import 'challenges_page.dart';
import 'player_leaderboard_page.dart';

class GameShell extends StatefulWidget {
  final String gameId;
  final String teamName;
  final String playerId;

  const GameShell({
    super.key,
    required this.gameId,
    required this.teamName,
    required this.playerId,
  });

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  int _tab = 0;
  Timer? _pollTimer;

  // Cached challenge list refreshed every 10s
  List<QueryDocumentSnapshot> _visibleChallenges = [];
  DateTime? _gameStartedAt;
  int _newCount = 0; // badge counter
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _fetchChallenges(); // immediate first load
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchChallenges());
  }

  Future<void> _fetchChallenges() async {
    try {
      // Get game data for startedAt
      final gameDoc = await FirebaseFirestore.instance
          .collection('games').doc(widget.gameId).get();
      final gData = gameDoc.data() ?? {};

      // Parse startedAt
      final startedTs = gData['startedAt'];
      DateTime? startedAt;
      if (startedTs is Timestamp) {
        startedAt = startedTs.toDate();
      }

      // Get all challenges
      final snap = await FirebaseFirestore.instance
          .collection('games').doc(widget.gameId)
          .collection('challenges')
          .orderBy('createdAt', descending: false)
          .get();

      final visible = ChallengeService.filterVisibleChallenges(snap.docs, startedAt);

      if (!mounted) return;
      setState(() {
        _gameStartedAt = startedAt;
        final prev = _visibleChallenges.length;
        _visibleChallenges = visible;
        // Badge for new challenges appearing after first load
        if (prev > 0 && visible.length > prev && _tab != 0) {
          _newCount += visible.length - prev;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games').doc(widget.gameId).snapshots(),
      builder: (context, snap) {
        final gData  = snap.hasData && snap.data!.exists
            ? snap.data!.data() as Map<String, dynamic> : <String, dynamic>{};
        final title  = gData['title'] ?? 'Game';
        final isActive = gData['isActive'] ?? false;

        return Scaffold(
          backgroundColor: ScavColors.bg,
          appBar: _buildAppBar(title, isActive),
          body: IndexedStack(index: _tab, children: [
            PlayerChallengesPage(
              gameId: widget.gameId,
              teamName: widget.teamName,
              playerId: widget.playerId,
              challenges: _visibleChallenges,
              onRefresh: _fetchChallenges,
            ),
            PlayerLeaderboardPage(
              gameId: widget.gameId,
              playerId: widget.playerId,
            ),
          ]),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: ScavColors.border))),
            child: BottomNavigationBar(
              currentIndex: _tab,
              onTap: (i) {
                setState(() {
                  _tab = i;
                  if (i == 0) _newCount = 0; // clear badge on tab switch
                });
              },
              backgroundColor: ScavColors.bg,
              selectedItemColor: ScavColors.accent,
              unselectedItemColor: ScavColors.textMuted,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: [
                BottomNavigationBarItem(
                  icon: _newCount > 0
                      ? Stack(children: [
                          const Text('🎯', style: TextStyle(fontSize: 20)),
                          Positioned(right: 0, top: 0, child: Container(
                            width: 14, height: 14,
                            decoration: const BoxDecoration(
                              color: ScavColors.accent, shape: BoxShape.circle),
                            child: Center(child: Text('$_newCount',
                              style: const TextStyle(color: Colors.white,
                                fontSize: 8, fontWeight: FontWeight.w900))),
                          )),
                        ])
                      : const Text('🎯', style: TextStyle(fontSize: 20)),
                  label: 'Challenges',
                ),
                const BottomNavigationBarItem(
                  icon: Text('🏆', style: TextStyle(fontSize: 20)),
                  label: 'Leaderboard',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String title, bool isActive) {
    return AppBar(
      backgroundColor: ScavColors.bg,
      automaticallyImplyLeading: false,
      title: Row(children: [
        const ScavLogo(size: 28),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: ScavColors.textPrimary,
            fontSize: 14, fontWeight: FontWeight.w700)),
          Text(widget.teamName, style: const TextStyle(
            color: ScavColors.textMuted, fontSize: 11)),
        ])),
        ScavChip(isActive ? 'LIVE' : 'Waiting',
          color: isActive ? ScavColors.green : ScavColors.amber, dot: true),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_outlined, size: 20, color: ScavColors.textMuted),
          onPressed: _fetchChallenges,
          tooltip: 'Refresh challenges',
        ),
      ],
    );
  }
}
