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
      '00:00': 'Good Morning',
      '04:59': 'Good Morning',
      '05:00': 'Good Morning',
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
  test('daylight stays dark before sunrise and sunset artwork starts at 17:00',
      () {
    final cases = <(int, int, SundoDayPeriod, SundoEnvironment)>[
      (0, 0, SundoDayPeriod.evening, SundoEnvironment.night),
      (4, 59, SundoDayPeriod.evening, SundoEnvironment.night),
      (5, 0, SundoDayPeriod.evening, SundoEnvironment.night),
      (6, 0, SundoDayPeriod.morning, SundoEnvironment.morning),
      (10, 59, SundoDayPeriod.morning, SundoEnvironment.morning),
      (11, 0, SundoDayPeriod.noon, SundoEnvironment.noon),
      (14, 59, SundoDayPeriod.noon, SundoEnvironment.noon),
      (15, 0, SundoDayPeriod.afternoon, SundoEnvironment.noon),
      (16, 59, SundoDayPeriod.afternoon, SundoEnvironment.noon),
      (17, 0, SundoDayPeriod.afternoon, SundoEnvironment.sunset),
      (18, 0, SundoDayPeriod.evening, SundoEnvironment.night),
      (23, 59, SundoDayPeriod.evening, SundoEnvironment.night),
    ];
    for (final (hour, minute, period, environment) in cases) {
      final mood = SundoTimeMood(DateTime(2026, 10, 5, hour, minute));
      expect(mood.period, period, reason: '$hour:$minute');
      expect(mood.environment, environment, reason: '$hour:$minute');
      expect(mood.isNight, environment == SundoEnvironment.night);
      expect(
          mood.greeting,
          hour < 12
              ? 'Good Morning'
              : hour >= 12 && hour < 18
                  ? 'Good Afternoon'
                  : 'Good Evening');
    }
  });
  test('rain respects sunlight independently of the greeting', () {
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
            hour < 6 || hour >= 18
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
    var clock = _phInstant(2026, 10, 4, 17);
    final container = ProviderContainer(
        overrides: [sundoClockProvider.overrideWithValue(() => clock)]);
    addTearDown(container.dispose);
    expect(container.read(sundoDayNightThemeProvider).isNight, isFalse);
    clock = _phInstant(2026, 10, 4, 18);
    container.read(sundoDayNightThemeProvider.notifier).refresh();
    expect(container.read(sundoDayNightThemeProvider).isNight, isTrue);
    expect(container.read(sundoDayNightThemeProvider).greeting, 'Good Evening');
  });

  test('sunrise and sunset change lighting without changing greeting wording',
      () {
    final midnight = _phInstant(2026, 10, 7);
    final night = SundoTimeMood.fromInstant(midnight);
    expect(night.greeting, 'Good Morning');
    expect(night.isNight, isTrue);
    expect(night.environment, SundoEnvironment.night);
    final sunrise = midnight.add(night.daylight.sunrise);
    expect(
        SundoTimeMood.fromInstant(
                sunrise.subtract(const Duration(microseconds: 1)))
            .isNight,
        isTrue);
    final day = SundoTimeMood.fromInstant(sunrise);
    expect(day.isNight, isFalse);
    expect(day.greeting, 'Good Morning');
    expect(day.environment, SundoEnvironment.morning);
    final sunset = midnight.add(night.daylight.sunset);
    expect(
        SundoTimeMood.fromInstant(
                sunset.subtract(const Duration(microseconds: 1)))
            .environment,
        SundoEnvironment.sunset);
    final afterSunset = SundoTimeMood.fromInstant(sunset);
    expect(afterSunset.isNight, isTrue);
    expect(afterSunset.environment, SundoEnvironment.night);
    // Local sunset can precede 6 PM: the afternoon greeting must not keep a sun.
    expect(afterSunset.greeting, 'Good Afternoon');
  });

  test('resolved solar area survives unavailable or expired weather', () {
    final midnight = _phInstant(2026, 10, 7);
    const area = WeatherLocation(
        latitude: 7.07,
        longitude: 125.61,
        label: 'Your location',
        isDeviceLocation: true);
    final city = SundoTimeMood.fromInstant(midnight);
    final areaMood = SundoTimeMood.fromInstant(midnight, location: area);
    expect(areaMood.daylight.sunrise, lessThan(city.daylight.sunrise));
    final instant = midnight.add(areaMood.daylight.sunrise);
    final staleRain = SipalayWeather(
        validAt: instant.subtract(const Duration(hours: 1)),
        fetchedAt: instant.subtract(const Duration(hours: 1)),
        weatherCode: 63,
        precipitationMm: 1,
        rainMm: 1,
        showersMm: 0,
        location: area);
    final container = ProviderContainer(overrides: [
      sundoClockProvider.overrideWithValue(() => instant),
      sundoWeatherProvider
          .overrideWith(() => _FixedWeatherController(staleRain, area: area)),
    ]);
    addTearDown(container.dispose);
    final mood = container.read(sundoDayNightThemeProvider);
    expect(mood.weather, isNull);
    expect(mood.raining, isFalse);
    expect(mood.daylight.sunrise, areaMood.daylight.sunrise);
    expect(mood.isNight, isFalse);
    expect(SundoTimeMood.fromInstant(instant).isNight, isTrue);
    final oldScope = SundoTimeScope(
        mood: SundoTimeMood.fromInstant(instant),
        child: const SizedBox.shrink());
    final newScope = SundoTimeScope(mood: mood, child: const SizedBox.shrink());
    expect(newScope.updateShouldNotify(oldScope), isTrue,
        reason: 'A new resolved area can change daylight at the same instant.');
  });

  testWidgets(
      'minute ticker changes greeting at midnight while scenery is night',
      (tester) async {
    var clock = _phInstant(2026, 10, 6, 23, 59, 55);
    final container = ProviderContainer(
        overrides: [sundoClockProvider.overrideWithValue(() => clock)]);
    addTearDown(container.dispose);
    final previous = container.read(sundoDayNightThemeProvider);
    expect(previous.greeting, 'Good Evening');
    clock = _phInstant(2026, 10, 7);
    await tester.pump(const Duration(seconds: 5));
    final midnight = container.read(sundoDayNightThemeProvider);
    expect(midnight.greeting, 'Good Morning');
    expect(midnight.environment, SundoEnvironment.night);
    expect(midnight.sceneryIdentity, previous.sceneryIdentity);
    container.dispose();
  });

  testWidgets('minute ticker starts sunset at exactly 5 PM', (tester) async {
    var clock = _phInstant(2026, 10, 7, 16, 59, 55);
    final container = ProviderContainer(
        overrides: [sundoClockProvider.overrideWithValue(() => clock)]);
    addTearDown(container.dispose);
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.noon);
    clock = _phInstant(2026, 10, 7, 17);
    await tester.pump(const Duration(seconds: 5));
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.sunset);
    container.dispose();
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
  _FixedWeatherController(this.weather, {this.area});
  final SipalayWeather? weather;
  final WeatherLocation? area;
  @override
  WeatherLocation? get location => area;
  @override
  SipalayWeather? build() => weather;
}

DateTime _phInstant(int year, int month, int day,
        [int hour = 0, int minute = 0, int second = 0]) =>
    DateTime.utc(year, month, day, hour, minute, second)
        .subtract(const Duration(hours: 8));
