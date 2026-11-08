import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/features/live_map/widgets/clay_map_markers.dart';
import 'package:sundo_sipalay/repositories/map_truck_repository.dart';

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

  testWidgets('stationary and stale fleet status remain accessible',
      (tester) async {
    final semantics = tester.ensureSemantics();
    for (final fresh in [true, false]) {
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: SundoMapTruckMarker(
                  headingDegrees: 90, fresh: fresh, moving: false))));
      expect(
          find.bySemanticsLabel(fresh
              ? 'Collection truck, stopped'
              : 'Collection truck, last known position'),
          findsOneWidget);
      expect(tester.getSize(find.byType(SundoMapTruckMarker)),
          const Size(100, 100));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
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
          SundoUserHouseMarker(pulse: double.nan),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('area and GPS markers announce their source and allow stop taps',
      (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    for (final (marker, label) in const [
      (SundoUserHouseMarker(), 'Approximate home area'),
      (SundoResidentBeacon(), 'Your private GPS location'),
    ]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Stack(alignment: Alignment.center, children: [
              GestureDetector(
                onTap: () => taps++,
                child: const SundoClayCollectionMarker(number: 1),
              ),
              marker,
            ]),
          ),
        ),
      ));
      expect(find.bySemanticsLabel(label), findsOneWidget);
      expect(tester.getSize(find.byWidget(marker)), const Size(72, 90));
      await tester.tap(find.byType(SundoClayCollectionMarker));
    }
    expect(taps, 2);
    semantics.dispose();
  });

  test('sample collection stops are positioned on route waypoints', () {
    for (final route in MockMapTruckRepository.routes) {
      for (final stop in route.collectionPoints) {
        expect(route.waypoints.contains(stop.position), isTrue);
      }
    }
  });
}
