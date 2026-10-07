import 'dart:math' as math;

/// Apparent sunrise, solar noon, and sunset as local wall-clock times.
///
/// Each [Duration] is measured from midnight on the requested calendar date;
/// none is an absolute timestamp. In particular, do not use these values to
/// measure weather freshness or convert them with `DateTime.toLocal()`.
class SolarDaylight {
  const SolarDaylight._({
    required this.sunrise,
    required this.solarNoon,
    required this.sunset,
    required this.usedFallback,
  });

  /// Sipalay's city center, matching EnvironmentLocationService's saved area.
  static const sipalayLatitude = 9.7525;
  static const sipalayLongitude = 122.4038;
  static const philippineOffset = Duration(hours: 8);

  final Duration sunrise;
  final Duration solarNoon;
  final Duration sunset;

  /// Invalid inputs or a date without a same-day rise/set use Sipalay daylight.
  final bool usedFallback;

  /// Calculates daylight offline using NOAA's two-pass Meeus solar equations.
  ///
  /// [localDate]'s year/month/day are consumed literally; its time and timezone
  /// are ignored. The caller must first choose the calendar date in the desired
  /// timezone. [timezoneOffset] explicitly supplies that timezone's UTC offset
  /// for this date, so the device timezone never participates in this calculation.
  /// North/east coordinates are positive. The 90.833-degree zenith includes the
  /// usual solar disk and atmospheric refraction correction, not civil twilight.
  ///
  /// Invalid coordinates/offsets, polar days/nights, and daylight crossing local
  /// midnight fall back to Sipalay in Philippine Standard Time. Dates outside
  /// 1800–2100 use a representative year with the same leap-year status there.
  /// This scenery estimate does not account for terrain or actual refraction.
  /// Sources: https://gml.noaa.gov/grad/solcalc/main.js and
  /// https://gml.noaa.gov/grad/solcalc/calcdetails.html.
  factory SolarDaylight.forDate(
    DateTime localDate, {
    double latitude = sipalayLatitude,
    double longitude = sipalayLongitude,
    Duration timezoneOffset = philippineOffset,
  }) {
    final supportedYear = localDate.year >= 1800 && localDate.year <= 2100;
    final validCoordinates = latitude.isFinite &&
        longitude.isFinite &&
        latitude.abs() <= 90 &&
        longitude.abs() <= 180;
    final validOffset = timezoneOffset >= const Duration(hours: -12) &&
        timezoneOffset <= const Duration(hours: 14);
    if (supportedYear && validCoordinates && validOffset) {
      final calculated = _calculate(
        localDate,
        latitude,
        longitude,
        timezoneOffset,
        usedFallback: false,
      );
      if (calculated != null) return calculated;
    }

    final year = supportedYear
        ? localDate.year
        : _isLeapYear(localDate.year)
            ? 2000
            : 2001;
    // Sipalay always has a finite rise/noon/set within its Philippine date.
    return _calculate(
      DateTime.utc(year, localDate.month, localDate.day),
      sipalayLatitude,
      sipalayLongitude,
      philippineOffset,
      usedFallback: true,
    )!;
  }

  static SolarDaylight? _calculate(
    DateTime date,
    double latitude,
    double longitude,
    Duration offset, {
    required bool usedFallback,
  }) {
    final midnight = DateTime.utc(date.year, date.month, date.day);
    final julianDay =
        midnight.millisecondsSinceEpoch / Duration.millisecondsPerDay +
            2440587.5;
    final offsetMinutes =
        offset.inMicroseconds / Duration.microsecondsPerMinute;
    final sunriseUtc = _eventUtc(julianDay, latitude, longitude, sunrise: true);
    final sunsetUtc = _eventUtc(julianDay, latitude, longitude, sunrise: false);
    if (sunriseUtc == null || sunsetUtc == null) return null;

    final initialNoon = 720 -
        4 * longitude -
        _SolarPosition(julianDay - longitude / 360).equationOfTime;
    final noon = 720 -
        4 * longitude -
        _SolarPosition(julianDay + initialNoon / 1440).equationOfTime +
        offsetMinutes;
    final rise = sunriseUtc + offsetMinutes;
    final set = sunsetUtc + offsetMinutes;
    if (!rise.isFinite ||
        !noon.isFinite ||
        !set.isFinite ||
        rise < 0 ||
        rise >= noon ||
        noon >= set ||
        set >= 1440) {
      return null;
    }
    return SolarDaylight._(
      sunrise: _wallClock(rise),
      solarNoon: _wallClock(noon),
      sunset: _wallClock(set),
      usedFallback: usedFallback,
    );
  }
}

bool _isLeapYear(int year) =>
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

Duration _wallClock(double minutes) =>
    Duration(microseconds: (minutes * Duration.microsecondsPerMinute).round());

double _radians(double degrees) => degrees * math.pi / 180;
double _degrees(double radians) => radians * 180 / math.pi;

double? _eventUtc(double julianDay, double latitude, double longitude,
    {required bool sunrise}) {
  double? eventAt(double day) {
    final solar = _SolarPosition(day);
    final latitudeRadians = _radians(latitude);
    final cosineHourAngle = math.cos(_radians(90.833)) /
            (math.cos(latitudeRadians) * math.cos(solar.declination)) -
        math.tan(latitudeRadians) * math.tan(solar.declination);
    // acos has no real solution during polar day/night. Check before calling it
    // rather than clamping away that state or allowing NaN into a Duration.
    if (!cosineHourAngle.isFinite || cosineHourAngle.abs() > 1) return null;
    final hourAngle = _degrees(math.acos(cosineHourAngle));
    return 720 -
        4 * (longitude + (sunrise ? hourAngle : -hourAngle)) -
        solar.equationOfTime;
  }

  final initial = eventAt(julianDay);
  return initial == null ? null : eventAt(julianDay + initial / 1440);
}

/// Solar declination in radians and the equation of time in minutes.
class _SolarPosition {
  _SolarPosition(double julianDay) {
    final t = (julianDay - 2451545) / 36525;
    final meanLongitude =
        _radians((280.46646 + t * (36000.76983 + t * 0.0003032)) % 360);
    final meanAnomaly = _radians(357.52911 + t * (35999.05029 - t * 0.0001537));
    final eccentricity = 0.016708634 - t * (0.000042037 + t * 0.0000001267);
    final center =
        math.sin(meanAnomaly) * (1.914602 - t * (0.004817 + t * 0.000014)) +
            math.sin(2 * meanAnomaly) * (0.019993 - t * 0.000101) +
            math.sin(3 * meanAnomaly) * 0.000289;
    final omega = _radians(125.04 - 1934.136 * t);
    final apparentLongitude =
        meanLongitude + _radians(center - 0.00569 - 0.00478 * math.sin(omega));
    final obliquitySeconds =
        21.448 - t * (46.815 + t * (0.00059 - t * 0.001813));
    final obliquity = _radians(
        23 + (26 + obliquitySeconds / 60) / 60 + 0.00256 * math.cos(omega));
    declination = math.asin(math.sin(obliquity) * math.sin(apparentLongitude));

    final tangent = math.tan(obliquity / 2);
    final y = tangent * tangent;
    equationOfTime = 4 *
        _degrees(y * math.sin(2 * meanLongitude) -
            2 * eccentricity * math.sin(meanAnomaly) +
            4 *
                eccentricity *
                y *
                math.sin(meanAnomaly) *
                math.cos(2 * meanLongitude) -
            0.5 * y * y * math.sin(4 * meanLongitude) -
            1.25 * eccentricity * eccentricity * math.sin(2 * meanAnomaly));
  }

  late final double equationOfTime;
  late final double declination;
}
