import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  // Let Flutter dynamically resolve platform fonts and Indic script fallbacks (Noto Sans Kannada/Devanagari)
  // without per-frame fallback penalty or glyph collision lag.
  static TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, height: 1.15),
    displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1.18),
    displaySmall: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.20),
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.28),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.30),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.35),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.45),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.40),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.50),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.35),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.40),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.35),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.35),
  );
}
