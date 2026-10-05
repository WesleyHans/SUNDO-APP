import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';

void main() {
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
          switch (period) {
            SundoDayPeriod.morning => 'Good Morning',
            SundoDayPeriod.noon || SundoDayPeriod.afternoon => 'Good Afternoon',
            SundoDayPeriod.evening => 'Good Evening',
          });
    }
  });
  test('rain overrides only environment and preserves all time colors', () {
    for (final hour in [4, 8, 12, 17, 20]) {
      final clear = SundoTimeMood(DateTime(2026, 10, 5, hour));
      final rain = SundoTimeMood(clear.now, raining: true);
      expect(rain.environment, SundoEnvironment.rainy);
      expect(rain.period, clear.period);
      expect(rain.isNight, clear.isNight);
      expect(rain.greeting, clear.greeting);
      expect(rain.surface, clear.surface);
      expect(rain.background, clear.background);
      expect(rain.textColor, clear.textColor);
      expect(rain.accent, clear.accent);
    }
  });
  test(
      'theme controller refreshes after a local time change and disposes ticker',
      () {
    var clock = DateTime(2026, 10, 4, 17, 59);
    final container = ProviderContainer(
        overrides: [sundoClockProvider.overrideWithValue(() => clock)]);
    addTearDown(container.dispose);
    expect(container.read(sundoDayNightThemeProvider).isNight, isFalse);
    clock = DateTime(2026, 10, 4, 18);
    container.read(sundoDayNightThemeProvider.notifier).refresh();
    expect(container.read(sundoDayNightThemeProvider).isNight, isTrue);
    expect(container.read(sundoDayNightThemeProvider).greeting, 'Good Evening');
  });
  test('weather-only scope changes notify without moving the clock', () {
    final now = DateTime(2026, 10, 5, 8);
    final clear = SundoTimeScope(
        mood: SundoTimeMood(now), child: const SizedBox.shrink());
    final rain = SundoTimeScope(
        mood: SundoTimeMood(now, raining: true),
        child: const SizedBox.shrink());
    expect(rain.updateShouldNotify(clear), isTrue);
    expect(clear.updateShouldNotify(clear), isFalse);
  });
  testWidgets('minute ticker changes at 11:00 even when started at 10:59:55',
      (tester) async {
    var clock = DateTime(2026, 10, 5, 10, 59, 55);
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
    final now = DateTime.utc(2026, 10, 5, 8);
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
    var clock = DateTime.utc(2026, 10, 5, 14);
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
  });
}

class _FixedWeatherController extends SundoWeatherController {
  _FixedWeatherController(this.weather);
  final SipalayWeather? weather;
  @override
  SipalayWeather? build() => weather;
}
