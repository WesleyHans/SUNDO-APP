import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/app/resident_shell.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/splash/splash_screen.dart';
import 'package:sundo_sipalay/features/onboarding/welcome_screen.dart';
import 'package:sundo_sipalay/features/auth/login_screen.dart';
import 'package:sundo_sipalay/features/auth/register_screen.dart';
import 'package:sundo_sipalay/features/schedule/schedule_screen.dart';
import 'package:sundo_sipalay/features/notifications/notifications_screen.dart';
import 'package:sundo_sipalay/features/report_concern/report_concern_screen.dart';
import 'package:sundo_sipalay/features/profile/profile_screen.dart';
import 'package:sundo_sipalay/features/home/widgets/sundo_card_scenery.dart';
import 'package:sundo_sipalay/features/live_map/truck_alert_modal.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';
import 'package:sundo_sipalay/shared/widgets/time_based_background.dart';
import 'package:sundo_sipalay/shared/widgets/sundo_graphics.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';
import 'location_platform_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
  setUp(mockUnavailableDeviceLocation);
  final screens = <String, Widget Function()>{
    'splash': () => SplashScreen(onContinue: () {}),
    'welcome': () => WelcomeScreen(
        onGetStarted: () {}, onLogIn: () {}, onCreateAccount: () {}),
    'login': () => LoginScreen(
        onLoginSuccess: () {}, onCreateAccount: () {}, onBack: () {}),
    'register': () => RegisterScreen(
        onBack: () {}, onRegisterSuccess: () {}, onGoToLogin: () {}),
    'home': () => MainNavigationShell(onLogout: () {}),
    'schedule': () => const ScheduleScreen(),
    'calendar': () => const ScheduleScreen(initialTab: 'Calendar'),
    'notifications': () => const NotificationsScreen(),
    'report': () => const ReportGarbageScreen(),
    'profile': () => ProfileScreen(onLogout: () {}),
    'alert': () => TruckAlertModal(
        onViewTruck: () {}, onDismiss: () {}, isStandalone: true),
  };
  for (final night in [false, true]) {
    for (final entry in screens.entries) {
      testWidgets(
          '${entry.key} renders in ${night ? 'evening' : 'daylight'} at two phone sizes',
          (tester) async {
        AppStore.setIdentity(null);
        final originalShadows = debugDisableShadows;
        debugDisableShadows = false;
        addTearDown(() => debugDisableShadows = originalShadows);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final mood = SundoTimeMood(DateTime(2026, 10, 4, night ? 20 : 9));
        await tester.runAsync(() async {
          for (final weight in FontWeight.values) {
            GoogleFonts.outfit(fontWeight: weight);
            GoogleFonts.plusJakartaSans(fontWeight: weight);
          }
          await GoogleFonts.pendingFonts();
          final icons = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await icons.load();
        });
        await tester.pumpWidget(MaterialApp(
            theme: buildSundoTheme(mood),
            home: SundoTimeScope(
                mood: mood,
                child: RepaintBoundary(
                    key: const ValueKey('preview'),
                    child: ScenicBackdrop(child: entry.value())))));
        await tester.runAsync(() async {
          await GoogleFonts.pendingFonts();
          final context = tester.element(find.byKey(const ValueKey('preview')));
          await precacheImage(const AssetImage(clayHeroAsset), context);
          await precacheImage(
              AssetImage(sundoEnvironmentArtwork(mood.environment)), context);
          await precacheImage(const AssetImage(sundoSideTruckAsset), context);
          await precacheImage(
              const AssetImage('assets/images/sundo-brand-logo.png'), context);
          if (entry.key == 'home') {
            for (final scene in SundoCardScene.values) {
              await precacheImage(
                  AssetImage(sundoCardSceneryArtwork(
                      scene, sundoCardSceneryState(mood))),
                  context);
            }
          }
        });
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1100));
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
          await expectLater(
              find.byKey(const ValueKey('preview')),
              matchesGoldenFile(
                  'goldens/${entry.key}${night ? '_night' : ''}.png'));
        }
        debugDisableShadows = originalShadows;
        tester.view.physicalSize = const Size(320, 640);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  // Exercise the actual Home route, rather than an isolated image or gallery.
  // Each preview includes real card text, controls, spacing and bottom tabs.
  for (final (name, hour, minute, code, state) in [
    ('morning', 9, 0, 0, SundoCardSceneryState.morning),
    ('noon', 12, 0, 0, SundoCardSceneryState.noon),
    ('sunset', 17, 0, 0, SundoCardSceneryState.sunset),
    ('early_evening_1800', 18, 0, 0, SundoCardSceneryState.earlyEvening),
    ('evening', 18, 30, 0, SundoCardSceneryState.evening),
    ('night', 19, 0, 0, SundoCardSceneryState.night),
    ('cloudy', 9, 0, 3, SundoCardSceneryState.cloudy),
    ('rainy', 9, 0, 63, SundoCardSceneryState.rainy),
  ]) {
    testWidgets('Home renders native $name card scenery', (tester) async {
      final instant = DateTime.now();
      final mood = SundoTimeMood(instant,
          philippineTime: DateTime(2026, 10, 8, hour, minute),
          weather: SipalayWeather(
              validAt: instant,
              fetchedAt: instant,
              weatherCode: code,
              precipitationMm: 0,
              rainMm: 0,
              showersMm: 0));
      expect(sundoCardSceneryState(mood), state);
      await _renderHomeScenery(tester, mood, 'home_card_scenery_$name');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final (name, width, scale) in [
    ('compact', 320.0, 1.0),
    ('large_text', 320.0, 1.5),
  ]) {
    testWidgets('Home card scenery remains readable at $name', (tester) async {
      final mood = SundoTimeMood(DateTime.now(),
          philippineTime: DateTime(2026, 10, 8, 9));
      await _renderHomeScenery(tester, mood, 'home_card_scenery_$name',
          width: width, scale: scale);
      await tester.ensureVisible(find.text('View Live Truck'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Future<void> _renderHomeScenery(
    WidgetTester tester, SundoTimeMood mood, String name,
    {double width = 390, double scale = 1}) async {
  AppStore.setIdentity(null);
  await AppStore.setName('Juan Dela Cruz');
  await AppStore.setBarangay('Barangay 1 (Poblacion)');
  final originalShadows = debugDisableShadows;
  debugDisableShadows = false;
  addTearDown(() => debugDisableShadows = originalShadows);
  try {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.runAsync(() async {
    for (final weight in FontWeight.values) {
      GoogleFonts.outfit(fontWeight: weight);
      GoogleFonts.plusJakartaSans(fontWeight: weight);
    }
    await GoogleFonts.pendingFonts();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  await tester.pumpWidget(MaterialApp(
      theme: buildSundoTheme(mood),
      home: MediaQuery(
          data: MediaQueryData(
              size: Size(width, 844),
              disableAnimations: true,
              textScaler: TextScaler.linear(scale)),
          child: SundoTimeScope(
              mood: mood,
              weatherEnabled: true,
              child: RepaintBoundary(
                  key: const ValueKey('home-scenery-preview'),
                  child: ScenicBackdrop(
                      child: MainNavigationShell(onLogout: () {})))))));
  await tester.runAsync(() async {
    await GoogleFonts.pendingFonts();
    final context =
        tester.element(find.byKey(const ValueKey('home-scenery-preview')));
    await precacheImage(
        AssetImage(sundoEnvironmentArtwork(mood.environment)), context);
    await precacheImage(const AssetImage(sundoSideTruckAsset), context);
    await precacheImage(const AssetImage(sundoLeafSprigAsset), context);
    for (final scene in SundoCardScene.values) {
      await precacheImage(
          AssetImage(sundoCardSceneryArtwork(scene, sundoCardSceneryState(mood))),
          context);
    }
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1100));
  expect(find.byType(SundoCardScenery), findsNWidgets(3));
  expect(find.text('Juan!'), findsOneWidget);
  expect(find.text('View Live Truck'), findsOneWidget);
  expect(tester.takeException(), isNull);
  if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
    await expectLater(find.byKey(const ValueKey('home-scenery-preview')),
        matchesGoldenFile('goldens/$name.png'));
  }
  } finally {
    debugDisableShadows = originalShadows;
  }
}
