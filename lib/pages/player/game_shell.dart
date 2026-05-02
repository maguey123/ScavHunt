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

  List<QueryDocumentSnapshot> _visibleChallenges = [];
  DateTime? _gameStartedAt;
  int? _durationMinutes;
  int _newCount = 0;

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
    _fetchChallenges();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchChallenges());
  }

  Future<void> _fetchChallenges() async {
    try {
      final gameDoc = await FirebaseFirestore.instance
          .collection('games').doc(widget.gameId).get();
      final gData = gameDoc.data() ?? {};

      final startedTs = gData['startedAt'];
      DateTime? startedAt;
      if (startedTs is Timestamp) startedAt = startedTs.toDate();

      final durationMinutes = gData['durationMinutes'] as int?;

      final snap = await FirebaseFirestore.instance
          .collection('games').doc(widget.gameId)
          .collection('challenges')
          .orderBy('createdAt', descending: false)
          .get();

      final visible = ChallengeService.filterVisibleChallenges(snap.docs, startedAt);

      if (!mounted) return;
      setState(() {
        _gameStartedAt   = startedAt;
        _durationMinutes = durationMinutes;
        final prev = _visibleChallenges.length;
        _visibleChallenges = visible;
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
        final gData    = snap.hasData && snap.data!.exists
            ? snap.data!.data() as Map<String, dynamic> : <String, dynamic>{};
        final title    = gData['title'] ?? 'Game';
        final isActive = gData['isActive'] ?? false;
        final startedAt = gData['startedAt'];
        final hasStarted = startedAt != null;

        // ── Lobby: joined but game hasn't started yet ──────
        if (!isActive && !hasStarted) {
          return _buildLobbyScaffold(title);
        }

        // ── Game over: was running, now stopped ────────────
        if (!isActive && hasStarted) {
          return _buildGameOverScaffold(title);
        }

        // ── Live game ──────────────────────────────────────
        return Scaffold(
          backgroundColor: ScavColors.bg,
          appBar: _buildAppBar(title, true),
          body: IndexedStack(index: _tab, children: [
            PlayerChallengesPage(
              gameId:          widget.gameId,
              teamName:        widget.teamName,
              playerId:        widget.playerId,
              challenges:      _visibleChallenges,
              onRefresh:       _fetchChallenges,
              durationMinutes: _durationMinutes,
              gameStartedAt:   _gameStartedAt,
            ),
            PlayerLeaderboardPage(
              gameId:   widget.gameId,
              playerId: widget.playerId,
            ),
          ]),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: ScavColors.border))),
            child: BottomNavigationBar(
              currentIndex: _tab,
              onTap: (i) => setState(() {
                _tab = i;
                if (i == 0) _newCount = 0;
              }),
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

  // ── Lobby scaffold ───────────────────────────────────────────────────────────

  Widget _buildLobbyScaffold(String title) {
    return Scaffold(
      backgroundColor: ScavColors.bg,
      appBar: _buildAppBar(title, false),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: ScavColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ScavColors.border)),
                child: const Center(child: Text('⏳', style: TextStyle(fontSize: 36)))),
              const SizedBox(height: 24),
              const Text('Waiting to start', style: TextStyle(
                color: ScavColors.textPrimary, fontSize: 24,
                fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text(
                'You\'re in! The host hasn\'t started the game yet.\nChallenges will appear as soon as it begins.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ScavColors.textSecondary, fontSize: 13, height: 1.5)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: ScavColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ScavColors.border)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('👥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Team: ', style: const TextStyle(
                    color: ScavColors.textMuted, fontSize: 13)),
                  Text(widget.teamName, style: const TextStyle(
                    color: ScavColors.textPrimary, fontSize: 13,
                    fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 48),
              _AnimatedWaitingDots(),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Game over scaffold ───────────────────────────────────────────────────────

  Widget _buildGameOverScaffold(String title) {
    final playerRef = FirebaseFirestore.instance
        .collection('games').doc(widget.gameId)
        .collection('players').doc(widget.playerId)
        .snapshots();

    return Scaffold(
      backgroundColor: ScavColors.bg,
      appBar: _buildAppBar(title, false),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: playerRef,
          builder: (context, snap) {
            final playerData = snap.hasData && snap.data!.exists
                ? snap.data!.data() as Map<String, dynamic> : <String, dynamic>{};
            final points = playerData['points'] ?? 0;

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🏆', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  const Text('Game Over', style: TextStyle(
                    color: ScavColors.textPrimary, fontSize: 28,
                    fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                  const SizedBox(height: 6),
                  const Text('The host has ended the game. Well played!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ScavColors.textSecondary, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: ScavColors.accentLo,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ScavColors.accent.withValues(alpha: 0.3))),
                    child: Column(children: [
                      const Text('Final Score', style: TextStyle(
                        color: ScavColors.textMuted, fontSize: 11,
                        fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('$points', style: const TextStyle(
                        color: ScavColors.accent, fontSize: 48,
                        fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                      Text('pts · ${widget.teamName}', style: const TextStyle(
                        color: ScavColors.textMuted, fontSize: 12)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScavColors.surface,
                        foregroundColor: ScavColors.textPrimary,
                        side: const BorderSide(color: ScavColors.border)),
                      child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w700)),
                    )),
                ]),
              ),
            );
          },
        ),
      ),
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
        if (isActive)
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20, color: ScavColors.textMuted),
            onPressed: _fetchChallenges,
            tooltip: 'Refresh challenges',
          ),
      ],
    );
  }
}

// ── Animated waiting dots ────────────────────────────────────────────────────

class _AnimatedWaitingDots extends StatefulWidget {
  @override
  State<_AnimatedWaitingDots> createState() => _AnimatedWaitingDotsState();
}

class _AnimatedWaitingDotsState extends State<_AnimatedWaitingDots> {
  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _step = (_step + 1) % 4);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '•' * _step + ' ' * (3 - _step);
    return Text(dots, style: const TextStyle(
      color: ScavColors.accent, fontSize: 24, letterSpacing: 4,
      fontWeight: FontWeight.w900));
  }
}
