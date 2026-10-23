import 'package:flutter/material.dart';

class AppTheme {
  static const green = Color(0xFF315E4B);
  static const noteColors = [
    Color(0xFFEAF0E3),
    Color(0xFFFAEDD9),
    Color(0xFFE8EDF6),
    Color(0xFFF3E5E2),
  ];
  static const darkNoteColors = [
    Color(0xFF263C30),
    Color(0xFF403727),
    Color(0xFF293547),
    Color(0xFF422E2D),
  ];
  static const colorNames = ['Sage', 'Pasir', 'Langit', 'Rose'];

  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: brightness,
      primary: dark ? const Color(0xFFA9D2B8) : green,
      surface: dark ? const Color(0xFF19231F) : const Color(0xFFFFFEFA),
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF111A16)
          : const Color(0xFFF7F8F2),
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? const Color(0xFF111A16)
            : const Color(0xFFF7F8F2),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
