import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/home/widgets/sundo_card_scenery.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';
import 'package:sundo_sipalay/shared/widgets/sundo_card_illustration.dart';
import 'package:sundo_sipalay/shared/widgets/weather_status_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> mountSummary(WidgetTester tester, SundoTimeMood mood,
      {double width = 390,
      double scale = 1,
      bool enabled = true,
      bool checking = false,
      VoidCallback? refresh}) async {
    tester.view.physicalSize = Size(width, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      for (final weight in FontWeight.values) {
        GoogleFonts.outfit(fontWeight: weight);
        GoogleFonts.plusJakartaSans(fontWeight: weight);
      }
      await GoogleFonts.pendingFonts();
    });
    await tester.pumpWidget(MaterialApp(
        theme: buildSundoTheme(mood),
        home: MediaQuery(
            data: MediaQueryData(
                size: Size(width, 640),
                disableAnimations: true,
                textScaler: TextScaler.linear(scale)),
            child: SundoTimeScope(
                mood: mood,
                weatherEnabled: enabled,
                checkingWeather: checking,
                onWeatherRefresh: refresh ?? () {},
                child: const Scaffold(
                    body: Padding(
                        padding: EdgeInsets.all(18),
                        child: SundoWeatherStatusBanner(dashboardStyle: true)))))));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(SundoWeatherStatusBanner));
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, context);
      }
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
  }

  test('weather illustrations distinguish sunlight, night, clouds and rain', () {
    for (final (condition, night, expected) in [
      (WeatherCondition.clear, false, SundoCardIllustration.sun),
      (WeatherCondition.clear, true, SundoCardIllustration.moon),
      (WeatherCondition.cloudy, false, SundoCardIllustration.cloud),
      (WeatherCondition.cloudy, true, SundoCardIllustration.cloud),
      (WeatherCondition.rain, false, SundoCardIllustration.rain),
      (WeatherCondition.drizzle, true, SundoCardIllustration.rain),
      (WeatherCondition.thunderstorm, false, SundoCardIllustration.storm),
      (WeatherCondition.unknown, true, SundoCardIllustration.cloud),
    ]) {
      expect(sundoWeatherIllustration(condition, isNight: night), expected);
    }
  });

  test('all illustrated card assets decode with transparent edges', () async {
    for (final illustration in SundoCardIllustration.values) {
      final data = await rootBundle.load(sundoCardIllustrationAsset(illustration));
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      try {
        expect(frame.image.width, 256);
        expect(frame.image.height, 256);
        final rgba = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(rgba, isNotNull);
        final bytes = rgba!.buffer.asUint8List();
        expect(bytes[3], 0, reason: '$illustration top-left must be transparent');
        expect(bytes[bytes.length - 1], 0,
            reason: '$illustration bottom-right must be transparent');
        var visible = 0;
        for (var offset = 3; offset < bytes.length; offset += 4) {
          if (bytes[offset] > 0) visible++;
        }
        expect(visible, greaterThan(256 * 256 * .15),
            reason: '$illustration must occupy a useful part of its frame');
        expect(visible, lessThan(256 * 256 * .85),
            reason: '$illustration must be a cutout, not a solid square');
      } finally {
        frame.image.dispose();
        codec.dispose();
      }
    }
  });

  for (final (name, code, hour, illustration) in [
    ('sun', 0, 9, SundoCardIllustration.sun),
    ('moon', 0, 20, SundoCardIllustration.moon),
    ('cloud', 3, 9, SundoCardIllustration.cloud),
    ('rain', 63, 9, SundoCardIllustration.rain),
    ('drizzle', 51, 9, SundoCardIllustration.rain),
    ('storm', 95, 20, SundoCardIllustration.storm),
  ]) {
    testWidgets('illustrated $name weather retains refresh and compact text',
        (tester) async {
      final originalShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = originalShadows);
      try {
      tester.view.physicalSize = const Size(320, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      final now = DateTime(2026, 10, 8, hour);
      final snapshot = SipalayWeather(
          validAt: now.subtract(const Duration(minutes: 5)),
          fetchedAt: now,
          weatherCode: code,
          precipitationMm: 0,
          rainMm: 0,
          showersMm: 0,
          location: const WeatherLocation(
              latitude: 9.75,
              longitude: 122.40,
              label: 'Your location',
              isDeviceLocation: true));
      final mood = SundoTimeMood(now, weather: snapshot);
      var refreshes = 0;
      await tester.pumpWidget(MaterialApp(
          theme: buildSundoTheme(mood),
          home: MediaQuery(
              data: const MediaQueryData(
                  size: Size(320, 540),
                  disableAnimations: true,
                  textScaler: TextScaler.linear(1.4)),
              child: SundoTimeScope(
                  mood: mood,
                  weatherEnabled: true,
                  onWeatherRefresh: () => refreshes++,
                  child: Scaffold(
                      backgroundColor: mood.innerBackground,
                      body: const RepaintBoundary(
                          key: ValueKey('weather-illustration-preview'),
                          child: Padding(
                              padding: EdgeInsets.all(18),
                              child: SundoWeatherStatusBanner(dashboardStyle: true))))))));
      await tester.runAsync(() async {
        final context = tester.element(find.byType(SundoWeatherStatusBanner));
        await precacheImage(AssetImage(sundoCardIllustrationAsset(illustration)), context);
        await precacheImage(AssetImage(sundoCardSceneryArtwork(
            SundoCardScene.weatherRiverside, sundoCardSceneryState(mood))), context);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Auto-refresh · 5 min'), findsOneWidget);
      expect(tester.getSize(find.byKey(const ValueKey('sundo-weather-summary')))
          .height, 84);
      expect(find.textContaining('Updated 5 min ago'), findsNothing,
          reason: 'The summary keeps its reference height; age is in details');
      final icon = tester.widget<SundoCardIllustratedIcon>(find.byType(SundoCardIllustratedIcon));
      expect(icon.illustration, illustration);
      final decoded = tester.widget<RawImage>(find.descendant(
          of: find.byType(SundoCardIllustratedIcon),
          matching: find.byType(RawImage)));
      expect(decoded.image, isNotNull,
          reason: 'The illustration must render, not just select an asset');
      expect(decoded.image!.width, 256);
      final shortTitle = switch (code) {
        0 => 'Clear weather',
        3 => 'Cloudy',
        63 => 'Rainy',
        51 => 'Light rain',
        _ => 'Storms',
      };
      final headline = find.text(shortTitle);
      expect(headline, findsOneWidget);
      final headlineText = tester.widget<Text>(headline).data!;
      final firstWord = headlineText.split(' ').first;
      final paragraph = tester.renderObject<RenderParagraph>(headline);
      expect(
          paragraph.getBoxesForSelection(TextSelection(
              baseOffset: 0, extentOffset: firstWord.length)),
          hasLength(1),
          reason: '$firstWord must stay whole at 320 px and larger system text');
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
        await expectLater(find.byKey(const ValueKey('weather-illustration-preview')),
            matchesGoldenFile('goldens/weather_illustrated_$name.png'));
      }
      await tester.tap(find.byTooltip('Refresh local weather'));
      expect(refreshes, 1);
      expect(find.text('Weather details'), findsNothing,
          reason: 'The nested refresh action must not also open the sheet');
      await tester.tap(find.byKey(const ValueKey('sundo-weather-summary')));
      await tester.pumpAndSettle();
      final fullTitle = code == 95 ? 'Thunderstorms' : shortTitle;
      expect(find.text('$fullTitle at your location'), findsOneWidget);
      expect(find.textContaining('Updated 5 min ago'), findsOneWidget,
          reason: 'Details report observation age, not the latest fetch time');
      expect(find.text('Auto-refresh · Every 5 min'), findsOneWidget);
      if (name == 'storm' && const bool.fromEnvironment('GENERATE_PREVIEWS')) {
        await expectLater(find.byKey(const ValueKey('sundo-weather-details')),
            matchesGoldenFile('goldens/weather_details_storm.png'));
      }
      if (code >= 51) {
        expect(find.textContaining('Collection may be affected'), findsOneWidget);
      }
      final detailText = tester.widget<Text>(find.text('$fullTitle at your location'));
      expect(detailText.textScaler, isNull,
          reason: 'Only compact summary text may clamp accessibility scaling');
      await tester.ensureVisible(find.text('Refresh weather'));
      await tester.tap(find.text('Refresh weather'));
      await tester.pumpAndSettle();
      expect(refreshes, 2);
      expect(find.text('Weather details'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        debugDisableShadows = originalShadows;
      }
    });
  }

  testWidgets('Home weather keeps 84 px through conditions, load, stale and off',
      (tester) async {
    final now = DateTime(2026, 10, 8, 9);
    SipalayWeather snapshot(int code, {bool stale = false}) => SipalayWeather(
        validAt: now.subtract(Duration(minutes: stale ? 31 : 5)),
        fetchedAt: now,
        weatherCode: code,
        precipitationMm: 0,
        rainMm: 0,
        showersMm: 0,
        location: const WeatherLocation(
            latitude: 9.75,
            longitude: 122.40,
            label: 'Your location',
            isDeviceLocation: true));
    for (final (width, scale) in [(390.0, 1.0), (320.0, 1.4), (390.0, 2.0)]) {
      for (final (weather, enabled, checking) in [
        (snapshot(0), true, false),
        (snapshot(51), true, false),
        (snapshot(95), true, false),
        (snapshot(63, stale: true), true, false),
        (null, true, false),
        (null, true, true),
        (null, false, false),
      ]) {
        await mountSummary(tester, SundoTimeMood(now, weather: weather),
            width: width, scale: scale, enabled: enabled, checking: checking);
        expect(tester.getSize(find.byKey(const ValueKey('sundo-weather-summary')))
            .height, 84);
        if (checking) {
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.byTooltip('Refresh local weather'), findsNothing);
        }
        if (!enabled) {
          expect(find.textContaining('Auto-refresh'), findsNothing);
          expect(find.byTooltip('Refresh local weather'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('saved-area details retain full data and original text scaling',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final now = DateTime(2026, 10, 8, 9);
    final weather = SipalayWeather(
        validAt: now.subtract(const Duration(minutes: 7)),
        fetchedAt: now,
        weatherCode: 51,
        precipitationMm: 0,
        rainMm: 0,
        showersMm: 0,
        location: const WeatherLocation(
            latitude: 9.75,
            longitude: 122.40,
            label: 'Barangay 2',
            isDeviceLocation: false));
    await mountSummary(tester, SundoTimeMood(now, weather: weather),
        width: 320, scale: 2);
    expect(find.bySemanticsLabel(RegExp(
        r'^Light rain in Barangay 2.*Updated 7 min ago.*Auto-refresh every 5 minutes.*')),
        findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('sundo-weather-summary')))
        .height, 84);
    await tester.tap(find.byKey(const ValueKey('sundo-weather-summary')));
    await tester.pumpAndSettle();
    expect(find.text('Light rain in Barangay 2'), findsOneWidget);
    expect(find.textContaining('Updated 7 min ago'), findsOneWidget);
    expect(find.textContaining('at your location'), findsNothing);
    final context = tester.element(find.text('Light rain in Barangay 2'));
    expect(MediaQuery.textScalerOf(context).scale(10), 20);
    await tester.ensureVisible(find.text('Close'));
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Weather details'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });

  testWidgets('off and checking detail sheets do not claim an enabled action',
      (tester) async {
    final mood = SundoTimeMood(DateTime(2026, 10, 8, 9));
    for (final (enabled, checking) in [(false, false), (true, true)]) {
      await mountSummary(tester, mood,
          enabled: enabled, checking: checking, width: 320, scale: 1.4);
      await tester.tap(find.byKey(const ValueKey('sundo-weather-summary')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Weather details'), findsOneWidget);
      expect(find.text('Refresh weather'), findsNothing);
      if (!enabled) {
        expect(find.textContaining('Auto-refresh'), findsNothing);
        expect(find.text('Weather is off in Settings'), findsNWidgets(2));
        expect(find.byWidgetPredicate((widget) => widget is FilledButton),
            findsNothing);
      } else {
        expect(find.text('Auto-refresh · Every 5 min'), findsOneWidget);
        final button = tester.widget<FilledButton>(
            find.byWidgetPredicate((widget) => widget is FilledButton));
        expect(button.onPressed, isNull);
      }
      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
