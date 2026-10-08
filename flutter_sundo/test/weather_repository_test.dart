import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';

const testWeatherLocation = WeatherLocation(
    latitude: 14.599512,
    longitude: 120.984222,
    label: 'your location',
    isDeviceLocation: true);

class TestWeatherLocationService extends EnvironmentLocationService {
  WeatherLocation? location = testWeatherLocation.approximate;
  EnvironmentLocationStatus status = EnvironmentLocationStatus.device;
  EnvironmentLocationStatus access = EnvironmentLocationStatus.device;
  int fixes = 0;
  int permissionRequests = 0;
  Future<EnvironmentLocationResult> Function()? onResolve;

  @override
  Future<EnvironmentLocationResult> resolve(
      {required bool requestPermission, bool Function()? canContinue}) async {
    fixes++;
    if (requestPermission) permissionRequests++;
    final result = await (onResolve?.call() ??
        Future.value(EnvironmentLocationResult(status, location: location)));
    return canContinue?.call() == false
        ? const EnvironmentLocationResult(EnvironmentLocationStatus.unavailable)
        : result;
  }

  @override
  Future<EnvironmentLocationStatus> deviceAccessStatus() async => access;
}

Map<String, dynamic> _payload(DateTime now,
        {int code = 0,
        double precipitation = 0,
        double rain = 0,
        double showers = 0}) =>
    {
      'current': <String, dynamic>{
        'time': now.millisecondsSinceEpoch ~/ 1000,
        'weather_code': code,
        'precipitation': precipitation,
        'rain': rain,
        'showers': showers,
      }
    };

http.Response _response(DateTime now,
        {int code = 0,
        double precipitation = 0,
        double rain = 0,
        double showers = 0}) =>
    http.Response(
        jsonEncode(_payload(now,
            code: code,
            precipitation: precipitation,
            rain: rain,
            showers: showers)),
        200);

void main() {
  final now = DateTime.utc(2026, 10, 5, 6);

  test('current request uses rounded selected coordinates without an API key',
      () async {
    final client = MockClient((request) async {
      expect(request.url.scheme, 'https');
      expect(request.url.host, 'api.open-meteo.com');
      expect(request.url.queryParameters['latitude'], '14.60');
      expect(request.url.queryParameters['longitude'], '120.98');
      expect(request.url.queryParameters['timeformat'], 'unixtime');
      expect(request.url.queryParameters['current'],
          'precipitation,rain,showers,weather_code');
      expect(request.url.queryParameters.containsKey('apikey'), isFalse);
      return _response(now, code: 63);
    });
    addTearDown(client.close);
    final weather =
        await SipalayWeatherRepository(client: client, clock: () => now)
            .fetchCurrent(location: testWeatherLocation);
    expect(weather?.validAt, now);
    expect(weather?.isRaining, isTrue);
    expect(weather?.location, testWeatherLocation.approximate);
  });

  test('WMO rain and drizzle codes detect rain with a rounded zero total', () {
    for (final code in [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82]) {
      expect(SipalayWeather.fromJson(_payload(now, code: code), now).isRaining,
          isTrue,
          reason: 'WMO code $code');
    }
  });

  test('missing or invalid location never sends a weather request', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return _response(now);
    });
    addTearDown(client.close);
    final repository =
        SipalayWeatherRepository(client: client, clock: () => now);
    expect(await repository.fetchCurrent(), isNull);
    expect(
        await repository.fetchCurrent(
            location: const WeatherLocation(
                latitude: 91,
                longitude: 180,
                label: 'invalid',
                isDeviceLocation: true)),
        isNull);
    expect(requests, 0);
  });

  test('fog, clouds, and unsupported codes do not select rainy artwork', () {
    for (final code in [0, 1, 2, 3, 45, 48, 71, 77, 97]) {
      expect(SipalayWeather.fromJson(_payload(now, code: code), now).isRaining,
          isFalse,
          reason: 'WMO code $code');
    }
  });

  test('accumulated rain does not override an instantaneous dry weather code',
      () {
    for (final payload in [
      _payload(now, rain: .01),
      _payload(now, showers: .01),
      _payload(now, code: 3, precipitation: 2),
    ]) {
      expect(SipalayWeather.fromJson(payload, now).isRaining, isFalse);
    }
  });

  test('both server timestamp and fetch timestamp must remain fresh', () {
    final weather = SipalayWeather.fromJson(_payload(now, code: 61), now);
    expect(weather.isFreshAt(now.add(const Duration(minutes: 10))), isTrue);
    expect(weather.isFreshAt(now.add(const Duration(minutes: 10, seconds: 1))),
        isFalse);
    expect(
        weather.isFreshAt(now.subtract(const Duration(minutes: 6))), isFalse);
    final staleServer = SipalayWeather.fromJson(
        _payload(now.subtract(const Duration(minutes: 21)), code: 61), now);
    expect(staleServer.isFreshAt(now), isFalse);
  });

  test('freshness compares instants rather than device/server timezone labels',
      () {
    final weather = SipalayWeather.fromJson(_payload(now, code: 61), now);
    expect(weather.isFreshAt(now.toLocal()), isTrue);
  });

  test('failed HTTP, invalid JSON, missing values, and stale data fall back',
      () async {
    for (final response in [
      http.Response('{}', 503),
      http.Response('not-json', 200),
      http.Response('[]', 200),
      http.Response('{}', 200),
      http.Response('{"current":{"time":0,"weather_code":61}}', 200),
      _response(now.subtract(const Duration(minutes: 31)), code: 63),
      _response(now.add(const Duration(minutes: 6)), code: 63),
    ]) {
      final client = MockClient((_) async => response);
      addTearDown(client.close);
      expect(
          await SipalayWeatherRepository(client: client, clock: () => now)
              .fetchCurrent(location: testWeatherLocation),
          isNull);
    }
  });

  test('malformed numeric weather is rejected instead of showing rain', () {
    for (final entry in <(String, Object)>[
      ('precipitation', -1),
      ('rain', 'heavy'),
      ('showers', double.nan),
      ('weather_code', 61.5),
      ('weather_code', 100),
      ('time', .5),
    ]) {
      final payload = _payload(now, code: 63);
      (payload['current'] as Map<String, dynamic>)[entry.$1] = entry.$2;
      expect(
          () => SipalayWeather.fromJson(payload, now), throwsFormatException);
    }
  });

  test('network failure and request timeout return null', () async {
    final throwing =
        MockClient((_) async => throw http.ClientException('offline'));
    final hanging = MockClient((_) => Completer<http.Response>().future);
    addTearDown(throwing.close);
    addTearDown(hanging.close);
    expect(
        await SipalayWeatherRepository(client: throwing, clock: () => now)
            .fetchCurrent(location: testWeatherLocation),
        isNull);
    expect(
        await SipalayWeatherRepository(
                client: hanging,
                clock: () => now,
                requestTimeout: const Duration(milliseconds: 5))
            .fetchCurrent(location: testWeatherLocation),
        isNull);
  });

  testWidgets(
      'polls only in foreground every five minutes and refreshes on resume',
      (tester) async {
    var clock = now;
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return _response(clock, code: 63);
    });
    addTearDown(client.close);
    final container = ProviderContainer(overrides: [
      sundoWeatherClockProvider.overrideWithValue(() => clock),
      environmentLocationServiceProvider
          .overrideWithValue(TestWeatherLocationService()),
      sundoSavedWeatherAreaProvider.overrideWithValue(() async => null),
      sundoWeatherRepositoryProvider.overrideWithValue(
          SipalayWeatherRepository(client: client, clock: () => clock)),
    ]);
    addTearDown(container.dispose);
    final controller = container.read(sundoWeatherProvider.notifier);
    await tester.pump(const Duration(minutes: 30));
    expect(requests, 0);
    controller.setForeground(true);
    await controller.initializeLocation(requestPermission: false);
    await tester.pump();
    expect(requests, 1);
    expect(container.read(sundoWeatherProvider)?.isRaining, isTrue);
    controller.setForeground(true);
    await tester.pump(const Duration(minutes: 4));
    expect(requests, 1);
    clock = clock.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 1));
    expect(requests, 2);
    controller.setForeground(false);
    await tester.pump(const Duration(hours: 1));
    expect(requests, 2);
    clock = clock.add(const Duration(hours: 1));
    controller.setForeground(true);
    await tester.pump();
    expect(requests, 3);
    expect(container.read(sundoWeatherProvider)?.validAt, clock);
    container.dispose();
    await tester.pump(const Duration(hours: 1));
    expect(requests, 3);
  });

  testWidgets('failed refresh keeps fresh rain but expired data returns to time',
      (tester) async {
    var clock = now;
    var fail = false;
    final client = MockClient((_) async =>
        fail ? http.Response('unavailable', 503) : _response(now, code: 61));
    addTearDown(client.close);
    final container = ProviderContainer(overrides: [
      sundoWeatherClockProvider.overrideWithValue(() => clock),
      environmentLocationServiceProvider
          .overrideWithValue(TestWeatherLocationService()),
      sundoSavedWeatherAreaProvider.overrideWithValue(() async => null),
      sundoClockProvider.overrideWithValue(() => clock),
      sundoWeatherRepositoryProvider.overrideWithValue(
          SipalayWeatherRepository(client: client, clock: () => clock)),
    ]);
    addTearDown(container.dispose);
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.noon);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    await controller.initializeLocation(requestPermission: false);
    await tester.pump();
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.rainy);
    fail = true;
    clock = clock.add(const Duration(minutes: 5));
    await controller.refresh();
    expect(container.read(sundoWeatherProvider)?.isRaining, isTrue);
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.rainy);
    clock = now.add(const Duration(minutes: 10, seconds: 1));
    await controller.refresh();
    expect(container.read(sundoWeatherProvider), isNull);
    expect(container.read(sundoDayNightThemeProvider).environment,
        SundoEnvironment.noon);
    container.dispose();
  });

  testWidgets('response arriving after backgrounding is ignored',
      (tester) async {
    final response = Completer<http.Response>();
    var requests = 0;
    final client = MockClient((_) {
      requests++;
      return requests == 1 ? response.future : Future.value(_response(now));
    });
    addTearDown(client.close);
    final container = ProviderContainer(overrides: [
      sundoWeatherClockProvider.overrideWithValue(() => now),
      environmentLocationServiceProvider
          .overrideWithValue(TestWeatherLocationService()),
      sundoSavedWeatherAreaProvider.overrideWithValue(() async => null),
      sundoWeatherRepositoryProvider.overrideWithValue(
          SipalayWeatherRepository(client: client, clock: () => now)),
    ]);
    addTearDown(container.dispose);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    final pending = controller.initializeLocation(requestPermission: false);
    await tester.pump();
    controller.setForeground(false);
    response.complete(_response(now, code: 63));
    await pending;
    expect(container.read(sundoWeatherProvider), isNull);
    controller.setForeground(true);
    await tester.pump();
    expect(container.read(sundoWeatherProvider)?.isRaining, isFalse);
    container.dispose();
  });

  testWidgets('pending response after disposal cannot restore weather',
      (tester) async {
    final response = Completer<http.Response>();
    final client = MockClient((_) => response.future);
    addTearDown(client.close);
    final container = ProviderContainer(overrides: [
      sundoWeatherClockProvider.overrideWithValue(() => now),
      environmentLocationServiceProvider
          .overrideWithValue(TestWeatherLocationService()),
      sundoSavedWeatherAreaProvider.overrideWithValue(() async => null),
      sundoWeatherRepositoryProvider.overrideWithValue(
          SipalayWeatherRepository(client: client, clock: () => now)),
    ]);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    unawaited(controller.initializeLocation(requestPermission: false));
    await tester.pump();
    container.dispose();
    response.complete(_response(now, code: 63));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
