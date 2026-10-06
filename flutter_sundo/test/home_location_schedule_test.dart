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

  test('tomorrow notice matches resident area and the next calendar day', () {
    final rows = [
      _schedule('afternoon', 'Barangay 1', DateTime(2027, 1, 1, 13)),
      _schedule('other-area', 'Barangay 2', DateTime(2027, 1, 1, 8)),
      _schedule('completed', 'Barangay 1', DateTime(2027, 1, 1, 7),
          status: 'Completed'),
      _schedule('today', 'Barangay 1', DateTime(2026, 12, 31, 23)),
      _schedule('morning', 'Barangay 1', DateTime(2027, 1, 1, 8)),
      _schedule('later', 'Barangay 1', DateTime(2027, 1, 2, 8)),
    ];
    final matching = tomorrowCollectionsForResidentArea(
        rows, 'Barangay 1 (Poblacion)', DateTime(2026, 12, 31, 20));
    expect(matching.map((entry) => entry.id), ['morning', 'afternoon']);
    expect(tomorrowCollectionsForResidentArea(rows, '', DateTime(2026, 12, 31)),
        isEmpty);
  });

  test('live tomorrow dates use Philippine time across UTC midnight', () {
    final rows = [
      _schedule('tomorrow', 'Barangay 1', DateTime.utc(2026, 10, 7, 16)),
      _schedule('today', 'Barangay 1', DateTime.utc(2026, 10, 6, 17)),
      _schedule('day-after', 'Barangay 1', DateTime.utc(2026, 10, 8, 16)),
    ];
    final mood = SundoTimeMood.fromInstant(DateTime.utc(2026, 10, 6, 17));
    expect(
        tomorrowCollectionsForResidentArea(rows, 'Barangay 1', mood.localTime,
                datesAreInstants: true)
            .map((entry) => entry.id),
        ['tomorrow']);
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

  testWidgets('tomorrow announcement labels demo data and opens Schedule',
      (tester) async {
    var opened = 0;
    await render(
        tester,
        HomeCollectionNotice(
            schedules: [
              _schedule('tomorrow', 'Barangay 1', DateTime(2026, 10, 7, 8))
            ],
            area: 'Barangay 1',
            isDemo: true,
            loaded: true,
            onOpenSchedule: () => opened++));
    expect(find.text('Collection tomorrow in your area'), findsOneWidget);
    expect(find.text('Sample schedule · Local demo'), findsOneWidget);
    expect(find.textContaining('8:00 AM'), findsOneWidget);
    await tester.tap(find.text('Collection tomorrow in your area'));
    expect(opened, 1);
    expect(tester.takeException(), isNull);
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
