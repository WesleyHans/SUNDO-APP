import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/core/theme/solar_daylight.dart';

void main() {
  // Independent minute-resolution US Naval Observatory reference data:
  // https://aa.usno.navy.mil/api/rstt/oneday?date=2026-06-21&coords=9.7525%2C122.4038&tz=8
  // Same endpoint/coordinates/offset for each date below, retrieved 2026-10-07.
  // The tolerance includes oracle rounding and ordinary solar model differences.
  final sipalayFixtures = <(DateTime, String, String, String)>[
    (DateTime.utc(2026, 3, 20), '05:55', '11:58', '18:01'),
    (DateTime.utc(2026, 6, 21), '05:31', '11:52', '18:13'),
    (DateTime.utc(2026, 10, 7), '05:39', '11:38', '17:38'),
    (DateTime.utc(2026, 12, 21), '06:02', '11:48', '17:35'),
    (DateTime.utc(2024, 2, 29), '06:05', '12:03', '18:01'),
    (DateTime.utc(2026, 12, 31), '06:06', '11:53', '17:40'),
    (DateTime.utc(2027, 1, 1), '06:07', '11:54', '17:41'),
  ];

  for (final (date, rise, noon, set) in sipalayFixtures) {
    test('Sipalay ${date.toIso8601String()} agrees with USNO', () {
      final daylight = SolarDaylight.forDate(date);
      expect(daylight.usedFallback, isFalse);
      _expectNear(daylight.sunrise, rise);
      _expectNear(daylight.solarNoon, noon);
      _expectNear(daylight.sunset, set);
    });
  }

  test('other latitudes and west longitudes agree with independent USNO data',
      () {
    // Same USNO endpoint, with the explicit coordinates and offsets below.
    final manila = SolarDaylight.forDate(DateTime.utc(2026, 12, 21),
        latitude: 14.5995, longitude: 120.9842);
    expect(manila.usedFallback, isFalse);
    _expectNear(manila.sunrise, '06:16');
    _expectNear(manila.solarNoon, '11:54');
    _expectNear(manila.sunset, '17:32');
    final newYork = SolarDaylight.forDate(DateTime.utc(2026, 6, 21),
        latitude: 40.7128,
        longitude: -74.0060,
        timezoneOffset: const Duration(hours: -4));
    expect(newYork.usedFallback, isFalse);
    _expectNear(newYork.sunrise, '05:25');
    _expectNear(newYork.solarNoon, '12:58');
    _expectNear(newYork.sunset, '20:31');
  });

  test('summer and winter have different sunrise and sunset boundaries', () {
    final summer = SolarDaylight.forDate(DateTime.utc(2026, 6, 21));
    final winter = SolarDaylight.forDate(DateTime.utc(2026, 12, 21));
    expect(winter.sunrise - summer.sunrise,
        greaterThan(const Duration(minutes: 25)));
    expect(summer.sunset - winter.sunset,
        greaterThan(const Duration(minutes: 30)));
    expect(summer.sunrise, greaterThan(const Duration(hours: 5)));
    expect(winter.sunrise, greaterThan(const Duration(hours: 6)));
  });

  test('calendar fields are literal regardless of time or UTC flag', () {
    final expected = SolarDaylight.forDate(DateTime.utc(2026, 10, 7));
    for (final date in [
      DateTime(2026, 10, 7),
      DateTime(2026, 10, 7, 23, 59, 59),
      DateTime.utc(2026, 10, 7, 1, 2, 3),
      // Display fields obtained from an absolute Philippine midnight instant.
      DateTime.parse('2026-10-07T00:00:00+08:00')
          .toUtc()
          .add(SolarDaylight.philippineOffset),
    ]) {
      _expectSameClock(SolarDaylight.forDate(date), expected);
    }
  });

  test('explicit fractional UTC offset shifts wall-clock times precisely', () {
    final date = DateTime.utc(2026, 10, 7);
    final philippine = SolarDaylight.forDate(date);
    final shifted = SolarDaylight.forDate(date,
        timezoneOffset: const Duration(hours: 8, minutes: 45));
    expect(shifted.usedFallback, isFalse);
    expect(shifted.sunrise - philippine.sunrise, const Duration(minutes: 45));
    expect(
        shifted.solarNoon - philippine.solarNoon, const Duration(minutes: 45));
    expect(shifted.sunset - philippine.sunset, const Duration(minutes: 45));
  });

  test('every date in regular and leap years has ordered Sipalay daylight', () {
    for (final year in [2024, 2026]) {
      final end = DateTime.utc(year + 1);
      for (var date = DateTime.utc(year);
          date.isBefore(end);
          date = date.add(const Duration(days: 1))) {
        final daylight = SolarDaylight.forDate(date);
        expect(daylight.usedFallback, isFalse, reason: '$date');
        expect(daylight.sunrise, greaterThan(const Duration(hours: 5)));
        expect(daylight.sunrise, lessThan(const Duration(hours: 7)));
        expect(daylight.sunrise, lessThan(daylight.solarNoon));
        expect(daylight.solarNoon, lessThan(daylight.sunset));
        expect(daylight.sunset, greaterThan(const Duration(hours: 17)));
        expect(daylight.sunset, lessThan(const Duration(hours: 19)));
      }
    }
  });

  test('leap day and year rollover stay continuous', () {
    for (final date in [
      DateTime.utc(2024, 2, 28),
      DateTime.utc(2024, 2, 29),
      DateTime.utc(2026, 12, 31),
    ]) {
      final today = SolarDaylight.forDate(date);
      final next = SolarDaylight.forDate(date.add(const Duration(days: 1)));
      expect((today.sunrise - next.sunrise).abs(),
          lessThan(const Duration(minutes: 2)));
      expect((today.sunset - next.sunset).abs(),
          lessThan(const Duration(minutes: 2)));
    }
  });

  test('invalid coordinates use the calculated Sipalay fallback', () {
    final date = DateTime.utc(2026, 10, 7);
    final expected = SolarDaylight.forDate(date);
    for (final (latitude, longitude) in [
      (double.nan, 122.4038),
      (9.7525, double.nan),
      (double.infinity, 122.4038),
      (9.7525, double.negativeInfinity),
      (90.001, 122.4038),
      (-90.001, 122.4038),
      (9.7525, 180.001),
      (9.7525, -180.001),
    ]) {
      final daylight =
          SolarDaylight.forDate(date, latitude: latitude, longitude: longitude);
      expect(daylight.usedFallback, isTrue);
      _expectSameClock(daylight, expected);
    }
  });

  test('polar summer and winter fall back without NaN or exceptions', () {
    for (final date in [
      DateTime.utc(2026, 6, 21),
      DateTime.utc(2026, 12, 21),
    ]) {
      final expected = SolarDaylight.forDate(date);
      for (final latitude in [-90.0, -89.0, 89.0, 90.0]) {
        final daylight =
            SolarDaylight.forDate(date, latitude: latitude, longitude: 0);
        expect(daylight.usedFallback, isTrue);
        _expectSameClock(daylight, expected);
      }
    }
  });

  test('unsupported offsets and midnight-crossing daylight safely fall back',
      () {
    final date = DateTime.utc(2026, 10, 7);
    final expected = SolarDaylight.forDate(date);
    for (final offset in [
      const Duration(hours: -13),
      const Duration(hours: 15),
    ]) {
      final daylight = SolarDaylight.forDate(date, timezoneOffset: offset);
      expect(daylight.usedFallback, isTrue);
      _expectSameClock(daylight, expected);
    }
    final crossing = SolarDaylight.forDate(date,
        latitude: 0, longitude: 0, timezoneOffset: const Duration(hours: 14));
    expect(crossing.usedFallback, isTrue);
    _expectSameClock(crossing, expected);
  });

  test('unsupported years use a representative year with matching leap status',
      () {
    final leap = SolarDaylight.forDate(DateTime.utc(2400, 2, 29));
    expect(leap.usedFallback, isTrue);
    _expectSameClock(leap, SolarDaylight.forDate(DateTime.utc(2000, 2, 29)));
    final regular = SolarDaylight.forDate(DateTime.utc(2401, 12, 31));
    expect(regular.usedFallback, isTrue);
    _expectSameClock(
        regular, SolarDaylight.forDate(DateTime.utc(2001, 12, 31)));
  });
}

void _expectNear(Duration actual, String expected) {
  final fields = expected.split(':').map(int.parse).toList();
  final oracle = Duration(hours: fields[0], minutes: fields[1]);
  expect((actual - oracle).abs(), lessThan(const Duration(minutes: 2)),
      reason: '$actual versus USNO $expected');
}

void _expectSameClock(SolarDaylight actual, SolarDaylight expected) {
  expect(actual.sunrise, expected.sunrise);
  expect(actual.solarNoon, expected.solarNoon);
  expect(actual.sunset, expected.sunset);
}
