import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/home/widgets/sundo_card_scenery.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('card skies use every Philippine time boundary, including 6:30 PM', () {
    final cases = <(int, int, int, SundoCardSceneryState)>[
      (0, 0, 0, SundoCardSceneryState.night),
      (5, 0, 0, SundoCardSceneryState.night),
      (6, 0, 0, SundoCardSceneryState.morning),
      (10, 59, 59, SundoCardSceneryState.morning),
      (11, 0, 0, SundoCardSceneryState.noon),
      (16, 59, 59, SundoCardSceneryState.noon),
      (17, 0, 0, SundoCardSceneryState.sunset),
      (17, 59, 59, SundoCardSceneryState.sunset),
      (18, 0, 0, SundoCardSceneryState.earlyEvening),
      (18, 29, 59, SundoCardSceneryState.earlyEvening),
      (18, 30, 0, SundoCardSceneryState.evening),
      (18, 59, 59, SundoCardSceneryState.evening),
      (19, 0, 0, SundoCardSceneryState.night),
      (23, 59, 59, SundoCardSceneryState.night),
    ];
    for (final (hour, minute, second, expected) in cases) {
      final mood = SundoTimeMood.fromInstant(_at(hour, minute, second));
      expect(sundoCardSceneryState(mood), expected,
          reason: 'Philippine time ${mood.localTime}');
    }
  });

  test('morning starts at local solar sunrise while midnight greets morning',
      () {
    const area = WeatherLocation(
        latitude: 7.07,
        longitude: 125.61,
        label: 'Your location',
        isDeviceLocation: true);
    final midnight = _at(0);
    final initial = SundoTimeMood.fromInstant(midnight, location: area);
    final sunrise = midnight.add(initial.daylight.sunrise);
    final before = SundoTimeMood.fromInstant(
        sunrise.subtract(const Duration(microseconds: 1)),
        location: area);
    final after = SundoTimeMood.fromInstant(sunrise, location: area);
    expect(initial.greeting, 'Good Morning');
    expect(before.greeting, 'Good Morning');
    expect(sundoCardSceneryState(initial), SundoCardSceneryState.night);
    expect(sundoCardSceneryState(before), SundoCardSceneryState.night);
    expect(sundoCardSceneryState(after), SundoCardSceneryState.morning);
    expect(initial.daylight.sunrise,
        lessThan(SundoTimeMood.fromInstant(midnight).daylight.sunrise));
  });

  test('6:30 PM and 7 PM scenery boundaries ignore the device timezone', () {
    for (final (stamp, expected) in [
      ('2026-10-08T10:30:00Z', SundoCardSceneryState.evening),
      ('2026-10-08T18:30:00+08:00', SundoCardSceneryState.evening),
      ('2026-10-08T06:30:00-04:00', SundoCardSceneryState.evening),
      ('2026-10-08T11:00:00Z', SundoCardSceneryState.night),
      ('2026-10-08T19:00:00+08:00', SundoCardSceneryState.night),
      ('2026-10-08T07:00:00-04:00', SundoCardSceneryState.night),
    ]) {
      expect(
          sundoCardSceneryState(
              SundoTimeMood.fromInstant(DateTime.parse(stamp))),
          expected,
          reason: stamp);
    }
  });

  testWidgets('minute clock advances cards at 6:30 PM within the twilight scene',
      (tester) async {
    var clock = _at(18, 29, 55);
    final container = ProviderContainer(overrides: [
      sundoClockProvider.overrideWithValue(() => clock),
      sundoWeatherProvider.overrideWith(_NoWeatherController.new),
    ]);
    addTearDown(container.dispose);
    final previous = container.read(sundoDayNightThemeProvider);
    expect(sundoCardSceneryState(previous), SundoCardSceneryState.earlyEvening);
    clock = clock.add(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 4));
    expect(sundoCardSceneryState(container.read(sundoDayNightThemeProvider)),
        SundoCardSceneryState.earlyEvening);
    clock = clock.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final next = container.read(sundoDayNightThemeProvider);
    expect(sundoCardSceneryState(next), SundoCardSceneryState.evening);
    expect(next.environment, previous.environment,
        reason: 'The separate card transition must work within 6 PM twilight.');
    expect(
        SundoTimeScope(mood: next, child: const SizedBox.shrink())
            .updateShouldNotify(SundoTimeScope(
                mood: previous, child: const SizedBox.shrink())),
        isTrue);
  });

  test('fresh daytime weather overrides time and stale weather falls back', () {
    for (final (code, expected) in [
      (3, SundoCardSceneryState.cloudy),
      (45, SundoCardSceneryState.cloudy),
      (51, SundoCardSceneryState.rainy),
      (63, SundoCardSceneryState.rainy),
      (95, SundoCardSceneryState.rainy),
    ]) {
      for (final (hour, minute, fallback) in [
        (9, 0, SundoCardSceneryState.morning),
        (17, 0, SundoCardSceneryState.sunset),
        (18, 0, SundoCardSceneryState.earlyEvening),
        (18, 30, SundoCardSceneryState.evening),
      ]) {
        final now = _at(hour, minute);
        expect(
            sundoCardSceneryState(
                SundoTimeMood.fromInstant(now, weather: _weather(now, code))),
            expected,
            reason: 'Fresh $code weather at $hour:$minute');
        expect(
            sundoCardSceneryState(SundoTimeMood.fromInstant(now,
                weather: _weather(
                    now.subtract(const Duration(minutes: 31)), code))),
            fallback,
            reason: 'Expired $code weather must not keep an obsolete sky.');
      }
    }
  });

  test('cloud cover at midnight retains dark scenery and rain retains rainfall',
      () {
    for (final hour in [0, 4, 19, 23]) {
      final now = _at(hour);
      expect(
          sundoCardSceneryState(
              SundoTimeMood.fromInstant(now, weather: _weather(now, 3))),
          SundoCardSceneryState.night,
          reason: 'Clouds must not restore daylight at $hour:00.');
      expect(
          sundoCardSceneryState(
              SundoTimeMood.fromInstant(now, weather: _weather(now, 63))),
          SundoCardSceneryState.rainy);
    }
  });

  test('all three cards have eight separately bundled scenery assets', () {
    final paths = {
      for (final scene in SundoCardScene.values)
        for (final state in SundoCardSceneryState.values)
          sundoCardSceneryArtwork(scene, state)
    };
    expect(SundoCardScene.values, hasLength(3));
    expect(SundoCardSceneryState.values, hasLength(8));
    expect(paths, hasLength(24));
    expect(paths.every((path) => path.endsWith('.webp')), isTrue);
    expect(
        sundoCardSceneryArtwork(SundoCardScene.weatherRiverside,
            SundoCardSceneryState.earlyEvening),
        'assets/images/card_scenery/weather_riverside/early_evening_1800.webp');
  });

  testWidgets('late first card frame fades in while its action stays usable',
      (tester) async {
    final mood = SundoTimeMood.fromInstant(_at(9));
    final path = _artwork(SundoCardSceneryState.morning);
    final bundle = _DelayedCardBundle([path]);
    var taps = 0;
    await tester.pumpWidget(_cardSurface(bundle, mood,
        onPressed: () => taps++));
    final actionRect = tester.getRect(find.text('Card action'));
    expect(_entryOpacity(tester), 0);
    expect(_displayedAssets(tester), isEmpty);
    await tester.pump(const Duration(seconds: 2));
    expect(_entryOpacity(tester), 0);
    await tester.tap(find.text('Card action'));
    expect(taps, 1);

    await _releaseCard(tester, bundle, path);
    expect(_entryOpacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 150));
    expect(_entryOpacity(tester), greaterThan(0));
    expect(_entryOpacity(tester), lessThan(1));
    expect(tester.getRect(find.text('Card action')), actionRect);
    await tester.pump(const Duration(milliseconds: 900));
    expect(_entryOpacity(tester), 1);
    expect(_displayedAssets(tester), [path]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('current card frame stays visible until replacement decodes',
      (tester) async {
    final morning = _artwork(SundoCardSceneryState.morning);
    final noon = _artwork(SundoCardSceneryState.noon);
    final bundle = _DelayedCardBundle([morning, noon]);
    await tester.pumpWidget(
        _cardSurface(bundle, SundoTimeMood.fromInstant(_at(9))));
    await _releaseCard(tester, bundle, morning);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpWidget(
        _cardSurface(bundle, SundoTimeMood.fromInstant(_at(12))));
    await tester.pump(const Duration(seconds: 2));
    expect(_displayedAssets(tester), [morning]);
    expect(_entryOpacity(tester), 1);

    await _releaseCard(tester, bundle, noon);
    expect(_displayedAssets(tester), containsAll([morning, noon]));
    final switcher = find.descendant(
        of: find.byType(SundoCardScenery),
        matching: find.byType(AnimatedSwitcher));
    expect(tester.widget<AnimatedSwitcher>(switcher).duration,
        const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 150));
    final opacities = tester
        .widgetList<FadeTransition>(find.descendant(
            of: switcher, matching: find.byType(FadeTransition)))
        .map((fade) => fade.opacity.value);
    expect(opacities.any((value) => value > 0 && value < 1), isTrue);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_displayedAssets(tester), [noon]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('superseded card target cannot replace the latest sky',
      (tester) async {
    final morning = _artwork(SundoCardSceneryState.morning);
    final noon = _artwork(SundoCardSceneryState.noon);
    final night = _artwork(SundoCardSceneryState.night);
    final bundle = _DelayedCardBundle([morning, noon, night]);
    await tester.pumpWidget(
        _cardSurface(bundle, SundoTimeMood.fromInstant(_at(9))));
    await _releaseCard(tester, bundle, morning);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpWidget(
        _cardSurface(bundle, SundoTimeMood.fromInstant(_at(12))));
    await tester.pumpWidget(
        _cardSurface(bundle, SundoTimeMood.fromInstant(_at(19))));
    await _releaseCard(tester, bundle, noon);
    expect(_displayedAssets(tester), [morning],
        reason: 'A late noon response must not undo the newer night request.');
    await _releaseCard(tester, bundle, night);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_displayedAssets(tester), [night]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion shows a decoded first card frame without fading',
      (tester) async {
    final path = _artwork(SundoCardSceneryState.morning);
    final bundle = _DelayedCardBundle([path]);
    await tester.pumpWidget(_cardSurface(
        bundle, SundoTimeMood.fromInstant(_at(9)),
        reduceMotion: true));
    expect(_entryOpacity(tester), 0);
    await _releaseCard(tester, bundle, path);
    expect(_entryOpacity(tester), 1);
    expect(
        tester
            .widget<AnimatedOpacity>(
                find.byKey(const ValueKey('sundo-card-scenery-first-frame')))
            .duration,
        Duration.zero);
    expect(tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
        Duration.zero);
    expect(_displayedAssets(tester), [path]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dusk and nighttime weather dim only decorative card artwork',
      (tester) async {
    for (final (hour, minute, code) in [
      (18, 0, 3),
      (18, 30, 3),
      (18, 0, 63),
      (18, 30, 63),
      (19, 0, 63),
      (0, 0, 63),
    ]) {
      final now = _at(hour, minute);
      final mood = SundoTimeMood.fromInstant(now, weather: _weather(now, code));
      await tester.pumpWidget(_cardSurface(rootBundle, mood,
          reduceMotion: true, onPressed: () {}));
      final path = _artwork(sundoCardSceneryState(mood));
      await tester.runAsync(() => precacheImage(
          AssetImage(path), tester.element(find.byType(SundoCardScenery))));
      await tester.pump();
      await tester.pump();
      expect(
          find.descendant(
              of: find.byType(SundoCardScenery),
              matching: find.byType(ColorFiltered)),
          findsOneWidget,
          reason: 'Weather artwork must darken at $hour:$minute.');
      expect(
          find.ancestor(
              of: find.text('Card action'),
              matching: find.byType(ColorFiltered)),
          findsNothing,
          reason: 'Weather lighting must not alter the foreground action.');
      expect(_entryOpacity(tester), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  for (final scene in SundoCardScene.values) {
    testWidgets('${scene.name} decodes every state with a stable crop and dark sky',
        (tester) async {
      final decoded = await tester.runAsync(() async {
        final result = <SundoCardSceneryState, _SceneFrame>{};
        for (final state in SundoCardSceneryState.values) {
          final path = sundoCardSceneryArtwork(scene, state);
          final bytes = await rootBundle.load(path);
          final codec = await ui.instantiateImageCodec(
              bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
          final image = (await codec.getNextFrame()).image;
          final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          result[state] = _SceneFrame(image.width, image.height,
              _skyLuminance(pixels!.buffer.asUint8List(), image.width, image.height));
          image.dispose();
          codec.dispose();
        }
        return result;
      });
      final master = decoded![SundoCardSceneryState.noon]!;
      for (final entry in decoded.entries) {
        expect(entry.value.width, master.width, reason: entry.key.name);
        expect(entry.value.height, master.height, reason: entry.key.name);
      }
      expect(master.width >= master.height,
          scene == SundoCardScene.weatherRiverside);
      final night = decoded[SundoCardSceneryState.night]!;
      expect(night.skyLuminance, lessThan(65),
          reason: 'Night must have a dark navy sky, not a sunset or blue hour.');
      expect(night.skyLuminance, lessThan(master.skyLuminance * .5));
      expect(tester.takeException(), isNull);
    });
  }
}

DateTime _at(int hour, [int minute = 0, int second = 0]) =>
    DateTime.utc(2026, 10, 8, hour, minute, second)
        .subtract(const Duration(hours: 8));

SipalayWeather _weather(DateTime instant, int code) => SipalayWeather(
    validAt: instant,
    fetchedAt: instant,
    weatherCode: code,
    precipitationMm: 0,
    rainMm: 0,
    showersMm: 0);

class _SceneFrame {
  const _SceneFrame(this.width, this.height, this.skyLuminance);
  final int width;
  final int height;
  final double skyLuminance;
}

class _NoWeatherController extends SundoWeatherController {
  @override
  SipalayWeather? build() => null;
}

String _artwork(SundoCardSceneryState state) =>
    sundoCardSceneryArtwork(SundoCardScene.weatherRiverside, state);

Widget _cardSurface(AssetBundle bundle, SundoTimeMood mood,
        {bool reduceMotion = false, VoidCallback? onPressed}) =>
    MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: DefaultAssetBundle(
                bundle: bundle,
                child: SundoTimeScope(
                    mood: mood,
                    child: Scaffold(
                        body: Center(
                            child: SizedBox(
                                width: 300,
                                height: 200,
                                child: Stack(fit: StackFit.expand, children: [
                                  const SundoCardScenery(
                                      scene: SundoCardScene.weatherRiverside),
                                  Center(
                                      child: TextButton(
                                          onPressed: onPressed,
                                          child: const Text('Card action'))),
                                ]))))))));

double _entryOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find
        .descendant(
            of: find.byKey(const ValueKey('sundo-card-scenery-first-frame')),
            matching: find.byType(FadeTransition))
        .first)
    .opacity
    .value;

List<String> _displayedAssets(WidgetTester tester) => tester
    .widgetList<Image>(find.descendant(
        of: find.byType(SundoCardScenery), matching: find.byType(Image)))
    .map((image) => (image.image as AssetImage).assetName)
    .toList();

Future<void> _releaseCard(
    WidgetTester tester, _DelayedCardBundle bundle, String path) async {
  final bytes = await tester.runAsync(() => rootBundle.load(path));
  bundle.release(path, bytes!);
  await tester.runAsync(() => precacheImage(AssetImage(path, bundle: bundle),
      tester.element(find.byType(SundoCardScenery))));
  await tester.pump();
  // The first image becomes visible on a post-frame callback, allowing its
  // opacity to animate from the already-mounted transparent clay fallback.
  await tester.pump();
}

class _DelayedCardBundle extends CachingAssetBundle {
  _DelayedCardBundle(Iterable<String> paths)
      : _pending = {for (final path in paths) path: Completer<ByteData>()};
  final Map<String, Completer<ByteData>> _pending;

  void release(String path, ByteData bytes) => _pending[path]!.complete(bytes);

  @override
  Future<ByteData> load(String key) =>
      _pending[key]?.future ?? rootBundle.load(key);
}

double _skyLuminance(Uint8List pixels, int width, int height) {
  var total = 0.0;
  var samples = 0;
  // Sample the open upper-middle sky, clear of side trees and buildings.
  for (var y = (height * .02).round(); y < height * .12; y += 4) {
    for (var x = (width * .25).round(); x < width * .70; x += 4) {
      final offset = (y * width + x) * 4;
      total += pixels[offset] * .2126 +
          pixels[offset + 1] * .7152 +
          pixels[offset + 2] * .0722;
      samples++;
    }
  }
  return total / samples;
}
