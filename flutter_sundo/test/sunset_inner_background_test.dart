import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/app/resident_shell.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/live_map/live_map_screen.dart';
import 'package:sundo_sipalay/models/map_tracking.dart';
import 'package:sundo_sipalay/repositories/map_truck_repository.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';
import 'package:sundo_sipalay/shared/widgets/screen_transition.dart';
import 'package:sundo_sipalay/shared/widgets/time_based_background.dart';

import 'location_platform_fixture.dart';

const _preview = ValueKey('sunset-inner-preview');
const _warm = Color(0xFFFFF5DF);
final _beforeSunset = SundoTimeMood(DateTime(2026, 10, 5, 16, 59));
final _sunset = SundoTimeMood(DateTime(2026, 10, 5, 17));
final _night = SundoTimeMood(DateTime(2026, 10, 5, 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
    mockUnavailableDeviceLocation();
  });

  testWidgets('five PM warmth animates even while sunset artwork is delayed',
      (tester) async {
    final bundle = _DelayedSunsetBundle();
    final foreground = Center(
        child:
            TextButton(onPressed: () {}, child: const Text('Fixed control')));
    await tester.pumpWidget(_app(_beforeSunset, foreground, bundle: bundle));
    await _precacheScene(tester, _beforeSunset);
    await tester.pump(const Duration(seconds: 1));
    final controlRect = tester.getRect(find.text('Fixed control'));
    expect(_backgroundColor(tester), _beforeSunset.background);
    expect(_navigationColor(tester), _beforeSunset.background);

    await tester.pumpWidget(_app(_sunset, foreground, bundle: bundle));
    expect(_backgroundColor(tester), _beforeSunset.background);
    expect(_navigationColor(tester), _beforeSunset.background);
    await tester.pump(const Duration(milliseconds: 450));
    for (final color in [_backgroundColor(tester), _navigationColor(tester)]) {
      expect(color, isNot(_beforeSunset.background));
      expect(color, isNot(_warm));
    }
    await tester.pump(const Duration(milliseconds: 450));
    expect(_backgroundColor(tester), _warm);
    expect(_navigationColor(tester), _warm);
    expect(tester.getRect(find.text('Fixed control')), controlRect);
    expect(bundle.sunsetRequested, isTrue);
    expect(_environmentImages(tester), [_beforeSunset.environment]);

    await tester.pumpWidget(_app(_night, foreground, bundle: bundle));
    await _precacheScene(tester, _night);
    await tester.pump(const Duration(seconds: 1));
    expect(_backgroundColor(tester), _night.background);
    expect(_navigationColor(tester), _night.background);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('full-scene sunset preserves the original background pixels',
      (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(_app(
        _sunset,
        const SundoTimeBasedBackground(
            fullScene: true,
            fit: BoxFit.fitWidth,
            alignment: Alignment(0, .35)),
        fullScene: true));
    await _precacheScene(tester, _sunset);
    await tester.pump(const Duration(seconds: 1));
    expect(_backgroundColor(tester), _sunset.background);
    expect(_backgroundColor(tester), isNot(_warm));
    final pixels = await _capturePixels(tester);
    _expectPixel(pixels, 195, 825, _sunset.background);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resident tabs share the warm backdrop and retain corner leaves',
      (tester) async {
    _phoneSize(tester);
    final shadows = debugDisableShadows;
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = shadows);
    await AppStore.setName('Juan Dela Cruz');
    await _loadFonts(tester);
    final shell = MainNavigationShell(onLogout: () {});
    await tester.pumpWidget(_app(_beforeSunset, shell));
    await _precacheScene(tester, _beforeSunset);
    await tester.pump(const Duration(milliseconds: 1100));
    final leaves = [
      for (final element in find.byType(LeafSprig).evaluate())
        tester.getRect(find.byWidget(element.widget)),
    ];
    expect(leaves, hasLength(2));
    final sceneState = tester.state(find.byType(SundoTimeBasedBackground));
    await tester.pumpWidget(_app(_sunset, shell));
    await _precacheScene(tester, _sunset);
    await tester.pump(const Duration(milliseconds: 1100));

    for (final label in ['Home', 'Schedule', 'Alerts', 'Profile']) {
      if (label != 'Home') {
        await tester.tap(find.text(label).last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
      }
      expect(_backgroundColor(tester), _warm, reason: label);
      expect(_navigationColor(tester), _warm, reason: label);
      expect(
          tester
              .widget<FadeTransition>(find
                  .descendant(
                      of: find.byType(SundoFadeThrough<int>),
                      matching: find.byType(FadeTransition))
                  .first)
              .opacity
              .value,
          1,
          reason: '$label content must finish arriving before capture');
      expect(tester.state(find.byType(SundoTimeBasedBackground)),
          same(sceneState));
      expect(
          tester.widgetList<Scaffold>(find.byType(Scaffold)).every(
              (scaffold) => scaffold.backgroundColor == Colors.transparent),
          isTrue,
          reason: '$label must expose its shared scenery');
      expect([
        for (final element in find.byType(LeafSprig).evaluate())
          tester.getRect(find.byWidget(element.widget)),
      ], leaves, reason: '$label keeps the existing leaf positions');
      if (label == 'Schedule') {
        final pixels = await _capturePixels(tester);
        _expectPixel(pixels, 195, 8, _warm);
        if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
          await expectLater(find.byKey(_preview),
              matchesGoldenFile('goldens/sunset_schedule.png'));
        }
      }
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    debugDisableShadows = shadows;
  });

  testWidgets('functional map keeps its opaque original surfaces at sunset',
      (tester) async {
    _phoneSize(tester);
    await _loadFonts(tester);
    const mapScreen = LiveMapScreen(
        isActive: false,
        enableGps: false,
        enableTiles: false,
        repository: _EmptyTrucks());
    for (final mood in [_beforeSunset, _sunset]) {
      await tester.pumpWidget(_app(mood, mapScreen));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          mood.background);
      expect(
          tester
              .widget<FlutterMap>(find.byType(FlutterMap))
              .options
              .backgroundColor,
          const Color(0xFFE3EEE3));
      expect(find.byType(TileLayer), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _app(SundoTimeMood mood, Widget child,
        {AssetBundle? bundle, bool fullScene = false}) =>
    ProviderScope(
        child: MaterialApp(
            theme: buildSundoTheme(mood),
            home: DefaultAssetBundle(
                bundle: bundle ?? rootBundle,
                child: SundoTimeScope(
                    mood: mood,
                    child: RepaintBoundary(
                        key: _preview,
                        child: fullScene
                            ? child
                            : ScenicBackdrop(
                                sceneryOpacity: const AlwaysStoppedAnimation(1),
                                child: child))))));

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
}

Future<void> _loadFonts(WidgetTester tester) => tester.runAsync(() async {
      for (final weight in FontWeight.values) {
        GoogleFonts.outfit(fontWeight: weight);
        GoogleFonts.plusJakartaSans(fontWeight: weight);
      }
      await GoogleFonts.pendingFonts();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });

Future<void> _precacheScene(WidgetTester tester, SundoTimeMood mood) async {
  final context = tester.element(find.byKey(_preview));
  await tester.runAsync(() async {
    await precacheImage(
        AssetImage(sundoEnvironmentArtwork(mood.environment)), context);
    await precacheImage(
        const ResizeImage(AssetImage(sundoLeafSprigAsset), width: 512), context);
  });
  await tester.pump();
}

Color _paintedColor(WidgetTester tester, Finder animatedContainer) {
  final decoration = tester
      .widget<DecoratedBox>(find
          .descendant(
              of: animatedContainer, matching: find.byType(DecoratedBox))
          .first)
      .decoration as BoxDecoration;
  return decoration.color ??
      (decoration.gradient as LinearGradient).colors.first;
}

Color _backgroundColor(WidgetTester tester) => _paintedColor(
    tester,
    find
        .descendant(
            of: find.byType(SundoTimeBasedBackground),
            matching: find.byType(AnimatedContainer))
        .first);

Color _navigationColor(WidgetTester tester) => _paintedColor(
    tester,
    find
        .descendant(
            of: find.byType(ScenicBackdrop),
            matching: find.byType(AnimatedContainer))
        .first);

List<SundoEnvironment> _environmentImages(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .where((image) => image.key is ValueKey<SundoEnvironment>)
    .map((image) => (image.key! as ValueKey<SundoEnvironment>).value)
    .toList();

Future<Uint8List> _capturePixels(WidgetTester tester) async =>
    (await tester.runAsync(() async {
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(_preview));
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return bytes!.buffer.asUint8List();
    }))!;

void _expectPixel(Uint8List pixels, int x, int y, Color expected) {
  final offset = (y * 390 + x) * 4;
  final color = expected.toARGB32();
  for (final (channel, shift) in [(0, 16), (1, 8), (2, 0)]) {
    expect(pixels[offset + channel], closeTo((color >> shift) & 255, 2));
  }
}

class _DelayedSunsetBundle extends CachingAssetBundle {
  final _pending = Completer<ByteData>();
  bool sunsetRequested = false;
  @override
  Future<ByteData> load(String key) {
    if (key == sundoEnvironmentArtwork(SundoEnvironment.sunset)) {
      sunsetRequested = true;
      return _pending.future;
    }
    return rootBundle.load(key);
  }
}

class _EmptyTrucks implements MapTruckRepository {
  const _EmptyTrucks();
  @override
  Stream<List<MapTruckSnapshot>> watchTrucks() => Stream.value([]);
}
