import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/services/environment_location_service.dart';

Position _position(DateTime timestamp,
        {double latitude = 14.599512,
        double longitude = 120.984222,
        double accuracy = 100}) =>
    Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: timestamp,
        accuracy: accuracy,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0);

void main() {
  final now = DateTime.utc(2026, 10, 6);
  EnvironmentLocationService makeService(
          {Future<Position> Function()? position,
          Future<LocationPermission> Function()? check,
          Future<LocationPermission> Function()? request,
          bool enabled = true}) =>
      EnvironmentLocationService(
          clock: () => now,
          timeout: const Duration(milliseconds: 10),
          checkPermission: check ?? () async => LocationPermission.whileInUse,
          requestPermission:
              request ?? () async => LocationPermission.whileInUse,
          checkService: () async => enabled,
          fetchPosition: position ?? () async => _position(now));

  tearDown(() => AppStore.setIdentity(null));

  test('foreground fix is rounded before being used by weather', () async {
    final result = await makeService().resolve(requestPermission: false);
    expect(result.status, EnvironmentLocationStatus.device);
    expect(result.location?.latitude, 14.60);
    expect(result.location?.longitude, 120.98);
    expect(result.location?.label, 'your location');
    expect(result.location?.isDeviceLocation, isTrue);
  });

  test(
      'denied or permanently denied access never reads a fix or prompts automatically',
      () async {
    for (final permission in [
      LocationPermission.denied,
      LocationPermission.deniedForever
    ]) {
      var prompts = 0;
      var fixes = 0;
      final service = makeService(
          check: () async => permission,
          request: () async {
            prompts++;
            return permission;
          },
          position: () async {
            fixes++;
            return _position(now);
          });
      final result = await service.resolve(requestPermission: false);
      expect(result.location, isNull);
      expect(
          result.status,
          permission == LocationPermission.deniedForever
              ? EnvironmentLocationStatus.deniedForever
              : EnvironmentLocationStatus.denied);
      expect(fixes, 0);
      expect(prompts, 0);
    }
  });

  test(
      'explicit OS permission is requested before checking the phone Location switch',
      () async {
    var permission = LocationPermission.denied;
    var prompts = 0;
    var fixes = 0;
    final service = makeService(
        enabled: false,
        check: () async => permission,
        request: () async {
          prompts++;
          return permission = LocationPermission.whileInUse;
        },
        position: () async {
          fixes++;
          return _position(now);
        });
    expect((await service.resolve(requestPermission: true)).status,
        EnvironmentLocationStatus.disabled);
    expect(prompts, 1);
    expect(fixes, 0);
    expect(
        await service.deviceAccessStatus(), EnvironmentLocationStatus.disabled);
  });

  test('denial takes precedence over disabled GPS when offering settings',
      () async {
    final service = makeService(
        enabled: false,
        check: () async => LocationPermission.denied,
        request: () async => LocationPermission.denied);
    expect((await service.resolve(requestPermission: true)).status,
        EnvironmentLocationStatus.denied);
    expect(
        await service.deviceAccessStatus(), EnvironmentLocationStatus.denied);
  });

  test('stale, future, invalid and excessively inaccurate fixes are rejected',
      () async {
    for (final position in [
      _position(now.subtract(const Duration(seconds: 61))),
      _position(now.add(const Duration(seconds: 6))),
      _position(now, latitude: double.nan),
      _position(now, longitude: 181),
      _position(now, accuracy: -1),
      _position(now, accuracy: 5001)
    ]) {
      final result = await makeService(position: () async => position)
          .resolve(requestPermission: false);
      expect(result.status, EnvironmentLocationStatus.unavailable);
      expect(result.location, isNull);
    }
  });

  test('permission revoked during a fix prevents weather coordinates',
      () async {
    var checks = 0;
    final service = makeService(
        check: () async => ++checks == 1
            ? LocationPermission.whileInUse
            : LocationPermission.deniedForever);
    final result = await service.resolve(requestPermission: false);
    expect(result.location, isNull);
    expect(result.status, EnvironmentLocationStatus.deniedForever);
  });

  test('backgrounding during the OS permission dialog stops the native fix',
      () async {
    var foreground = true;
    var fixes = 0;
    final permission = Completer<LocationPermission>();
    final service = makeService(
        check: () async => LocationPermission.denied,
        request: () => permission.future,
        position: () async {
          fixes++;
          return _position(now);
        });
    final pending =
        service.resolve(requestPermission: true, canContinue: () => foreground);
    await Future<void>.delayed(Duration.zero);
    foreground = false;
    permission.complete(LocationPermission.whileInUse);
    expect((await pending).location, isNull);
    expect(fixes, 0);
  });

  test('timed-out or unavailable fixes return no weather location', () async {
    for (final getPosition in <Future<Position> Function()>[
      () => Completer<Position>().future,
      () async => throw StateError('Unavailable fix')
    ]) {
      expect(
          (await makeService(position: getPosition)
                  .resolve(requestPermission: false))
              .location,
          isNull);
    }
  });

  test('saved area yields explicitly approximate city weather only', () {
    final location =
        EnvironmentLocationService.savedAreaLocation('Barangay 1 (Poblacion)');
    expect(location?.label, 'Sipalay City (saved area)');
    expect(location?.isDeviceLocation, isFalse);
    expect(location?.latitude, 9.75);
    for (final unknown in [null, '', 'Unknown City']) {
      expect(EnvironmentLocationService.savedAreaLocation(unknown), isNull);
    }
  });

  test(
      'default demo barangay is not a saved weather area and account fallback is scoped',
      () async {
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
    expect(await AppStore.getBarangay(), 'Barangay 1 (Poblacion)');
    expect(await AppStore.getSavedWeatherArea(), isNull);
    await AppStore.setBarangay('Nauhang');
    expect(await AppStore.getSavedWeatherArea(), 'Nauhang');
    AppStore.setIdentity('another-resident');
    expect(await AppStore.getSavedWeatherArea(), isNull);
  });

  test(
      'saved address needs explicit Sipalay City rather than an arbitrary town',
      () async {
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
    await AppStore.addSavedAddress('Home', 'Unknown town');
    expect(await AppStore.getSavedWeatherArea(), isNull);
    await AppStore.addSavedAddress('Home', 'Purok 1, Sipalay City');
    expect(await AppStore.getSavedWeatherArea(), 'Sipalay City');
  });

  test('account switch during preference load rejects the previous area',
      () async {
    SharedPreferences.setMockInitialValues(
        {'sundo_profile_barangay': 'Nauhang'});
    AppStore.setIdentity(null);
    final pending = AppStore.getSavedWeatherArea();
    AppStore.setIdentity('new-resident');
    expect(await pending, isNull);
  });
}
