import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/core/utils/resident_area.dart';
import 'package:sundo_sipalay/features/home/home_collection_notice.dart';
import 'package:sundo_sipalay/features/home/home_location_card.dart';
import 'package:sundo_sipalay/repositories/schedule_repository.dart';
import 'package:sundo_sipalay/services/environment_location_service.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';

CollectionSchedule _schedule(String id, String area, DateTime date,
        {String? status}) =>
    CollectionSchedule(
        id: id,
        barangay: area,
        pickupAt: date,
        timeLabel: '8:00 AM – 12:00 PM',
        route: 'Published route',
        wasteType: 'Recyclable',
        explicitStatus: status);

Position _fix(DateTime date,
        {double latitude = 9.753456, double accuracy = 8}) =>
    Position(
        latitude: latitude,
        longitude: 122.404321,
        timestamp: date,
        accuracy: accuracy,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0);

EnvironmentLocationService _access(
        {Future<LocationPermission> Function()? permission,
        Future<LocationPermission> Function()? request,
        bool enabled = true}) =>
    EnvironmentLocationService(
        checkPermission:
            permission ?? () async => LocationPermission.whileInUse,
        requestPermission: request ?? () async => LocationPermission.whileInUse,
        checkService: () async => enabled);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
  });

  test('Today matches the resident area and full Philippine calendar day', () {
    final rows = [
      _schedule('afternoon', 'Barangay 1', DateTime(2026, 12, 31, 13)),
      _schedule('other-area', 'Barangay 2', DateTime(2026, 12, 31, 8)),
      _schedule('completed', 'Barangay 1', DateTime(2026, 12, 31, 7),
          status: 'Completed'),
      _schedule('cancelled', 'Barangay 1', DateTime(2026, 12, 31, 9),
          status: 'Cancelled'),
      _schedule('morning', 'Barangay 1 · Stop A', DateTime(2026, 12, 31, 8)),
      _schedule('tomorrow', 'Barangay 1', DateTime(2027, 1, 1, 8)),
      _schedule('neighbor-prefix', 'Barangay 11', DateTime(2026, 12, 31, 8)),
    ];
    final matching = todayCollectionsForResidentArea(
        rows, 'Barangay 1 (Poblacion)', DateTime(2026, 12, 31, 20));
    expect(matching.map((entry) => entry.id),
        ['completed', 'morning', 'cancelled', 'afternoon']);
    expect(todayCollectionsForResidentArea(rows, '', DateTime(2026, 12, 31)),
        isEmpty);
  });

  test('live Today dates use Philippine time across UTC midnight', () {
    final rows = [
      _schedule('tomorrow', 'Barangay 1', DateTime.utc(2026, 10, 7, 16)),
      _schedule('today-midnight', 'Barangay 1', DateTime.utc(2026, 10, 6, 16)),
      _schedule('today-late', 'Barangay 1', DateTime.utc(2026, 10, 7, 15, 59)),
      _schedule('yesterday', 'Barangay 1', DateTime.utc(2026, 10, 6, 15, 59)),
    ];
    final mood = SundoTimeMood.fromInstant(DateTime.utc(2026, 10, 6, 17));
    expect(
        todayCollectionsForResidentArea(rows, 'Barangay 1', mood.localTime,
                datesAreInstants: true)
            .map((entry) => entry.id),
        ['today-midnight', 'today-late']);
  });

  test('Next Collection skips all of Today and completed or cancelled windows',
      () {
    final rows = [
      _schedule('later-today', 'Barangay 1', DateTime(2026, 12, 31, 23)),
      _schedule('completed', 'Barangay 1', DateTime(2027, 1, 1, 7),
          status: ' Completed '),
      _schedule('cancelled', 'Barangay 1', DateTime(2027, 1, 1, 8),
          status: 'Cancelled'),
      _schedule('canceled', 'Barangay 1', DateTime(2027, 1, 1, 9),
          status: 'canceled'),
      _schedule('next', 'Barangay 1 · Stop A', DateTime(2027, 1, 1, 13),
          status: 'Delayed'),
      _schedule('other', 'Barangay 2', DateTime(2027, 1, 1, 12)),
      _schedule('neighbor-prefix', 'Barangay 11', DateTime(2027, 1, 1, 12)),
    ];
    expect(
        nextCollectionForResidentArea(
            rows, 'Barangay 1 (Poblacion)', DateTime(2026, 12, 31, 20),
            afterToday: true)?.id,
        'next');
    expect(
        nextCollectionForResidentArea(
            rows.take(4).toList(), 'Barangay 1', DateTime(2026, 12, 31, 20),
            afterToday: true),
        isNull);
    expect(
        nextCollectionForResidentArea(
            rows, '', DateTime(2026, 12, 31, 20), afterToday: true),
        isNull);
  });

  test('live Next Collection crosses the UTC+8 year boundary exactly', () {
    final rows = [
      _schedule('today', 'Barangay 1', DateTime.utc(2026, 12, 31, 15, 59)),
      _schedule('next', 'Barangay 1', DateTime.utc(2026, 12, 31, 16)),
      _schedule('later', 'Barangay 1', DateTime.utc(2027, 1, 1, 1)),
    ];
    final mood = SundoTimeMood.fromInstant(DateTime.utc(2026, 12, 31, 12));
    expect(
        nextCollectionForResidentArea(rows, 'Barangay 1', mood.localTime,
            afterToday: true, datesAreInstants: true)?.id,
        'next');
    final midnight = SundoTimeMood.fromInstant(DateTime.utc(2026, 12, 31, 16));
    expect(
        todayCollectionsForResidentArea(rows, 'Barangay 1', midnight.localTime,
            datesAreInstants: true).map((row) => row.id),
        ['next', 'later']);
    expect(
        nextCollectionForResidentArea(rows, 'Barangay 1', midnight.localTime,
            afterToday: true, datesAreInstants: true),
        isNull);
  });

  test('sample afternoon remains on its calendar day without a UTC shift', () {
    final rows = [
      _schedule('today-late', 'Barangay 1', DateTime(2026, 10, 7, 23)),
      _schedule('tomorrow', 'Barangay 1', DateTime(2026, 10, 8, 8)),
    ];
    final now = DateTime(2026, 10, 7, 20);
    expect(todayCollectionsForResidentArea(rows, 'Barangay 1', now).single.id,
        'today-late');
    expect(
        nextCollectionForResidentArea(rows, 'Barangay 1', now,
            afterToday: true)?.id,
        'tomorrow');
  });

  test('Home never asks permission or reads GPS when access is denied',
      () async {
    var prompts = 0;
    var fixes = 0;
    final service = HomeLocationService(
        access: _access(
            permission: () async => LocationPermission.denied,
            request: () async {
              prompts++;
              return LocationPermission.whileInUse;
            }),
        lastKnownPosition: () async {
          fixes++;
          return null;
        },
        fetchPosition: () async {
          fixes++;
          return _fix(DateTime.now());
        });
    final result = await service.resolve();
    expect(result.status, EnvironmentLocationStatus.denied);
    expect(result.fix, isNull);
    expect(result.center, isNull);
    expect(prompts, 0);
    expect(fixes, 0);
  });

  test('Home uses a fresh precise cached fix without rounding or new GPS work',
      () async {
    final now = DateTime.utc(2026, 10, 6, 2);
    var fetches = 0;
    final service = HomeLocationService(
        access: _access(),
        clock: () => now,
        lastKnownPosition: () async => _fix(now),
        fetchPosition: () async {
          fetches++;
          return _fix(now);
        });
    final result = await service.resolve();
    expect(result.status, EnvironmentLocationStatus.device);
    expect(result.center?.latitude, 9.753456);
    expect(result.center?.longitude, 122.404321);
    expect(fetches, 0);
    final cached = await service.resolve();
    expect(cached.fix, result.fix);
    expect(await AppStore.getResidentLocation(), isNull,
        reason: 'The Home preview does not persist precise GPS.');
  });

  test('stale GPS falls back to an explicitly saved area without a current pin',
      () async {
    await AppStore.setBarangay('Barangay 2');
    final now = DateTime.utc(2026, 10, 6, 2);
    final stale = _fix(now.subtract(const Duration(minutes: 5)));
    final service = HomeLocationService(
        access: _access(),
        clock: () => now,
        lastKnownPosition: () async => stale,
        fetchPosition: () async => stale);
    final result = await service.resolve();
    expect(result.status, EnvironmentLocationStatus.unavailable);
    expect(result.fix, isNull);
    expect(result.savedArea, 'Barangay 2');
    expect(result.savedCenter, isNotNull);
  });

  test('revoked permission after a slow fix cannot publish current location',
      () async {
    var checks = 0;
    final now = DateTime.utc(2026, 10, 6, 2);
    final fix = Completer<Position>();
    final requested = Completer<void>();
    final service = HomeLocationService(
        access: _access(
            permission: () async => ++checks == 1
                ? LocationPermission.whileInUse
                : LocationPermission.denied),
        clock: () => now,
        lastKnownPosition: () async => null,
        fetchPosition: () {
          requested.complete();
          return fix.future;
        });
    final resultFuture = service.resolve();
    await requested.future;
    fix.complete(_fix(now));
    final result = await resultFuture;
    expect(result.status, EnvironmentLocationStatus.denied);
    expect(result.fix, isNull);
  });

  test('reactivation shares pending GPS but retired request cannot publish it',
      () async {
    final now = DateTime.utc(2026, 10, 6, 2);
    var firstActive = true;
    var fetches = 0;
    var reads = 0;
    final requested = Completer<void>();
    final secondRead = Completer<void>();
    final pending = Completer<Position>();
    final service = HomeLocationService(
        access: _access(),
        clock: () => now,
        lastKnownPosition: () async {
          if (++reads == 2) secondRead.complete();
          return null;
        },
        fetchPosition: () {
          fetches++;
          requested.complete();
          return pending.future;
        });
    final retired = service.resolve(canContinue: () => firstActive);
    await requested.future;
    firstActive = false;
    final resumed = service.resolve(canContinue: () => true);
    await secondRead.future;
    await Future<void>.delayed(Duration.zero);
    expect(fetches, 1,
        reason: 'Rapid navigation must not create another native GPS request.');
    pending.complete(_fix(now));
    final oldResult = await retired;
    final currentResult = await resumed;
    expect(oldResult.fix, isNull);
    expect(currentResult.status, EnvironmentLocationStatus.device);
    expect(currentResult.fix, isNotNull);
  });

  Future<void> render(WidgetTester tester, Widget card) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      for (final weight in FontWeight.values) {
        GoogleFonts.outfit(fontWeight: weight);
      }
      await GoogleFonts.pendingFonts();
    });
    final mood = SundoTimeMood(DateTime(2026, 10, 6, 11));
    await tester.pumpWidget(MaterialApp(
        theme: buildSundoTheme(mood),
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: SundoTimeScope(
                mood: mood,
                child: Scaffold(
                    body: SingleChildScrollView(
                        padding: const EdgeInsets.all(18), child: card))))));
    await tester.pumpAndSettle();
  }

  testWidgets('Today labels demo data and opens Schedule',
      (tester) async {
    var opened = 0;
    await render(
        tester,
        HomeCollectionNotice(
            schedules: [
              _schedule('today', 'Barangay 1', DateTime(2026, 10, 6, 8))
            ],
            area: 'Barangay 1',
            isDemo: true,
            loaded: true,
            onOpenSchedule: () => opened++));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Collection scheduled today'), findsOneWidget);
    expect(find.text('Sample schedule · Local demo'), findsOneWidget);
    expect(find.textContaining('8:00 AM'), findsOneWidget);
    expect(find.textContaining('Scheduled'), findsOneWidget);
    await tester.tap(find.text('Today'));
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today distinguishes empty, loading, error and missing area',
      (tester) async {
    for (final (loaded, failed, area, summary, details) in [
      (true, false, 'Barangay 1', 'No collection scheduled today',
          'Tue, Oct 6 · Barangay 1'),
      (false, false, 'Barangay 1', 'Checking today’s schedule…',
          'Loading published collection times.'),
      (true, true, 'Barangay 1', 'Schedule unavailable', 'Pull down to retry.'),
      (true, false, '', 'Choose your collection area',
          'Set your barangay in Profile.'),
    ]) {
      await render(
          tester,
          HomeCollectionNotice(
              schedules: const [],
              area: area,
              isDemo: true,
              loaded: loaded,
              failed: failed,
              onOpenSchedule: () {}));
      expect(find.text('Today'), findsOneWidget);
      expect(find.text(summary), findsOneWidget);
      expect(find.text(details), findsOneWidget);
      expect(find.textContaining('tomorrow'), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Today reports completed or cancelled collection truthfully',
      (tester) async {
    for (final (status, summary) in [
      ('Completed', 'Collection completed today'),
      ('Cancelled', 'Collection cancelled today'),
      ('Delayed', 'Collection scheduled today'),
    ]) {
      await render(
          tester,
          HomeCollectionNotice(
              schedules: [
                _schedule('today', 'Barangay 1', DateTime(2026, 10, 6, 8),
                    status: status)
              ],
              area: 'Barangay 1',
              isDemo: true,
              loaded: true,
              onOpenSchedule: () {}));
      expect(find.text(summary), findsOneWidget);
      expect(find.textContaining(' · $status'), findsOneWidget);
      expect(find.text('No collection scheduled today'), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('live Today displays Philippine pickup time without a demo label',
      (tester) async {
    await render(
        tester,
        HomeCollectionNotice(
            schedules: [
              _schedule('live-today', 'Barangay 1', DateTime.utc(2026, 10, 6))
            ],
            area: 'Barangay 1',
            isDemo: false,
            loaded: true,
            onOpenSchedule: () {}));
    expect(find.text('Collection scheduled today'), findsOneWidget);
    expect(find.text('8:00 AM · Recyclable · Scheduled'), findsOneWidget);
    expect(find.text('Sample schedule · Local demo'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mixed finished Today windows do not claim another scheduled pickup',
      (tester) async {
    await render(
        tester,
        HomeCollectionNotice(
            schedules: [
              _schedule('completed', 'Barangay 1', DateTime(2026, 10, 6, 8),
                  status: ' Completed '),
              _schedule('cancelled', 'Barangay 1', DateTime(2026, 10, 6, 13),
                  status: 'Canceled'),
            ],
            area: 'Barangay 1',
            isDemo: true,
            loaded: true,
            onOpenSchedule: () {}));
    expect(find.text('No remaining collection today'), findsOneWidget);
    expect(find.text('Collection scheduled today'), findsNothing);
    expect(find.textContaining(' · Completed'), findsOneWidget);
    expect(find.textContaining(' · Canceled'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Today hides retained pickup rows while loading or after failure',
      (tester) async {
    for (final (loaded, failed) in [(false, false), (true, true)]) {
      await render(
          tester,
          HomeCollectionNotice(
              schedules: [
                _schedule('cached-today', 'Barangay 1', DateTime(2026, 10, 6, 8))
              ],
              area: 'Barangay 1',
              isDemo: true,
              loaded: loaded,
              failed: failed,
              onOpenSchedule: () {}));
      expect(find.textContaining('8:00 AM'), findsNothing);
      expect(find.text('Collection scheduled today'), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('fresh location renders a small leaf-free map at larger text',
      (tester) async {
    var opened = 0;
    final now = DateTime.now();
    await render(
        tester,
        HomeLocationCard(
            enableTiles: false,
            service: HomeLocationService(
                access: _access(),
                clock: () => now,
                lastKnownPosition: () async => _fix(now)),
            onOpenMap: () => opened++));
    expect(find.text('Your current location'), findsOneWidget);
    expect(find.text('GPS · ±8 m'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(tester.getSize(find.byType(FlutterMap)).height, 132);
    expect(
        find.descendant(
            of: find.byType(FlutterMap), matching: find.byType(LeafSprig)),
        findsNothing);
    expect(find.byType(MarkerLayer), findsOneWidget);
    await tester.tap(find.byTooltip('Open location map'));
    expect(opened, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'saved area map has no GPS pin and unavailable state has no fake map',
      (tester) async {
    await AppStore.setBarangay('Barangay 2');
    final service = HomeLocationService(
        access: _access(permission: () async => LocationPermission.denied));
    await render(
        tester,
        HomeLocationCard(
            enableTiles: false, service: service, onOpenMap: () {}));
    expect(find.textContaining('not current GPS'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(MarkerLayer), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    SharedPreferences.setMockInitialValues({});
    await render(
        tester,
        HomeLocationCard(
            enableTiles: false, service: service, onOpenMap: () {}));
    expect(find.text('Location permission is off'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
    expect(find.text('Open Live Map'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'Home expires a precise marker at 60 seconds while GPS is pending',
      (tester) async {
    final recordedAt = DateTime.utc(2026, 10, 6, 2);
    var now = recordedAt;
    var fetches = 0;
    final nextFix = Completer<Position>();
    await render(
        tester,
        HomeLocationCard(
            enableTiles: false,
            service: HomeLocationService(
                access: _access(),
                clock: () => now,
                lastKnownPosition: () async => _fix(recordedAt),
                fetchPosition: () {
                  fetches++;
                  return nextFix.future;
                }),
            onOpenMap: () {}));
    expect(find.text('Your current location'), findsOneWidget);
    expect(find.byType(MarkerLayer), findsOneWidget);
    // The 30-second poll may reuse a 59-second-old native fix. It must not
    // restart a fresh one-minute lifetime for that same position.
    now = recordedAt.add(const Duration(seconds: 59));
    await tester.pump(const Duration(seconds: 59));
    await tester.pump();
    expect(find.byType(MarkerLayer), findsOneWidget);
    now = recordedAt.add(const Duration(seconds: 60));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Your current location'), findsNothing);
    expect(find.byType(MarkerLayer), findsNothing);
    expect(fetches, 1);
    nextFix.complete(_fix(now));
    await tester.pumpAndSettle();
    expect(find.text('Your current location'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
