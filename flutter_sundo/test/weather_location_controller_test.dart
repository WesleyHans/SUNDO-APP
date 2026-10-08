import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';

import 'weather_repository_test.dart' show TestWeatherLocationService;

class _PendingPermissionLocationService extends TestWeatherLocationService {
  final permissionResult = Completer<void>();
  bool granted = false;
  int quietChecks = 0;
  @override
  Future<EnvironmentLocationResult> resolve(
      {required bool requestPermission, bool Function()? canContinue}) async {
    if (requestPermission) {
      permissionRequests++;
      await permissionResult.future;
      granted = true;
    } else {
      quietChecks++;
    }
    if (canContinue?.call() == false) {
      return const EnvironmentLocationResult(
          EnvironmentLocationStatus.unavailable);
    }
    return granted
        ? EnvironmentLocationResult(EnvironmentLocationStatus.device,
            location: location)
        : const EnvironmentLocationResult(EnvironmentLocationStatus.denied);
  }
}

http.Response _response(DateTime now, {int code = 0}) => http.Response(
    jsonEncode({
      'current': {
        'time': now.millisecondsSinceEpoch ~/ 1000,
        'weather_code': code,
        'precipitation': 0,
        'rain': 0,
        'showers': 0
      }
    }),
    200);

void main() {
  final now = DateTime.utc(2026, 10, 6);
  setUp(() {
    AppStore.setIdentity(null);
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => AppStore.setIdentity(null));

  ProviderContainer containerFor(
      http.Client client, TestWeatherLocationService service,
      {Future<String?> Function()? savedArea,
      DateTime Function()? clock,
      Duration requestTimeout = const Duration(seconds: 8)}) {
    final currentTime = clock ?? () => now;
    final container = ProviderContainer(overrides: [
      sundoWeatherClockProvider.overrideWithValue(currentTime),
      environmentLocationServiceProvider.overrideWithValue(service),
      if (savedArea != null)
        sundoSavedWeatherAreaProvider.overrideWithValue(savedArea),
      sundoWeatherRepositoryProvider.overrideWithValue(
          SipalayWeatherRepository(
              client: client,
              clock: currentTime,
              requestTimeout: requestTimeout)),
    ]);
    addTearDown(container.dispose);
    addTearDown(client.close);
    return container;
  }

  testWidgets('foreground startup sends no fix or HTTP request before consent',
      (tester) async {
    var requests = 0;
    final service = TestWeatherLocationService();
    final client = MockClient((_) async {
      requests++;
      return _response(now);
    });
    final container = containerFor(client, service);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    await tester.pump(const Duration(hours: 1));
    await controller.refresh();
    expect(requests, 0);
    expect(service.fixes, 0);
    expect(controller.enabled, isFalse);
    await controller.initializeLocation(requestPermission: true);
    expect(service.permissionRequests, 1);
    expect(requests, 1);
    container.dispose();
  });

  testWidgets(
      'permission grant after an early resume triggers one fresh quiet check',
      (tester) async {
    var requests = 0;
    final service = _PendingPermissionLocationService();
    final client = MockClient((_) async {
      requests++;
      return _response(now, code: 63);
    });
    final container = containerFor(client, service);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    final pending = controller.initializeLocation(requestPermission: true);
    await tester.pump();
    controller.setForeground(false);
    controller.setForeground(true);
    await tester.pump();
    expect(service.quietChecks, 1);
    expect(requests, 0);
    service.permissionResult.complete();
    await pending;
    expect(service.permissionRequests, 1);
    expect(service.quietChecks, 2);
    expect(requests, 1);
    expect(
        container.read(sundoWeatherProvider)?.condition, WeatherCondition.rain);
    container.dispose();
  });

  testWidgets(
      'permission result cannot restart weather after opt-out or while backgrounded',
      (tester) async {
    for (final optOut in [false, true]) {
      var requests = 0;
      final service = _PendingPermissionLocationService();
      final client = MockClient((_) async {
        requests++;
        return _response(now);
      });
      final container = containerFor(client, service);
      final controller = container.read(sundoWeatherProvider.notifier);
      controller.setForeground(true);
      final pending = controller.initializeLocation(requestPermission: true);
      await tester.pump();
      if (optOut) {
        controller.useTimeOnly();
      } else {
        controller.setForeground(false);
      }
      service.permissionResult.complete();
      await pending;
      expect(service.quietChecks, 0);
      expect(requests, 0);
      expect(container.read(sundoWeatherProvider), isNull);
      container.dispose();
    }
  });

  testWidgets(
      'denied and unavailable location do not use the default demo barangay',
      (tester) async {
    for (final status in [
      EnvironmentLocationStatus.denied,
      EnvironmentLocationStatus.deniedForever,
      EnvironmentLocationStatus.disabled,
      EnvironmentLocationStatus.unavailable
    ]) {
      var requests = 0;
      final service = TestWeatherLocationService()
        ..location = null
        ..status = status;
      final client = MockClient((_) async {
        requests++;
        return _response(now);
      });
      final container = containerFor(client, service);
      final controller = container.read(sundoWeatherProvider.notifier);
      controller.setForeground(true);
      await controller.initializeLocation(requestPermission: true);
      expect(requests, 0);
      expect(container.read(environmentLocationStatusProvider), status);
      expect(container.read(sundoWeatherProvider), isNull);
      container.dispose();
    }
  });

  testWidgets(
      'denied GPS can use an actual saved Sipalay area with an explicit label',
      (tester) async {
    await AppStore.setBarangay('Cabadiangan');
    final service = TestWeatherLocationService()
      ..location = null
      ..status = EnvironmentLocationStatus.denied;
    final client = MockClient((request) async {
      expect(request.url.queryParameters['latitude'], '9.75');
      expect(request.url.queryParameters['longitude'], '122.40');
      return _response(now, code: 63);
    });
    final container = containerFor(client, service);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    await controller.initializeLocation(requestPermission: true);
    expect(container.read(sundoWeatherProvider)?.location?.isDeviceLocation,
        isFalse);
    expect(container.read(sundoWeatherProvider)?.location?.label,
        'Sipalay City (saved area)');
    expect(container.read(environmentLocationStatusProvider),
        EnvironmentLocationStatus.savedArea);
    container.dispose();
  });

  testWidgets('unavailable saved preferences keep time-only weather fallback',
      (tester) async {
    var requests = 0;
    final service = TestWeatherLocationService()
      ..location = null
      ..status = EnvironmentLocationStatus.denied;
    final client = MockClient((_) async {
      requests++;
      return _response(now);
    });
    final container = containerFor(client, service,
        savedArea: () async => throw StateError('Preferences unavailable'));
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    await controller.initializeLocation(requestPermission: false);
    expect(requests, 0);
    expect(container.read(sundoWeatherProvider), isNull);
    expect(tester.takeException(), isNull);
    container.dispose();
  });

  testWidgets(
      'malformed or permission-denied location results never start device HTTP',
      (tester) async {
    for (final result in [
      const EnvironmentLocationResult(EnvironmentLocationStatus.device,
          location: WeatherLocation(
              latitude: 91,
              longitude: 180,
              label: 'invalid',
              isDeviceLocation: true)),
      const EnvironmentLocationResult(EnvironmentLocationStatus.denied,
          location: WeatherLocation(
              latitude: 10,
              longitude: 123,
              label: 'denied',
              isDeviceLocation: true)),
    ]) {
      var requests = 0;
      final service = TestWeatherLocationService()
        ..onResolve = () async => result;
      final client = MockClient((_) async {
        requests++;
        return _response(now);
      });
      final container = containerFor(client, service);
      final controller = container.read(sundoWeatherProvider.notifier);
      controller.setForeground(true);
      await controller.initializeLocation(requestPermission: false);
      expect(requests, 0);
      expect(controller.location, isNull);
      expect(container.read(sundoWeatherProvider), isNull);
      container.dispose();
    }
  });

  testWidgets('resume resolves new coordinates rather than reusing a stale fix',
      (tester) async {
    final service = TestWeatherLocationService();
    final longitudes = <String>[];
    final client = MockClient((request) async {
      longitudes.add(request.url.queryParameters['longitude']!);
      return _response(now);
    });
    final container = containerFor(client, service);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    await controller.initializeLocation(requestPermission: false);
    controller.setForeground(false);
    service.location = const WeatherLocation(
        latitude: 10.31,
        longitude: 123.89,
        label: 'your location',
        isDeviceLocation: true);
    controller.setForeground(true);
    await tester.pump();
    expect(longitudes, ['120.98', '123.89']);
    expect(container.read(sundoWeatherProvider)?.location, service.location);
    container.dispose();
  });

  testWidgets('time-only opt-out invalidates pending location and HTTP replies',
      (tester) async {
    final response = Completer<http.Response>();
    final client = MockClient((_) => response.future);
    final container = containerFor(client, TestWeatherLocationService());
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    final pending = controller.initializeLocation(requestPermission: false);
    await tester.pump();
    controller.useTimeOnly();
    response.complete(_response(now, code: 63));
    await pending;
    expect(container.read(sundoWeatherProvider), isNull);
    expect(controller.location, isNull);
    expect(controller.enabled, isFalse);
    expect(container.read(environmentLocationStatusProvider),
        EnvironmentLocationStatus.idle);
    container.dispose();
  });

  testWidgets('an older reply cannot replace the newer location snapshot',
      (tester) async {
    final old = Completer<http.Response>();
    var requests = 0;
    final client = MockClient((_) =>
        ++requests == 1 ? old.future : Future.value(_response(now, code: 3)));
    final service = TestWeatherLocationService();
    final container = containerFor(client, service);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    final first = controller.initializeLocation(requestPermission: false);
    await tester.pump();
    service.location = const WeatherLocation(
        latitude: 10.31,
        longitude: 123.89,
        label: 'your location',
        isDeviceLocation: true);
    await controller.refreshSavedArea();
    old.complete(_response(now, code: 63));
    await first;
    expect(container.read(sundoWeatherProvider)?.condition,
        WeatherCondition.cloudy);
    expect(container.read(sundoWeatherProvider)?.location, service.location);
    container.dispose();
  });

  testWidgets(
      'permission revoked during HTTP rejects device weather and uses no invented area',
      (tester) async {
    final response = Completer<http.Response>();
    final service = TestWeatherLocationService();
    final client = MockClient((_) => response.future);
    final container = containerFor(client, service);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    final pending = controller.initializeLocation(requestPermission: false);
    await tester.pump();
    service.access = EnvironmentLocationStatus.deniedForever;
    response.complete(_response(now, code: 63));
    await pending;
    expect(container.read(sundoWeatherProvider), isNull);
    expect(controller.location, isNull);
    expect(container.read(environmentLocationStatusProvider),
        EnvironmentLocationStatus.deniedForever);
    container.dispose();
  });

  testWidgets('account switch clears a former saved area and ignores its reply',
      (tester) async {
    AppStore.setIdentity('resident-one');
    final old = Completer<http.Response>();
    var requests = 0;
    final client = MockClient((_) {
      requests++;
      return old.future;
    });
    final service = TestWeatherLocationService()
      ..location = null
      ..status = EnvironmentLocationStatus.denied;
    final container = containerFor(client, service,
        savedArea: () async =>
            AppStore.identity == 'resident-one' ? 'Nauhang' : null);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    final first = controller.initializeLocation(requestPermission: false);
    await tester.pump();
    AppStore.setIdentity('resident-two');
    await controller.refreshSavedArea();
    expect(controller.location, isNull);
    old.complete(_response(now, code: 63));
    await first;
    expect(container.read(sundoWeatherProvider), isNull);
    expect(requests, 1);
    container.dispose();
  });

  testWidgets('pending native fix after opt-out cannot begin a weather request',
      (tester) async {
    final location = Completer<EnvironmentLocationResult>();
    var requests = 0;
    final service = TestWeatherLocationService()
      ..onResolve = () => location.future;
    final client = MockClient((_) async {
      requests++;
      return _response(now);
    });
    final container = containerFor(client, service);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    final pending = controller.initializeLocation(requestPermission: false);
    await tester.pump();
    controller.useTimeOnly();
    location.complete(EnvironmentLocationResult(
        EnvironmentLocationStatus.device,
        location: service.location));
    await pending;
    expect(requests, 0);
    expect(container.read(sundoWeatherProvider), isNull);
    container.dispose();
  });

  testWidgets(
      'automatic polls and repeated refresh taps share one pending request',
      (tester) async {
    var clock = now;
    var requests = 0;
    final pendingResponse = Completer<http.Response>();
    final service = TestWeatherLocationService();
    final client = MockClient((_) async {
      requests++;
      return requests == 1 ? _response(clock) : pendingResponse.future;
    });
    final container = containerFor(client, service,
        clock: () => clock, requestTimeout: const Duration(minutes: 20));
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    await controller.initializeLocation(requestPermission: false);
    clock = clock.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(requests, 2);
    expect(container.read(sundoWeatherLoadingProvider), isTrue);
    final firstTap = controller.refresh();
    final secondTap = controller.refresh();
    clock = clock.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(requests, 2);
    expect(service.fixes, 2);
    pendingResponse.complete(_response(clock, code: 3));
    await Future.wait([firstTap, secondTap]);
    expect(container.read(sundoWeatherProvider)?.condition,
        WeatherCondition.cloudy);
    expect(container.read(sundoWeatherLoadingProvider), isFalse);
    container.dispose();
  });

  testWidgets('automatic failure retains fresh scenery then retries at next poll',
      (tester) async {
    var clock = now;
    var requests = 0;
    final pendingResponse = Completer<http.Response>();
    final client = MockClient((_) async {
      requests++;
      if (requests == 2) return pendingResponse.future;
      return _response(clock, code: requests == 1 ? 63 : 0);
    });
    final container = containerFor(client, TestWeatherLocationService(),
        clock: () => clock);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    await controller.initializeLocation(requestPermission: false);
    final rainy = container.read(sundoWeatherProvider);
    clock = clock.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(container.read(sundoWeatherProvider), same(rainy));
    expect(container.read(sundoWeatherLoadingProvider), isTrue);
    pendingResponse.complete(http.Response('offline', 503));
    await tester.pump();
    expect(container.read(sundoWeatherProvider), same(rainy));
    expect(container.read(sundoWeatherLoadingProvider), isFalse);
    clock = clock.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(requests, 3);
    expect(container.read(sundoWeatherProvider)?.condition,
        WeatherCondition.clear);
    container.dispose();
  });

  testWidgets(
      'saved-area polling preserves the same fresh snapshot while offline',
      (tester) async {
    var clock = now;
    var fail = false;
    final service = TestWeatherLocationService()
      ..location = null
      ..status = EnvironmentLocationStatus.denied;
    final client = MockClient((_) async =>
        fail ? http.Response('offline', 503) : _response(clock, code: 3));
    final container = containerFor(client, service,
        clock: () => clock, savedArea: () async => 'Cabadiangan');
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    await controller.initializeLocation(requestPermission: false);
    final previous = container.read(sundoWeatherProvider);
    fail = true;
    clock = clock.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(container.read(sundoWeatherProvider), same(previous));
    expect(container.read(environmentLocationStatusProvider),
        EnvironmentLocationStatus.savedArea);
    clock = now.add(const Duration(minutes: 10, seconds: 1));
    await controller.refresh();
    expect(container.read(sundoWeatherProvider), isNull);
    container.dispose();
  });

  testWidgets('refresh never retains previous weather for a changed location',
      (tester) async {
    var fail = false;
    final service = TestWeatherLocationService();
    final client = MockClient((_) async =>
        fail ? http.Response('offline', 503) : _response(now, code: 63));
    final container = containerFor(client, service);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    await controller.initializeLocation(requestPermission: false);
    expect(container.read(sundoWeatherProvider)?.isRaining, isTrue);
    fail = true;
    service.location = const WeatherLocation(
        latitude: 10.31,
        longitude: 123.89,
        label: 'your location',
        isDeviceLocation: true);
    await controller.refresh();
    expect(container.read(sundoWeatherProvider), isNull);
    expect(controller.location, service.location);
    container.dispose();
  });

  testWidgets('revoked device access clears a previously fresh cached snapshot',
      (tester) async {
    var fail = false;
    final service = TestWeatherLocationService();
    final client = MockClient((_) async =>
        fail ? http.Response('offline', 503) : _response(now, code: 63));
    final container = containerFor(client, service);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    await controller.initializeLocation(requestPermission: false);
    expect(container.read(sundoWeatherProvider)?.isRaining, isTrue);
    service.access = EnvironmentLocationStatus.deniedForever;
    fail = true;
    await controller.refresh();
    expect(container.read(sundoWeatherProvider), isNull);
    expect(controller.location, isNull);
    expect(container.read(environmentLocationStatusProvider),
        EnvironmentLocationStatus.deniedForever);
    container.dispose();
  });

  testWidgets('successful automatic polls preserve the actual observation age',
      (tester) async {
    var clock = now;
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return _response(now, code: 3);
    });
    final container = containerFor(client, TestWeatherLocationService(),
        clock: () => clock);
    final controller = container.read(sundoWeatherProvider.notifier);
    controller.setForeground(true);
    await controller.initializeLocation(requestPermission: false);
    clock = clock.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    final weather = container.read(sundoWeatherProvider)!;
    expect(requests, 2);
    expect(weather.validAt, now);
    expect(weather.fetchedAt, clock);
    expect(clock.difference(weather.validAt), const Duration(minutes: 5));
    container.dispose();
  });

  test('unknown snow weather is not mislabeled as rain by total precipitation',
      () {
    final weather = SipalayWeather(
        validAt: now,
        fetchedAt: now,
        weatherCode: 71,
        precipitationMm: 1,
        rainMm: 0,
        showersMm: 0);
    expect(weather.condition, WeatherCondition.unknown);
    expect(weather.isRaining, isFalse);
  });

  test(
      'clear, cloudy, drizzle and thunderstorm retain distinct model conditions',
      () {
    for (final entry in {
      0: WeatherCondition.clear,
      3: WeatherCondition.cloudy,
      51: WeatherCondition.drizzle,
      95: WeatherCondition.thunderstorm
    }.entries) {
      final weather = SipalayWeather(
          validAt: now,
          fetchedAt: now,
          weatherCode: entry.key,
          precipitationMm: 0,
          rainMm: 0,
          showersMm: 0);
      expect(weather.condition, entry.value);
    }
  });
}
