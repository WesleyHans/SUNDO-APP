import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/live_map/live_map_screen.dart';
import 'package:sundo_sipalay/models/map_tracking.dart';
import 'package:sundo_sipalay/repositories/map_truck_repository.dart';
import 'package:sundo_sipalay/shared/widgets/sundo_graphics.dart';

import 'fixtures/map_tile_fixture.dart';

class _SceneTruckRepository implements MapTruckRepository {
  @override
  Stream<List<MapTruckSnapshot>> watchTrucks() => Stream.value([
        MapTruckSnapshot(
          id: 'Truck 02',
          route: MockMapTruckRepository.routes.first,
          position: const LatLng(9.7520, 122.4038),
          updatedAt: DateTime.now(),
          heading: 146,
          etaMinutes: 8,
          distanceKm: 1.2,
          nextStop: 'Barangay 2 · sample stop',
          currentArea: 'Sipalay Poblacion',
          progress: .38,
          active: true,
          simulated: true,
          stage: MapTrackingStage.onRoute,
        ),
      ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final scene in ['day', 'night', 'flat']) {
    testWidgets('native $scene map scene fits regular and narrow phones',
        (tester) async {
      AppStore.setIdentity(null);
      await AppStore.setBarangay('Barangay 1');
      final originalShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = originalShadows);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late SipalayMapFixtureTileProvider tiles;
      await tester.runAsync(() async {
        for (final weight in FontWeight.values) {
          GoogleFonts.outfit(fontWeight: weight);
          GoogleFonts.plusJakartaSans(fontWeight: weight);
        }
        await GoogleFonts.pendingFonts();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
        tiles = await SipalayMapFixtureTileProvider.create();
      });
      final mood =
          SundoTimeMood(DateTime(2026, 10, 5, scene == 'night' ? 20 : 9));
      await tester.pumpWidget(MaterialApp(
        theme: buildSundoTheme(mood),
        home: SundoTimeScope(
          mood: mood,
          child: RepaintBoundary(
            key: const ValueKey('map-scene-preview'),
            child: Stack(children: [
              LiveMapScreen(
                isActive: false,
                enableGps: false,
                repository: _SceneTruckRepository(),
                tileProvider: tiles,
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 18,
                    color: const Color(0xFF0B302E),
                    alignment: Alignment.center,
                    child: Text(
                      'TEST BASEMAP · LOCAL FIXTURE · NOT OSM IMAGERY',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 8,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();
      if (scene == 'flat') {
        await tester.tap(find.text('2D'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.runAsync(() async {
        final context =
            tester.element(find.byKey(const ValueKey('map-scene-preview')));
        await precacheImage(const AssetImage(sundoMapTruckAsset), context);
        await precacheImage(const AssetImage(sundoSideTruckAsset), context);
        await Future.wait([
          for (final image in tiles.requestedImages.toSet())
            precacheImage(image, context),
        ]);
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Live Truck Tracking'), findsOneWidget);
      expect(find.text('Watch'), findsOneWidget);
      expect(find.bySemanticsLabel('Your private GPS location'), findsNothing);
      expect(tiles.requestedImages, isNotEmpty);
      final paintedTiles = tester
          .widgetList<RawImage>(find.descendant(
              of: find.byType(TileLayer), matching: find.byType(RawImage)))
          .where(
              (tile) => tile.image != null && (tile.opacity?.value ?? 1) > .99);
      expect(paintedTiles.length, greaterThan(4),
          reason:
              'The scene must display decoded basemap tiles, not a blank plane.');
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(
          map.mapController!.camera.center.latitude, closeTo(9.7525, .00001));
      final transform = tester
          .widget<Transform>(find.byKey(const ValueKey('map-perspective')));
      expect(transform.transform.entry(3, 2),
          scene == 'flat' ? 0 : greaterThan(0));
      if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
        await expectLater(
          find.byKey(const ValueKey('map-scene-preview')),
          matchesGoldenFile('goldens/map_scene_$scene.png'),
        );
      }
      debugDisableShadows = originalShadows;
      tester.view.physicalSize = const Size(320, 640);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('2D'), findsOneWidget);
      expect(find.text('3D'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tiles.disposeCalls, 1);
    });
  }

  testWidgets('day and night changes retain the mounted map tile provider',
      (tester) async {
    AppStore.setIdentity(null);
    late SipalayMapFixtureTileProvider tiles;
    await tester.runAsync(() async {
      for (final weight in FontWeight.values) {
        GoogleFonts.outfit(fontWeight: weight);
        GoogleFonts.plusJakartaSans(fontWeight: weight);
      }
      await GoogleFonts.pendingFonts();
      tiles = await SipalayMapFixtureTileProvider.create();
    });
    final mood = ValueNotifier(SundoTimeMood(DateTime(2026, 10, 5, 9)));
    addTearDown(mood.dispose);
    final screen = LiveMapScreen(
        isActive: false,
        enableGps: false,
        repository: _SceneTruckRepository(),
        tileProvider: tiles);
    await tester.pumpWidget(ValueListenableBuilder<SundoTimeMood>(
        valueListenable: mood,
        builder: (context, value, _) => MaterialApp(
            theme: buildSundoTheme(value),
            home: SundoTimeScope(mood: value, child: screen))));
    await tester.pump();
    final tileState = tester.state(find.byType(TileLayer));
    final controller =
        tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController;
    for (final hour in [20, 9, 20]) {
      mood.value = SundoTimeMood(DateTime(2026, 10, 5, hour));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.state(find.byType(TileLayer)), same(tileState));
      expect(tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController,
          same(controller));
      expect(tiles.disposeCalls, 0);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tiles.disposeCalls, 1);
  });
}
