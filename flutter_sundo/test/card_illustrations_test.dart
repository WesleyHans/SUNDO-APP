import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
      expect(find.textContaining('Auto-refresh · Every 5 min'), findsOneWidget);
      expect(find.textContaining('Updated 5 min ago'), findsOneWidget,
          reason: 'Polling must not misrepresent the observation time');
      final icon = tester.widget<SundoCardIllustratedIcon>(find.byType(SundoCardIllustratedIcon));
      expect(icon.illustration, illustration);
      final decoded = tester.widget<RawImage>(find.descendant(
          of: find.byType(SundoCardIllustratedIcon),
          matching: find.byType(RawImage)));
      expect(decoded.image, isNotNull,
          reason: 'The illustration must render, not just select an asset');
      expect(decoded.image!.width, 256);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
        await expectLater(find.byKey(const ValueKey('weather-illustration-preview')),
            matchesGoldenFile('goldens/weather_illustrated_$name.png'));
      }
      await tester.tap(find.byTooltip('Refresh local weather'));
      expect(refreshes, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        debugDisableShadows = originalShadows;
      }
    });
  }
}
