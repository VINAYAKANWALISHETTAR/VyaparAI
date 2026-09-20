import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'Roboto';

  static TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 48, fontWeight: FontWeight.w700, height: 1.08, letterSpacing: -1.2),
    displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 36, fontWeight: FontWeight.w700, height: 1.12, letterSpacing: -0.8),
    displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 30, fontWeight: FontWeight.w700, height: 1.18, letterSpacing: -0.5),
    headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.4),
    headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
    headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
    titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700, height: 1.33),
    titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, height: 1.50, letterSpacing: 0.15),
    titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, height: 1.43, letterSpacing: 0.10),
    bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, height: 1.50, letterSpacing: 0.50),
    bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, height: 1.43, letterSpacing: 0.25),
    bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, height: 1.33, letterSpacing: 0.40),
    labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, height: 1.43, letterSpacing: 0.10),
    labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, height: 1.33, letterSpacing: 0.50),
    labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500, height: 1.45, letterSpacing: 0.50),
  );
}
