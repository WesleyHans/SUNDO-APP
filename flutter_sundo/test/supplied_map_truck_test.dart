import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/features/live_map/widgets/clay_map_markers.dart';
import 'package:sundo_sipalay/shared/widgets/directional_truck.dart';

void main() {
  test('direction selection covers all sixteen headings and north wrap', () {
    for (var i = 0; i < 16; i++) {
      expect(truckDirectionIndex(i * 22.5), i);
      expect(truckDirectionIndex(i * 22.5 + 360), i);
      expect(truckDirectionIndex(i * 22.5 - 360), i);
    }
    expect(truckDirectionIndex(359), 0);
    expect(truckDirectionIndex(1), 0);
    expect(truckDirectionIndex(double.nan), 8);
    expect(truckScreenHeading(270, 90), 0);
    expect(truckScreenHeading(0, -90), 270);
  });
  test('calibrated front vector follows GPS on a rotated map', () {
    for (final heading in [0.0, 23.0, 90.0, 180.0, 270.0, 359.0]) {
      for (final camera in [-90.0, 0.0, 30.0, 360.0]) {
        final screen = truckScreenHeading(heading, camera);
        final index = truckDirectionIndex(screen);
        final front = truckIllustratedBearings[index] * math.pi / 180;
        final correction = truckDirectionCorrection(screen, index);
        expect(math.sin(front + correction),
            closeTo(math.sin(screen * math.pi / 180), 1e-9));
        expect(math.cos(front + correction),
            closeTo(math.cos(screen * math.pi / 180), 1e-9));
      }
    }
  });
  testWidgets('turns select different artwork, keep GPS bounds and settle',
      (tester) async {
    Future<void> mount(double? heading,
        {bool fresh = true, bool reduced = false}) async {
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: reduced),
                  child: Center(
                      child: SizedBox.square(
                          dimension: 84,
                          child: SundoMapTruckMarker(
                              headingDegrees: heading,
                              fresh: fresh,
                              moving: true)))))));
      await tester.runAsync(() async {
        final context = tester.element(find.byType(SundoMapTruckMarker));
        for (var i = 0; i < 16; i++) {
          await precacheImage(
              ResizeImage(AssetImage(truckDirectionAsset(i)), width: 256),
              context);
        }
      });
      await tester.pumpAndSettle();
    }

    String asset() {
      final image = tester.widget<Image>(find.descendant(
          of: find.byType(SundoDirectionalTruck),
          matching: find.byType(Image)));
      return ((image.image as ResizeImage).imageProvider as AssetImage)
          .assetName;
    }

    await mount(0);
    expect(asset(), endsWith('truck_000.png'));
    await mount(90);
    expect(asset(), endsWith('truck_090.png'));
    await mount(180, reduced: true);
    expect(asset(), endsWith('truck_180.png'));
    await mount(270, fresh: false);
    expect(asset(), endsWith('truck_270.png'));
    expect(
        tester.getSize(find.byType(SundoMapTruckMarker)), const Size(84, 84));
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('missing heading remains described as unavailable',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: SundoMapTruckMarker()));
    expect(
        find.bySemanticsLabel(RegExp('heading unavailable')), findsOneWidget);
    expect(
        tester
            .widget<SundoDirectionalTruck>(find.byType(SundoDirectionalTruck))
            .headingDegrees,
        isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });
}
