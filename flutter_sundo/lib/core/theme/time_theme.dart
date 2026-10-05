import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/weather_repository.dart';

enum SundoDayPeriod { morning, noon, afternoon, evening }

enum SundoEnvironment { morning, noon, sunset, night, rainy, rainyNight }

class SundoTimeMood {
  final DateTime now;

  /// Only a current, reliable snapshot is supplied by the theme controller.
  final SipalayWeather? weather;
  final bool _raining;
  final WeatherCondition _weatherCondition;
  const SundoTimeMood(this.now,
      {bool raining = false,
      WeatherCondition weatherCondition = WeatherCondition.unknown,
      this.weather})
      : _raining = raining,
        _weatherCondition = weatherCondition;
  WeatherCondition get weatherCondition =>
      weather?.condition ?? _weatherCondition;
  bool get raining =>
      _raining ||
      weatherCondition == WeatherCondition.rain ||
      weatherCondition == WeatherCondition.drizzle ||
      weatherCondition == WeatherCondition.thunderstorm;
  SundoDayPeriod get period => now.hour >= 5 && now.hour < 11
      ? SundoDayPeriod.morning
      : now.hour >= 11 && now.hour < 15
          ? SundoDayPeriod.noon
          : now.hour >= 15 && now.hour < 18
              ? SundoDayPeriod.afternoon
              : SundoDayPeriod.evening;
  SundoEnvironment get environment => raining
      ? (isNight ? SundoEnvironment.rainyNight : SundoEnvironment.rainy)
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
  Color get background => isNight
      ? (raining ? const Color(0xFF101D29) : const Color(0xFF0F1E1A))
      : (raining || weatherCondition == WeatherCondition.cloudy
          ? const Color(0xFFF5F9FA)
          : const Color(0xFFF8FCF9));
  Color get surface => isNight ? const Color(0xFF1C2B24) : Colors.white;
  Color get textColor =>
      isNight ? const Color(0xFFF0F8EF) : const Color(0xFF153B2A);
  Color get mutedTextColor =>
      isNight ? const Color(0xFFB3C6BB) : const Color(0xFF64756B);
  Color get accent =>
      isNight ? const Color(0xFF7EDC9A) : const Color(0xFF0B8F3E);
  Color get sky => raining || weatherCondition == WeatherCondition.cloudy
      ? (isNight ? const Color(0xFF1D324B) : const Color(0xFFCFDCE5))
      : switch (period) {
          SundoDayPeriod.morning => const Color(0xFFA9E4F5),
          SundoDayPeriod.noon => const Color(0xFF78C8F6),
          SundoDayPeriod.afternoon => const Color(0xFFF6EBC4),
          SundoDayPeriod.evening => const Color(0xFF18344A),
        };

  // Lighting is part of the scene identity, including cloudy-to-clear changes
  // that use the same illustration and rainy changes at a time boundary.
  Object get sceneryIdentity => (environment, period, weatherCondition);
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
        weather: weather != null && weather.isFreshAt(now) ? weather : null);
  }

  void refresh() {
    final now = ref.read(sundoClockProvider)();
    final weather = ref.read(sundoWeatherProvider);
    state = SundoTimeMood(now,
        weather: weather != null && weather.isFreshAt(now) ? weather : null);
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
      oldWidget.mood.now != mood.now ||
      oldWidget.mood.raining != mood.raining ||
      oldWidget.mood.weatherCondition != mood.weatherCondition ||
      oldWidget.mood.weather != mood.weather;
}
