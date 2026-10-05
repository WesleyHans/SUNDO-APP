import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/features/live_map/widgets/clay_map_markers.dart';

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

  testWidgets('truck headings and external phase repaint the native vehicle',
      (tester) async {
    Future<CustomPainter> painter(double heading, double phase) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SundoMapTruckMarker(headingDegrees: heading, pulse: phase),
          ),
        ),
      ));
      return tester
          .widget<CustomPaint>(find.descendant(
              of: find.byType(SundoMapTruckMarker),
              matching: find.byType(CustomPaint)))
          .painter!;
    }

    final north = await painter(0, 0);
    final same = await painter(0, 0);
    final east = await painter(90, 0);
    final nextFrame = await painter(90, .5);
    expect(same.shouldRepaint(north), isFalse);
    expect(east.shouldRepaint(north), isTrue);
    expect(nextFrame.shouldRepaint(east), isTrue);
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
