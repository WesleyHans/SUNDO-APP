import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/weather_repository.dart';
import 'solar_daylight.dart';

enum SundoDayPeriod { morning, noon, afternoon, evening }

enum SundoEnvironment { morning, noon, sunset, twilight, night, rainy, rainyNight }

class SundoTimeMood {
  final DateTime now;
  final DateTime? _philippineTime;
  final SolarDaylight? _daylight;

  /// UI clock fields in Philippine Standard Time. `now` remains the actual
  /// instant for freshness/elapsed time; wall-clock offsets must not age weather.
  DateTime get localTime => _philippineTime ?? now;

  /// Only a current, reliable snapshot is supplied by the theme controller.
  final SipalayWeather? weather;
  final bool _raining;
  final WeatherCondition _weatherCondition;
  const SundoTimeMood(this.now,
      {bool raining = false,
      WeatherCondition weatherCondition = WeatherCondition.unknown,
      DateTime? philippineTime,
      SolarDaylight? daylight,
      this.weather})
      : _raining = raining,
        _philippineTime = philippineTime,
        _daylight = daylight,
        _weatherCondition = weatherCondition;

  /// Production clocks use an absolute instant, independent of device timezone.
  /// The original constructor also supports explicit wall-clock preview scenes.
  factory SundoTimeMood.fromInstant(DateTime instant,
      {SipalayWeather? weather, WeatherLocation? location}) {
    final localTime = instant.toUtc().add(const Duration(hours: 8));
    final area = location ??
        (weather?.isFreshAt(instant) == true ? weather?.location : null);
    final daylight = area?.isValid == true
        ? SolarDaylight.forDate(localTime,
            latitude: area!.latitude, longitude: area.longitude)
        : SolarDaylight.forDate(localTime);
    return SundoTimeMood(instant,
        weather: weather, philippineTime: localTime, daylight: daylight);
  }

  /// Greeting wording and sunlight are independent. The estimated local solar
  /// times work offline, using Sipalay when no permitted area is available.
  SolarDaylight get daylight => _daylight ?? SolarDaylight.forDate(localTime);
  Duration get _timeOfDay => Duration(
      hours: localTime.hour,
      minutes: localTime.minute,
      seconds: localTime.second,
      milliseconds: localTime.millisecond,
      microseconds: localTime.microsecond);
  WeatherCondition get weatherCondition => weather == null
      ? _weatherCondition
      : weather!.isFreshAt(now)
          ? weather!.condition
          : WeatherCondition.unknown;
  bool get raining =>
      _raining ||
      weatherCondition == WeatherCondition.rain ||
      weatherCondition == WeatherCondition.drizzle ||
      weatherCondition == WeatherCondition.thunderstorm;
  SundoDayPeriod get period => isNight
      ? SundoDayPeriod.evening
      : localTime.hour < 11
          ? SundoDayPeriod.morning
          : localTime.hour < 15
              ? SundoDayPeriod.noon
              : SundoDayPeriod.afternoon;
  bool get isSunset => !isNight && localTime.hour >= 17;
  SundoEnvironment get environment => raining
      ? (isNight ? SundoEnvironment.rainyNight : SundoEnvironment.rainy)
      : isNight
          ? (isDarkNight ? SundoEnvironment.night : SundoEnvironment.twilight)
          : isSunset
              ? SundoEnvironment.sunset
              : period == SundoDayPeriod.morning
                  ? SundoEnvironment.morning
                  : SundoEnvironment.noon;
  bool get isNight =>
      _timeOfDay < daylight.sunrise || _timeOfDay >= daylight.sunset;

  /// Keep the supplied twilight artwork through 6 PM. The full-night image
  /// starts at 7 PM and remains in use before the next local sunrise.
  bool get isDarkNight =>
      isNight && (localTime.hour >= 19 || _timeOfDay < daylight.sunrise);
  String get greeting => localTime.hour < 12
      ? 'Good Morning'
      : localTime.hour >= 12 && localTime.hour < 18
          ? 'Good Afternoon'
          : 'Good Evening';
  Color get background => isNight
      ? (raining ? const Color(0xFF101D29) : const Color(0xFF0F1E1A))
      : (raining || weatherCondition == WeatherCondition.cloudy
          ? const Color(0xFFF5F9FA)
          : const Color(0xFFF8FCF9));

  /// A faint sunset wash behind inner-page content, separate from the original
  /// full-scene artwork and functional map surfaces.
  Color get innerBackground => isSunset
      ? (raining ? const Color(0xFFF6F1E6) : const Color(0xFFFFF5DF))
      : background;
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
          SundoDayPeriod.afternoon =>
            isSunset ? const Color(0xFFF6EBC4) : const Color(0xFF78C8F6),
          SundoDayPeriod.evening => const Color(0xFF18344A),
        };

  // Lighting is part of the scene identity, including cloudy-to-clear changes
  // that use the same illustration and rainy changes at a time boundary.
  Object get sceneryIdentity =>
      (environment, period, isSunset, isDarkNight, weatherCondition);
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
    ref.watch(environmentLocationStatusProvider);
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
    return SundoTimeMood.fromInstant(now,
        location: ref.read(sundoWeatherProvider.notifier).location,
        weather: weather != null && weather.isFreshAt(now) ? weather : null);
  }

  void refresh() {
    final now = ref.read(sundoClockProvider)();
    final weather = ref.read(sundoWeatherProvider);
    state = SundoTimeMood.fromInstant(now,
        location: ref.read(sundoWeatherProvider.notifier).location,
        weather: weather != null && weather.isFreshAt(now) ? weather : null);
  }
}

class SundoTimeScope extends InheritedWidget {
  final SundoTimeMood mood;
  final VoidCallback? onWeatherRefresh;
  final bool checkingWeather;
  final bool weatherEnabled;
  const SundoTimeScope(
      {super.key,
      required this.mood,
      required super.child,
      this.onWeatherRefresh,
      this.checkingWeather = false,
      this.weatherEnabled = false});
  static SundoTimeMood of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SundoTimeScope>()?.mood ??
      SundoTimeMood.fromInstant(DateTime.now());
  @override
  bool updateShouldNotify(SundoTimeScope oldWidget) =>
      oldWidget.mood.now != mood.now ||
      oldWidget.mood.localTime != mood.localTime ||
      oldWidget.mood.sceneryIdentity != mood.sceneryIdentity ||
      oldWidget.checkingWeather != checkingWeather ||
      oldWidget.weatherEnabled != weatherEnabled ||
      oldWidget.mood.raining != mood.raining ||
      oldWidget.mood.weatherCondition != mood.weatherCondition ||
      oldWidget.mood.weather != mood.weather;
}
