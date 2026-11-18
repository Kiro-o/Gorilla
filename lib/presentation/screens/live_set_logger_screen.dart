import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../viewmodels/workout_viewmodel.dart';
import '../widgets/stepper_button.dart';
import '../widgets/photo_zoom_dialog.dart';

class LiveSetLoggerScreen extends StatelessWidget {
  final WorkoutViewModel viewModel;

  const LiveSetLoggerScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final gc = context.gorilla;
        final exercise = viewModel.activeExercise;
        if (exercise == null) {
          return Scaffold(
            backgroundColor: gc.bgCore,
            body: Center(child: Text('No exercise selected', style: TextStyle(color: gc.textMain))),
          );
        }

        final todaySets = viewModel.getTodaySetsForActiveExercise();
        final lastSession = viewModel.getLastSessionSets(exercise.id);
        final hasPhoto = exercise.photoPath != null && File(exercise.photoPath!).existsSync();

        return Scaffold(
          backgroundColor: gc.bgCore,
          appBar: AppBar(
            backgroundColor: gc.bgSurface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.close, color: gc.textMain),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: gc.textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  exercise.targetMuscle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neonCyan,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, size: 18, color: gc.textSecondary),
                tooltip: 'Previous Exercise',
                onPressed: () => viewModel.navigateAdjacentExercise(-1),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 18, color: gc.textSecondary),
                tooltip: 'Next Exercise',
                onPressed: () => viewModel.navigateAdjacentExercise(1),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Machine Setup & Pin Banner ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gc.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: gc.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (hasPhoto)
                          GestureDetector(
                            onTap: () => PhotoZoomDialog.show(context, exercise.photoPath!, exercise.name),
                            child: Container(
                              width: 64,
                              height: 64,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.neonCyan, width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(exercise.photoPath!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.settings, color: AppTheme.neonAmber, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'MACHINE ADJUSTMENT SETUP',
                                    style: TextStyle(
                                      color: AppTheme.neonAmber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                exercise.adjustmentNotes.isNotEmpty
                                    ? exercise.adjustmentNotes
                                    : 'No adjustment notes recorded yet.',
                                style: const TextStyle(
                                  color: AppTheme.neonAmber,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Previous Session Reference ---
                  if (lastSession.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: gc.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: gc.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Prev: ${lastSession.map((s) => '${s.weightKg.toStringAsFixed(s.weightKg % 1 == 0 ? 0 : 1)}k×${s.reps}').join(', ')}',
                              style: TextStyle(
                                color: gc.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => viewModel.copyLastSessionValues(),
                            icon: const Icon(Icons.copy, size: 14, color: AppTheme.neonGreen),
                            label: const Text(
                              'Copy Last',
                              style: TextStyle(
                                color: AppTheme.neonGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- Set Number Stepper Indicator ---
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: gc.bgSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: gc.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18, color: AppTheme.neonAmber),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Previous Set (-1)',
                            onPressed: () => viewModel.adjustSetNumber(-1),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen.withAlpha(25),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.neonGreen.withAlpha(80)),
                            ),
                            child: Text(
                              'SET ${viewModel.activeSetNumber}',
                              style: const TextStyle(
                                color: AppTheme.neonGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18, color: AppTheme.neonGreen),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Next Set (+1)',
                            onPressed: () => viewModel.adjustSetNumber(1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- Steppers Section ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weight Stepper
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: gc.bgSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: gc.border),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'WEIGHT (KG)',
                                style: TextStyle(
                                  color: gc.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                viewModel.currentWeight.toStringAsFixed(
                                  viewModel.currentWeight % 1 == 0 ? 0 : 1,
                                ),
                                style: TextStyle(
                                  color: gc.textMain,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 4,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: [
                                  StepperButton(label: '-10', onTap: () => viewModel.adjustWeight(-10), isPositive: false, width: 42),
                                  StepperButton(label: '-5', onTap: () => viewModel.adjustWeight(-5), isPositive: false, width: 42),
                                  StepperButton(label: '-2.5', onTap: () => viewModel.adjustWeight(-2.5), isPositive: false, width: 42),
                                  StepperButton(label: '-1', onTap: () => viewModel.adjustWeight(-1), isPositive: false, width: 42),
                                  StepperButton(label: '+1', onTap: () => viewModel.adjustWeight(1), width: 42),
                                  StepperButton(label: '+2.5', onTap: () => viewModel.adjustWeight(2.5), width: 42),
                                  StepperButton(label: '+5', onTap: () => viewModel.adjustWeight(5), width: 42),
                                  StepperButton(label: '+10', onTap: () => viewModel.adjustWeight(10), width: 42),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Reps Stepper
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: gc.bgSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: gc.border),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'REPS COUNT',
                                style: TextStyle(
                                  color: gc.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${viewModel.currentReps}',
                                style: TextStyle(
                                  color: gc.textMain,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 4,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: [
                                  StepperButton(label: '-5', onTap: () => viewModel.adjustReps(-5), isPositive: false, width: 42),
                                  StepperButton(label: '-1', onTap: () => viewModel.adjustReps(-1), isPositive: false, width: 42),
                                  StepperButton(label: '+1', onTap: () => viewModel.adjustReps(1), width: 42),
                                  StepperButton(label: '+5', onTap: () => viewModel.adjustReps(5), width: 42),
                                  StepperButton(label: '8', onTap: () => viewModel.setReps(8), isAccent: true, width: 42),
                                  StepperButton(label: '10', onTap: () => viewModel.setReps(10), isAccent: true, width: 42),
                                  StepperButton(label: '12', onTap: () => viewModel.setReps(12), isAccent: true, width: 42),
                                  StepperButton(label: '15', onTap: () => viewModel.setReps(15), isAccent: true, width: 42),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- Rest Duration Selector ---
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: AppTheme.neonCyan),
                          const SizedBox(width: 4),
                          Text(
                            'REST TIMER:',
                            style: TextStyle(
                              color: gc.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [60, 90, 120, 180, 240].map((sec) {
                            final isSelected = viewModel.chosenRestDuration == sec;
                            final label = sec == 180 ? '180s (3m)' : '${sec}s';
                            return Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: ChoiceChip(
                                label: Text(label),
                                selected: isSelected,
                                onSelected: (_) => viewModel.setChosenRestDuration(sec),
                                backgroundColor: gc.bgSurface,
                                selectedColor: AppTheme.neonCyan,
                                labelStyle: TextStyle(
                                  color: isSelected ? const Color(0xFF031217) : gc.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.neonCyan : gc.border,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),

                  // --- Active Rest Countdown Card (Dynamic -30s / +30s) ---
                  if (viewModel.isRestTimerRunning && viewModel.restSecondsRemaining > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: gc.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.neonCyan, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonCyan.withAlpha(50),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.neonCyan, width: 2),
                                ),
                                child: const Icon(Icons.timer, color: AppTheme.neonCyan, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    viewModel.restFormattedTime,
                                    style: TextStyle(
                                      color: gc.textMain,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const Text(
                                    'REST COUNTDOWN',
                                    style: TextStyle(
                                      color: AppTheme.neonCyan,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => viewModel.subtractRestSeconds(30),
                                style: TextButton.styleFrom(
                                  backgroundColor: gc.bgSurface,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: AppTheme.neonAmber),
                                  ),
                                ),
                                child: const Text(
                                  '-30s',
                                  style: TextStyle(color: AppTheme.neonAmber, fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: () => viewModel.addRestSeconds(30),
                                style: TextButton.styleFrom(
                                  backgroundColor: gc.bgSurface,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: AppTheme.neonCyan),
                                  ),
                                ),
                                child: const Text(
                                  '+30s',
                                  style: TextStyle(color: AppTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: () => viewModel.skipRestTimer(),
                                style: TextButton.styleFrom(
                                  backgroundColor: gc.bgSurface,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: gc.border),
                                  ),
                                ),
                                child: Text(
                                  'Skip',
                                  style: TextStyle(color: gc.textMuted, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- Big Primary Complete Set CTA ---
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => viewModel.logSet(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonGreen,
                        foregroundColor: const Color(0xFF021206),
                        elevation: 6,
                        shadowColor: AppTheme.neonGreen.withAlpha(120),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'COMPLETE SET',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Today's Sets Table ---
                  const SizedBox(height: 20),
                  Text(
                    'TODAY\'S LOGGED SETS',
                    style: TextStyle(
                      color: gc.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (todaySets.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Text(
                        'No sets logged yet today. Press COMPLETE SET to start!',
                        style: TextStyle(color: gc.textDim, fontSize: 13),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todaySets.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final set = todaySets[index];
                        final timeStr = DateTime.fromMillisecondsSinceEpoch(set.timestamp)
                            .toLocal()
                            .toString()
                            .substring(11, 16);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: gc.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: gc.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.neonGreen.withAlpha(30),
                                child: Text(
                                  '${set.setNumber}',
                                  style: const TextStyle(
                                    color: AppTheme.neonGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${set.weightKg.toStringAsFixed(set.weightKg % 1 == 0 ? 0 : 1)} kg × ${set.reps} reps',
                                      style: TextStyle(
                                        color: gc.textMain,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    Text(
                                      '$timeStr • Est. 1RM: ${set.estimated1RM.round()} kg',
                                      style: TextStyle(
                                        color: gc.textDim,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.neonRed, size: 20),
                                onPressed: () => viewModel.deleteLog(set.id),
                                tooltip: 'Delete Set',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
