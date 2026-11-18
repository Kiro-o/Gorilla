import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../viewmodels/workout_viewmodel.dart';

class RestTimerDock extends StatelessWidget {
  final WorkoutViewModel viewModel;

  const RestTimerDock({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (!viewModel.isRestTimerRunning || viewModel.restSecondsRemaining <= 0) {
      return const SizedBox.shrink();
    }

    final gc = context.gorilla;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: gc.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withAlpha(50),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonCyan, width: 2),
                ),
                child: const Icon(Icons.timer_outlined, color: AppTheme.neonCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    viewModel.restFormattedTime,
                    style: TextStyle(
                      color: gc.textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'REST REMAINING',
                    style: TextStyle(
                      color: gc.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _timerBtn(
                label: '-30s',
                color: AppTheme.neonAmber,
                borderColor: gc.border,
                bg: gc.bgCard,
                onTap: () => viewModel.subtractRestSeconds(30),
              ),
              const SizedBox(width: 6),
              _timerBtn(
                label: '+30s',
                color: AppTheme.neonCyan,
                borderColor: gc.border,
                bg: gc.bgCard,
                onTap: () => viewModel.addRestSeconds(30),
              ),
              const SizedBox(width: 6),
              _timerBtn(
                label: 'Skip',
                color: gc.textMuted,
                borderColor: gc.border,
                bg: gc.bgCard,
                onTap: () => viewModel.skipRestTimer(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timerBtn({
    required String label,
    required Color color,
    required Color borderColor,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: bg,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
