import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/app/resident_shell.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/auth/login_screen.dart';
import 'package:sundo_sipalay/features/auth/register_screen.dart';
import 'package:sundo_sipalay/features/live_map/live_map_screen.dart';
import 'package:sundo_sipalay/features/live_map/truck_alert_modal.dart';
import 'package:sundo_sipalay/features/live_map/widgets/map_scene_controls.dart';
import 'package:sundo_sipalay/features/notifications/notifications_screen.dart';
import 'package:sundo_sipalay/features/onboarding/welcome_screen.dart';
import 'package:sundo_sipalay/features/profile/profile_screen.dart';
import 'package:sundo_sipalay/features/report_concern/report_concern_screen.dart';
import 'package:sundo_sipalay/features/schedule/schedule_screen.dart';
import 'package:sundo_sipalay/repositories/concern_repository.dart';
import 'package:sundo_sipalay/repositories/mock_auth_repository.dart';
import 'package:sundo_sipalay/repositories/notification_repository.dart';
import 'package:sundo_sipalay/services/weather_consent.dart';
import 'package:sundo_sipalay/shared/widgets/resident_components.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';
import 'package:sundo_sipalay/shared/widgets/schedule_notification_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({weatherLocationConsentKey: false});
    MockAuthRepository.resetMemory();
    AppStore.setIdentity(null);
    const locationChannel = MethodChannel('flutter.baseflow.com/geolocator');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            locationChannel,
            (call) async => switch (call.method) {
                  'isLocationServiceEnabled' => false,
                  'checkPermission' || 'requestPermission' => 0,
                  _ => null,
                });
  });
  tearDown(() {
    const locationChannel = MethodChannel('flutter.baseflow.com/geolocator');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(locationChannel, null);
  });

  for (final scale in [1.3, 1.5]) {
    testWidgets('welcome actions remain reachable on a short phone at $scale',
        (tester) async {
      var demos = 0;
      var logins = 0;
      var accounts = 0;
      await _mount(
          tester,
          WelcomeScreen(
              onGetStarted: () => demos++,
              onLogIn: () => logins++,
              onCreateAccount: () => accounts++),
          scale: scale);
      await _reach(tester, find.text('Get Started'));
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      expect(demos, 1);
      await _reach(tester, find.text('Log In'));
      await tester.tap(find.text('Log In'));
      expect(logins, 1);
      await _reach(tester, find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      expect(accounts, 1);
      await _preview(tester, 'welcome_$scale');
      _expectNoError(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'login retains input and reaches its actions above keyboard at $scale',
        (tester) async {
      var accounts = 0;
      await _mount(
          tester,
          LoginScreen(
              onBack: () {},
              onLoginSuccess: () {},
              onCreateAccount: () => accounts++),
          scale: scale);
      final identifier = find.byType(TextFormField).first;
      await _reach(tester, identifier);
      await tester.enterText(identifier, 'resident@example.com');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await _reach(tester, find.text('Log In'));
      expect(
          tester.getRect(find.text('Log In')).bottom, lessThanOrEqualTo(340));
      _expectNoError(tester);
      tester.view.viewInsets = const FakeViewPadding();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _reach(tester, find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      expect(accounts, 1);
      expect(find.text('resident@example.com'), findsOneWidget);
      _expectNoError(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'registration reaches the final form and sign-in actions at $scale',
        (tester) async {
      var logins = 0;
      await _mount(
          tester,
          RegisterScreen(
              onBack: () {},
              onRegisterSuccess: () {},
              onGoToLogin: () => logins++),
          scale: scale);
      final name = find.byType(TextFormField).first;
      await _reach(tester, name);
      await tester.enterText(name, 'Juan Dela Cruz');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await _reach(tester, find.text('Create Account'));
      expect(tester.getRect(find.text('Create Account')).bottom,
          lessThanOrEqualTo(340));
      _expectNoError(tester);
      tester.view.viewInsets = const FakeViewPadding();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _reach(tester, find.text('Log In'));
      await tester.tap(find.text('Log In'));
      expect(logins, 1);
      expect(tester.widget<TextFormField>(name).controller!.text,
          'Juan Dela Cruz');
      _expectNoError(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'resident tabs retain calendar selection and reachable content at $scale',
        (tester) async {
      await _mount(tester, MainNavigationShell(onLogout: () {}), scale: scale);
      expect(find.text('Good Morning,'), findsOneWidget);
      await _tab(tester, 'Schedule');
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      final scheduleState = tester.state(find.byType(ScheduleScreen));
      expect(find.byTooltip('Next month').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      _expectNoError(tester);
      await _tab(tester, 'Alerts');
      await tester.tap(find.text('Announcements'));
      await tester.pumpAndSettle();
      await _tab(tester, 'Profile');
      await _reach(tester, find.text('Logout'));
      _expectNoError(tester);
      await _tab(tester, 'Schedule');
      expect(tester.state(find.byType(ScheduleScreen)), same(scheduleState));
      expect(
          tester
              .widget<SundoSegmentedTabs>(find.byType(SundoSegmentedTabs))
              .selected,
          'Calendar');
      expect(find.byTooltip('Next month'), findsOneWidget);
      await _tab(tester, 'Alerts');
      expect(find.text('Special Collection'), findsOneWidget);
      await _tab(tester, 'Home');
      await _reach(tester, find.text('Waste Guide'));
      await _preview(tester, 'home_$scale');
      _expectNoError(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'report description and submit button fit with keyboard at $scale',
        (tester) async {
      await _mount(
          tester,
          ReportGarbageScreen(
              onBack: () {}, repository: MockConcernRepository()),
          scale: scale);
      final description = find.byType(TextFormField).first;
      await _reach(tester, description);
      await tester.enterText(
          description, 'Please collect our waste on the next route.');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await _reach(tester, find.text('Submit Report'));
      expect(tester.getRect(find.text('Submit Report')).bottom,
          lessThanOrEqualTo(340));
      _expectNoError(tester);
      tester.view.viewInsets = const FakeViewPadding();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('My Reports'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Reports'));
      await tester.pumpAndSettle();
      expect(find.text('No reports yet'), findsOneWidget);
      _expectNoError(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'profile sheets and notification dialog fit large text at $scale',
        (tester) async {
      await AppStore.setName('Juan Dela Cruz With A Longer Resident Name');
      await _mount(tester, ProfileScreen(onLogout: () {}), scale: scale);
      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();
      final name = find.byType(TextFormField).first;
      await tester.enterText(name, 'Juan Dela Cruz');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await _reach(tester, find.text('Save Changes'));
      expect(tester.getRect(find.text('Save Changes')).bottom,
          lessThanOrEqualTo(340));
      await _preview(tester, 'profile_keyboard_$scale');
      _expectNoError(tester);
      tester.view.viewInsets = const FakeViewPadding();
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(tester.element(name)).pop();
      await tester.pumpAndSettle();
      await _reach(tester, find.text('Notification Settings'));
      await tester.tap(find.text('Notification Settings'));
      await tester.pumpAndSettle();
      await _reach(tester, find.text('Save Preferences'));
      await _preview(tester, 'profile_notifications_$scale');
      _expectNoError(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await _reach(tester, find.text('Logout'));
      _expectNoError(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('alert detail and reminder settings remain usable at $scale',
        (tester) async {
      await _mount(
          tester, NotificationsScreen(repository: MockNotificationRepository()),
          scale: scale);
      final card = find.byType(SundoNotificationCard).first;
      await _reach(tester, card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      await _reach(tester, find.text('Close'));
      _expectNoError(tester);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byTooltip('Notification settings'), -180,
          scrollable: find
              .descendant(
                  of: find.byType(NotificationsScreen),
                  matching: find.byType(Scrollable))
              .first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Notification settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SwitchListTile).hitTestable(), findsOneWidget);
      await _preview(tester, 'alerts_settings_$scale');
      _expectNoError(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('approaching alert can scroll to both actions at $scale',
        (tester) async {
      var views = 0;
      var dismisses = 0;
      await _mount(
          tester,
          TruckAlertModal(
              simulated: true,
              isStandalone: true,
              onViewTruck: () => views++,
              onDismiss: () => dismisses++),
          scale: scale,
          settle: false);
      await _reach(tester, find.text('View Truck'), settle: false);
      await tester.tap(find.text('View Truck'));
      expect(views, 1);
      await _reach(tester, find.text('Dismiss'), settle: false);
      await tester.tap(find.text('Dismiss'));
      expect(dismisses, 1);
      _expectNoError(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'short 2D and 3D map controls stay usable without leaves at $scale',
        (tester) async {
      await _mount(
          tester,
          const Scaffold(
              body: SizedBox(
                  height: 495,
                  child: LiveMapScreen(
                      isActive: false, enableTiles: false, enableGps: false))),
          scale: scale);
      expect(find.byType(LeafSprig), findsNothing);
      for (final mode in ['2D', '3D']) {
        await tester.tap(find.text(mode));
        await tester.pumpAndSettle();
        final locationText =
            find.text('Use location to see your private GPS marker');
        final locationBanner = find
            .ancestor(of: locationText, matching: find.byType(Container))
            .first;
        final viewBar = find.byType(SundoMapViewBar);
        expect(tester.getRect(locationBanner).bottom,
            lessThanOrEqualTo(tester.getRect(viewBar).top),
            reason:
                'Wrapped GPS status must not overlap the map mode controls.');
        for (final action in [
          'Reset map north',
          'Fit active route',
          'Zoom in',
          'Zoom out',
          'Use my current location',
          'Map layers'
        ]) {
          expect(find.byTooltip(action).hitTestable(), findsOneWidget,
              reason:
                  '$action must remain accessible in $mode at text scale $scale.');
        }
        await tester.tap(find.byTooltip('Map layers'));
        await tester.pumpAndSettle();
        expect(find.text('Numbered collection points'), findsOneWidget);
        _expectNoError(tester);
        Navigator.of(tester.element(find.text('Numbered collection points')))
            .pop();
        await tester.pumpAndSettle();
      }
      await _preview(tester, 'map_$scale');
      _expectNoError(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Future<void> _mount(WidgetTester tester, Widget screen,
    {required double scale, bool settle = true}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewInsets);
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
  final mood = SundoTimeMood(DateTime(2026, 10, 6, 11));
  await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
          theme: buildSundoTheme(mood),
          builder: (context, child) => RepaintBoundary(
              key: const ValueKey('responsive-audit'),
              child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: SundoTimeScope(
                      mood: mood, child: ScenicBackdrop(child: child!)))),
          home: screen)));
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
  _expectNoError(tester);
}

Future<void> _reach(WidgetTester tester, Finder target,
    {bool settle = true}) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(target.hitTestable(), findsOneWidget,
      reason: 'A resident must be able to reach and use this control.');
}

Future<void> _tab(WidgetTester tester, String label) async {
  final tab = find.descendant(
      of: find.byType(SundoBottomNavigation), matching: find.text(label));
  await tester.tap(tab);
  await tester.pumpAndSettle();
  _expectNoError(tester);
}

void _expectNoError(WidgetTester tester) =>
    expect(tester.takeException(), isNull);

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('GENERATE_PREVIEWS')) return;
  final target = find.byKey(const ValueKey('responsive-audit'));
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, tester.element(target));
    }
  });
  await tester.pump();
  await expectLater(target, matchesGoldenFile('goldens/audit_$name.png'));
}
