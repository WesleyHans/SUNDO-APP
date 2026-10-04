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

class _EmptyTruckRepository implements MapTruckRepository {
  @override
  Stream<List<MapTruckSnapshot>> watchTrucks() => Stream.value([]);
}

class _PublishedTruckRepository implements MapTruckRepository {
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
                      1, 'Collection point 1', LatLng(9.7535, 122.404))
                ]),
            updatedAt: DateTime.now(),
            etaMinutes: 8,
            active: true,
            stage: MapTrackingStage.onRoute,
            nextStop: 'Barangay 1',
            currentArea: 'Sipalay City'),
      ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> loadFonts(WidgetTester tester) => tester.runAsync(() async {
        for (final weight in FontWeight.values) {
          GoogleFonts.outfit(fontWeight: weight);
          GoogleFonts.plusJakartaSans(fontWeight: weight);
        }
        await GoogleFonts.pendingFonts();
      });

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
    await tester.tap(find.byTooltip('Re-center active route'));
    await tester.pump();
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
              child: LiveMapScreen(
                  isActive: false,
                  enableGps: false,
                  enableTiles: false,
                  repository: _PublishedTruckRepository()))));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Live Truck Tracking'), findsOneWidget);
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
