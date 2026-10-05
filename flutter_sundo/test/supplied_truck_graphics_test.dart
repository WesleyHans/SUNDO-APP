import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/shared/widgets/sundo_graphics.dart';

void main() {
  testWidgets('supplied trucks keep their original image dimensions',
      (tester) async {
    await tester.runAsync(() async {
      for (final (asset, size) in [
        (sundoSideTruckAsset, const Size(1536, 1024)),
        (sundoMapTruckAsset, const Size(1254, 1254)),
      ]) {
        final bytes = await rootBundle.load(asset);
        final codec =
            await ui.instantiateImageCodec(bytes.buffer.asUint8List());
        try {
          final frame = await codec.getNextFrame();
          try {
            expect(
                Size(frame.image.width.toDouble(),
                    frame.image.height.toDouble()),
                size);
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      }
    });
  });

  testWidgets('truck artwork fits narrow icon slots and has one readable label',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 44,
            height: 36,
            child: SundoTruckGraphic(),
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      await precacheImage(const AssetImage(sundoSideTruckAsset),
          tester.element(find.byType(SundoVehicleGraphic)));
    });
    await tester.pump();
    expect(
        tester.getSize(find.byType(SundoVehicleGraphic)), const Size(44, 36));
    expect(find.bySemanticsLabel('SUNDO garbage collection truck'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('only silver rims change when externally driven wheels rotate',
      (tester) async {
    const boundaryKey = ValueKey('truck-pixels');

    Future<Uint8List> frame(double phase, {bool moving = true}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: ColoredBox(
                color: const Color(0xFFF1F8EE),
                child: SundoVehicleGraphic(
                  width: 384,
                  height: 256,
                  moving: moving,
                  wheelPhase: phase,
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.runAsync(() async {
        await precacheImage(const AssetImage(sundoSideTruckAsset),
            tester.element(find.byType(SundoVehicleGraphic)));
      });
      await tester.pump();
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
      final pixels = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return bytes!.buffer.asUint8List();
      });
      return pixels!;
    }

    final original = await frame(0, moving: false);
    final stopped = await frame(.25, moving: false);
    expect(stopped, orderedEquals(original));
    final rotating = await frame(.25);
    var changedRimPixels = 0;
    // The actual supplied silver rims sit inside these two image regions.
    const allowed = [
      Rect.fromLTWH(74, 179, 39, 40),
      Rect.fromLTWH(290, 179, 39, 40)
    ];
    for (var y = 0; y < 256; y++) {
      for (var x = 0; x < 384; x++) {
        final index = (y * 384 + x) * 4;
        var changed = false;
        for (var channel = 0; channel < 4; channel++) {
          changed |= original[index + channel] != rotating[index + channel];
        }
        if (!changed) continue;
        expect(
            allowed.any(
                (rect) => rect.contains(Offset(x.toDouble(), y.toDouble()))),
            isTrue,
            reason: 'Truck body changed outside its rims at $x, $y.');
        changedRimPixels++;
      }
    }
    expect(changedRimPixels, greaterThan(50));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion disables spinning and invalid phase stays safe',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: SundoVehicleGraphic(
              mapView: true,
              moving: true,
              wheelPhase: double.nan,
            ),
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      await precacheImage(const AssetImage(sundoMapTruckAsset),
          tester.element(find.byType(SundoVehicleGraphic)));
    });
    await tester.pump();
    expect(find.byKey(const ValueKey('sundo-truck-rim-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
    testWidgets('review supplied truck rim animation in native Flutter',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(780, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const boundaryKey = ValueKey('truck-preview');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: const Color(0xFFF1F8EE),
              child: Column(children: [
                for (final phase in [0.0, .125, .25, .375])
                  Row(children: [
                    SundoVehicleGraphic(
                        width: 420,
                        height: 135,
                        moving: true,
                        wheelPhase: phase),
                    SundoVehicleGraphic(
                        mapView: true,
                        width: 170,
                        height: 135,
                        moving: true,
                        wheelPhase: phase),
                    const SundoTruckGraphic(width: 44, height: 36),
                  ]),
              ]),
            ),
          ),
        ),
      ));
      await tester.runAsync(() async {
        final context = tester.element(find.byKey(boundaryKey));
        await precacheImage(const AssetImage(sundoSideTruckAsset), context);
        await precacheImage(const AssetImage(sundoMapTruckAsset), context);
      });
      await tester.pump();
      await expectLater(find.byKey(boundaryKey),
          matchesGoldenFile('goldens/supplied_truck_rims.png'));
      expect(tester.takeException(), isNull);
    });
  }
}
