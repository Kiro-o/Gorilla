import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_machine.dart';
import '../viewmodels/workout_viewmodel.dart';
import 'photo_zoom_dialog.dart';

class MachineCard extends StatelessWidget {
  final ExerciseMachine exercise;
  final WorkoutViewModel viewModel;
  final VoidCallback onLogSet;
  final VoidCallback onEdit;
  final VoidCallback onViewHistory;

  const MachineCard({
    super.key,
    required this.exercise,
    required this.viewModel,
    required this.onLogSet,
    required this.onEdit,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final stats = viewModel.getStatsForExercise(exercise.id);
    final hasHistory = stats['hasHistory'] as bool;
    final lastSet = stats['lastSet'] as String?;
    final prWeight = (stats['prWeight'] as num).toDouble();
    final prReps = (stats['prReps'] as num).toInt();

    final hasPhoto = exercise.photoPath != null && File(exercise.photoPath!).existsSync();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(0, 4),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Machine Photo Thumbnail
                GestureDetector(
                  onTap: () {
                    if (hasPhoto) {
                      PhotoZoomDialog.show(context, exercise.photoPath!, exercise.name);
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasPhoto ? AppTheme.neonCyan.withAlpha(120) : AppTheme.borderSubtle,
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: hasPhoto
                              ? Image.file(
                                  File(exercise.photoPath!),
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: AppTheme.neonCyan,
                                    size: 32,
                                  ),
                                ),
                        ),
                      ),
                      if (hasPhoto)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.zoom_in, color: AppTheme.neonCyan, size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: AppTheme.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Target Muscle Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.neonCyan.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.neonCyan.withAlpha(80)),
                        ),
                        child: Text(
                          exercise.targetMuscle.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.neonCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Pin / Setup Notes Callout
                      if (exercise.adjustmentNotes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.neonAmber.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.neonAmber.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.settings, color: AppTheme.neonAmber, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  exercise.adjustmentNotes,
                                  style: const TextStyle(
                                    color: Color(0xFFFFE082),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Stats Row
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (hasHistory && lastSet != null)
                            _buildStatPill('⏱️ Last', lastSet, AppTheme.textSecondary),
                          if (hasHistory && prWeight > 0)
                            _buildStatPill(
                              '🏆 PR',
                              '${prWeight.toStringAsFixed(prWeight % 1 == 0 ? 0 : 1)}kg×$prReps',
                              AppTheme.neonAmber,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onLogSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: const Color(0xFF041208),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'LOG SET',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onViewHistory,
                  icon: const Icon(Icons.insights, color: AppTheme.neonCyan),
                  tooltip: 'History & Progressive Overload',
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.textMuted),
                  tooltip: 'Edit Machine',
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline, color: AppTheme.neonRed),
                  tooltip: 'Delete Machine',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 10, color: AppTheme.textDim, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Delete Exercise?', style: TextStyle(color: AppTheme.textMain)),
        content: Text(
          'Are you sure you want to delete "${exercise.name}" and all its logged history?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              viewModel.deleteExercise(exercise.id);
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
}
