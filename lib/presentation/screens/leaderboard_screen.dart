import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../data/storage/firestore_sync_service.dart';
import '../viewmodels/workout_viewmodel.dart';

enum LeaderboardMetric { maxWeight, totalVolume, best1RM }

class LeaderboardScreen extends StatefulWidget {
  final WorkoutViewModel viewModel;

  const LeaderboardScreen({super.key, required this.viewModel});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _currentRoomCode = FirestoreSyncService.defaultRoomCode;
  LeaderboardMetric _selectedMetric = LeaderboardMetric.maxWeight;
  String _selectedExercise = 'All Exercises';
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadRoomCodeAndSync();
  }

  Future<void> _loadRoomCodeAndSync() async {
    final code = await firestoreSyncService.getRoomCode();
    if (mounted) {
      setState(() {
        _currentRoomCode = code;
      });
    }
    _triggerSync();
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await firestoreSyncService.syncLocalStats(
        storage: widget.viewModel.storage,
        roomCodeOverride: _currentRoomCode,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Stats synced to Squad Leaderboard!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.bgSurface,
          ),
        );
      }
    } catch (_) {
      // Offline fallback
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _showRoomDialog() {
    final textController = TextEditingController(text: _currentRoomCode);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Row(
          children: [
            Icon(Icons.groups_outlined, color: AppTheme.neonGreen),
            SizedBox(width: 8),
            Text(
              'Squad Room Code',
              style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Share this room code with friends in any gym to compete on max weight and total volume in real-time.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                color: AppTheme.neonGreen,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                labelText: 'ROOM CODE',
                labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                hintText: 'e.g. GORILLA-01',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.shuffle, color: AppTheme.neonCyan),
                  tooltip: 'Generate Random Code',
                  onPressed: () {
                    final random = Random();
                    final randomCode = 'GORILLA-${random.nextInt(9000) + 1000}';
                    textController.text = randomCode;
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCode = textController.text.trim().toUpperCase();
              if (newCode.isNotEmpty) {
                final nav = Navigator.of(ctx);
                await firestoreSyncService.setRoomCode(newCode);
                if (!mounted) return;
                setState(() => _currentRoomCode = newCode);
                nav.pop();
                _triggerSync();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: const Color(0xFF021206),
            ),
            child: const Text('Join Room', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: _currentRoomCode));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room Code "$_currentRoomCode" copied to clipboard! Share with your squad 🦍'),
        backgroundColor: AppTheme.bgSurface,
      ),
    );
  }

  double _getScoreForMember(LeaderboardMember member) {
    if (_selectedExercise != 'All Exercises') {
      final lift = member.maxLifts[_selectedExercise];
      if (lift == null) return 0.0;
      switch (_selectedMetric) {
        case LeaderboardMetric.maxWeight:
          return (lift['weight'] as num?)?.toDouble() ?? 0.0;
        case LeaderboardMetric.totalVolume:
          final w = (lift['weight'] as num?)?.toDouble() ?? 0.0;
          final r = (lift['reps'] as num?)?.toInt() ?? 0;
          return w * r;
        case LeaderboardMetric.best1RM:
          return (lift['est1RM'] as num?)?.toDouble() ?? 0.0;
      }
    }

    switch (_selectedMetric) {
      case LeaderboardMetric.maxWeight:
        return member.maxWeight;
      case LeaderboardMetric.totalVolume:
        return member.totalVolume;
      case LeaderboardMetric.best1RM:
        return member.best1RM;
    }
  }

  String _formatScore(double score) {
    if (_selectedMetric == LeaderboardMetric.totalVolume) {
      return '${score.toStringAsFixed(0)} kg';
    }
    return '${score.toStringAsFixed(score % 1 == 0 ? 0 : 1)} kg';
  }

  String _getMetricTitle() {
    switch (_selectedMetric) {
      case LeaderboardMetric.maxWeight:
        return 'Max Weight PR';
      case LeaderboardMetric.totalVolume:
        return 'Total Volume';
      case LeaderboardMetric.best1RM:
        return 'Estimated 1RM';
    }
  }

  List<String> _getAvailableExercises(List<LeaderboardMember> members) {
    final Set<String> exercises = {'All Exercises'};
    for (final ex in widget.viewModel.storage.getExercises()) {
      exercises.add(ex.name);
    }
    for (final m in members) {
      exercises.addAll(m.maxLifts.keys);
    }
    return exercises.toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<LeaderboardMember>>(
      stream: firestoreSyncService.streamRoomMembers(_currentRoomCode),
      builder: (context, snapshot) {
        final members = snapshot.data ?? [];
        final availableExercises = _getAvailableExercises(members);

        // Sort members descending based on active metric
        final sortedMembers = List<LeaderboardMember>.from(members)
          ..sort((a, b) => _getScoreForMember(b).compareTo(_getScoreForMember(a)));

        final double leaderScore = sortedMembers.isNotEmpty
            ? _getScoreForMember(sortedMembers.first)
            : 1.0;

        return Scaffold(
          backgroundColor: AppTheme.bgCore,
          body: RefreshIndicator(
            onRefresh: _triggerSync,
            color: AppTheme.neonGreen,
            backgroundColor: AppTheme.bgSurface,
            child: CustomScrollView(
              slivers: [
                // --- Room Code Header Banner ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF141F1A), Color(0xFF0F1722)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.neonGreen.withAlpha(90)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonGreen.withAlpha(30),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppTheme.neonGreen.withAlpha(30),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.neonGreen, width: 1.5),
                                    ),
                                    child: const Center(
                                      child: Text('🦍', style: TextStyle(fontSize: 18)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ACTIVE SQUAD ROOM',
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        _currentRoomCode,
                                        style: const TextStyle(
                                          color: AppTheme.neonGreen,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'monospace',
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: AppTheme.neonCyan, size: 20),
                                    tooltip: 'Copy Code',
                                    onPressed: _copyRoomCode,
                                  ),
                                  OutlinedButton(
                                    onPressed: _showRoomDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.textMain,
                                      side: const BorderSide(color: AppTheme.borderSubtle),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text('Switch Room', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${sortedMembers.length} Athletes in Room',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              TextButton.icon(
                                onPressed: _isSyncing ? null : _triggerSync,
                                icon: _isSyncing
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonGreen),
                                      )
                                    : const Icon(Icons.sync, size: 14, color: AppTheme.neonGreen),
                                label: Text(
                                  _isSyncing ? 'Syncing...' : 'Sync Now ⚡',
                                  style: const TextStyle(color: AppTheme.neonGreen, fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Metric Selection Chips ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildMetricChip(
                            label: 'Max Weight PR',
                            metric: LeaderboardMetric.maxWeight,
                            icon: Icons.fitness_center,
                          ),
                          const SizedBox(width: 8),
                          _buildMetricChip(
                            label: 'Total Volume',
                            metric: LeaderboardMetric.totalVolume,
                            icon: Icons.stacked_bar_chart,
                          ),
                          const SizedBox(width: 8),
                          _buildMetricChip(
                            label: 'Est. 1RM',
                            metric: LeaderboardMetric.best1RM,
                            icon: Icons.military_tech_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Exercise Filter Dropdown ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: availableExercises.contains(_selectedExercise)
                              ? _selectedExercise
                              : 'All Exercises',
                          dropdownColor: AppTheme.bgCard,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.neonCyan),
                          style: const TextStyle(color: AppTheme.textMain, fontSize: 13, fontWeight: FontWeight.w700),
                          items: availableExercises.map((ex) {
                            return DropdownMenuItem<String>(
                              value: ex,
                              child: Text(
                                ex,
                                style: TextStyle(
                                  color: ex == _selectedExercise ? AppTheme.neonCyan : AppTheme.textMain,
                                  fontWeight: ex == _selectedExercise ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            if (newVal != null) {
                              setState(() => _selectedExercise = newVal);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // --- Top 3 Podium (Visual Showcase) ---
                if (sortedMembers.length >= 2)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: _buildPodium(sortedMembers, currentUserId),
                    ),
                  ),

                // --- Ranked List Header ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SQUAD RANKINGS (${_getMetricTitle().toUpperCase()})',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          _selectedExercise,
                          style: const TextStyle(
                            color: AppTheme.neonCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Leaderboard Member List ---
                if (sortedMembers.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 48, color: AppTheme.textDim),
                          SizedBox(height: 12),
                          Text(
                            'No athletes in this squad room yet.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Log a set or share the Room Code to start competing!',
                            style: TextStyle(color: AppTheme.textDim, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final member = sortedMembers[index];
                          final rank = index + 1;
                          final isCurrentUser = member.userId == currentUserId;
                          final score = _getScoreForMember(member);
                          final percent = leaderScore > 0 ? (score / leaderScore).clamp(0.0, 1.0) : 0.0;

                          return _buildMemberCard(
                            rank: rank,
                            member: member,
                            score: score,
                            percent: percent,
                            isCurrentUser: isCurrentUser,
                          );
                        },
                        childCount: sortedMembers.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricChip({
    required String label,
    required LeaderboardMetric metric,
    required IconData icon,
  }) {
    final isSelected = _selectedMetric == metric;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? const Color(0xFF031206) : AppTheme.textSecondary,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedMetric = metric),
      backgroundColor: AppTheme.bgSurface,
      selectedColor: AppTheme.neonGreen,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF031206) : AppTheme.textSecondary,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppTheme.neonGreen : AppTheme.borderSubtle,
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardMember> sorted, String? currentUserId) {
    final first = sorted.isNotEmpty ? sorted[0] : null;
    final second = sorted.length > 1 ? sorted[1] : null;
    final third = sorted.length > 2 ? sorted[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            _buildPodiumSpot(
              member: second,
              rank: 2,
              medal: '🥈',
              color: const Color(0xFFB0BEC5),
              height: 100,
              score: _getScoreForMember(second),
              isUser: second.userId == currentUserId,
            ),
          // 1st Place (Center, Tallest)
          if (first != null)
            _buildPodiumSpot(
              member: first,
              rank: 1,
              medal: '🥇',
              color: AppTheme.neonAmber,
              height: 128,
              score: _getScoreForMember(first),
              isUser: first.userId == currentUserId,
            ),
          // 3rd Place
          if (third != null)
            _buildPodiumSpot(
              member: third,
              rank: 3,
              medal: '🥉',
              color: const Color(0xFFCD7F32),
              height: 80,
              score: _getScoreForMember(third),
              isUser: third.userId == currentUserId,
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot({
    required LeaderboardMember member,
    required int rank,
    required String medal,
    required Color color,
    required double height,
    required double score,
    required bool isUser,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(medal, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 2),
        Text(
          member.avatar,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            member.userName,
            style: TextStyle(
              color: isUser ? AppTheme.neonGreen : AppTheme.textMain,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _formatScore(score),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 76,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(80), color.withAlpha(20)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withAlpha(120)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard({
    required int rank,
    required LeaderboardMember member,
    required double score,
    required double percent,
    required bool isCurrentUser,
  }) {
    Color rankColor = AppTheme.textMuted;
    if (rank == 1) rankColor = AppTheme.neonAmber;
    if (rank == 2) rankColor = const Color(0xFFB0BEC5);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppTheme.neonGreen.withAlpha(15) : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser ? AppTheme.neonGreen.withAlpha(140) : AppTheme.borderSubtle,
          width: isCurrentUser ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank Badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: rankColor.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: rankColor.withAlpha(100)),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Member Avatar & Name
              Text(member.avatar, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.userName,
                            style: const TextStyle(
                              color: AppTheme.textMain,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen.withAlpha(40),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.neonGreen),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: AppTheme.neonGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${member.totalSets} sets logged',
                      style: const TextStyle(color: AppTheme.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Score Display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatScore(score),
                    style: TextStyle(
                      color: isCurrentUser ? AppTheme.neonGreen : AppTheme.neonCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    _getMetricTitle().toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar Relative to #1
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor: AppTheme.bgSurface,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCurrentUser ? AppTheme.neonGreen : AppTheme.neonCyan.withAlpha(200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
