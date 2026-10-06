import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/shared/widgets/directional_truck.dart';

void main() {
  testWidgets('all directional sprites decode and render on a common anchor',
      (tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final font = FontLoader('SpritePreviewFont')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'));
      await font.load();
    });
    await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
            key: const ValueKey('directional-trucks-preview'),
            child: ColoredBox(
                color: const Color(0xffedf4ef),
                child: GridView.count(crossAxisCount: 4, children: [
                  for (var index = 0; index < 16; index++)
                    Column(children: [
                      Text('${index * 22.5}°',
                          style: const TextStyle(
                              fontFamily: 'SpritePreviewFont',
                              fontSize: 16,
                              color: Color(0xff123b2a),
                              decoration: TextDecoration.none)),
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SundoDirectionalTruck(
                                  headingDegrees: index * 22.5,
                                  animate: false)))
                    ])
                ])))));
    await tester.runAsync(() async {
      final context = tester
          .element(find.byKey(const ValueKey('directional-trucks-preview')));
      for (var index = 0; index < 16; index++) {
        await precacheImage(
            ResizeImage(AssetImage(truckDirectionAsset(index)), width: 256),
            context);
      }
    });
    await tester.pumpAndSettle();
    expect(find.byType(SundoDirectionalTruck), findsNWidgets(16));
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
      await expectLater(
          find.byKey(const ValueKey('directional-trucks-preview')),
          matchesGoldenFile('goldens/directional_trucks.png'));
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
