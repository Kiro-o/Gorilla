import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted theme mode notifier. Listens with [ListenableBuilder] or [AnimatedBuilder].
class ThemeNotifier extends ChangeNotifier {
  static const _key = 'gorilla_theme_mode';

  ThemeMode _mode;

  ThemeNotifier._(this._mode);

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  /// Factory: loads persisted preference, defaults to dark.
  static Future<ThemeNotifier> create() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    final mode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    return ThemeNotifier._(mode);
  }

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    _persist();
    _applySystemUI();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
  }

  void _applySystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? const Color(0xFF07080C) : const Color(0xFFF0F4F8),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}

