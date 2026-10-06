import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';

void main() {
  test('Philippine greeting changes at noon, independent of device timezone',
      () {
    for (final stamp in [
      '2026-10-06T03:00:00Z',
      '2026-10-06T11:00:00+08:00',
      '2026-10-05T23:00:00-04:00'
    ]) {
      final instant = DateTime.parse(stamp);
      final mood = SundoTimeMood.fromInstant(instant);
      expect(mood.localTime.hour, 11);
      expect(mood.localTime.day, 6);
      expect(mood.greeting, 'Good Morning');
      expect(mood.environment, SundoEnvironment.noon);
      expect(mood.now.toUtc(), DateTime.utc(2026, 10, 6, 3));
    }
    for (final entry in {
      '11:59': 'Good Morning',
      '12:00': 'Good Afternoon',
      '17:59': 'Good Afternoon',
      '18:00': 'Good Evening'
    }.entries) {
      final instant = DateTime.parse('2026-10-06T${entry.key}:00+08:00');
      expect(SundoTimeMood.fromInstant(instant).greeting, entry.value);
    }
    expect(
        SundoTimeMood.fromInstant(DateTime.utc(2026, 10, 6, 16)).localTime.day,
        7);
  });

  test('Philippine display offset does not expire a fresh weather snapshot',
      () {
    final now = DateTime.utc(2026, 10, 6, 3);
    final weather = SipalayWeather(
        validAt: now,
        fetchedAt: now,
        weatherCode: 61,
        precipitationMm: 0,
        rainMm: 0,
        showersMm: 0);
    final mood = SundoTimeMood.fromInstant(now, weather: weather);
    expect(mood.localTime.hour, 11);
    expect(mood.raining, isTrue);
    expect(weather.isFreshAt(mood.now), isTrue);
  });
  test('all four periods switch at the exact requested minute boundaries', () {
    final cases = <(int, int, SundoDayPeriod, SundoEnvironment)>[
      (0, 0, SundoDayPeriod.evening, SundoEnvironment.night),
      (4, 59, SundoDayPeriod.evening, SundoEnvironment.night),
      (5, 0, SundoDayPeriod.morning, SundoEnvironment.morning),
      (10, 59, SundoDayPeriod.morning, SundoEnvironment.morning),
      (11, 0, SundoDayPeriod.noon, SundoEnvironment.noon),
      (14, 59, SundoDayPeriod.noon, SundoEnvironment.noon),
      (15, 0, SundoDayPeriod.afternoon, SundoEnvironment.sunset),
      (17, 59, SundoDayPeriod.afternoon, SundoEnvironment.sunset),
      (18, 0, SundoDayPeriod.evening, SundoEnvironment.night),
      (23, 59, SundoDayPeriod.evening, SundoEnvironment.night),
    ];
    for (final (hour, minute, period, environment) in cases) {
      final mood = SundoTimeMood(DateTime(2026, 10, 5, hour, minute));
      expect(mood.period, period, reason: '$hour:$minute');
      expect(mood.environment, environment, reason: '$hour:$minute');
      expect(mood.isNight, hour < 5 || hour >= 18);
      expect(
          mood.greeting,
          hour >= 5 && hour < 12
              ? 'Good Morning'
              : hour >= 12 && hour < 18
                  ? 'Good Afternoon'
                  : 'Good Evening');
    }
  });
  test('rain retains local time and uses dark rainy scenery after 18:00', () {
    for (final hour in [4, 8, 12, 17, 20]) {
      final clear = SundoTimeMood(DateTime(2026, 10, 5, hour));
      final rain = SundoTimeMood(clear.now, raining: true);
      expect(rain.environment,
          clear.isNight ? SundoEnvironment.rainyNight : SundoEnvironment.rainy);
      expect(rain.period, clear.period);
      expect(rain.isNight, clear.isNight);
      expect(rain.greeting, clear.greeting);
      expect(rain.surface, clear.surface);
      expect(rain.textColor, clear.textColor);
      expect(rain.accent, clear.accent);
    }
  });
  test('rain, drizzle and thunderstorm all respect the four time periods', () {
    for (final condition in [
      WeatherCondition.rain,
      WeatherCondition.drizzle,
      WeatherCondition.thunderstorm,
    ]) {
      for (final hour in [4, 5, 11, 15, 18]) {
        final mood = SundoTimeMood(DateTime(2026, 10, 5, hour),
            weatherCondition: condition);
        expect(mood.raining, isTrue);
        expect(
            mood.environment,
            hour < 5 || hour >= 18
                ? SundoEnvironment.rainyNight
                : SundoEnvironment.rainy);
      }
    }
  });
  test('cloudy and unknown conditions keep their appropriate time artwork', () {
    for (final condition in [
      WeatherCondition.clear,
      WeatherCondition.cloudy,
      WeatherCondition.unknown,
    ]) {
      for (final hour in [8, 12, 17, 20]) {
        final mood = SundoTimeMood(DateTime(2026, 10, 5, hour),
            weatherCondition: condition);
        final timeOnly = SundoTimeMood(mood.now);
        expect(mood.environment, timeOnly.environment);
        expect(mood.greeting, timeOnly.greeting);
        expect(mood.raining, isFalse);
      }
    }
  });
  test(
      'theme controller refreshes after a local time change and disposes ticker',
      () {
    var clock = _phInstant(2026, 10, 4, 17, 59);
    final container = ProviderContainer(
        overrides: [sundoClockProvider.overrideWithValue(() => clock)]);
    addTearDown(container.dispose);
    expect(container.read(sundoDayNightThemeProvider).isNight, isFalse);
    clock = _phInstant(2026, 10, 4, 18);
    container.read(sundoDayNightThemeProvider.notifier).refresh();
    expect(container.read(sundoDayNightThemeProvider).isNight, isTrue);
    expect(container.read(sundoDayNightThemeProvider).greeting, 'Good Evening');
  });
  test('weather-only scope changes notify without moving the clock', () {
    final now = _phInstant(2026, 10, 5, 8);
    final clear = SundoTimeScope(
        mood: SundoTimeMood(now), child: const SizedBox.shrink());
    final rain = SundoTimeScope(
        mood: SundoTimeMood(now, raining: true),
        child: const SizedBox.shrink());
    expect(rain.updateShouldNotify(clear), isTrue);
    expect(clear.updateShouldNotify(clear), isFalse);
    final cloudy = SundoTimeScope(
        mood: SundoTimeMood(now, weatherCondition: WeatherCondition.cloudy),
        child: const SizedBox.shrink());
    expect(cloudy.updateShouldNotify(clear), isTrue);
  });
  testWidgets('minute ticker changes at 11:00 even when started at 10:59:55',
      (tester) async {
    var clock = _phInstant(2026, 10, 5, 10, 59, 55);
    final container = ProviderContainer(
        overrides: [sundoClockProvider.overrideWithValue(() => clock)]);
    addTearDown(container.dispose);
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.morning);
    clock = clock.add(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 4));
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.morning);
    clock = clock.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.noon);
    container.dispose();
  });
  test('theme provider ignores stale rainy current conditions', () {
    final now = _phInstant(2026, 10, 5, 8);
    final weather = SipalayWeather(
      validAt: now.subtract(const Duration(minutes: 31)),
      fetchedAt: now,
      weatherCode: 63,
      precipitationMm: 1,
      rainMm: 1,
      showersMm: 0,
    );
    final container = ProviderContainer(overrides: [
      sundoClockProvider.overrideWithValue(() => now),
      sundoWeatherProvider.overrideWith(() => _FixedWeatherController(weather)),
    ]);
    addTearDown(container.dispose);
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.morning);
  });
  test('theme expires rain even when no replacement response arrives', () {
    var clock = _phInstant(2026, 10, 5, 14);
    final weather = SipalayWeather(
      validAt: clock,
      fetchedAt: clock,
      weatherCode: 63,
      precipitationMm: 1,
      rainMm: 1,
      showersMm: 0,
    );
    final container = ProviderContainer(overrides: [
      sundoClockProvider.overrideWithValue(() => clock),
      sundoWeatherProvider.overrideWith(() => _FixedWeatherController(weather)),
    ]);
    addTearDown(container.dispose);
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.rainy);
    clock = clock.add(const Duration(minutes: 31));
    container.read(sundoDayNightThemeProvider.notifier).refresh();
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.noon);
    expect(container.read(sundoDayNightThemeProvider).weather, isNull);
    expect(container.read(sundoDayNightThemeProvider).weatherCondition,
        WeatherCondition.unknown);
  });
  test('fresh local rain snapshot remains available in the evening theme', () {
    final now = _phInstant(2026, 10, 5, 19, 10);
    final weather = SipalayWeather(
      validAt: now,
      fetchedAt: now,
      weatherCode: 63,
      precipitationMm: 1,
      rainMm: 1,
      showersMm: 0,
    );
    final container = ProviderContainer(overrides: [
      sundoClockProvider.overrideWithValue(() => now),
      sundoWeatherProvider.overrideWith(() => _FixedWeatherController(weather)),
    ]);
    addTearDown(container.dispose);
    final mood = container.read(sundoDayNightThemeProvider);
    expect(mood.weather, same(weather));
    expect(mood.weatherCondition, WeatherCondition.rain);
    expect(mood.environment, SundoEnvironment.rainyNight);
    expect(mood.greeting, 'Good Evening');
  });
}

class _FixedWeatherController extends SundoWeatherController {
  _FixedWeatherController(this.weather);
  final SipalayWeather? weather;
  @override
  SipalayWeather? build() => weather;
}

DateTime _phInstant(int year, int month, int day,
        [int hour = 0, int minute = 0, int second = 0]) =>
    DateTime.utc(year, month, day, hour, minute, second)
        .subtract(const Duration(hours: 8));
