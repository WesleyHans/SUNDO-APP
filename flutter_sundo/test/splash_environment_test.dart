import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/splash/splash_screen.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';
import 'package:sundo_sipalay/shared/widgets/sundo_graphics.dart';
import 'package:sundo_sipalay/shared/widgets/time_based_background.dart';

const _previewKey = ValueKey('splash-environment-preview');
const _slogan = 'Track. Prepare. Collect.';
const _communitySlogan = 'Together for a cleaner Sipalay';

final _environments = <String, SundoTimeMood>{
  'morning': SundoTimeMood(DateTime(2026, 10, 5, 8)),
  'noon': SundoTimeMood(DateTime(2026, 10, 5, 12, 30)),
  'sunset': SundoTimeMood(DateTime(2026, 10, 5, 17)),
  'night': SundoTimeMood(DateTime(2026, 10, 5, 20)),
  'rainy': SundoTimeMood(DateTime(2026, 10, 5, 14), raining: true),
};

Future<void> _loadFonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final weight in FontWeight.values) {
      GoogleFonts.outfit(fontWeight: weight);
      GoogleFonts.plusJakartaSans(fontWeight: weight);
    }
    await GoogleFonts.pendingFonts();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
}

Future<void> _pumpSplash(
  WidgetTester tester,
  SundoTimeMood mood,
  Size size, {
  Duration elapsed = const Duration(milliseconds: 950),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(MaterialApp(
    theme: buildSundoTheme(mood),
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        devicePixelRatio: 1,
        padding: const EdgeInsets.only(top: 24, bottom: 24),
        viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
      ),
      child: SundoTimeScope(
        mood: mood,
        child: RepaintBoundary(
          key: _previewKey,
          child: SplashScreen(onContinue: () {}),
        ),
      ),
    ),
  ));
  await tester.runAsync(() async {
    await GoogleFonts.pendingFonts();
    final context = tester.element(find.byKey(_previewKey));
    // Production keeps its previous scene until the requested asset decodes.
    // Await that same image stream before advancing the transition clock.
    await precacheImage(
        AssetImage(sundoEnvironmentArtwork(mood.environment)), context);
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, context);
    }
  });
  await tester.pump();
  await tester.pump(elapsed);
  expect(tester.takeException(), isNull);
}

Finder get _sloganCardDecoration => find
    .ancestor(of: find.text(_slogan), matching: find.byType(DecoratedBox))
    .first;

Map<String, Object?> _fixedBranding(WidgetTester tester) {
  final logo = tester.widget<SundoLogoGraphic>(find.byType(SundoLogoGraphic));
  final brand = tester.widget<Image>(find.descendant(
    of: find.byType(SundoBrandMark),
    matching: find.byType(Image),
  ));
  return {
    'logoRect': tester.getRect(find.byType(SundoLogoGraphic)),
    'brandRect': tester.getRect(find.byType(SundoBrandMark)),
    'logoSize': logo.size,
    'subtitleVisible': logo.showSubtitle,
    'brandAsset': (brand.image as AssetImage).assetName,
    'brandFit': brand.fit,
    'brandColor': brand.color,
    'leaves': [
      for (final leaf in find.byType(LeafSprig).evaluate())
        tester.getRect(find.byWidget(leaf.widget)),
    ],
    'leafSizes': [
      for (final leaf in tester.widgetList<LeafSprig>(find.byType(LeafSprig)))
        (leaf.size, leaf.flipped),
    ],
    'titleRect': tester.getRect(find.text('SUNDO')),
    'titleStyle': tester.widget<Text>(find.text('SUNDO')).style,
    'subtitleRect': tester.getRect(find.text('Smart Urban Navigation')),
    'subtitleStyle':
        tester.widget<Text>(find.text('Smart Urban Navigation')).style,
    'subtitleSecondRect':
        tester.getRect(find.text('for Dynamic Waste Operations')),
    'subtitleSecondStyle':
        tester.widget<Text>(find.text('for Dynamic Waste Operations')).style,
    'cardRect': tester.getRect(_sloganCardDecoration),
    'cardDecoration':
        tester.widget<DecoratedBox>(_sloganCardDecoration).decoration,
    'sloganRect': tester.getRect(find.text(_slogan)),
    'sloganStyle': tester.widget<Text>(find.text(_slogan)).style,
    'communityRect': tester.getRect(find.text(_communitySlogan)),
    'communityStyle': tester.widget<Text>(find.text(_communitySlogan)).style,
  };
}

Future<Uint8List> _fixedZonePixels(WidgetTester tester, double bottom) async {
  final boundary = tester
      .firstState(find.byType(SplashScreen))
      .context
      .findAncestorRenderObjectOfType<RenderRepaintBoundary>()!;
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final result = Uint8List.fromList(bytes!.buffer
        .asUint8List(bytes.offsetInBytes, image.width * bottom.floor() * 4));
    image.dispose();
    return result;
  });
  return pixels!;
}

Finder get _environmentImages => find.byWidgetPredicate((widget) =>
    widget is Image &&
    widget.image is AssetImage &&
    (widget.image as AssetImage).assetName.contains('environment-'));

Map<String, Object?> _sceneGeometry(WidgetTester tester) {
  final image = tester.widget<Image>(_environmentImages);
  return {
    'imageRect': tester.getRect(_environmentImages),
    'fit': image.fit,
    'alignment': image.alignment,
    'imageColor': image.color,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets(
        'branding, corner leaves and card stay fixed in all five environments at $size',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _loadFonts(tester);
      Map<String, Object?>? original;
      Map<String, Object?>? originalScene;
      Uint8List? originalPixels;
      for (final environment in _environments.entries) {
        await _pumpSplash(tester, environment.value, size);
        final current = _fixedBranding(tester);
        original ??= current;
        expect(current, equals(original), reason: environment.key);
        expect(_environmentImages, findsOneWidget);
        final scene = _sceneGeometry(tester);
        originalScene ??= scene;
        expect(scene, equals(originalScene), reason: environment.key);
        expect(scene['fit'], BoxFit.fitWidth);
        expect(scene['alignment'], const Alignment(0, .35));
        expect(scene['imageColor'], isNull);
        final sceneImage = tester.widget<Image>(_environmentImages);
        expect((sceneImage.image as AssetImage).assetName,
            sundoEnvironmentArtwork(environment.value.environment));
        final pixels = await _fixedZonePixels(
            tester, (current['logoRect']! as Rect).bottom);
        originalPixels ??= pixels;
        expect(pixels, orderedEquals(originalPixels),
            reason:
                'Fixed branding pixels must not change in ${environment.key}');

        expect(find.byType(SundoBrandMark), findsOneWidget);
        expect(current['logoSize'], 135);
        expect(current['subtitleVisible'], isTrue);
        expect(current['brandAsset'], sundoBrandLogoAsset);
        expect(current['brandColor'], isNull);
        expect(current['brandFit'], BoxFit.contain);
        final brandRect = current['brandRect']! as Rect;
        expect(brandRect.top, 79);
        expect(brandRect.width, 202.5);
        expect(brandRect.center.dx, size.width / 2);
        expect(current['leaves'], [
          const Rect.fromLTWH(-22, 25, 120, 120),
          Rect.fromLTWH(size.width - 50, 100, 85, 85),
        ]);
        expect(current['leafSizes'], [(120.0, true), (85.0, false)]);

        final cardRect = current['cardRect']! as Rect;
        expect(cardRect.bottom, size.height - 24 - 26);
        expect(cardRect.left, greaterThanOrEqualTo(26));
        expect(cardRect.right, lessThanOrEqualTo(size.width - 26));
        expect((current['subtitleSecondRect']! as Rect).bottom,
            lessThan(cardRect.top));
        expect(
            find.ancestor(
              of: find.byType(SundoBrandMark),
              matching: find.byType(ColorFiltered),
            ),
            findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('branding remains fixed throughout an environment fade',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadFonts(tester);
    const size = Size(390, 844);
    await _pumpSplash(tester, _environments['morning']!, size);
    final before = _fixedBranding(tester);
    await _pumpSplash(tester, _environments['rainy']!, size,
        elapsed: const Duration(milliseconds: 200));
    expect(_environmentImages, findsNWidgets(2));
    expect(_fixedBranding(tester), before);
    await tester.pump(const Duration(milliseconds: 250));
    expect(_fixedBranding(tester), before);
    await tester.pump(const Duration(milliseconds: 800));
    expect(_environmentImages, findsOneWidget);
    expect(_fixedBranding(tester), before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('all environment assets preserve the same source framing',
      (tester) async {
    final dimensions = await tester.runAsync(() async {
      final result = <Size>[];
      for (final environment in SundoEnvironment.values) {
        final bytes =
            await rootBundle.load(sundoEnvironmentArtwork(environment));
        final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
        final frame = await codec.getNextFrame();
        result.add(
            Size(frame.image.width.toDouble(), frame.image.height.toDouble()));
        frame.image.dispose();
        codec.dispose();
      }
      return result;
    });
    expect(dimensions, hasLength(5));
    expect(dimensions!.toSet(), hasLength(1));
    expect(dimensions.first.aspectRatio, closeTo(2 / 3, .001));
  });

  for (final environment in _environments.entries) {
    testWidgets('splash ${environment.key} visual preview', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final originalShadows = debugDisableShadows;
      debugDisableShadows = false;
      await _loadFonts(tester);
      await _pumpSplash(tester, environment.value, const Size(390, 844));
      if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
        await expectLater(find.byKey(_previewKey),
            matchesGoldenFile('goldens/splash_${environment.key}.png'));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      debugDisableShadows = originalShadows;
    });
  }
}
