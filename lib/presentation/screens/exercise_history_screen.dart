import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_machine.dart';
import '../viewmodels/workout_viewmodel.dart';

class ExerciseHistoryScreen extends StatelessWidget {
  final ExerciseMachine exercise;
  final WorkoutViewModel viewModel;

  const ExerciseHistoryScreen({
    super.key,
    required this.exercise,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final stats = viewModel.getStatsForExercise(exercise.id);
        final hasHistory = stats['hasHistory'] as bool;
        final prWeight = (stats['prWeight'] as num).toDouble();
        final prReps = (stats['prReps'] as num).toInt();
        final best1RM = (stats['best1RM'] as num).toDouble();
        final totalVolume = (stats['totalVolume'] as num).toDouble();
        final grouped = viewModel.getGroupedHistory(exercise.id);
        final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return Scaffold(
          backgroundColor: AppTheme.bgCore,
          appBar: AppBar(
            title: Text(exercise.name),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stats Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricBox(
                        title: 'PERSONAL RECORD',
                        value: hasHistory
                            ? '${prWeight.toStringAsFixed(prWeight % 1 == 0 ? 0 : 1)}k × $prReps'
                            : '-',
                        color: AppTheme.neonAmber,
                        icon: Icons.emoji_events,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricBox(
                        title: 'EST. 1RM MAX',
                        value: hasHistory ? '${best1RM.round()} kg' : '-',
                        color: AppTheme.neonGreen,
                        icon: Icons.fitness_center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricBox(
                        title: 'TOTAL VOLUME',
                        value: hasHistory ? '${(totalVolume / 1000).toStringAsFixed(1)}k kg' : '-',
                        color: AppTheme.neonCyan,
                        icon: Icons.trending_up,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'WORKOUT SESSIONS HISTORY',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                if (!hasHistory || dates.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: const Text(
                      'No workout history recorded yet for this machine.',
                      style: TextStyle(color: AppTheme.textDim, fontSize: 14),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dates.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final sets = grouped[date]!;
                      final sessionVolume = sets.fold<double>(0.0, (acc, s) => acc + s.volume);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: AppTheme.neonCyan),
                                    const SizedBox(width: 6),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        color: AppTheme.neonCyan,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Volume: ${sessionVolume.round()} kg',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: AppTheme.borderSubtle, height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sets.map((s) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgCard,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.borderSubtle),
                                  ),
                                  child: Text(
                                    'S${s.setNumber}: ${s.weightKg.toStringAsFixed(s.weightKg % 1 == 0 ? 0 : 1)}kg × ${s.reps}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricBox({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textDim,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
