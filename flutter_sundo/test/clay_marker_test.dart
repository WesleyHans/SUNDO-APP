import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/features/live_map/widgets/clay_map_markers.dart';
import 'package:sundo_sipalay/shared/widgets/sundo_graphics.dart';

void main() {
  testWidgets('collection markers announce their number and selection',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SundoClayCollectionMarker(
              number: 12, name: 'Public collection pavilion', selected: true),
        ),
      ),
    ));

    expect(
        find.bySemanticsLabel(
            'Collection point 12, Public collection pavilion'),
        findsOneWidget);
    expect(tester.getSize(find.byType(SundoClayCollectionMarker)),
        const Size(72, 90));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
      'telemetry turns the supplied truck and externally drives its rims',
      (tester) async {
    Future<SundoVehicleGraphic> vehicle(double heading, double phase,
        {bool moving = true}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SundoMapTruckMarker(
                headingDegrees: heading, pulse: phase, moving: moving),
          ),
        ),
      ));
      return tester
          .widget<SundoVehicleGraphic>(find.byType(SundoVehicleGraphic));
    }

    List<double> bearingMatrix() => tester
        .widget<Transform>(find.byKey(const ValueKey('supplied-truck-bearing')))
        .transform
        .storage
        .toList();
    await vehicle(0, 0);
    final north = bearingMatrix();
    await vehicle(0, 0);
    expect(bearingMatrix(), orderedEquals(north));
    await vehicle(90, 0);
    final east = bearingMatrix();
    expect(east, isNot(orderedEquals(north)));
    final nextFrame = await vehicle(90, .5);
    expect(bearingMatrix(), orderedEquals(east));
    expect(nextFrame.moving, isTrue);
    expect(nextFrame.wheelPhase, .5);
    final body =
        tester.widget<Image>(find.byKey(const ValueKey('sundo-truck-body')));
    expect((body.image as AssetImage).assetName, sundoMapTruckAsset);
    expect(find.byKey(const ValueKey('sundo-truck-rim-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('sundo-truck-rim-1')), findsOneWidget);
    final stationary = await vehicle(90, .75, moving: false);
    expect(stationary.moving, isFalse);
    expect(stationary.wheelPhase, 0);
    expect(find.byKey(const ValueKey('sundo-truck-rim-0')), findsNothing);
    expect(
        tester.getSize(find.byType(SundoMapTruckMarker)), const Size(100, 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown headings and malformed phases remain safe to render',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Row(children: [
          SundoMapTruckMarker(
              headingDegrees: double.nan,
              mapRotationDegrees: double.infinity,
              pulse: double.nan,
              fresh: false),
          SundoClayCollectionMarker(number: 2, pulse: double.infinity),
          SundoResidentBeacon(pulse: -4),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
