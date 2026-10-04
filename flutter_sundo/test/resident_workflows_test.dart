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
import 'package:sundo_sipalay/core/storage/app_store.dart';
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

  Future<void> prepare(WidgetTester tester, Widget screen) async {
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
    await tester.pumpWidget(MaterialApp(
        home: SundoTimeScope(
            mood: SundoTimeMood(DateTime.now()), child: screen)));
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
    expect(find.byType(SundoNotificationCard), findsNWidgets(5));
    await tester.tap(find.text('Announcements'));
    await tester.pumpAndSettle();
    expect(find.byType(SundoNotificationCard), findsOneWidget);
    expect(find.text('Special Collection'), findsOneWidget);
    await tester.tap(find.byTooltip('Mark all read'));
    await tester.pumpAndSettle();
    expect(await repository.unreadCount(), 0);
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
}
