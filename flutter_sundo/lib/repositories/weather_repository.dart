import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/storage/app_store.dart';
import '../services/environment_location_service.dart';

export '../services/environment_location_service.dart';

enum WeatherCondition { clear, cloudy, rain, drizzle, thunderstorm, unknown }

/// Model-based current conditions for an explicitly selected approximate area.
class SipalayWeather {
  const SipalayWeather({
    required this.validAt,
    required this.fetchedAt,
    required this.weatherCode,
    required this.precipitationMm,
    required this.rainMm,
    required this.showersMm,
    this.location,
  });

  final DateTime validAt;
  final DateTime fetchedAt;
  final int weatherCode;
  final double precipitationMm;
  final double rainMm;
  final double showersMm;
  final WeatherLocation? location;

  static const maximumAge = Duration(minutes: 20);
  static const maximumFetchAge = Duration(minutes: 10);
  static const _clockTolerance = Duration(minutes: 5);
  WeatherCondition get condition {
    if ({95, 96, 99}.contains(weatherCode)) {
      return WeatherCondition.thunderstorm;
    }
    if ({51, 53, 55, 56, 57}.contains(weatherCode)) {
      return WeatherCondition.drizzle;
    }
    // The instantaneous WMO code describes current conditions. Rain totals
    // cover a preceding interval and can stay positive after rain has stopped.
    // Do not turn a clear/cloudy code into rain from a trace accumulated amount.
    if ({61, 63, 65, 66, 67, 80, 81, 82}.contains(weatherCode)) {
      return WeatherCondition.rain;
    }
    if ({0, 1}.contains(weatherCode)) return WeatherCondition.clear;
    if ({2, 3, 45, 48}.contains(weatherCode)) return WeatherCondition.cloudy;
    return WeatherCondition.unknown;
  }

  bool get isRaining => {
        WeatherCondition.rain,
        WeatherCondition.drizzle,
        WeatherCondition.thunderstorm,
      }.contains(condition);

  bool isFreshAt(DateTime now) {
    bool fresh(DateTime value, Duration limit) {
      final age = now.toUtc().difference(value.toUtc());
      return age >= -_clockTolerance && age <= limit;
    }

    return fresh(validAt, maximumAge) && fresh(fetchedAt, maximumFetchAge);
  }

  factory SipalayWeather.fromJson(Map<String, dynamic> json, DateTime fetchedAt,
      {WeatherLocation? location}) {
    final current = json['current'];
    if (current is! Map<String, dynamic>) {
      throw const FormatException('Missing current weather');
    }

    num number(String key) {
      final value = current[key];
      if (value is! num || !value.isFinite) {
        throw FormatException('Invalid current weather $key');
      }
      return value;
    }

    double rainfall(String key) {
      final value = number(key).toDouble();
      if (value < 0) throw FormatException('Negative current weather $key');
      return value;
    }

    final time = number('time');
    final code = number('weather_code');
    if (time != time.round() || code != code.round() || code < 0 || code > 99) {
      throw const FormatException('Invalid weather timestamp or code');
    }
    return SipalayWeather(
      validAt:
          DateTime.fromMillisecondsSinceEpoch(time.toInt() * 1000, isUtc: true),
      fetchedAt: fetchedAt.toUtc(),
      weatherCode: code.toInt(),
      precipitationMm: rainfall('precipitation'),
      rainMm: rainfall('rain'),
      showersMm: rainfall('showers'),
      location: location,
    );
  }
}

/// Uses Open-Meteo's keyless noncommercial current-weather endpoint.
/// Failed, malformed, or stale data returns null so time remains the fallback.
class SipalayWeatherRepository {
  SipalayWeatherRepository({
    required http.Client client,
    DateTime Function()? clock,
    this.requestTimeout = const Duration(seconds: 8),
  })  : _client = client,
        _clock = clock ?? DateTime.now;

  final http.Client _client;
  final DateTime Function() _clock;
  final Duration requestTimeout;

  static Uri endpointFor(WeatherLocation location) =>
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': location.approximate.latitude.toStringAsFixed(2),
        'longitude': location.approximate.longitude.toStringAsFixed(2),
        'current': 'precipitation,rain,showers,weather_code',
        'timeformat': 'unixtime',
        'timezone': 'GMT',
        'forecast_days': '1',
      });

  Future<SipalayWeather?> fetchCurrent({WeatherLocation? location}) async {
    // Startup and time-only mode must never silently send a default location.
    if (location == null || !location.isValid) return null;
    final requestedLocation = location.approximate;
    try {
      final response = await _client
          .get(endpointFor(requestedLocation))
          .timeout(requestTimeout);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;
      final now = _clock();
      final weather =
          SipalayWeather.fromJson(json, now, location: requestedLocation);
      return weather.isFreshAt(now) ? weather : null;
    } catch (_) {
      return null;
    }
  }
}

final sundoWeatherClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);
final sundoWeatherRepositoryProvider =
    Provider<SipalayWeatherRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return SipalayWeatherRepository(
      client: client, clock: ref.watch(sundoWeatherClockProvider));
});
final sundoWeatherProvider =
    NotifierProvider<SundoWeatherController, SipalayWeather?>(
        SundoWeatherController.new);
final sundoWeatherLoadingProvider =
    NotifierProvider<WeatherLoadingController, bool>(
        WeatherLoadingController.new);

class WeatherLoadingController extends Notifier<bool> {
  @override
  bool build() => false;
  void setLoading(bool value) => state = value;
}

final sundoSavedWeatherAreaProvider =
    Provider<Future<String?> Function()>((ref) => AppStore.getSavedWeatherArea);

/// Polling starts only when the app is foregrounded and never blocks startup.
class SundoWeatherController extends Notifier<SipalayWeather?> {
  static const refreshInterval = Duration(minutes: 5);
  Timer? _timer;
  bool _foreground = false;
  int _request = 0;
  bool _disposed = false;
  bool _enabled = false;
  WeatherLocation? _location;

  WeatherLocation? get location => _location;
  bool get enabled => _enabled;

  void _setStatus(EnvironmentLocationStatus value) {
    if (!_disposed && ref.mounted) {
      ref.read(environmentLocationStatusProvider.notifier).setStatus(value);
    }
  }

  void _setLoading(bool value) {
    if (!_disposed && ref.mounted) {
      ref.read(sundoWeatherLoadingProvider.notifier).setLoading(value);
    }
  }

  @override
  SipalayWeather? build() {
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
      _request++;
    });
    return null;
  }

  void setForeground(bool foreground) {
    if (_disposed || _foreground == foreground) return;
    _foreground = foreground;
    _timer?.cancel();
    _timer = null;
    if (!foreground) {
      // A response from before backgrounding must not restore stale rain.
      _request++;
      _setLoading(false);
      return;
    }
    if (_enabled) {
      _timer = Timer.periodic(refreshInterval, (_) => unawaited(refresh()));
      unawaited(refresh());
    }
  }

  Future<void> initializeLocation({required bool requestPermission}) async {
    if (_disposed) return;
    _enabled = true;
    _timer?.cancel();
    if (_foreground) {
      _timer = Timer.periodic(refreshInterval, (_) => unawaited(refresh()));
      final permissionRequest = _request + 1;
      await _refresh(requestPermission: requestPermission);
      // The native permission sheet may resume SUNDO before its result reaches
      // Dart. A resume refresh can then see the old denial and supersede this
      // request. Recheck once after the permission result arrives.
      if (requestPermission &&
          !_disposed &&
          ref.mounted &&
          _foreground &&
          _enabled &&
          _request != permissionRequest) {
        await refresh();
      }
    }
  }

  /// Turning weather off invalidates pending fixes and HTTP responses immediately.
  void useTimeOnly() {
    if (_disposed) return;
    _enabled = false;
    _request++;
    _timer?.cancel();
    _timer = null;
    _location = null;
    state = null;
    _setLoading(false);
    _setStatus(EnvironmentLocationStatus.idle);
  }

  /// Called after authentication or address changes so saved-area weather can
  /// never bleed between residents. The previous snapshot is cleared first.
  Future<void> refreshSavedArea() {
    if (_disposed) return Future.value();
    _request++;
    _location = null;
    state = null;
    _setStatus(EnvironmentLocationStatus.idle);
    return refresh();
  }

  Future<void> refresh() => _refresh(requestPermission: false);

  Future<String?> _savedArea() async {
    try {
      return await ref
          .read(sundoSavedWeatherAreaProvider)()
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // An unavailable preference store is not reliable location information.
      return null;
    }
  }

  Future<void> _refresh({required bool requestPermission}) async {
    if (!_foreground || _disposed || !_enabled) return;
    final request = ++_request;
    final identity = AppStore.identity;
    bool current() =>
        !_disposed &&
        ref.mounted &&
        _foreground &&
        _enabled &&
        request == _request &&
        AppStore.identity == identity;
    _setLoading(true);
    try {
      _setStatus(EnvironmentLocationStatus.checking);
      final resolved = await ref
          .read(environmentLocationServiceProvider)
          .resolve(requestPermission: requestPermission, canContinue: current);
      if (!current()) return;
      final validDeviceResult =
          resolved.status == EnvironmentLocationStatus.device &&
              resolved.location?.isValid == true &&
              resolved.location?.isDeviceLocation == true;
      var location = validDeviceResult ? resolved.location : null;
      final locationStatus =
          resolved.status == EnvironmentLocationStatus.device &&
                  !validDeviceResult
              ? EnvironmentLocationStatus.unavailable
              : resolved.status;
      if (location == null) {
        final area = await _savedArea();
        if (!current()) return;
        location = EnvironmentLocationService.savedAreaLocation(area);
      }
      if (!current()) return;
      if (_location != location || resolved.location == null) state = null;
      _location = location;
      _setStatus(location == null
          ? locationStatus
          : location.isDeviceLocation
              ? EnvironmentLocationStatus.device
              : EnvironmentLocationStatus.savedArea);
      if (location == null) return;
      final repository = ref.read(sundoWeatherRepositoryProvider);
      final weather = await repository.fetchCurrent(location: location);
      if (!current()) return;
      if (location.isDeviceLocation) {
        final access = await ref
            .read(environmentLocationServiceProvider)
            .deviceAccessStatus();
        if (!current()) return;
        if (access != EnvironmentLocationStatus.device) {
          _location = null;
          state = null;
          _setStatus(access);
          // Permission may be revoked while HTTP is pending. A real saved area
          // can still provide explicitly approximate city weather.
          final area = await _savedArea();
          if (!current()) return;
          final fallback = EnvironmentLocationService.savedAreaLocation(area);
          if (fallback == null) return;
          _location = fallback;
          _setStatus(EnvironmentLocationStatus.savedArea);
          final fallbackWeather =
              await repository.fetchCurrent(location: fallback);
          if (!current()) return;
          final now = ref.read(sundoWeatherClockProvider)();
          state = fallbackWeather != null && fallbackWeather.isFreshAt(now)
              ? fallbackWeather
              : null;
          return;
        }
      }
      final now = ref.read(sundoWeatherClockProvider)();
      state = weather != null && weather.isFreshAt(now) ? weather : null;
    } finally {
      if (current()) _setLoading(false);
    }
  }
}
