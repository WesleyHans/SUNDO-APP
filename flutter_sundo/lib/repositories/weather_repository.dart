import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Model-based current conditions for Sipalay, never the resident's GPS position.
class SipalayWeather {
  const SipalayWeather({
    required this.validAt,
    required this.fetchedAt,
    required this.weatherCode,
    required this.precipitationMm,
    required this.rainMm,
    required this.showersMm,
  });

  final DateTime validAt;
  final DateTime fetchedAt;
  final int weatherCode;
  final double precipitationMm;
  final double rainMm;
  final double showersMm;

  static const maximumAge = Duration(minutes: 30);
  static const _clockTolerance = Duration(minutes: 5);
  static const _rainCodes = {
    51,
    53,
    55,
    56,
    57,
    61,
    63,
    65,
    66,
    67,
    80,
    81,
    82,
  };

  // Require a nonzero precipitation amount for thunderstorm codes.
  bool get isRaining =>
      rainMm > 0 ||
      showersMm > 0 ||
      precipitationMm > 0 ||
      _rainCodes.contains(weatherCode);

  bool isFreshAt(DateTime now) {
    bool fresh(DateTime value) {
      final age = now.toUtc().difference(value.toUtc());
      return age >= -_clockTolerance && age <= maximumAge;
    }

    return fresh(validAt) && fresh(fetchedAt);
  }

  factory SipalayWeather.fromJson(
      Map<String, dynamic> json, DateTime fetchedAt) {
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

  static final endpoint = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '9.7525',
    'longitude': '122.4038',
    'current': 'precipitation,rain,showers,weather_code',
    'timeformat': 'unixtime',
    'timezone': 'GMT',
    'forecast_days': '1',
  });

  Future<SipalayWeather?> fetchCurrent() async {
    try {
      final response = await _client.get(endpoint).timeout(requestTimeout);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;
      final now = _clock();
      final weather = SipalayWeather.fromJson(json, now);
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

/// Polling starts only when the app is foregrounded and never blocks startup.
class SundoWeatherController extends Notifier<SipalayWeather?> {
  static const refreshInterval = Duration(minutes: 15);
  Timer? _timer;
  bool _foreground = false;
  int _request = 0;
  bool _disposed = false;

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
      return;
    }
    _timer = Timer.periodic(refreshInterval, (_) => unawaited(refresh()));
    unawaited(refresh());
  }

  Future<void> refresh() async {
    if (!_foreground || _disposed) return;
    final request = ++_request;
    final repository = ref.read(sundoWeatherRepositoryProvider);
    final weather = await repository.fetchCurrent();
    if (_disposed || !_foreground || request != _request) return;
    state = weather;
  }
}
