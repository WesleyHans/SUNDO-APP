import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/app/app.dart';
import 'package:sundo_sipalay/app/bootstrap.dart';
import 'package:sundo_sipalay/app/router.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/repositories/mock_auth_repository.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';
import 'package:sundo_sipalay/services/weather_consent.dart';
import 'package:sundo_sipalay/shared/widgets/resident_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({weatherLocationConsentKey: false});
    FlutterSecureStorage.setMockInitialValues({});
    MockAuthRepository.resetMemory();
    AppStore.setIdentity(null);
  });
  Future<void> loadFonts(WidgetTester tester) => tester.runAsync(() async {
        for (final weight in FontWeight.values) {
          GoogleFonts.outfit(fontWeight: weight);
          GoogleFonts.plusJakartaSans(fontWeight: weight);
        }
        await GoogleFonts.pendingFonts();
      });

  SipalayWeatherRepository unavailableWeather() {
    final client = MockClient((_) async => http.Response('', 503));
    addTearDown(client.close);
    return SipalayWeatherRepository(
        client: client, clock: () => DateTime(2026, 10, 5, 9));
  }

  testWidgets('startup failure offers a working retry before navigation',
      (tester) async {
    await loadFonts(tester);
    var attempts = 0;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sundoWeatherRepositoryProvider
              .overrideWithValue(unavailableWeather()),
          sundoClockProvider.overrideWithValue(() => DateTime(2026, 10, 5, 9)),
        ],
        child: SundoBootstrap(initialize: () async {
          if (++attempts == 1) throw StateError('test storage error');
        })));
    await tester.pumpAndSettle();
    expect(find.text('SUNDO could not start.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(find.text('SUNDO could not start.'), findsNothing);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'browse demo clears account scope and five-tab navigation survives logout',
      (tester) async {
    await loadFonts(tester);
    await MockAuthRepository.register(
        name: 'Private Resident',
        email: 'private@example.com',
        phone: '09123456789',
        barangay: 'Barangay 2',
        street: 'Private Street',
        zone: 'Purok 1',
        password: 'secure-demo');
    await AppStore.setName('Private Resident');
    final container = ProviderContainer(overrides: [
      sundoClockProvider.overrideWithValue(() => DateTime(2026, 10, 5, 9)),
      sundoWeatherRepositoryProvider.overrideWithValue(unavailableWeather()),
    ]);
    var containerDisposed = false;
    void disposeContainer() {
      if (containerDisposed) return;
      containerDisposed = true;
      container.dispose();
    }

    addTearDown(disposeContainer);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const SundoApp()));
    await tester.pump(const Duration(milliseconds: 2900));
    await tester.pumpAndSettle();
    container.read(sundoRouterProvider).go('/welcome');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(AppStore.identity, 'guest');
    expect(MockAuthRepository.hasSession, isFalse);
    expect(find.textContaining('Private Resident'), findsNothing);
    for (final label in ['Home', 'Live Map', 'Schedule', 'Alerts', 'Profile']) {
      expect(
          find.descendant(
              of: find.byType(SundoBottomNavigation),
              matching: find.text(label)),
          findsOneWidget);
    }
    await tester.tap(find.descendant(
        of: find.byType(SundoBottomNavigation),
        matching: find.text('Schedule')));
    await tester.pumpAndSettle();
    expect(find.text('Collection Schedule'), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(SundoBottomNavigation), matching: find.text('Alerts')));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(SundoBottomNavigation),
        matching: find.text('Profile')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Logout'));
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    disposeContainer();
  });
}
