import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './time_theme.dart';

ThemeData buildSundoTheme(SundoTimeMood mood) {
  final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B8F3E),
      primary: mood.accent,
      brightness: mood.isNight ? Brightness.dark : Brightness.light,
      surface: mood.surface);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    primaryColor: const Color(0xFF0B8F3E),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(mood.isNight
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
        backgroundColor: mood.surface,
        elevation: 0,
        foregroundColor: mood.textColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
            fontSize: 17, fontWeight: FontWeight.w700, color: mood.textColor)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0B8F3E),
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: mood.accent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)))),
    inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: mood.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDCE9E0))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15)),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: mood.surface,
        height: 64,
        indicatorColor: mood.accent.withValues(alpha: .14)),
  );
}
