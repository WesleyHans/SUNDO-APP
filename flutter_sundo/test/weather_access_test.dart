import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/app/app.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';
import 'package:sundo_sipalay/services/weather_consent.dart';

class _AccessWeather extends SundoWeatherController {
  final permissionRequests = <bool>[];
  int timeOnlyChoices = 0;
  @override
  SipalayWeather? build() => null;
  @override
  void setForeground(bool foreground) {}
  @override
  void useTimeOnly() => timeOnlyChoices++;
  @override
  Future<void> initializeLocation({required bool requestPermission}) async {
    permissionRequests.add(requestPermission);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
  });

  Future<ProviderContainer> start(
      WidgetTester tester, _AccessWeather controller,
      {EnvironmentLocationService? locationService}) async {
    await tester.runAsync(() async {
      for (final weight in FontWeight.values) {
        GoogleFonts.outfit(fontWeight: weight);
        GoogleFonts.plusJakartaSans(fontWeight: weight);
      }
      await GoogleFonts.pendingFonts();
    });
    final container = ProviderContainer(overrides: [
      sundoWeatherProvider.overrideWith(() => controller),
      sundoClockProvider.overrideWithValue(() => DateTime(2026, 10, 5, 9)),
      environmentLocationServiceProvider.overrideWithValue(locationService ??
          EnvironmentLocationService(
              checkService: () async => true,
              checkPermission: () async => LocationPermission.whileInUse)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const SundoApp()));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> stop(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  }

  testWidgets('first launch explains weather before any permission request',
      (tester) async {
    final controller = _AccessWeather();
    final container = await start(tester, controller);
    expect(AppStore.identity, 'guest');
    expect(find.text('Weather for your area'), findsOneWidget);
    expect(controller.permissionRequests, isEmpty);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Weather for your area'), findsOneWidget);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(weatherLocationConsentKey),
        false);
    await tester.tap(find.text('Use time only'));
    await tester.pumpAndSettle();
    expect(controller.permissionRequests, isEmpty);
    expect(controller.timeOnlyChoices, 1);
    expect(
        (await SharedPreferences.getInstance())
            .getBool(weatherLocationConsentKey),
        false);
    await stop(tester, container);
  });

  testWidgets('first guest can open phone Location settings after permission',
      (tester) async {
    var opened = 0;
    final controller = _AccessWeather();
    final container = await start(tester, controller,
        locationService: EnvironmentLocationService(
          checkService: () async => false,
          checkPermission: () async => LocationPermission.whileInUse,
          openLocationSettings: () async {
            opened++;
            return true;
          },
        ));
    await tester.tap(find.text('Enable local weather'));
    await tester.pumpAndSettle();
    expect(find.text('Turn on phone Location?'), findsOneWidget);
    await tester.tap(find.text('Open Location settings'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(controller.permissionRequests, [true]);
    await stop(tester, container);
  });

  testWidgets('enabling weather requests location before account creation',
      (tester) async {
    final controller = _AccessWeather();
    final container = await start(tester, controller);
    await tester.tap(find.text('Enable local weather'));
    await tester.pumpAndSettle();
    expect(AppStore.identity, 'guest');
    expect(controller.permissionRequests, [true]);
    expect(
        (await SharedPreferences.getInstance())
            .getBool(weatherLocationConsentKey),
        true);
    await stop(tester, container);
  });

  testWidgets('saved opt-out skips prompt and never requests location',
      (tester) async {
    SharedPreferences.setMockInitialValues({weatherLocationConsentKey: false});
    final controller = _AccessWeather();
    final container = await start(tester, controller);
    expect(find.text('Weather for your area'), findsNothing);
    expect(controller.permissionRequests, isEmpty);
    expect(controller.timeOnlyChoices, 1);
    await stop(tester, container);
  });

  testWidgets('saved opt-in checks weather without repeating OS permission',
      (tester) async {
    SharedPreferences.setMockInitialValues({weatherLocationConsentKey: true});
    final controller = _AccessWeather();
    final container = await start(tester, controller);
    expect(find.text('Weather for your area'), findsNothing);
    expect(controller.permissionRequests, [false]);
    await stop(tester, container);
  });
}
