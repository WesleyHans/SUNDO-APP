import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/app/resident_shell.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/auth/login_screen.dart';
import 'package:sundo_sipalay/features/live_map/live_map_screen.dart';
import 'package:sundo_sipalay/features/live_map/widgets/map_tracking_widgets.dart';
import 'package:sundo_sipalay/features/report_concern/report_concern_screen.dart';
import 'package:sundo_sipalay/shared/widgets/resident_components.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';
import 'package:sundo_sipalay/shared/widgets/schedule_notification_widgets.dart';
import 'location_platform_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() {
    mockUnavailableDeviceLocation();
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
  });

  testWidgets(
      'login leaves enter from the reference corners and stay fixed while scrolling',
      (tester) async {
    tester.view.physicalSize = const Size(320, 715);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    var backs = 0;
    final mood = SundoTimeMood(DateTime(2026, 10, 6, 11));
    await tester.pumpWidget(MaterialApp(
        theme: buildSundoTheme(mood),
        home: SundoTimeScope(
            mood: mood,
            child: ScenicBackdrop(
                child: LoginScreen(
                    onBack: () => backs++,
                    onLoginSuccess: () {},
                    onCreateAccount: () {})))));
    await tester.pumpAndSettle();
    final leaves = _leafBounds(tester);
    const viewport = Rect.fromLTRB(0, 0, 320, 715);
    _expectCornerEntry(leaves, viewport);
    expect(leaves.first.top, lessThan(0),
        reason: 'The upper leaf cluster enters above the screen edge.');
    expect(leaves.last.bottom, lessThanOrEqualTo(715 - 24));
    expect(leaves.first.center.dx, greaterThan(160));
    expect(leaves.last.center.dx, lessThan(160));
    expect(
        tester.getRect(find.byTooltip('Back')).overlaps(leaves.first), isFalse);
    await tester.tap(find.byTooltip('Back'));
    expect(backs, 1);
    await tester.enterText(
        find.byType(TextFormField).first, 'juan@example.com');
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(_leafBounds(tester), leaves,
        reason: 'The corner art must not scroll away with the login form.');
    expect(find.text('juan@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('report keeps corner leaves and usable back and filter controls',
      (tester) async {
    const locationChannel = MethodChannel('flutter.baseflow.com/geolocator');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            locationChannel,
            (call) async =>
                call.method == 'isLocationServiceEnabled' ? false : null);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(locationChannel, null));
    tester.view.physicalSize = const Size(320, 715);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    var backs = 0;
    final mood = SundoTimeMood(DateTime(2026, 10, 6, 11));
    await tester.pumpWidget(MaterialApp(
        theme: buildSundoTheme(mood),
        home: SundoTimeScope(
            mood: mood,
            child: ScenicBackdrop(
                child: ReportGarbageScreen(onBack: () => backs++)))));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    final leaves = _leafBounds(tester);
    final frame = tester.getRect(find.byType(SundoResidentLeaves).first);
    _expectCornerEntry(leaves, frame);
    expect(frame.top, greaterThanOrEqualTo(32));
    expect(leaves.last.bottom, lessThanOrEqualTo(715 - 24));
    expect(
        tester.getRect(find.byTooltip('Back')).overlaps(leaves.first), isFalse);
    expect(tester.getRect(find.byType(SundoSegmentedTabs)).top,
        greaterThanOrEqualTo(tester.getRect(find.byTooltip('Back')).bottom));
    await tester.tap(find.text('My Reports'));
    await tester.pumpAndSettle();
    expect(find.text('No reports yet'), findsOneWidget);
    expect(_leafBounds(tester), leaves);
    await tester.tap(find.byTooltip('Back'));
    expect(backs, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'resident tabs retain corner leaves without page headers or blocked actions',
      (tester) async {
    await _loadPreviewFonts(tester);
    tester.view.physicalSize = const Size(320, 715);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final mood = SundoTimeMood(DateTime(2026, 10, 6, 11));
    final residentPreview = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        theme: buildSundoTheme(mood),
        home: MediaQuery(
            data: const MediaQueryData(
                disableAnimations: true,
                size: Size(320, 715),
                padding: EdgeInsets.only(top: 32, bottom: 24),
                viewPadding: EdgeInsets.only(top: 32, bottom: 24),
                textScaler: TextScaler.linear(1.4)),
            child: SundoTimeScope(
                mood: mood,
                child: RepaintBoundary(
                    key: residentPreview,
                    child: ScenicBackdrop(
                        child: MainNavigationShell(onLogout: () {})))))));
    await tester.pumpAndSettle();
    List<Rect>? originalLeaves;
    for (final tab in ['Home', 'Schedule', 'Alerts', 'Profile']) {
      await tester.tap(find.descendant(
          of: find.byType(SundoBottomNavigation), matching: find.text(tab)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(SundoHeaderLeaves), findsNothing);
      expect(find.byType(SundoResidentLeaves), findsWidgets);
      final frame = tester.getRect(find.byType(SundoResidentLeaves).first);
      final navigation = tester.getRect(find.byType(SundoBottomNavigation));
      final leaves = _leafBounds(tester);
      expect(frame.top, 0,
          reason: 'The shared corner art extends behind the status bar.');
      expect(frame.bottom, lessThanOrEqualTo(navigation.top));
      _expectCornerEntry(leaves, frame);
      originalLeaves ??= leaves;
      expect(leaves, originalLeaves,
          reason: 'Corner decorations must not jump between resident tabs.');
      final upperLeaf = leaves.first;
      final actions = switch (tab) {
        'Schedule' => ['Refresh schedules'],
        'Alerts' => ['Mark all read', 'Notification settings'],
        'Profile' => ['Edit profile'],
        _ => <String>[],
      };
      for (final action in actions) {
        expect(
            tester.getRect(find.byTooltip(action)).overlaps(upperLeaf), isFalse,
            reason: '$action must remain separate from the upper leaves.');
      }
      if (tab == 'Schedule' || tab == 'Alerts') {
        final filters = tester.getRect(find.byType(SundoSegmentedTabs));
        expect(filters.top, greaterThanOrEqualTo(upperLeaf.bottom));
      }
      if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
        await tester.runAsync(() async {
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(image.image, residentPreview.currentContext!);
          }
        });
        await tester.pumpAndSettle();
        await expectLater(
            find.byKey(residentPreview),
            matchesGoldenFile(
                'goldens/resident_${tab.toLowerCase()}_leaves.png'));
      }
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsWidgets);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(TextFormField).first)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alerts').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notification settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'map has no decorative leaves and keeps navigation controls usable',
      (tester) async {
    await _loadPreviewFonts(tester);
    tester.view.physicalSize = const Size(320, 715);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final preview = GlobalKey();
    final mood = SundoTimeMood(DateTime(2026, 10, 6, 11));
    await tester.pumpWidget(MaterialApp(
        theme: buildSundoTheme(mood),
        home: SundoTimeScope(
            mood: mood,
            child: RepaintBoundary(
                key: preview,
                child: const LiveMapScreen(
                    isActive: false, enableTiles: false, enableGps: false)))));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Live Truck Tracking'), findsNothing);
    expect(find.byType(LeafSprig), findsNothing);
    final frame = tester.getRect(find.byType(LiveMapScreen));
    for (final action in [
      'Reset map north',
      'Fit active route',
      'Zoom in',
      'Zoom out',
      'Use my current location',
      'Map layers',
    ]) {
      final control = find.byTooltip(action);
      _expectWithin(tester.getRect(control), frame);
      expect(control.hitTestable(), findsOneWidget);
    }
    if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
      await tester.runAsync(() async {
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(image.image, preview.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      await expectLater(find.byKey(preview),
          matchesGoldenFile('goldens/resident_map_leaves.png'));
    }
    await tester.tap(find.byTooltip('Map layers'));
    await tester.pumpAndSettle();
    expect(find.text('Numbered collection points'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('short shell map keeps controls above the tracking sheet',
      (tester) async {
    await _loadPreviewFonts(tester);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final preview = GlobalKey();
    final mood = SundoTimeMood(DateTime(2026, 10, 6, 11));
    await tester.pumpWidget(MaterialApp(
        theme: buildSundoTheme(mood),
        home: SundoTimeScope(
            mood: mood,
            child: RepaintBoundary(
                key: preview,
                child: Scaffold(
                    body: SafeArea(
                        bottom: false,
                        child: Column(children: [
                          Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 5),
                              color: const Color(0xFFEAF8EE),
                              child: const Text(
                                  'LOCAL DEMO · Sample fleet and schedules · Reports stay on this phone',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 9))),
                          const Expanded(
                              child: LiveMapScreen(
                                  isActive: false,
                                  enableTiles: false,
                                  enableGps: false))
                        ])),
                    bottomNavigationBar: SundoBottomNavigation(
                        index: 1, onChanged: (_) {}, unread: 0))))));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LeafSprig), findsNothing);
    final sheet = tester.getRect(find.byType(SundoTrackingBottomSheet));
    final viewport = tester.getRect(find.byType(LiveMapScreen));
    expect(viewport.height, lessThan(520));
    expect(sheet.bottom, lessThanOrEqualTo(viewport.bottom));
    for (final action in [
      'Reset map north',
      'Fit active route',
      'Zoom in',
      'Zoom out',
      'Use my current location',
      'Map layers'
    ]) {
      final control = find.byTooltip(action);
      final bounds = tester.getRect(control);
      expect(control.hitTestable(), findsOneWidget,
          reason: '$action must remain tappable in a short resident map.');
      expect(bounds.bottom, lessThanOrEqualTo(sheet.top),
          reason: '$action must remain above the default tracking sheet.');
    }
    if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
      await tester.runAsync(() async {
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(image.image, preview.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      await expectLater(find.byKey(preview),
          matchesGoldenFile('goldens/resident_map_short_leaves.png'));
    }
    await tester.tap(find.byTooltip('Map layers'));
    await tester.pumpAndSettle();
    expect(find.text('Numbered collection points'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _loadPreviewFonts(WidgetTester tester) =>
    tester.runAsync(() async {
      for (final weight in FontWeight.values) {
        GoogleFonts.outfit(fontWeight: weight);
        GoogleFonts.plusJakartaSans(fontWeight: weight);
      }
      await GoogleFonts.pendingFonts();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });

List<Rect> _leafBounds(WidgetTester tester) {
  final finder = find.byType(LeafSprig);
  expect(finder, findsNWidgets(2));
  for (final leaf in finder.evaluate()) {
    final leafFinder = find.byWidget(leaf.widget);
    final artwork = tester.widget<Image>(
        find.descendant(of: leafFinder, matching: find.byType(Image)));
    final provider = artwork.image;
    final asset = (provider is ResizeImage ? provider.imageProvider : provider)
        as AssetImage;
    expect(asset.assetName, 'assets/images/sundo-leaf-sprig.png',
        reason: 'Reference corners retain the original natural leaf image.');
    expect(artwork.excludeFromSemantics, isTrue);
  }
  return [
    for (var index = 0; index < 2; index++) tester.getRect(finder.at(index))
  ]..sort((a, b) => a.top.compareTo(b.top));
}

void _expectCornerEntry(List<Rect> leaves, Rect frame) {
  expect(leaves.first.right, greaterThan(frame.right),
      reason: 'The upper sprig enters from the right screen edge.');
  expect(leaves.last.left, lessThan(frame.left),
      reason: 'The lower sprig enters from the left screen edge.');
  for (final leaf in leaves) {
    final visible = leaf.intersect(frame);
    expect(visible.width, greaterThanOrEqualTo(60));
    expect(visible.height, greaterThan(70));
    _expectWithin(visible, frame);
  }
}

void _expectWithin(Rect subject, Rect frame) {
  expect(subject.left, greaterThanOrEqualTo(frame.left));
  expect(subject.top, greaterThanOrEqualTo(frame.top));
  expect(subject.right, lessThanOrEqualTo(frame.right));
  expect(subject.bottom, lessThanOrEqualTo(frame.bottom));
}
