import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/models/map_tracking.dart';
import 'package:sundo_sipalay/repositories/map_truck_repository.dart';
import 'package:sundo_sipalay/features/live_map/live_map_screen.dart';
import 'package:sundo_sipalay/features/live_map/truck_alert_modal.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/features/live_map/widgets/clay_map_markers.dart';

class _EmptyTruckRepository implements MapTruckRepository {
  @override
  Stream<List<MapTruckSnapshot>> watchTrucks() => Stream.value([]);
}

class _PublishedTruckRepository implements MapTruckRepository {
  const _PublishedTruckRepository({this.stale = false});
  final bool stale;

  @override
  Stream<List<MapTruckSnapshot>> watchTrucks() => Stream.value([
        MapTruckSnapshot(
            id: 'Truck 02',
            position: const LatLng(9.7525, 122.4038),
            route: const MapOperatingRoute(
                id: 'A',
                name: 'Route A',
                waypoints: [
                  LatLng(9.7525, 122.4038),
                  LatLng(9.7535, 122.404)
                ],
                collectionPoints: [
                  MapCollectionPoint(
                      1, 'Collection point 1', LatLng(9.7530, 122.4042))
                ]),
            updatedAt: DateTime.now()
                .subtract(stale ? const Duration(minutes: 5) : Duration.zero),
            etaMinutes: 8,
            active: true,
            stage: MapTrackingStage.onRoute,
            nextStop: 'Barangay 1',
            currentArea: 'Sipalay City'),
      ]);
}

class _ControlledTruckRepository implements MapTruckRepository {
  _ControlledTruckRepository() {
    _updates = StreamController<List<MapTruckSnapshot>>(
        onListen: () => publish(const LatLng(9.7525, 122.4038)));
  }

  late final StreamController<List<MapTruckSnapshot>> _updates;

  void publish(LatLng position, {String id = 'Truck 02', double? heading}) =>
      _updates.add([
        MapTruckSnapshot(
          id: id,
          position: position,
          heading: heading,
          route: const MapOperatingRoute(
            id: 'A',
            name: 'Route A',
            waypoints: [
              LatLng(9.7525, 122.4038),
              LatLng(9.7535, 122.404),
            ],
            collectionPoints: [
              MapCollectionPoint(
                  1, 'Collection point 1', LatLng(9.7530, 122.4042)),
            ],
          ),
          updatedAt: DateTime.now(),
          etaMinutes: 8,
          active: true,
          stage: MapTrackingStage.onRoute,
        ),
      ]);

  @override
  Stream<List<MapTruckSnapshot>> watchTrucks() => _updates.stream;

  Future<void> dispose() => _updates.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() {
    AppStore.setIdentity(null);
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> loadFonts(WidgetTester tester) => tester.runAsync(() async {
        for (final weight in FontWeight.values) {
          GoogleFonts.outfit(fontWeight: weight);
          GoogleFonts.plusJakartaSans(fontWeight: weight);
        }
        await GoogleFonts.pendingFonts();
      });

  Future<void> mountMap(WidgetTester tester,
      {MapTruckRepository repository = const _PublishedTruckRepository(),
      bool reducedMotion = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadFonts(tester);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reducedMotion),
                child: SundoTimeScope(
                    mood: SundoTimeMood(DateTime(2026, 10, 5, 9)),
                    child: LiveMapScreen(
                        enableGps: false,
                        enableTiles: false,
                        repository: repository))))));
    await tester.pump();
    await tester.pump();
  }

  MapController mapController(WidgetTester tester) =>
      tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;

  Future<void> finishCamera(WidgetTester tester) async {
    // The route effects intentionally keep scheduling frames in active mode.
    // Advance the finite camera animation without waiting for those to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pump();
  }

  testWidgets('returning to map refreshes the selected resident area',
      (tester) async {
    await loadFonts(tester);
    AppStore.setIdentity(null);
    await AppStore.setBarangay('Barangay 1');
    final active = ValueNotifier(false);
    addTearDown(active.dispose);
    await tester.pumpWidget(MaterialApp(
        home: ValueListenableBuilder<bool>(
            valueListenable: active,
            builder: (context, value, _) => LiveMapScreen(
                isActive: value,
                enableGps: false,
                enableTiles: false,
                repository: _EmptyTruckRepository()))));
    await tester.pump();
    await AppStore.setBarangay('Barangay 2 (Poblacion)');
    active.value = true;
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byTooltip('Fit active route'));
    await finishCamera(tester);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.mapController!.camera.center.latitude, closeTo(9.7508, .00001));
    expect(
        map.mapController!.camera.center.longitude, closeTo(122.4050, .00001));
    expect(find.bySemanticsLabel('Your private GPS location'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final hour in [9, 19]) {
    testWidgets(
        'map controls and sheet fit 320px ${hour == 9 ? "day" : "night"} view',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadFonts(tester);
      await tester.pumpWidget(MaterialApp(
          home: SundoTimeScope(
              mood: SundoTimeMood(DateTime(2026, 10, 4, hour)),
              child: const LiveMapScreen(
                  isActive: false,
                  enableGps: false,
                  enableTiles: false,
                  repository: _PublishedTruckRepository()))));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Live Truck Tracking'), findsNothing);
      final north = find.byTooltip('Reset map north');
      final fit = find.byTooltip('Fit active route');
      expect(north.hitTestable(), findsOneWidget);
      expect(fit.hitTestable(), findsOneWidget);
      final northBounds = tester.getRect(north);
      final fitBounds = tester.getRect(fit);
      expect(northBounds.center.dy, closeTo(fitBounds.center.dy, .1));
      expect(northBounds.right, lessThanOrEqualTo(fitBounds.left));
      expect(northBounds.left, greaterThanOrEqualTo(0));
      expect(fitBounds.right, lessThanOrEqualTo(320));
      expect(find.bySemanticsLabel('Your private GPS location'), findsNothing);
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final startingZoom = map.mapController!.camera.zoom;
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(map.mapController!.camera.zoom, greaterThan(startingZoom));
      await tester.tap(find.byTooltip('Map layers'));
      await tester.pumpAndSettle();
      expect(find.text('Numbered collection points'), findsOneWidget);
      expect(find.text('Operational routes are managed by the city.'),
          findsNothing);
      await tester.tap(find.widgetWithText(SwitchListTile, 'Active route'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('2D and 3D change the ground plane while north resets bearing',
      (tester) async {
    await mountMap(tester);
    final initialPlane = tester
        .widget<Transform>(find.byKey(const ValueKey('map-perspective')))
        .transform;
    expect(initialPlane.entry(3, 2).abs(), greaterThan(0));
    expect(initialPlane.entry(1, 2).abs(), greaterThan(0));

    await tester.tap(find.text('2D'));
    await finishCamera(tester);
    final flatPlane = tester
        .widget<Transform>(find.byKey(const ValueKey('map-perspective')))
        .transform;
    for (var i = 0; i < 16; i++) {
      expect(flatPlane.storage[i], closeTo(i % 5 == 0 ? 1 : 0, .000001));
    }
    expect(mapController(tester).camera.rotation % 360, closeTo(0, .0001));

    await tester.tap(find.text('3D'));
    await finishCamera(tester);
    final raisedPlane = tester
        .widget<Transform>(find.byKey(const ValueKey('map-perspective')))
        .transform;
    expect(raisedPlane.entry(3, 2).abs(), greaterThan(0));
    expect(mapController(tester).camera.rotation % 360, closeTo(342, .0001));

    await tester.tap(find.byTooltip('Reset map north'));
    await finishCamera(tester);
    expect(mapController(tester).camera.rotation % 360, closeTo(0, .0001));
    expect(
        tester
            .widget<Transform>(find.byKey(const ValueKey('map-perspective')))
            .transform
            .entry(3, 2)
            .abs(),
        greaterThan(0));

    final zoom = mapController(tester).camera.zoom;
    await tester.tap(find.byTooltip('Zoom in'));
    await finishCamera(tester);
    expect(mapController(tester).camera.zoom, closeTo(zoom + 1, .0001));
    await tester.tap(find.byTooltip('Zoom out'));
    await finishCamera(tester);
    expect(mapController(tester).camera.zoom, closeTo(zoom, .0001));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('watch can stop and dragging the tilted map cancels following',
      (tester) async {
    await mountMap(tester);
    await tester.tap(find.text('Watch'));
    await finishCamera(tester);
    expect(find.text('Watching'), findsOneWidget);
    expect(mapController(tester).camera.zoom, closeTo(16.5, .0001));

    await tester.tap(find.text('Watching'));
    await tester.pump();
    expect(find.text('Watch'), findsOneWidget);
    expect(find.text('Watching'), findsNothing);

    await tester.tap(find.text('Watch'));
    await finishCamera(tester);
    final beforeDrag = mapController(tester).camera.center;
    await tester.dragFrom(const Offset(90, 390), const Offset(70, 45));
    await tester.pump(const Duration(milliseconds: 300));
    final afterDrag = mapController(tester).camera.center;
    expect(
        (beforeDrag.latitude - afterDrag.latitude).abs() +
            (beforeDrag.longitude - afterDrag.longitude).abs(),
        greaterThan(.00001));
    expect(find.text('Watching'), findsNothing);
    expect(find.text('Watch'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tapping an elevated collection point focuses its actual stop',
      (tester) async {
    await mountMap(tester);
    await tester.tap(find.text('Watch'));
    await finishCamera(tester);
    expect(find.text('Watching'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('collection-stop-1')));
    await finishCamera(tester);

    final selected = tester.widget<SundoClayCollectionMarker>(
        find.byType(SundoClayCollectionMarker));
    expect(selected.selected, isTrue);
    expect(
        mapController(tester).camera.center.latitude, closeTo(9.7530, .00001));
    expect(mapController(tester).camera.center.longitude,
        closeTo(122.4042, .00001));
    expect(mapController(tester).camera.zoom, closeTo(16.8, .0001));
    expect(find.text('Watching'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stale truck fixes disable watch and moving route hints',
      (tester) async {
    await mountMap(tester,
        repository: const _PublishedTruckRepository(stale: true));
    final watchButton = tester.widget<TextButton>(find
        .ancestor(
            of: find.text('Watch'),
            matching: find.byWidgetPredicate((widget) => widget is TextButton))
        .first);
    expect(watchButton.onPressed, isNull);
    expect(
        tester
            .widget<SundoMapTruckMarker>(find.byType(SundoMapTruckMarker))
            .fresh,
        isFalse);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);
    expect(find.text('Last known position'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion avoids recurring frames and camera travel',
      (tester) async {
    await mountMap(tester, reducedMotion: true);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.tap(find.text('Watch'));
    await tester.pump();
    expect(mapController(tester).camera.zoom, closeTo(16.5, .0001));
    await tester.tap(find.text('2D'));
    await tester.pump();
    expect(
        tester
            .widget<Transform>(find.byKey(const ValueKey('map-perspective')))
            .transform
            .entry(3, 2),
        0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('saved address coordinates never become a live GPS beacon',
      (tester) async {
    await AppStore.setBarangay('Saved coastal address');
    await AppStore.setResidentLocation(
        latitude: 9.7513, longitude: 122.4024, accuracy: 7);
    await mountMap(tester,
        repository: _EmptyTruckRepository(), reducedMotion: true);
    await tester.tap(find.byTooltip('Fit active route'));
    await tester.pump();
    expect(
        mapController(tester).camera.center.latitude, closeTo(9.7513, .00001));
    expect(mapController(tester).camera.center.longitude,
        closeTo(122.4024, .00001));
    expect(find.byType(SundoResidentBeacon), findsNothing);
    expect(find.bySemanticsLabel('Your private GPS location'), findsNothing);
    expect(find.text('Your Location · private'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'truck rolls only between source fixes and preserves unknown heading',
      (tester) async {
    final repository = _ControlledTruckRepository();
    await mountMap(tester, repository: repository);
    try {
      SundoMapTruckMarker truck() =>
          tester.widget<SundoMapTruckMarker>(find.byType(SundoMapTruckMarker));
      Marker marker() => tester
          .widget<MarkerLayer>(find
              .ancestor(
                  of: find.byType(SundoMapTruckMarker),
                  matching: find.byType(MarkerLayer))
              .first)
          .markers
          .last;
      expect(truck().headingDegrees, isNull,
          reason: 'An active first fix does not establish compass direction.');
      expect(truck().moving, isFalse);

      const previous = LatLng(9.7525, 122.4038);
      const next = LatLng(9.7531, 122.4041);
      repository.publish(next);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(truck().moving, isTrue);
      expect(
          truck().headingDegrees, closeTo(mapBearing(previous, next), .0001));
      expect(marker().point.latitude, greaterThan(previous.latitude));
      expect(marker().point.latitude, lessThan(next.latitude));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(marker().point, next);
      expect(truck().moving, isFalse);

      const replacement = LatLng(9.7490, 122.4050);
      repository.publish(replacement, id: 'Truck 03');
      await tester.pump();
      await tester.pump();
      expect(marker().point, replacement,
          reason:
              'Replacing trucks must not animate across unrelated GPS fixes.');
      expect(truck().headingDegrees, isNull);
      expect(truck().moving, isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(repository.dispose);
      await tester.pump();
    }
  });

  testWidgets('pausing map effects keeps published GPS tracking live',
      (tester) async {
    final repository = _ControlledTruckRepository();
    await mountMap(tester, repository: repository);
    try {
      SundoMapTruckMarker truck() =>
          tester.widget<SundoMapTruckMarker>(find.byType(SundoMapTruckMarker));
      MarkerLayer arrows() => tester.widget<MarkerLayer>(find.byWidgetPredicate(
          (widget) => widget is MarkerLayer && !widget.rotate));
      final firstPulse = truck().pulse;
      final firstArrow = arrows().markers.first.point;
      await tester.pump(const Duration(milliseconds: 700));
      expect(truck().pulse, isNot(closeTo(firstPulse, .0001)));
      final advancedArrow = arrows().markers.first.point;
      expect(
          (advancedArrow.latitude - firstArrow.latitude).abs() +
              (advancedArrow.longitude - firstArrow.longitude).abs(),
          greaterThan(.000001));

      await tester.tap(find.text('Watch'));
      await finishCamera(tester);
      await tester.tap(find.byTooltip('Map layers'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(
          find.widgetWithText(SwitchListTile, 'Animate route and beacons'));
      await tester.pump();
      expect(
          tester
              .widget<SwitchListTile>(find.widgetWithText(
                  SwitchListTile, 'Animate route and beacons'))
              .value,
          isFalse);
      await tester.tapAt(const Offset(10, 50));
      // Settling is safe once the user has disabled continuous visual effects.
      await tester.pumpAndSettle(const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
      final pausedPulse = truck().pulse;
      expect(truck().moving, isFalse);
      final pausedArrow = arrows().markers.first.point;
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(truck().pulse, pausedPulse);
      expect(arrows().markers.first.point, pausedArrow);
      expect(tester.binding.hasScheduledFrame, isFalse);

      const updated = LatLng(9.7531, 122.4041);
      repository.publish(updated);
      await tester.pump();
      await tester.pump();
      final vehicleLayer = tester.widget<MarkerLayer>(find
          .ancestor(
              of: find.byType(SundoMapTruckMarker),
              matching: find.byType(MarkerLayer))
          .first);
      expect(vehicleLayer.markers.last.point, updated);
      expect(truck().moving, isFalse);
      expect(mapController(tester).camera.center.latitude,
          closeTo(updated.latitude, .000001));
      expect(mapController(tester).camera.center.longitude,
          closeTo(updated.longitude, .000001));
      expect(find.text('Watching'), findsOneWidget);
      expect(truck().pulse, pausedPulse);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(repository.dispose);
      await tester.pump();
    }
  });

  testWidgets(
      'map wheels pause for OS dialogs and background without losing fixes',
      (tester) async {
    final repository = _ControlledTruckRepository();
    await mountMap(tester, repository: repository);
    try {
      SundoMapTruckMarker truck() =>
          tester.widget<SundoMapTruckMarker>(find.byType(SundoMapTruckMarker));
      Marker marker() => tester
          .widget<MarkerLayer>(find
              .ancestor(
                  of: find.byType(SundoMapTruckMarker),
                  matching: find.byType(MarkerLayer))
              .first)
          .markers
          .last;
      var latitude = 9.7525;
      for (final lifecycle in [
        AppLifecycleState.inactive,
        AppLifecycleState.paused
      ]) {
        latitude += .0004;
        repository.publish(LatLng(latitude, 122.4038));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(truck().moving, isTrue);
        expect(tester.binding.hasScheduledFrame, isTrue);

        tester.binding.handleAppLifecycleStateChanged(lifecycle);
        await tester.pump();
        final paused = truck().pulse;
        expect(truck().moving, isFalse);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(truck().pulse, paused);

        // Operational updates continue while visual effects are paused. Flutter
        // intentionally skips painting while fully backgrounded; verify that
        // pending fixes appear immediately on return rather than forcing frames.
        latitude += .0004;
        final currentFix = LatLng(latitude, 122.4038);
        repository.publish(currentFix);
        await tester.pump();
        await tester.pump();
        if (lifecycle == AppLifecycleState.inactive) {
          expect(marker().point, currentFix);
        } else {
          expect(tester.binding.framesEnabled, isFalse);
        }
        expect(truck().moving, isFalse);
        expect(truck().pulse, paused);
        expect(tester.binding.hasScheduledFrame, isFalse);

        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(marker().point, currentFix,
            reason: 'The latest operational fix must survive backgrounding.');
        expect(tester.binding.hasScheduledFrame, isTrue);
        expect(truck().pulse, isNot(closeTo(paused, .0001)));
        expect(truck().moving, isFalse,
            reason: 'Returning alone must not invent vehicle travel.');
      }
      expect(tester.takeException(), isNull);
    } finally {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(repository.dispose);
      await tester.pump();
    }
  });

  testWidgets('approaching alert fits narrow night view and buttons work',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadFonts(tester);
    var viewed = false;
    await tester.pumpWidget(MaterialApp(
        home: SundoTimeScope(
            mood: SundoTimeMood(DateTime(2026, 10, 4, 19)),
            child: TruckAlertModal(
                etaMinutes: 10,
                simulated: true,
                onViewTruck: () => viewed = true,
                onDismiss: () {}))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('DEMO · simulated arrival'), findsOneWidget);
    await tester.tap(find.text('View Truck'));
    expect(viewed, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
