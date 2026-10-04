import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SundoDayPeriod { morning, afternoon, evening }

class SundoTimeMood {
  final DateTime now;
  const SundoTimeMood(this.now);
  SundoDayPeriod get period => now.hour >= 6 && now.hour < 12
      ? SundoDayPeriod.morning
      : now.hour >= 12 && now.hour < 18
          ? SundoDayPeriod.afternoon
          : SundoDayPeriod.evening;
  bool get isNight => period == SundoDayPeriod.evening;
  String get greeting => switch (period) {
        SundoDayPeriod.morning => 'Good Morning',
        SundoDayPeriod.afternoon => 'Good Afternoon',
        SundoDayPeriod.evening => 'Good Evening',
      };
  Color get background =>
      isNight ? const Color(0xFF0F1E1A) : const Color(0xFFF8FCF9);
  Color get surface => isNight ? const Color(0xFF1C2B24) : Colors.white;
  Color get textColor =>
      isNight ? const Color(0xFFF0F8EF) : const Color(0xFF153B2A);
  Color get mutedTextColor =>
      isNight ? const Color(0xFFB3C6BB) : const Color(0xFF64756B);
  Color get accent =>
      isNight ? const Color(0xFF7EDC9A) : const Color(0xFF0B8F3E);
  Color get sky => switch (period) {
        SundoDayPeriod.morning => const Color(0xFFA9E4F5),
        SundoDayPeriod.afternoon => const Color(0xFFF6EBC4),
        SundoDayPeriod.evening => const Color(0xFF18344A),
      };
}

final sundoClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final sundoDayNightThemeProvider =
    NotifierProvider<SundoDayNightThemeController, SundoTimeMood>(
  SundoDayNightThemeController.new,
);

/// Re-evaluates local time at minute boundaries and when the app resumes.
class SundoDayNightThemeController extends Notifier<SundoTimeMood> {
  @override
  SundoTimeMood build() {
    final clock = ref.watch(sundoClockProvider);
    final timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
    ref.onDispose(timer.cancel);
    return SundoTimeMood(clock());
  }

  void refresh() => state = SundoTimeMood(ref.read(sundoClockProvider)());
}

class SundoTimeScope extends InheritedWidget {
  final SundoTimeMood mood;
  const SundoTimeScope({super.key, required this.mood, required super.child});
  static SundoTimeMood of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SundoTimeScope>()?.mood ??
      SundoTimeMood(DateTime.now());
  @override
  bool updateShouldNotify(SundoTimeScope oldWidget) =>
      oldWidget.mood.now != mood.now;
}
