import 'package:flutter/material.dart';

class AppTheme {
  // Calming, inviting palette: indigo + teal accents, warm background
  static const Color primary = Color(0xFF4F6ADF); // Indigo blue (trust/calm)
  static const Color secondary = Color(0xFF22B8A7); // Teal (balance)
  static const Color background = Color(0xFFF5F7FB); // Soft light
  static const Color surface = Colors.white;

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    // Color psychology: trust/calm (indigo/teal), warmth/accent (peach).
    const seed = Color(0xFF3F51B5); // indigo
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    final onSurfaceMuted = scheme.onSurface.withValues(alpha: 0.84);
    final divider = scheme.outlineVariant;

    return base.copyWith(
      colorScheme: scheme.copyWith(
        secondary: const Color(0xFF00B8A9), // teal accent
        tertiary: const Color(0xFFFFC2A1), // warm peach accent
      ),
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: divider,
      textTheme: base.textTheme.apply(
        bodyColor: onSurfaceMuted,
        displayColor: scheme.onSurface,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF6F8FC),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE3E7EF)),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: seed, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        helperStyle: TextStyle(color: Color(0xFF6B7280)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(140, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(140, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        elevation: 0,
        color: const Color(0xFFFAFBFF),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        space: 24,
        thickness: 1,
      ),
    );
  }

  static ThemeData get dark => ThemeData.dark(useMaterial3: true);
}