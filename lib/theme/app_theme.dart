import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const primaryBlue = Color(0xFF2563EB);
  static const successGreen = Color(0xFF16A34A);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primaryBlue,
    scaffoldBackgroundColor: const Color(0xFFF3F4F6),
    // TODO: خط Cairo مكانش مرفوع فعلياً (محتاج ملفات .ttf حقيقية تحت
    // assets/fonts/ + تسجيله في pubspec.yaml تحت flutter.fonts). سيبنا
    // خط النظام الافتراضي دلوقتي بدل وعد بخط مش موجود فعلياً.
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: primaryBlue,
    scaffoldBackgroundColor: const Color(0xFF111318),
    // TODO: خط Cairo مكانش مرفوع فعلياً (محتاج ملفات .ttf حقيقية تحت
    // assets/fonts/ + تسجيله في pubspec.yaml تحت flutter.fonts). سيبنا
    // خط النظام الافتراضي دلوقتي بدل وعد بخط مش موجود فعلياً.
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1C22),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E2128),
    ),
  );
}
