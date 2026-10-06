import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/app/resident_shell.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';
import 'package:sundo_sipalay/shared/widgets/resident_header.dart';
import 'package:sundo_sipalay/shared/widgets/time_based_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
  });

  for (final condition in [
    WeatherCondition.clear,
    WeatherCondition.cloudy,
    WeatherCondition.rain
  ]) {
    testWidgets(
        'schedule header leaves fit below system inset for ${condition.name}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 715);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final mood =
          SundoTimeMood.fromInstant(DateTime.parse('2026-10-06T11:00:00+08:00'),
              weather: SipalayWeather(
                  validAt: DateTime.parse('2026-10-06T11:00:00+08:00'),
                  fetchedAt: DateTime.parse('2026-10-06T11:00:00+08:00'),
                  weatherCode: condition == WeatherCondition.rain
                      ? 63
                      : condition == WeatherCondition.cloudy
                          ? 3
                          : 0,
                  precipitationMm: 0,
                  rainMm: 0,
                  showersMm: 0));
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
      await tester.pumpWidget(MaterialApp(
          theme: buildSundoTheme(mood),
          home: MediaQuery(
              data: const MediaQueryData(
                  size: Size(320, 715),
                  padding: EdgeInsets.only(top: 32, bottom: 24),
                  viewPadding: EdgeInsets.only(top: 32, bottom: 24),
                  textScaler: TextScaler.linear(1.4)),
              child: SundoTimeScope(
                  mood: mood,
                  child: RepaintBoundary(
                      key: const ValueKey('schedule-weather-preview'),
                      child: ScenicBackdrop(
                          child: MainNavigationShell(onLogout: () {})))))));
      await _waitForScene(tester, mood.environment);
      await tester.tap(find.text('Schedule').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.runAsync(() => precacheImage(
          const AssetImage(sundoLeafSprigAsset),
          tester.element(find.byType(SundoHeaderLeaves))));
      await tester.pump();
      final leaves = tester.getRect(find.byType(LeafSprig));
      final header = tester.getRect(find.byType(SundoResidentHeader));
      expect(leaves.top, greaterThanOrEqualTo(32));
      expect(leaves.left, greaterThanOrEqualTo(0));
      expect(leaves.right, lessThanOrEqualTo(320));
      expect(leaves.bottom, lessThanOrEqualTo(header.bottom));
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
        await expectLater(
            find.byKey(const ValueKey('schedule-weather-preview')),
            matchesGoldenFile(
                'goldens/schedule_weather_${condition.name}.png'));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  final moods = [
    SundoTimeMood(DateTime(2026, 10, 5, 8)),
    SundoTimeMood(DateTime(2026, 10, 5, 12)),
    SundoTimeMood(DateTime(2026, 10, 5, 17)),
    SundoTimeMood(DateTime(2026, 10, 5, 20)),
    SundoTimeMood(DateTime(2026, 10, 5, 14), raining: true),
    SundoTimeMood(DateTime(2026, 10, 5, 19, 10),
        weatherCondition: WeatherCondition.rain),
  ];
  for (final mood in moods) {
    testWidgets(
        '${mood.environment.name} scenery has no former 220 px band seam',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          home: SundoTimeScope(
              mood: mood,
              child: RepaintBoundary(
                  key: boundaryKey,
                  child: const ScenicBackdrop(child: SizedBox.shrink())))));
      await tester.runAsync(() async {
        final context = boundaryKey.currentContext!;
        await precacheImage(
            AssetImage(sundoEnvironmentArtwork(mood.environment)), context);
        await precacheImage(const AssetImage(sundoLeafSprigAsset), context);
      });
      await tester.pump();
      final backgroundRect =
          tester.getRect(find.byType(SundoTimeBasedBackground));
      expect(backgroundRect, const Rect.fromLTWH(0, 0, 320, 640));
      final pixels = await tester.runAsync(() async {
        final image = await (boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
        final bytes =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return bytes!.buffer.asUint8List();
      });
      double rowLuminance(int y) {
        var total = 0.0;
        for (var x = 80; x < 240; x++) {
          final offset = (y * 320 + x) * 4;
          total += pixels![offset] * .2126 +
              pixels[offset + 1] * .7152 +
              pixels[offset + 2] * .0722;
        }
        return total / 160;
      }

      // The old illustrated band began abruptly at y=420 on this phone.
      for (var y = 412; y < 428; y++) {
        expect((rowLuminance(y + 1) - rowLuminance(y)).abs(), lessThan(5),
            reason: 'The backdrop must blend continuously across row $y.');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('only scenery fades while foreground controls stay fixed',
      (tester) async {
    var presses = 0;
    final foreground = TextButton(
        onPressed: () => presses++,
        child: const Text('Fixed branding control'));
    Widget surface(SundoTimeMood mood, {bool reduceMotion = false}) =>
        MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduceMotion),
                child: SundoTimeScope(
                    mood: mood,
                    child: SundoTimeBasedBackground(
                        fullScene: true, child: Center(child: foreground)))));
    await tester.pumpWidget(surface(moods.first));
    await _waitForScene(tester, moods.first.environment);
    final original = tester.getRect(find.text('Fixed branding control'));
    await tester.pumpWidget(surface(moods[4]));
    await _waitForScene(tester, moods[4].environment);
    await tester.pump(const Duration(milliseconds: 450));
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(2));
    expect(images.map((image) => image.fit).toSet(), {BoxFit.cover});
    expect(images.map((image) => image.alignment).toSet(),
        {Alignment.bottomCenter});
    expect(tester.getRect(find.text('Fixed branding control')), original);
    await tester.tap(find.text('Fixed branding control'));
    expect(presses, 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpWidget(surface(moods.first, reduceMotion: true));
    await _waitForScene(tester, moods.first.environment);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(tester.getRect(find.text('Fixed branding control')), original);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('clear to cloudy fades even when the time artwork is unchanged',
      (tester) async {
    final now = DateTime(2026, 10, 5, 12);
    final clear = SundoTimeMood(now, weatherCondition: WeatherCondition.clear);
    final cloudy =
        SundoTimeMood(now, weatherCondition: WeatherCondition.cloudy);
    await tester.pumpWidget(_surface(clear));
    await _waitForScene(tester, clear.environment);
    await tester.pumpWidget(_surface(cloudy));
    await tester.pump(const Duration(milliseconds: 450));
    expect(_displayedScenes(tester),
        [SundoEnvironment.noon, SundoEnvironment.noon]);
    expect(find.byType(ColorFiltered), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(_displayedScenes(tester), [SundoEnvironment.noon]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('wet night is darker while retaining the exact wet-day image',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    final day = SundoTimeMood(DateTime(2026, 10, 5, 12),
        weatherCondition: WeatherCondition.rain);
    final night = SundoTimeMood(DateTime(2026, 10, 5, 19, 10),
        weatherCondition: WeatherCondition.rain);
    await tester.pumpWidget(_surface(day, boundary: boundary));
    await _waitForScene(tester, day.environment);
    final dayImage = tester.widget<Image>(find.byType(Image));
    final dayRect = tester.getRect(find.byType(Image));
    final dayPixels = await _capturePixels(tester, boundary);
    await tester.pumpWidget(_surface(night, boundary: boundary));
    await _waitForScene(tester, night.environment);
    await tester.pump(const Duration(milliseconds: 950));
    final nightImage = tester.widget<Image>(find.byType(Image));
    final nightPixels = await _capturePixels(tester, boundary);
    expect(nightImage.image, dayImage.image);
    expect(nightImage.fit, dayImage.fit);
    expect(nightImage.alignment, dayImage.alignment);
    expect(tester.getRect(find.byType(Image)), dayRect);
    double luminance(List<int> pixels) {
      var total = 0.0;
      for (var offset = 0; offset < pixels.length; offset += 4) {
        total += pixels[offset] * .2126 +
            pixels[offset + 1] * .7152 +
            pixels[offset + 2] * .0722;
      }
      return total / (pixels.length / 4);
    }

    expect(luminance(nightPixels), lessThan(luminance(dayPixels) * .7));
    expect(_displayedScenes(tester), [SundoEnvironment.rainyNight]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('expired rain clears even if the dry scene cannot decode',
      (tester) async {
    final bundle = _DeferredSceneBundle();
    final dryAsset = sundoEnvironmentArtwork(SundoEnvironment.noon);
    bundle.defer(dryAsset);
    await tester.pumpWidget(_surface(moods[4], bundle: bundle));
    await _waitForScene(tester, SundoEnvironment.rainy);
    await tester.pumpWidget(_surface(moods[1], bundle: bundle));
    await tester.pump(const Duration(seconds: 1));
    expect(_displayedScenes(tester), isEmpty);
    await tester.runAsync(() async {
      bundle.fail(dryAsset);
      await precacheImage(AssetImage(dryAsset, bundle: bundle),
          tester.element(find.byType(SundoTimeBasedBackground)),
          onError: (error, stack) {});
      await AssetImage(dryAsset, bundle: bundle).evict();
    });
    await tester.pump();
    expect(_displayedScenes(tester), isEmpty);
    await tester.pumpWidget(
        _surface(SundoTimeMood(DateTime(2026, 10, 5, 12, 1)), bundle: bundle));
    await _waitForScene(tester, SundoEnvironment.noon);
    await tester.pump(const Duration(seconds: 1));
    expect(_displayedScenes(tester), [SundoEnvironment.noon]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('slow next decode retains the ready scene until fade can start',
      (tester) async {
    final bundle = _DeferredSceneBundle();
    final rainyAsset = sundoEnvironmentArtwork(SundoEnvironment.rainy);
    bundle.defer(rainyAsset);
    await tester.pumpWidget(_surface(moods.first, bundle: bundle));
    await _waitForScene(tester, SundoEnvironment.morning);
    await tester.pumpWidget(_surface(moods[4], bundle: bundle));
    await tester.pump(const Duration(seconds: 2));
    expect(_displayedScenes(tester), [SundoEnvironment.morning]);
    expect(bundle.sceneRequests.toSet(), {
      sundoEnvironmentArtwork(SundoEnvironment.morning),
      rainyAsset,
    });
    await _releaseScene(tester, bundle, rainyAsset);
    await _waitForScene(tester, SundoEnvironment.rainy);
    await tester.pump(const Duration(milliseconds: 450));
    expect(_displayedScenes(tester).toSet(), {
      SundoEnvironment.morning,
      SundoEnvironment.rainy,
    });
    await tester.pump(const Duration(milliseconds: 500));
    expect(_displayedScenes(tester), [SundoEnvironment.rainy]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('returning to ready scene cancels a pending different scene',
      (tester) async {
    final bundle = _DeferredSceneBundle();
    final rainyAsset = sundoEnvironmentArtwork(SundoEnvironment.rainy);
    bundle.defer(rainyAsset);
    await tester.pumpWidget(_surface(moods.first, bundle: bundle));
    await _waitForScene(tester, SundoEnvironment.morning);
    await tester.pumpWidget(_surface(moods[4], bundle: bundle));
    await tester.pumpWidget(_surface(moods.first, bundle: bundle));
    await _releaseScene(tester, bundle, rainyAsset);
    await _waitForScene(tester, SundoEnvironment.rainy);
    await tester.pump(const Duration(seconds: 1));
    expect(_displayedScenes(tester), [SundoEnvironment.morning]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed next scene keeps current artwork and a later retry works',
      (tester) async {
    final bundle = _DeferredSceneBundle();
    final rainyAsset = sundoEnvironmentArtwork(SundoEnvironment.rainy);
    bundle.defer(rainyAsset);
    await tester.pumpWidget(_surface(moods.first, bundle: bundle));
    await _waitForScene(tester, SundoEnvironment.morning);
    await tester.pumpWidget(_surface(moods[4], bundle: bundle));
    await tester.runAsync(() async {
      bundle.fail(rainyAsset);
      // Wait for the failing decoder before requesting the retry.
      await precacheImage(AssetImage(rainyAsset, bundle: bundle),
          tester.element(find.byType(SundoTimeBasedBackground)),
          onError: (error, stack) {});
      await AssetImage(rainyAsset, bundle: bundle).evict();
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_displayedScenes(tester), [SundoEnvironment.morning]);
    expect(tester.takeException(), isNull);
    // A later clock refresh requests the same desired scene again.
    await tester.pumpWidget(_surface(
        SundoTimeMood(DateTime(2026, 10, 5, 14, 1), raining: true),
        bundle: bundle));
    await _waitForScene(tester, SundoEnvironment.rainy);
    await tester.pump(const Duration(seconds: 1));
    expect(_displayedScenes(tester), [SundoEnvironment.rainy]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a scene finishing after disposal never updates the old widget',
      (tester) async {
    final bundle = _DeferredSceneBundle();
    final rainyAsset = sundoEnvironmentArtwork(SundoEnvironment.rainy);
    bundle.defer(rainyAsset);
    await tester.pumpWidget(_surface(moods.first, bundle: bundle));
    await _waitForScene(tester, SundoEnvironment.morning);
    await tester.pumpWidget(_surface(moods[4], bundle: bundle));
    await tester.pumpWidget(const SizedBox.shrink());
    await _releaseScene(tester, bundle, rainyAsset);
    await tester.runAsync(() async {
      await precacheImage(AssetImage(rainyAsset, bundle: bundle),
          tester.element(find.byType(SizedBox).first));
    });
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  for (final mood in [moods.first, moods[3], moods[4], moods.last]) {
    testWidgets(
        '${mood.environment.name} full truck scene feathers into tall-phone bottom',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      await tester.pumpWidget(_surface(mood,
          boundary: boundary,
          fit: BoxFit.fitWidth,
          alignment: const Alignment(0, .35)));
      await _waitForScene(tester, mood.environment);
      final pixels = await _capturePixels(tester, boundary);
      double rowLuminance(int y) {
        var total = 0.0;
        for (var x = 80; x < 240; x++) {
          final offset = (y * 320 + x) * 4;
          total += pixels[offset] * .2126 +
              pixels[offset + 1] * .7152 +
              pixels[offset + 2] * .0722;
        }
        return total / 160;
      }

      // 320x480 artwork aligned at .35 ends at y588 in this viewport.
      // Its last pixels blend into the surface instead of forming a stripe.
      for (var y = 580; y < 594; y++) {
        expect((rowLuminance(y + 1) - rowLuminance(y)).abs(), lessThan(8));
      }
      final color = mood.background.toARGB32();
      const bottom = (620 * 320 + 160) * 4;
      expect(pixels.sublist(bottom, bottom + 3),
          [(color >> 16) & 255, (color >> 8) & 255, color & 255]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final scale in [1.0, 1.4]) {
    testWidgets('narrow demo home shows full greeting at text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      await AppStore.setName('Juan Dela Cruz');
      await tester.runAsync(() async {
        for (final weight in FontWeight.values) {
          GoogleFonts.outfit(fontWeight: weight);
          GoogleFonts.plusJakartaSans(fontWeight: weight);
        }
        await GoogleFonts.pendingFonts();
      });
      final mood = moods.first;
      await tester.pumpWidget(MaterialApp(
          theme: buildSundoTheme(mood),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: SundoTimeScope(
              mood: mood,
              child: ScenicBackdrop(
                  child: MainNavigationShell(onLogout: () {})))));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pump();
      final banner = tester.getRect(find.text(
          'LOCAL DEMO · Sample fleet and schedules · Reports stay on this phone'));
      final greeting = tester.getRect(find.text('Good Morning,'));
      final firstName = tester.getRect(find.text('Juan!'));
      final collection = tester.getRect(find.text('Next Collection'));
      final header = tester.getRect(find.byType(SundoResidentHeader));
      expect(banner.top, greaterThanOrEqualTo(24));
      expect(header.top, banner.bottom + 5);
      expect(greeting.top, greaterThan(header.bottom + 15));
      expect(greeting.top, lessThan(header.bottom + 40));
      expect(firstName.top, greaterThanOrEqualTo(greeting.bottom));
      expect(firstName.bottom, lessThan(collection.top));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}

Widget _surface(SundoTimeMood mood,
        {AssetBundle? bundle,
        GlobalKey? boundary,
        BoxFit fit = BoxFit.cover,
        Alignment alignment = Alignment.bottomCenter}) =>
    MaterialApp(
        home: DefaultAssetBundle(
            bundle: bundle ?? rootBundle,
            child: SundoTimeScope(
                mood: mood,
                child: RepaintBoundary(
                    key: boundary,
                    child: SundoTimeBasedBackground(
                        fullScene: true, fit: fit, alignment: alignment)))));

Future<void> _waitForScene(
    WidgetTester tester, SundoEnvironment environment) async {
  final context = tester.element(find.byType(SundoTimeBasedBackground).first);
  await tester.runAsync(() =>
      precacheImage(AssetImage(sundoEnvironmentArtwork(environment)), context));
  await tester.pump();
}

List<SundoEnvironment> _displayedScenes(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .where((image) => image.key is ValueKey<SundoEnvironment>)
    .map((image) => (image.key! as ValueKey<SundoEnvironment>).value)
    .toList();

Future<List<int>> _capturePixels(WidgetTester tester, GlobalKey key) async =>
    (await tester.runAsync(() async {
      final image = await (key.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return bytes!.buffer.asUint8List();
    }))!;

Future<void> _releaseScene(
    WidgetTester tester, _DeferredSceneBundle bundle, String asset) async {
  final bytes = await tester.runAsync(() => rootBundle.load(asset));
  bundle.complete(asset, bytes!);
  await tester.pump();
}

class _DeferredSceneBundle extends CachingAssetBundle {
  final _deferred = <String, Completer<ByteData>>{};
  final sceneRequests = <String>[];

  void defer(String asset) => _deferred[asset] = Completer<ByteData>();

  void complete(String asset, ByteData bytes) =>
      _deferred.remove(asset)!.complete(bytes);

  void fail(String asset) =>
      _deferred.remove(asset)!.completeError(StateError('Missing test scene'));

  @override
  Future<ByteData> load(String key) {
    if (key.startsWith('assets/images/environment-')) {
      sceneRequests.add(key);
      final pending = _deferred[key];
      if (pending != null) return pending.future;
    }
    return rootBundle.load(key);
  }
}
