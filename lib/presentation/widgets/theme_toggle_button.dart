import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_notifier.dart';

/// Minimalist Sun/Moon icon button for the AppBar.
/// Wrap with a [ListenableBuilder] so it rebuilds on theme change.
class ThemeToggleButton extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const ThemeToggleButton({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.isDark;

    return Tooltip(
      message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: IconButton(
          key: ValueKey(isDark),
          icon: Icon(
            isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
            size: 22,
            color: isDark
                ? AppTheme.neonAmber          // warm sun in dark mode
                : AppTheme.neonCyan,          // cool moon in light mode
          ),
          onPressed: themeNotifier.toggle,
        ),
      ),
    );
  }
}

