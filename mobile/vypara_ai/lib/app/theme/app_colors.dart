import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF79747E);

  static const Color lightBackground = background;
  static const Color darkBackground = Color(0xFF121212);

  static ColorScheme lightColorScheme = const ColorScheme.light(
    primary: primary,
    primaryContainer: Color(0xFFEADDFF),
    secondary: secondary,
    secondaryContainer: Color(0xFFE0F7FA),
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
