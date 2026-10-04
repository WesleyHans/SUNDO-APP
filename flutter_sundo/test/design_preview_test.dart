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
import 'package:sundo_sipalay/features/live_map/truck_alert_modal.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
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
              const AssetImage('assets/images/sundo-brand-logo.png'), context);
        });
        await tester.pump(const Duration(milliseconds: 300));
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
}
