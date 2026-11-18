import 'package:flutter/material.dart';

class AppTheme {
  // ─── Brand Accent Colors (shared across themes) ────────────────────────────
  static const Color neonGreen  = Color(0xFF00C96A); // slightly muted for light
  static const Color neonCyan   = Color(0xFF00B8D4);
  static const Color neonAmber  = Color(0xFFFFB703);
  static const Color neonRed    = Color(0xFFE53935);
  static const Color neonPurple = Color(0xFFA855F7);

  // ─── Dark Theme Palette ─────────────────────────────────────────────────────
  static const Color bgCore    = Color(0xFF07080C);
  static const Color bgCard    = Color(0xFF0F1219);
  static const Color bgSurface = Color(0xFF161B26);
  static const Color bgInput   = Color(0xFF1C2230);

  static const Color borderSubtle = Color(0xFF262E3E);
  static const Color borderGlow   = Color(0x4D00FF88);

  static const Color textMain      = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted     = Color(0xFF94A3B8);
  static const Color textDim       = Color(0xFF64748B);

  // ─── Light Theme Palette ────────────────────────────────────────────────────
  static const Color lBgCore    = Color(0xFFF0F4F8);
  static const Color lBgCard    = Color(0xFFFFFFFF);
  static const Color lBgSurface = Color(0xFFE8EFF7);
  static const Color lBgInput   = Color(0xFFF5F8FB);

  static const Color lBorderSubtle = Color(0xFFD1DCE8);

  static const Color lTextMain      = Color(0xFF0F172A);
  static const Color lTextSecondary = Color(0xFF334155);
  static const Color lTextMuted     = Color(0xFF64748B);
  static const Color lTextDim       = Color(0xFF94A3B8);

  // ─── Helper: pick color by brightness ───────────────────────────────────────
  static Color adaptive(BuildContext context, {required Color dark, required Color light}) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  // ─── Dark ThemeData ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  // ─── Light ThemeData ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg      = isDark ? bgCore    : lBgCore;
    final card    = isDark ? bgCard    : lBgCard;
    final surface = isDark ? bgSurface : lBgSurface;
    final input   = isDark ? bgInput   : lBgInput;
    final border  = isDark ? borderSubtle : lBorderSubtle;
    final onCard  = isDark ? textMain  : lTextMain;
    final muted   = isDark ? textMuted : lTextMuted;
    final dim     = isDark ? textDim   : lTextDim;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: neonGreen,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary:   neonGreen,
        secondary: neonCyan,
        surface:   card,
        error:     neonRed,
        onPrimary: isDark ? const Color(0xFF041208) : Colors.white,
        onSecondary: isDark ? const Color(0xFF021217) : Colors.white,
        onSurface: onCard,
        onError:   Colors.white,
      ),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onCard,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: onCard),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 2,
        shadowColor: isDark ? Colors.transparent : const Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        hintStyle: TextStyle(color: dim, fontSize: 14),
        labelStyle: TextStyle(color: muted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: isDark ? const Color(0xFF041208) : Colors.white,
          elevation: 4,
          shadowColor: neonGreen.withAlpha(80),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: neonGreen,
        disabledColor: surface,
        labelStyle: TextStyle(color: onCard, fontWeight: FontWeight.w700),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: onCard),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: neonGreen,
        unselectedItemColor: muted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        indicatorColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      extensions: [
        GorillaColors(
          bgCore:    bg,
          bgCard:    card,
          bgSurface: surface,
          bgInput:   input,
          border:    border,
          textMain:  onCard,
          textSecondary: isDark ? textSecondary : lTextSecondary,
          textMuted: muted,
          textDim:   dim,
        ),
      ],
    );
  }
}

/// Theme extension so any widget can access Gorilla semantic colors
/// without hardcoding dark-only hex values.
class GorillaColors extends ThemeExtension<GorillaColors> {
  const GorillaColors({
    required this.bgCore,
    required this.bgCard,
    required this.bgSurface,
    required this.bgInput,
    required this.border,
    required this.textMain,
    required this.textSecondary,
    required this.textMuted,
    required this.textDim,
  });

  final Color bgCore;
  final Color bgCard;
  final Color bgSurface;
  final Color bgInput;
  final Color border;
  final Color textMain;
  final Color textSecondary;
  final Color textMuted;
  final Color textDim;

  /// Convenience accessor: `context.gc.bgCard`
  static GorillaColors of(BuildContext context) =>
      Theme.of(context).extension<GorillaColors>()!;

  @override
  GorillaColors copyWith({
    Color? bgCore, Color? bgCard, Color? bgSurface, Color? bgInput,
    Color? border, Color? textMain, Color? textSecondary, Color? textMuted, Color? textDim,
  }) {
    return GorillaColors(
      bgCore:        bgCore        ?? this.bgCore,
      bgCard:        bgCard        ?? this.bgCard,
      bgSurface:     bgSurface     ?? this.bgSurface,
      bgInput:       bgInput       ?? this.bgInput,
      border:        border        ?? this.border,
      textMain:      textMain      ?? this.textMain,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted:     textMuted     ?? this.textMuted,
      textDim:       textDim       ?? this.textDim,
    );
  }

  @override
  GorillaColors lerp(GorillaColors? other, double t) {
    if (other == null) return this;
    return GorillaColors(
      bgCore:        Color.lerp(bgCore,        other.bgCore,        t)!,
      bgCard:        Color.lerp(bgCard,        other.bgCard,        t)!,
      bgSurface:     Color.lerp(bgSurface,     other.bgSurface,     t)!,
      bgInput:       Color.lerp(bgInput,       other.bgInput,       t)!,
      border:        Color.lerp(border,        other.border,        t)!,
      textMain:      Color.lerp(textMain,      other.textMain,      t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted:     Color.lerp(textMuted,     other.textMuted,     t)!,
      textDim:       Color.lerp(textDim,       other.textDim,       t)!,
    );
  }
}

/// Extension for terse access: `context.gorilla.bgCard`
extension GorillaThemeExt on BuildContext {
  GorillaColors get gorilla => GorillaColors.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
