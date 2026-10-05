import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/weather_repository.dart';

enum SundoDayPeriod { morning, noon, afternoon, evening }

enum SundoEnvironment { morning, noon, sunset, night, rainy }

class SundoTimeMood {
  final DateTime now;
  final bool raining;
  const SundoTimeMood(this.now, {this.raining = false});
  SundoDayPeriod get period => now.hour >= 5 && now.hour < 11
      ? SundoDayPeriod.morning
      : now.hour >= 11 && now.hour < 15
          ? SundoDayPeriod.noon
          : now.hour >= 15 && now.hour < 18
              ? SundoDayPeriod.afternoon
              : SundoDayPeriod.evening;
  SundoEnvironment get environment => raining
      ? SundoEnvironment.rainy
      : switch (period) {
          SundoDayPeriod.morning => SundoEnvironment.morning,
          SundoDayPeriod.noon => SundoEnvironment.noon,
          SundoDayPeriod.afternoon => SundoEnvironment.sunset,
          SundoDayPeriod.evening => SundoEnvironment.night,
        };
  bool get isNight => period == SundoDayPeriod.evening;
  String get greeting => switch (period) {
        SundoDayPeriod.morning => 'Good Morning',
        SundoDayPeriod.noon => 'Good Afternoon',
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
        SundoDayPeriod.noon => const Color(0xFF78C8F6),
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
    final weather = ref.watch(sundoWeatherProvider);
    Timer? timer;
    void scheduleMinuteBoundary() {
      final now = clock();
      final intoMinute = Duration(
          seconds: now.second,
          milliseconds: now.millisecond,
          microseconds: now.microsecond);
      timer = Timer(const Duration(minutes: 1) - intoMinute, () {
        if (!ref.mounted) return;
        refresh();
        scheduleMinuteBoundary();
      });
    }

    scheduleMinuteBoundary();
    ref.onDispose(() => timer?.cancel());
    final now = clock();
    return SundoTimeMood(now,
        raining:
            weather != null && weather.isFreshAt(now) && weather.isRaining);
  }

  void refresh() {
    final now = ref.read(sundoClockProvider)();
    final weather = ref.read(sundoWeatherProvider);
    state = SundoTimeMood(now,
        raining:
            weather != null && weather.isFreshAt(now) && weather.isRaining);
  }
}

class SundoTimeScope extends InheritedWidget {
  final SundoTimeMood mood;
  const SundoTimeScope({super.key, required this.mood, required super.child});
  static SundoTimeMood of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SundoTimeScope>()?.mood ??
      SundoTimeMood(DateTime.now());
  @override
  bool updateShouldNotify(SundoTimeScope oldWidget) =>
      oldWidget.mood.now != mood.now || oldWidget.mood.raining != mood.raining;
}
