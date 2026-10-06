import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/repositories/concern_repository.dart';
import 'package:sundo_sipalay/repositories/notification_repository.dart';
import 'package:sundo_sipalay/repositories/schedule_repository.dart';
import 'package:sundo_sipalay/features/notifications/notifications_screen.dart';
import 'package:sundo_sipalay/features/report_concern/report_concern_screen.dart';
import 'package:sundo_sipalay/features/schedule/schedule_screen.dart';
import 'package:sundo_sipalay/features/profile/profile_screen.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/shared/widgets/schedule_notification_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
  });

  test(
      'mock collection dates follow the supplied local month across year boundaries',
      () async {
    final repository = MockScheduleRepository(now: DateTime(2027, 1, 1, 10));
    final rows = await repository.load();
    expect(rows.where((schedule) => schedule.isOn(DateTime(2027, 1, 1))),
        hasLength(2));
    expect(rows.first.pickupAt.year, 2026);
    expect(rows.first.statusAt(DateTime(2027, 1, 1)), 'Completed');
    expect(rows[2].statusAt(DateTime(2027, 1, 1)), 'Delayed');
    expect(rows[3].statusAt(DateTime(2027, 1, 1)), 'Upcoming');
  });

  test(
      'reading notices and disabling approaching alerts stay private to an account',
      () async {
    final repository = MockNotificationRepository(now: DateTime(2027, 1, 1));
    AppStore.setIdentity('resident-one');
    await repository.markAllRead();
    await repository.setRemindersEnabled(false);
    expect(await repository.unreadCount(), 0);
    expect(await repository.remindersEnabled(), false);
    AppStore.setIdentity('resident-two');
    expect(await repository.unreadCount(), 5);
    expect(await repository.remindersEnabled(), true);
  });

  test('address-only demo concerns persist without fabricated GPS', () async {
    final repository = MockConcernRepository();
    await repository.submit(GarbageReportItem(
        id: 'demo-no-gps',
        concernType: 'Missed Collection',
        description: 'Bins were not collected.',
        photoPaths: [],
        locationAddress: 'Purok 1, Barangay 1, Sipalay City',
        createdAt: DateTime(2027, 1, 1)));
    final saved = (await repository.load()).single;
    expect(saved.latitude, isNull);
    expect(saved.longitude, isNull);
    expect(saved.locationAddress, contains('Purok 1'));
    expect(SupabaseConcernRepository().requiresGps, true);
  });

  test(
      'actual on-device notices start empty and preserve concurrent account-scoped events',
      () async {
    final repository = LocalNotificationRepository();
    AppStore.setIdentity('resident-one');
    expect(await repository.load(), isEmpty);
    await Future.wait([
      repository.recordEvent(
          id: 'actual-route',
          title: 'Route Changed',
          message: 'The active route changed.',
          type: 'route'),
      repository.recordEvent(
          id: 'actual-approaching',
          title: 'Truck Approaching',
          message: 'A live truck is near your collection area.',
          type: 'alert'),
    ]);
    await repository.recordEvent(
        id: 'actual-route',
        title: 'Route Changed',
        message: 'The active route changed.',
        type: 'route');
    expect(await repository.load(), hasLength(2));
    AppStore.setIdentity('resident-two');
    expect(await repository.load(), isEmpty);
    AppStore.setIdentity('resident-one');
    expect(await repository.unreadCount(), 2);
  });

  Future<void> prepare(WidgetTester tester, Widget screen,
      {double textScale = 1}) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      for (final weight in FontWeight.values) {
        GoogleFonts.outfit(fontWeight: weight);
        GoogleFonts.plusJakartaSans(fontWeight: weight);
      }
      await GoogleFonts.pendingFonts();
    });
    final mood = SundoTimeMood(DateTime.now());
    await tester.pumpWidget(MaterialApp(
        theme: buildSundoTheme(mood),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!),
        home: SundoTimeScope(mood: mood, child: screen)));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'calendar uses current month and does not repeat a schedule on empty dates',
      (tester) async {
    await prepare(tester, ScheduleScreen(repository: MockScheduleRepository()));
    expect(find.byType(SundoScheduleCard), findsNWidgets(2));
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text(DateFormat('MMMM yyyy').format(DateTime.now())),
        findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.byType(SundoScheduleCard), findsNothing);
    expect(find.text('No collection scheduled for this date.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'notifications filter announcements and mark all read at a narrow width',
      (tester) async {
    final repository = MockNotificationRepository();
    await prepare(tester, NotificationsScreen(repository: repository));
    final notices = await repository.load();
    expect(notices, hasLength(5));
    await tester.scrollUntilVisible(find.text('Special Collection'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Special Collection'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Announcements'), -180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Announcements'));
    await tester.pumpAndSettle();
    expect(find.byType(SundoNotificationCard), findsOneWidget);
    expect(find.text('Special Collection'), findsOneWidget);
    await tester.tap(find.byTooltip('Mark all read'));
    await tester.pumpAndSettle();
    expect(await repository.unreadCount(), 0);
    expect(await repository.readIds(),
        containsAll(notices.map((notice) => notice.id)));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'concern form has four selectable concerns and validates an empty description',
      (tester) async {
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            channel,
            (call) async =>
                call.method == 'isLocationServiceEnabled' ? false : null);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await prepare(
        tester, ReportGarbageScreen(repository: MockConcernRepository()));
    expect(find.byType(SundoConcernRadioOption), findsNWidgets(4));
    await tester.tap(find.text('Route Concern'));
    await tester.pump();
    final selected = tester.widget<SundoConcernRadioOption>(
        find.widgetWithText(SundoConcernRadioOption, 'Route Concern'));
    expect(selected.selected, true);
    await tester.ensureVisible(find.text('Submit Report'));
    await tester.tap(find.text('Submit Report'));
    await tester.pumpAndSettle();
    expect(find.text('Please describe your concern.'), findsOneWidget);
    expect(await AppStore.getReports(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long announcement details scroll while Close stays reachable',
      (tester) async {
    final repository = MockNotificationRepository();
    final message = List.filled(22,
            'Prepare separated waste and keep collection access clear. Follow the published barangay schedule.')
        .join(' ');
    repository.items
      ..clear()
      ..add(SundoNotification(
          id: 'long-announcement',
          title: 'Collection advisory',
          message: message,
          createdAt: DateTime.now(),
          category: 'Announcements',
          type: 'special'));
    await prepare(tester, NotificationsScreen(repository: repository),
        textScale: 1.3);
    await tester.tap(find.text('Collection advisory'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    final close = find.widgetWithText(TextButton, 'Close');
    final dialogRect = tester.getRect(dialog);
    final closeRect = tester.getRect(close);
    expect(closeRect.top, greaterThanOrEqualTo(dialogRect.top));
    expect(closeRect.bottom, lessThanOrEqualTo(dialogRect.bottom));
    final scroll = find.descendant(
        of: dialog, matching: find.byType(SingleChildScrollView));
    await tester.drag(scroll, const Offset(0, -5000));
    await tester.pumpAndSettle();
    final footer = find.descendant(
        of: dialog, matching: find.text('Sample notification for the demo.'));
    expect(tester.getRect(footer).bottom,
        lessThanOrEqualTo(tester.getRect(scroll).bottom));
    expect(await repository.readIds(), contains('long-announcement'));
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report description remains editable above a large keyboard',
      (tester) async {
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            channel,
            (call) async =>
                call.method == 'isLocationServiceEnabled' ? false : null);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewInsets);
    var backs = 0;
    await prepare(
        tester,
        ReportGarbageScreen(
            onBack: () => backs++, repository: MockConcernRepository()),
        textScale: 1.3);
    final initialFilters = tester.getRect(find.byType(SundoSegmentedTabs));
    tester.view.viewInsets = const FakeViewPadding(bottom: 350);
    tester.view.padding = const FakeViewPadding(top: 24);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final keyboardFilters = tester.getRect(find.byType(SundoSegmentedTabs));
    expect(keyboardFilters.top, initialFilters.top,
        reason:
            'Compact scrolling controls stay stable when the keyboard opens.');
    final field = find.byType(TextFormField);
    await tester.ensureVisible(field);
    const text =
        'Missed collection.\nBins remain outside.\nPlease inspect our street.';
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    final render = editable.renderEditable;
    final caret = render
        .getLocalRectForCaret(const TextPosition(offset: text.length))
        .shift(render.localToGlobal(Offset.zero));
    expect(caret.bottom, lessThanOrEqualTo(640 - 350));
    expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        text);
    await tester.ensureVisible(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    expect(backs, 1);
    tester.view.viewInsets = const FakeViewPadding();
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pump();
    expect(tester.getRect(find.byType(SundoSegmentedTabs)).top,
        initialFilters.top);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'profile editors and saved-address dialog fit a short phone keyboard',
      (tester) async {
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewInsets);
    await prepare(tester, ProfileScreen(onLogout: () {}), textScale: 1.3);
    for (final action in ['Edit profile', 'Address']) {
      final finder =
          action == 'Edit profile' ? find.byTooltip(action) : find.text(action);
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      tester.view.padding = const FakeViewPadding(top: 24);
      await tester.pumpAndSettle();
      final save =
          find.text(action == 'Address' ? 'Save Address' : 'Save Changes');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(640 - 320));
      expect(find.byType(TextFormField), findsNWidgets(2));
      Navigator.of(tester.element(save)).pop();
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding();
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.text('Saved Addresses'));
    await tester.tap(find.text('Saved Addresses'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add saved address'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    tester.view.padding = const FakeViewPadding(top: 24);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Home');
    await tester.enterText(
        find.byType(TextFormField).last, 'Purok 1, Barangay 2, Sipalay City');
    final save = find.widgetWithText(TextButton, 'Save');
    expect(tester.getRect(save).bottom, lessThanOrEqualTo(640 - 320));
    await tester.tap(save);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding();
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(await AppStore.getSavedAddresses(), hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
