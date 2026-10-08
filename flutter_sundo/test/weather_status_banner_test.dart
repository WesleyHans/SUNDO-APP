import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/home/home_screen.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';
import 'package:sundo_sipalay/shared/widgets/weather_status_banner.dart';
import 'package:sundo_sipalay/shared/widgets/time_based_background.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';
import 'location_platform_fixture.dart';

const _deviceLocation = WeatherLocation(
  latitude: 9.75,
  longitude: 122.40,
  label: 'Your location',
  isDeviceLocation: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final now = DateTime(2026, 10, 5, 19, 10);

  setUp(() {
    mockUnavailableDeviceLocation();
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
  });

  Future<void> loadFonts(WidgetTester tester) => tester.runAsync(() async {
        for (final weight in FontWeight.values) {
          GoogleFonts.outfit(fontWeight: weight);
          GoogleFonts.plusJakartaSans(fontWeight: weight);
        }
        await GoogleFonts.pendingFonts();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });

  SipalayWeather weather({
    int code = 0,
    DateTime? validAt,
    DateTime? fetchedAt,
    WeatherLocation? location = _deviceLocation,
  }) =>
      SipalayWeather(
        validAt: validAt ?? now,
        fetchedAt: fetchedAt ?? now,
        weatherCode: code,
        precipitationMm: 0,
        rainMm: 0,
        showersMm: 0,
        location: location,
      );

  Widget banner(SipalayWeather? snapshot,
      {DateTime? clock,
      bool enabled = false,
      bool checking = false,
      VoidCallback? refresh}) {
    final mood = SundoTimeMood(clock ?? now, weather: snapshot);
    return MaterialApp(
      theme: buildSundoTheme(mood),
      home: SundoTimeScope(
        mood: mood,
        weatherEnabled: enabled,
        checkingWeather: checking,
        onWeatherRefresh: refresh,
        child: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(18),
            child: SundoWeatherStatusBanner(),
          ),
        ),
      ),
    );
  }

  testWidgets('enabled weather shows unavailable status and a working retry',
      (tester) async {
    await loadFonts(tester);
    var requests = 0;
    await tester
        .pumpWidget(banner(null, enabled: true, refresh: () => requests++));
    expect(find.textContaining('Weather unavailable'), findsOneWidget);
    expect(find.textContaining('Rainy'), findsNothing);
    expect(find.textContaining('Clear weather'), findsNothing);
    await tester.tap(find.byTooltip('Refresh local weather'));
    expect(requests, 1);
    await tester.pumpWidget(
        banner(null, enabled: true, checking: true, refresh: () => requests++));
    expect(find.textContaining('Checking weather'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Refresh local weather'), findsNothing);
    await tester.pumpWidget(
        banner(weather(code: 3), enabled: true, refresh: () => requests++));
    expect(find.text('Cloudy at your location'), findsOneWidget);
    expect(find.textContaining('Weather unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('unavailable, stale, unknown and unlocated weather stays hidden',
      (tester) async {
    await loadFonts(tester);
    for (final snapshot in [
      null,
      weather(validAt: now.subtract(const Duration(minutes: 31))),
      weather(fetchedAt: now.subtract(const Duration(minutes: 31))),
      weather(code: 4),
      weather(location: null),
    ]) {
      await tester.pumpWidget(banner(snapshot));
      expect(
        find.descendant(
          of: find.byType(SundoWeatherStatusBanner),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'fresh local conditions distinguish clear, cloudy and wet weather',
      (tester) async {
    await loadFonts(tester);
    final expectations = {
      0: 'Clear weather at your location',
      3: 'Cloudy at your location',
      61: 'Rainy at your location',
      51: 'Light rain at your location',
      95: 'Thunderstorms at your location',
    };
    for (final entry in expectations.entries) {
      await tester.pumpWidget(banner(weather(code: entry.key)));
      expect(find.text(entry.value), findsOneWidget);
      expect(find.textContaining('Model-based current conditions'),
          findsOneWidget);
      expect(find.textContaining('Collection may be affected'),
          entry.key >= 51 ? findsOneWidget : findsNothing);
      expect(find.textContaining('alert'), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('saved-area conditions name the area without claiming device GPS',
      (tester) async {
    await loadFonts(tester);
    const savedArea = WeatherLocation(
      latitude: 9.75,
      longitude: 122.40,
      label: 'Barangay 2 (Poblacion)',
      isDeviceLocation: false,
    );
    await tester.pumpWidget(banner(weather(code: 51, location: savedArea)));
    expect(find.text('Light rain in Barangay 2 (Poblacion)'), findsOneWidget);
    expect(find.textContaining('at your location'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('status announces its location, observation age and rain caution',
      (tester) async {
    await loadFonts(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(banner(weather(
      code: 63,
      validAt: now.subtract(const Duration(minutes: 7)),
    )));
    expect(find.textContaining('Updated 7 min ago'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(
        r'^Rainy at your location\. Model-based current conditions.*'
        r'Updated 7 min ago\. Collection may be affected by rain\.$',
      )),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });

  testWidgets('weather disappears when its current observation ages out',
      (tester) async {
    await loadFonts(tester);
    final snapshot = weather(code: 63);
    await tester.pumpWidget(banner(snapshot));
    expect(find.text('Rainy at your location'), findsOneWidget);
    await tester.pumpWidget(
        banner(snapshot, clock: now.add(const Duration(minutes: 31))));
    expect(find.text('Rainy at your location'), findsNothing);
    expect(find.textContaining('Clear weather'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final hour in [8, 19]) {
    testWidgets('home weather remains usable at 320 px and large text at $hour',
        (tester) async {
      await loadFonts(tester);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final clock = DateTime(2026, 10, 5, hour, 10);
      final snapshot = weather(code: 63, validAt: clock, fetchedAt: clock);
      final mood = SundoTimeMood(clock, weather: snapshot);
      final navigations = <int>[];
      await tester.pumpWidget(MaterialApp(
        theme: buildSundoTheme(mood),
        home: RepaintBoundary(
          key: const ValueKey('weather-home-preview'),
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.4),
            ),
            child: SundoTimeScope(
              mood: mood,
              child: ScenicBackdrop(
                  child: HomeScreen(onNavigate: navigations.add)),
            ),
          ),
        ),
      ));
      await tester.runAsync(() async {
        final context =
            tester.element(find.byKey(const ValueKey('weather-home-preview')));
        await precacheImage(
            AssetImage(sundoEnvironmentArtwork(mood.environment)), context);
      });
      await tester.pump(const Duration(milliseconds: 300));
      final greeting = tester.getRect(find.text('${mood.greeting},'));
      final status = tester.getRect(find.text('Rainy'));
      final collection = tester.getRect(find.text('Next Collection'));
      expect(status.top, greaterThan(greeting.bottom));
      expect(status.bottom, lessThan(collection.top));
      expect(status.left, greaterThanOrEqualTo(18));
      expect(status.right, lessThanOrEqualTo(302));
      if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
        await expectLater(find.byKey(const ValueKey('weather-home-preview')),
            matchesGoldenFile('goldens/weather_home_$hour.png'));
      }
      await tester.ensureVisible(find.text('View Live Truck'));
      await tester.pump();
      await tester.tap(find.text('View Live Truck'));
      expect(navigations, [1]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
