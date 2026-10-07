import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/app/resident_shell.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/home/home_screen.dart';
import 'package:sundo_sipalay/features/home/widgets/sundo_dashboard_widgets.dart';
import 'package:sundo_sipalay/models/map_tracking.dart';
import 'package:sundo_sipalay/repositories/schedule_repository.dart';
import 'package:sundo_sipalay/repositories/weather_repository.dart';
import 'package:sundo_sipalay/shared/widgets/resident_components.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';
import 'package:sundo_sipalay/shared/widgets/time_based_background.dart';
import 'package:sundo_sipalay/shared/widgets/weather_status_banner.dart';

import 'location_platform_fixture.dart';

const _preview = ValueKey('home-dashboard-preview');

// Freeze Philippine sample dates while the absolute clock keeps fleet fixes fresh.
DateTime get _previewDay => DateTime(2026, 10, 7, 9);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() async {
    mockUnavailableDeviceLocation();
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
    await AppStore.setName('Juan Dela Cruz');
    await AppStore.setBarangay('Barangay 1 (Poblacion)');
    final repository = MockScheduleRepository.shared;
    final original = List<CollectionSchedule>.of(repository.items);
    repository.items
      ..clear()
      ..addAll([
        CollectionSchedule(
            id: 'sample-next-collection',
            barangay: 'Barangay 1',
            pickupAt: DateTime(2026, 10, 10, 13),
            timeLabel: '1:00 PM – 4:00 PM',
            route: 'Route A',
            wasteType: 'Recyclables'),
        CollectionSchedule(
            id: 'other-area-tomorrow',
            barangay: 'Barangay 2',
            pickupAt: DateTime(2026, 10, 8, 8),
            timeLabel: '8:00 AM – 12:00 PM',
            route: 'Route B',
            wasteType: 'General Waste'),
      ]);
    addTearDown(() => repository.items
      ..clear()
      ..addAll(original));
  });

  for (final width in [390.0, 320.0]) {
    testWidgets('reference info cards remain balanced side by side at $width',
        (tester) async {
      await _mount(tester, MainNavigationShell(onLogout: () {}), width: width);
      expect(find.byKey(const ValueKey('sundo-home-info-row')), findsOneWidget);
      expect(find.text('Good Morning,'), findsOneWidget);
      expect(find.text('Juan!'), findsOneWidget);
      expect(find.text('JD'), findsOneWidget);
      expect(find.text('No collection scheduled tomorrow'), findsOneWidget);
      expect(find.text('Thu, Oct 8 · Barangay 1 (Poblacion)'), findsOneWidget);
      expect(find.text('Sample schedule · Local demo'), findsOneWidget);
      expect(find.text('Saturday, Oct 10, 2026'), findsOneWidget);
      final cards = find.byType(SundoInfoCard);
      expect(cards, findsNWidgets(2));
      final left = tester.getRect(cards.first);
      final right = tester.getRect(cards.last);
      expect(left.top, closeTo(right.top, .01));
      expect(left.height, closeTo(right.height, .01));
      expect(left.right, lessThan(right.left));
      expect(left.left, greaterThanOrEqualTo(18));
      expect(right.right, lessThanOrEqualTo(width - 18));
      final nav = tester
          .widget<SundoBottomNavigation>(find.byType(SundoBottomNavigation));
      expect(nav.index, 0);
      for (final label in SundoBottomNavigation.labels) {
        expect(
            find.descendant(
                of: find.byType(SundoBottomNavigation),
                matching: find.text(label)),
            findsOneWidget);
      }
      if (width == 390) {
        expect(tester.getRect(find.text('View Live Truck')).bottom,
            lessThan(tester.getRect(find.byType(SundoBottomNavigation)).top),
            reason:
                'The main map action stays visible above the fixed navigation.');
      }
      expect(tester.takeException(), isNull);
      await _capture(tester, 'dashboard_${width.toInt()}');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
      'large text receives full-width cards and a reachable live action',
      (tester) async {
    final navigations = <int>[];
    await _mount(tester, HomeScreen(onNavigate: navigations.add),
        width: 320, scale: 1.5);
    final name = tester.renderObject<RenderParagraph>(find.text('Juan!'));
    expect(name.didExceedMaxLines, isFalse,
        reason: 'The resident name must stay readable when system text grows.');
    expect(find.byKey(const ValueKey('sundo-home-info-stack')), findsOneWidget);
    final cards = find.byType(SundoInfoCard);
    expect(cards, findsNWidgets(2));
    final first = tester.getRect(cards.first);
    final second = tester.getRect(cards.last);
    expect(first.bottom, lessThan(second.top));
    expect(first.left, second.left);
    expect(first.width, second.width);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'dashboard_large_text');
    await tester.ensureVisible(find.text('View Live Truck'));
    await _finishMotion(tester);
    await tester.tap(find.text('View Live Truck'));
    expect(navigations, [1]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('header, both schedule cards and live button use real navigation',
      (tester) async {
    final navigations = <int>[];
    await _mount(tester, HomeScreen(onNavigate: navigations.add));
    final header = find.byType(SundoGreetingHeader);
    await tester.tap(find.descendant(
        of: header, matching: find.byIcon(Icons.notifications_rounded)));
    await tester.tap(find.descendant(of: header, matching: find.text('JD')));
    for (final card
        in tester.widgetList<SundoInfoCard>(find.byType(SundoInfoCard))) {
      final target = find.byWidget(card);
      await tester.ensureVisible(target);
      await _finishMotion(tester);
      await tester.tap(target);
    }
    await tester.ensureVisible(find.text('View Live Truck'));
    await _finishMotion(tester);
    await tester.tap(find.text('View Live Truck'));
    expect(navigations, [3, 4, 2, 2, 1]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dashboard weather reports real conditions and supports refresh',
      (tester) async {
    var refreshes = 0;
    final now = DateTime.utc(2026, 10, 7, 1);
    final weather = SipalayWeather(
        validAt: now,
        fetchedAt: now,
        weatherCode: 63,
        precipitationMm: 1,
        rainMm: 1,
        showersMm: 0,
        location: const WeatherLocation(
            latitude: 9.75,
            longitude: 122.40,
            label: 'Barangay 2',
            isDeviceLocation: false));
    Future<void> show(SundoTimeMood mood, {bool enabled = true}) => _mount(
        tester,
        const Scaffold(body: SundoWeatherStatusBanner(dashboardStyle: true)),
        mood: mood,
        weatherEnabled: enabled,
        refresh: () => refreshes++);
    await show(SundoTimeMood.fromInstant(now));
    expect(find.text('Weather unavailable'), findsOneWidget);
    expect(find.text('Using time-based scenery'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh local weather'));
    expect(refreshes, 1);
    await show(SundoTimeMood.fromInstant(now, weather: weather));
    expect(find.text('Rainy in Barangay 2'), findsOneWidget);
    expect(find.textContaining('at your location'), findsNothing);
    await show(SundoTimeMood.fromInstant(now.add(const Duration(minutes: 31)),
        weather: weather));
    expect(find.text('Weather unavailable'), findsOneWidget);
    expect(find.text('Rainy in Barangay 2'), findsNothing);
    await show(SundoTimeMood.fromInstant(now), enabled: false);
    expect(find.text('Time-based scenery'), findsOneWidget);
    expect(find.byTooltip('Refresh local weather'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('truck dashboard distinguishes demo, live and aged positions',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final now = DateTime.utc(2026, 10, 7, 1);
    MapTruckSnapshot truck({bool simulated = false, bool stale = false}) =>
        MapTruckSnapshot(
            id: 'sundo-test-truck',
            route: const MapOperatingRoute(id: 'A', name: 'Route A'),
            position: const LatLng(9.75, 122.40),
            updatedAt: stale ? now.subtract(const Duration(minutes: 3)) : now,
            active: true,
            simulated: simulated,
            stage: MapTrackingStage.onRoute,
            distanceKm: 3.2,
            etaMinutes: 12);
    Future<void> show(MapTruckSnapshot? snapshot) => _mount(tester,
        Scaffold(body: SundoLiveTruckCard(truck: snapshot, onViewMap: () {})),
        mood: SundoTimeMood.fromInstant(now), width: 390);
    await show(truck(simulated: true));
    expect(find.text('Truck is ON ROUTE'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Live demo updates')), findsOneWidget);
    expect(find.text('3.2 km away · ETA: 12 minutes'), findsOneWidget);
    expect(find.text('Simulated collection · Route A'), findsOneWidget);
    await show(truck());
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Live city updates')), findsOneWidget);
    expect(find.text('Live city update · Route A'), findsOneWidget);
    await show(truck(stale: true));
    expect(find.text('Truck is OFFLINE'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    expect(find.textContaining('3.2 km'), findsNothing);
    expect(find.textContaining('ETA:'), findsNothing);
    expect(find.text('Last known position · Route A'), findsOneWidget);
    await show(null);
    expect(find.textContaining('Awaiting fleet data'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    expect(tester.takeException(), isNull);
    for (final (width, scale) in [(250.0, 1.0), (320.0, 1.0), (250.0, 1.5)]) {
      await _mount(
          tester,
          Scaffold(
              body: Center(
                  child: SizedBox(
                      width: width,
                      child: const SundoProgressTracker(
                          stage: MapTrackingStage.onRoute)))),
          width: 390,
          scale: scale);
      final bounds = tester.getRect(find.byType(SundoProgressTracker));
      for (final label in [
        'Not Started', 'On Route', 'Approaching', 'Nearby', 'Completed'
      ]) {
        final finder = find.byWidgetPredicate((widget) => widget is Text &&
            widget.data?.replaceAll('\n', ' ') == label);
        expect(finder, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        expect(paragraph.didExceedMaxLines, isFalse);
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(bounds.left));
        expect(rect.right, lessThanOrEqualTo(bounds.right));
        final text = tester.widget<Text>(finder).data!;
        for (final box in paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length))) {
          expect(box.left, greaterThanOrEqualTo(-.01));
          expect(box.right, lessThanOrEqualTo(paragraph.size.width + .01),
              reason: '$label must render whole at $width px and scale $scale.');
        }
      }
      expect(find.bySemanticsLabel('Collection status: On Route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });

  testWidgets('Philippine greeting updates at noon and evening',
      (tester) async {
    for (final (instant, greeting) in [
      (DateTime.utc(2026, 10, 7, 3), 'Good Morning,'),
      (DateTime.utc(2026, 10, 7, 4), 'Good Afternoon,'),
      (DateTime.utc(2026, 10, 7, 10), 'Good Evening,'),
    ]) {
      await _mount(
          tester,
          SundoGreetingHeader(
              firstName: 'Juan',
              initials: 'JD',
              unread: 2,
              onNotifications: () {},
              onProfile: () {}),
          mood: SundoTimeMood.fromInstant(instant));
      expect(find.text(greeting), findsOneWidget);
      expect(find.text('Juan!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'decorative clock pauses off Home, in background and for reduced motion',
      (tester) async {
    var active = true;
    var reduced = false;
    var tickerEnabled = true;
    late StateSetter change;
    await tester.pumpWidget(
        MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      change = setState;
      return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: TickerMode(
              enabled: tickerEnabled,
              child: SundoDashboardMotion(
                  isActive: active,
                  child: const SundoDashboardCard(
                      decoration: SundoDashboardDecoration.weather,
                      child: SizedBox(width: 200, height: 90)))));
    })));
    Animation<double> clock() => tester
        .widget<SundoDashboardMotionScope>(
            find.byType(SundoDashboardMotionScope))
        .animation;
    await tester.pump(const Duration(milliseconds: 100));
    final initial = clock().value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock().value, greaterThan(initial));
    expect(clock().value - initial, lessThan(.06),
        reason:
            'The shared decorative cycle moves slowly over eighteen seconds.');
    for (final update in [
      () => active = false,
      () {
        active = true;
        reduced = true;
      },
      () {
        reduced = false;
        tickerEnabled = false;
      },
    ]) {
      change(update);
      await tester.pump();
      final paused = clock().value;
      await tester.pump(const Duration(seconds: 1));
      expect(clock().value, paused);
    }
    change(() => tickerEnabled = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final paused = clock().value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock().value, paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(clock().value, greaterThan(paused));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('card entrance finishes once and does not replay for new data',
      (tester) async {
    late StateSetter change;
    var label = 'Initial fleet data';
    await tester.pumpWidget(
        MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      change = setState;
      return SundoDashboardEntrance(
          order: 2, child: Center(child: Text(label)));
    })));
    double opacity() => tester
        .widget<Opacity>(find.descendant(
            of: find.byType(SundoDashboardEntrance),
            matching: find.byType(Opacity)))
        .opacity;
    expect(opacity(), 0);
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacity(), greaterThan(0));
    expect(opacity(), lessThan(1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(), 1);
    change(() => label = 'Updated fleet data');
    await tester.pump();
    expect(opacity(), 1);
    expect(find.text('Updated fleet data'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _mount(WidgetTester tester, Widget child,
    {double width = 390,
    double scale = 1,
    SundoTimeMood? mood,
    bool weatherEnabled = true,
    VoidCallback? refresh}) async {
  tester.view.physicalSize = Size(width, 844);
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
  final clock =
      mood ?? SundoTimeMood(DateTime.now(), philippineTime: _previewDay);
  await tester.pumpWidget(MaterialApp(
      theme: buildSundoTheme(clock),
      home: RepaintBoundary(
          key: _preview,
          child: MediaQuery(
              data: MediaQueryData(
                  size: Size(width, 844), textScaler: TextScaler.linear(scale)),
              child: SundoTimeScope(
                  mood: clock,
                  weatherEnabled: weatherEnabled,
                  onWeatherRefresh: refresh ?? () {},
                  child: ScenicBackdrop(child: child))))));
  await _finishMotion(tester);
}

// Repeating cloud/leaf painters intentionally never settle while Home is open.
Future<void> _finishMotion(WidgetTester tester) async {
  await tester.pump();
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('GENERATE_PREVIEWS')) return;
  final shadows = debugDisableShadows;
  debugDisableShadows = false;
  addTearDown(() => debugDisableShadows = shadows);
  await tester.runAsync(() async {
    final context = tester.element(find.byKey(_preview));
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, context);
    }
    final mood =
        tester.widget<SundoTimeScope>(find.byType(SundoTimeScope).first).mood;
    await precacheImage(
        AssetImage(sundoEnvironmentArtwork(mood.environment)), context);
  });
  await _finishMotion(tester);
  await expectLater(
      find.byKey(_preview), matchesGoldenFile('goldens/$name.png'));
  debugDisableShadows = shadows;
}
