import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/features/live_map/widgets/clay_map_markers.dart';
import 'package:sundo_sipalay/shared/widgets/sundo_graphics.dart';

void main() {
  test('supplied truck front follows telemetry and rotated map compass', () {
    // The original artwork faces southeast. Rotate its front vector and verify
    // that it points along the actual geographic heading on the map canvas.
    const intrinsic = sundoMapTruckIntrinsicHeading * math.pi / 180;
    final front = Offset(math.sin(intrinsic), -math.cos(intrinsic));
    for (final heading in [0.0, 90.0, 180.0, 270.0, 359.0, 1.0]) {
      for (final mapRotation in [-18.0, 0.0, 30.0]) {
        final rotation = sundoMapTruckRotationRadians(heading,
            mapRotationDegrees: mapRotation);
        final rotated = Offset(
            front.dx * math.cos(rotation) - front.dy * math.sin(rotation),
            front.dx * math.sin(rotation) + front.dy * math.cos(rotation));
        final expected = (heading + mapRotation) * math.pi / 180;
        expect(rotated.dx, closeTo(math.sin(expected), 1e-9));
        expect(rotated.dy, closeTo(-math.cos(expected), 1e-9));
      }
    }
    expect(sundoMapTruckRotationRadians(null, mapRotationDegrees: 30), 0);
    expect(sundoMapTruckRotationRadians(double.nan), 0);
  });

  Future<void> mount(WidgetTester tester,
      {bool fresh = true,
      bool moving = true,
      bool reducedMotion = false,
      double? heading = 90}) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
          child: Center(
            child: SizedBox.square(
              dimension: 84,
              child: SundoMapTruckMarker(
                headingDegrees: heading,
                mapRotationDegrees: -18,
                fresh: fresh,
                moving: moving,
                pulse: .4,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      await precacheImage(const AssetImage(sundoMapTruckAsset),
          tester.element(find.byType(SundoMapTruckMarker)));
    });
    await tester.pump();
  }

  testWidgets('map uses supplied artwork within the existing GPS touch bounds',
      (tester) async {
    await mount(tester);
    final vehicle =
        tester.widget<SundoVehicleGraphic>(find.byType(SundoVehicleGraphic));
    expect(vehicle.mapView, isTrue);
    expect(vehicle.moving, isTrue);
    expect(vehicle.wheelPhase, .4);
    final body =
        tester.widget<Image>(find.byKey(const ValueKey('sundo-truck-body')));
    expect((body.image as AssetImage).assetName, sundoMapTruckAsset);
    expect(
        tester.getSize(find.byType(SundoMapTruckMarker)), const Size(84, 84));
    expect(find.byKey(const ValueKey('sundo-truck-rim-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('sundo-truck-rim-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse,
        reason: 'Truck artwork must use the caller phase, not its own ticker.');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stale, stationary and reduced-motion trucks keep wheels still',
      (tester) async {
    for (final mode in ['stale', 'stationary', 'reduced']) {
      await mount(tester,
          fresh: mode != 'stale',
          moving: mode != 'stationary',
          reducedMotion: mode == 'reduced');
      final vehicle =
          tester.widget<SundoVehicleGraphic>(find.byType(SundoVehicleGraphic));
      expect(vehicle.moving, isFalse, reason: mode);
      expect(vehicle.wheelPhase, 0, reason: mode);
      expect(find.byKey(const ValueKey('sundo-truck-rim-0')), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('unknown heading is visibly stationary and described as unknown',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await mount(tester, heading: null, moving: false);
    final transform = tester.widget<Transform>(
        find.byKey(const ValueKey('supplied-truck-bearing')));
    expect(
        transform.transform.storage, orderedEquals(Matrix4.identity().storage));
    expect(
        find.bySemanticsLabel(
            RegExp('Collection truck, stopped, heading unavailable')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });
}
