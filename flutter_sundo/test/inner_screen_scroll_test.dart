import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/app/resident_shell.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/notifications/notifications_screen.dart';
import 'package:sundo_sipalay/features/profile/profile_screen.dart';
import 'package:sundo_sipalay/features/report_concern/report_concern_screen.dart';
import 'package:sundo_sipalay/features/schedule/schedule_screen.dart';
import 'package:sundo_sipalay/repositories/notification_repository.dart';
import 'package:sundo_sipalay/repositories/schedule_repository.dart';
import 'package:sundo_sipalay/shared/widgets/resident_components.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';
import 'package:sundo_sipalay/shared/widgets/schedule_notification_widgets.dart';

const _previewKey = ValueKey('inner-screen-scroll-preview');
const _demoLabel =
    'LOCAL DEMO · Sample fleet and schedules · Reports stay on this phone';
const _locationChannel = MethodChannel('flutter.baseflow.com/geolocator');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
    await AppStore.setName('Juan Dela Cruz');
    await AppStore.setEmail('juan@example.com');
    await AppStore.setPhone('09123456789');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            _locationChannel,
            (call) async =>
                call.method == 'isLocationServiceEnabled' ? false : null);
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_locationChannel, null));

  for (final night in [false, true]) {
    testWidgets(
        'profile has compact scrolling content in ${night ? 'night' : 'day'} theme',
        (tester) async {
      await _mount(tester, MainNavigationShell(onLogout: () {}), night: night);
      await tester.tap(find.descendant(
          of: find.byType(SundoBottomNavigation),
          matching: find.text('Profile')));
      await tester.pumpAndSettle();
      final avatar = find.descendant(
          of: find.byType(ProfileScreen), matching: find.byType(CircleAvatar));
      final avatarTop = tester.getRect(avatar).top;
      final demoBottom = tester.getRect(find.text(_demoLabel)).bottom;
      expect(avatarTop - demoBottom, inInclusiveRange(16, 40),
          reason:
              'The account starts near the demo strip, without an empty header.');
      expect(
          tester
              .getRect(find.byTooltip('Edit profile'))
              .overlaps(_leaves(tester).first),
          isFalse);
      expect(find.byType(AppBar), findsNothing);
      await _preview(tester, 'profile_${night ? 'night' : 'day'}_compact');
      final leaves = _leaves(tester);
      await tester.drag(_scrollable(ProfileScreen), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.getRect(avatar).top, lessThan(avatarTop - 50));
      expect(_leaves(tester), leaves);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('calendar actions and filters scroll with collection content',
      (tester) async {
    await _mount(
        tester,
        ScheduleScreen(
            repository: MockScheduleRepository(now: DateTime(2026, 10, 6)),
            initialTab: 'Calendar'));
    await _expectScrollingControls(tester, ScheduleScreen, 'Refresh schedules');
  });

  testWidgets('notification actions and filters scroll with notices',
      (tester) async {
    await _mount(
        tester,
        NotificationsScreen(
            repository:
                MockNotificationRepository(now: DateTime(2026, 10, 6))));
    await _expectScrollingControls(
        tester, NotificationsScreen, 'Notification settings');
  });

  testWidgets('report back action and filters scroll with its form',
      (tester) async {
    await _mount(tester, ReportGarbageScreen(onBack: () {}));
    await _expectScrollingControls(tester, ReportGarbageScreen, 'Back');
  });
}

Future<void> _expectScrollingControls(
    WidgetTester tester, Type screen, String action) async {
  final control = find.byTooltip(action);
  final filters = find.byType(SundoSegmentedTabs);
  final originalControl = tester.getRect(control);
  final originalFilters = tester.getRect(filters);
  final leaves = _leaves(tester);
  expect(originalControl.top, inInclusiveRange(44, 48),
      reason: 'Actions use only 20 px of padding below the safe area.');
  expect(originalControl.overlaps(leaves.first), isFalse);
  expect(control.hitTestable(), findsOneWidget);
  final scrollable = _scrollable(screen);
  final position = tester.state<ScrollableState>(scrollable).position;
  final originalOffset = position.pixels;
  await tester.drag(scrollable, const Offset(0, -180));
  await tester.pumpAndSettle();
  expect(position.pixels, greaterThan(originalOffset + 50));
  // A lazy ListView may discard its header after it scrolls out of view.
  // A fixed header would still be hittable, which must fail this check.
  expect(control.hitTestable(), findsNothing);
  expect(filters.hitTestable(), findsNothing);
  if (control.evaluate().isNotEmpty) {
    expect(tester.getRect(control).top, lessThan(originalControl.top - 50));
  }
  if (filters.evaluate().isNotEmpty) {
    expect(tester.getRect(filters).top, lessThan(originalFilters.top - 50));
  }
  expect(_leaves(tester), leaves,
      reason: 'Only screen content scrolls; corner artwork stays fixed.');
  expect(find.byType(AppBar), findsNothing);
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
}

Finder _scrollable(Type screen) => find
    .descendant(of: find.byType(screen), matching: find.byType(Scrollable))
    .first;

List<Rect> _leaves(WidgetTester tester) => [
      for (var index = 0;
          index < find.byType(LeafSprig).evaluate().length;
          index++)
        tester.getRect(find.byType(LeafSprig).at(index))
    ];

Future<void> _mount(WidgetTester tester, Widget screen,
    {bool night = false}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  final mood = SundoTimeMood(DateTime(2026, 10, 6, night ? 20 : 11));
  await tester.runAsync(() async {
    for (final weight in FontWeight.values) {
      GoogleFonts.outfit(fontWeight: weight);
      GoogleFonts.plusJakartaSans(fontWeight: weight);
    }
    await GoogleFonts.pendingFonts();
  });
  await tester.pumpWidget(MaterialApp(
      theme: buildSundoTheme(mood),
      home: MediaQuery(
          data: const MediaQueryData(
              disableAnimations: true,
              size: Size(320, 640),
              padding: EdgeInsets.only(top: 24, bottom: 24),
              viewPadding: EdgeInsets.only(top: 24, bottom: 24),
              textScaler: TextScaler.linear(1.4)),
          child: SundoTimeScope(
              mood: mood,
              child: RepaintBoundary(
                  key: _previewKey, child: ScenicBackdrop(child: screen))))));
  await tester.pumpAndSettle();
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('GENERATE_PREVIEWS')) return;
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, tester.element(find.byKey(_previewKey)));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  await tester.pumpAndSettle();
  await expectLater(
      find.byKey(_previewKey), matchesGoldenFile('goldens/inner_$name.png'));
}
