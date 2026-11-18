import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_notifier.dart';
import '../../data/models/workout_split.dart';
import '../viewmodels/workout_viewmodel.dart';
import '../widgets/machine_card.dart';
import '../widgets/rest_timer_dock.dart';
import '../widgets/theme_toggle_button.dart';
import 'live_set_logger_screen.dart';
import 'add_edit_machine_screen.dart';
import 'exercise_history_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final WorkoutViewModel viewModel;
  final ThemeNotifier themeNotifier;

  const HomeScreen({
    super.key,
    required this.viewModel,
    required this.themeNotifier,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmLogout() {
    final gc = context.gorilla;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: gc.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: gc.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppTheme.neonRed),
            const SizedBox(width: 8),
            Text('Log Out?', style: TextStyle(color: gc.textMain, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your Gorilla gym account?',
          style: TextStyle(color: gc.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: gc.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showAddEditSplitDialog({WorkoutSplit? splitToEdit}) {
    final gc = context.gorilla;
    final nameCtrl = TextEditingController(text: splitToEdit?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: gc.bgCard,
        title: Text(
          splitToEdit == null ? 'Create Workout Split' : 'Edit Workout Split',
          style: TextStyle(color: gc.textMain, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: TextStyle(color: gc.textMain),
          decoration: const InputDecoration(
            hintText: 'e.g., Push Day, Posterior, Upper Body',
            labelText: 'Split Routine Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: gc.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                widget.viewModel.saveSplit(id: splitToEdit?.id, name: name);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCurrentSplit() {
    final gc = context.gorilla;
    final current = widget.viewModel.activeSplit;
    if (current == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: gc.bgCard,
        title: Text('Delete "${current.name}"?', style: TextStyle(color: gc.textMain)),
        content: Text(
          'This will permanently delete this split and all of its exercises and history.',
          style: TextStyle(color: gc.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: gc.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.viewModel.deleteSplit(current.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gorilla;
    final isDark = context.isDark;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final splits = widget.viewModel.splits;
        final currentSplit = widget.viewModel.activeSplit;
        final exercises = widget.viewModel.exercisesForActiveSplit;

        return Scaffold(
          backgroundColor: gc.bgCore,
          appBar: AppBar(
            backgroundColor: gc.bgCore,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withAlpha(isDark ? 35 : 28),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.neonGreen.withAlpha(isDark ? 120 : 160)),
                  ),
                  child: const Center(
                    child: Text('🦍', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GORILLA',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: gc.textMain,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Text(
                      'PRO GYM LOGGER',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.neonGreen,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // ─── Sun / Moon Theme Toggle ───────────────────────────────
              ListenableBuilder(
                listenable: widget.themeNotifier,
                builder: (context, _) => ThemeToggleButton(themeNotifier: widget.themeNotifier),
              ),
              if (_currentTabIndex == 0) ...[
                if (currentSplit != null) ...[
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20, color: gc.textSecondary),
                    tooltip: 'Edit Split Name',
                    onPressed: () => _showAddEditSplitDialog(splitToEdit: currentSplit),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.neonRed),
                    tooltip: 'Delete Current Split',
                    onPressed: _confirmDeleteCurrentSplit,
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonGreen),
                  tooltip: 'New Split',
                  onPressed: () => _showAddEditSplitDialog(),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.logout, color: AppTheme.neonRed, size: 20),
                tooltip: 'Log Out',
                onPressed: _confirmLogout,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: IndexedStack(
            index: _currentTabIndex,
            children: [
              // ─── Tab 0: Workouts ───────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Splits Navigation Carousel
                  Container(
                    height: 48,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: splits.length + 1,
                      itemBuilder: (context, index) {
                        if (index == splits.length) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: ActionChip(
                              avatar: const Icon(Icons.add, size: 16, color: AppTheme.neonGreen),
                              label: const Text('Add Split'),
                              backgroundColor: gc.bgSurface,
                              labelStyle: const TextStyle(
                                color: AppTheme.neonGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: gc.border),
                              ),
                              onPressed: () => _showAddEditSplitDialog(),
                            ),
                          );
                        }

                        final split = splits[index];
                        final isActive = split.id == widget.viewModel.activeSplitId;
                        final count = widget.viewModel.getExerciseCountForSplit(split.id);

                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            selected: isActive,
                            onSelected: (_) => widget.viewModel.selectSplit(split.id),
                            backgroundColor: gc.bgSurface,
                            selectedColor: AppTheme.neonGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isActive ? AppTheme.neonGreen : gc.border,
                                width: isActive ? 1.5 : 1,
                              ),
                            ),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive ? (isDark ? const Color(0xFF031206) : Colors.white) : AppTheme.neonCyan,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  split.name,
                                  style: TextStyle(
                                    color: isActive ? (isDark ? const Color(0xFF031206) : Colors.white) : gc.textSecondary,
                                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? (isDark ? Colors.white.withAlpha(40) : Colors.black.withAlpha(30))
                                        : gc.bgCard,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      color: isActive
                                          ? (isDark ? Colors.white : Colors.white)
                                          : gc.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => widget.viewModel.setSearchQuery(val),
                      style: TextStyle(color: gc.textMain, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search machine name or notes...',
                        prefixIcon: Icon(Icons.search, color: gc.textMuted, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 18, color: gc.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  widget.viewModel.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),

                  // Subheader
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentSplit?.name ?? 'Exercises',
                          style: TextStyle(
                            color: gc.textMain,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${exercises.length} machines',
                          style: TextStyle(
                            color: gc.textDim,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Exercise Cards
                  Expanded(
                    child: exercises.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fitness_center_outlined, size: 60, color: gc.textDim.withAlpha(120)),
                                const SizedBox(height: 12),
                                Text(
                                  'No exercises in this split yet',
                                  style: TextStyle(color: gc.textSecondary, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add your first gym machine to start logging sets!',
                                  style: TextStyle(color: gc.textDim, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AddEditMachineScreen(viewModel: widget.viewModel),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Machine'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: exercises.length,
                            padding: const EdgeInsets.only(bottom: 90),
                            itemBuilder: (context, index) {
                              final exercise = exercises[index];
                              return MachineCard(
                                exercise: exercise,
                                viewModel: widget.viewModel,
                                onLogSet: () {
                                  widget.viewModel.openLiveLogger(exercise);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => LiveSetLoggerScreen(viewModel: widget.viewModel),
                                    ),
                                  );
                                },
                                onEdit: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddEditMachineScreen(
                                      viewModel: widget.viewModel,
                                      initialExercise: exercise,
                                    ),
                                  ),
                                ),
                                onViewHistory: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ExerciseHistoryScreen(
                                      exercise: exercise,
                                      viewModel: widget.viewModel,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),

              // ─── Tab 1: Ranking / Leaderboard ─────────────────────────────
              LeaderboardScreen(viewModel: widget.viewModel),
            ],
          ),

          // ─── Bottom: RestTimer dock + BottomNavigationBar ─────────────────
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RestTimerDock(viewModel: widget.viewModel),
              BottomNavigationBar(
                currentIndex: _currentTabIndex,
                onTap: (index) => setState(() => _currentTabIndex = index),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.fitness_center),
                    activeIcon: Icon(Icons.fitness_center, color: AppTheme.neonGreen),
                    label: 'Workouts',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events_outlined),
                    activeIcon: Icon(Icons.emoji_events, color: AppTheme.neonGreen),
                    label: 'Ranking',
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: _currentTabIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditMachineScreen(viewModel: widget.viewModel),
                    ),
                  ),
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: isDark ? const Color(0xFF031407) : Colors.white,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text(
                    'Add Machine',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                )
              : null,
        );
      },
    );
  }
}
