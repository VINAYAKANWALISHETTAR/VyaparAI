import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2155F5);
  static const Color primaryDark = Color(0xFF173FC4);
  static const Color primaryLight = Color(0xFFEAF0FF);
  static const Color secondary = Color(0xFF6C3EF0);
  static const Color success = Color(0xFF149D6E);
  static const Color successSurface = Color(0xFFE2F7EE);
  static const Color error = Color(0xFFD92D20);
  static const Color errorSurface = Color(0xFFFEE9E7);
  static const Color warning = Color(0xFFF79009);
  static const Color warningSurface = Color(0xFFFFF2D9);
  static const Color background = Color(0xFFF7F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F4FC);
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF475467);
  static const Color textTertiary = Color(0xFF98A2B3);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = textPrimary;
  static const Color onSurface = textPrimary;
  static const Color onError = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFD0D5DD);

  static const Color lightBackground = background;
  static const Color darkBackground = Color(0xFF121212);

  static ColorScheme lightColorScheme = const ColorScheme.light(
    primary: primary,
    primaryContainer: primaryLight,
    secondary: secondary,
    secondaryContainer: Color(0xFFEEE8FF),
    error: error,
    surface: surface,
    onPrimary: onPrimary,
    onSecondary: onSecondary,
    onSurface: onSurface,
    onError: onError,
    outline: outline,
  );

  static ColorScheme darkColorScheme = ColorScheme.dark(
    primary: primary,
    primaryContainer: const Color(0xFF3F378E),
    secondary: secondary,
    secondaryContainer: const Color(0xFF006B5F),
    error: error,
    surface: const Color(0xFF1E1E1E),
    onPrimary: onPrimary,
    onSecondary: onSecondary,
    onSurface: const Color(0xFFE6E1E5),
    onError: onError,
    outline: const Color(0xFF938F99),
  );
}
