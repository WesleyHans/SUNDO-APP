import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/app/router.dart';
import 'package:sundo_sipalay/app/resident_shell.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/auth/login_screen.dart';
import 'package:sundo_sipalay/features/onboarding/welcome_screen.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';
import 'package:sundo_sipalay/shared/widgets/sundo_tab_stack.dart';
import 'package:sundo_sipalay/shared/widgets/resident_header.dart';
import 'package:sundo_sipalay/shared/widgets/time_based_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppStore.setIdentity(null);
  });

  for (final hour in [11, 20]) {
    testWidgets('welcome to login scenery blends continuously at $hour',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(sundoRouterProvider)..go('/welcome');
      final mood = SundoTimeMood(DateTime(2026, 10, 6, hour));
      final boundary = GlobalKey();
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
              theme: buildSundoTheme(mood),
              routerConfig: router,
              builder: (context, child) => RepaintBoundary(
                  key: boundary,
                  child: SundoTimeScope(
                      mood: mood, child: ScenicBackdrop(child: child!))))));
      await tester.runAsync(() async {
        final context = boundary.currentContext!;
        await precacheImage(
            AssetImage(sundoEnvironmentArtwork(mood.environment)), context);
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(image.image, context);
        }
      });
      await tester.pumpAndSettle();
      final start = await _sceneryLuminance(tester, boundary);
      router.go('/login');
      await tester.pump();
      final first = await _sceneryLuminance(tester, boundary);
      expect((first - start).abs(), lessThan(1),
          reason: 'The first login frame must retain the outgoing scenery.');
      await tester.pump(const Duration(milliseconds: 150));
      final quarter = await _sceneryLuminance(tester, boundary);
      await tester.pump(const Duration(milliseconds: 150));
      final middle = await _sceneryLuminance(tester, boundary);
      if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
        await expectLater(find.byKey(boundary),
            matchesGoldenFile('goldens/login_transition_${hour}_midpoint.png'));
      }
      await tester.pump(const Duration(milliseconds: 350));
      final end = await _sceneryLuminance(tester, boundary);
      expect((end - start).abs(), greaterThan(8));
      expect((quarter - start).abs(), lessThan((middle - start).abs()));
      expect((middle - start).abs(), lessThan((end - start).abs()));
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
        await expectLater(find.byKey(boundary),
            matchesGoldenFile('goldens/login_transition_${hour}_complete.png'));
      }
      await tester.enterText(
          find.byType(TextFormField).first, 'resident@example.com');
      expect(find.text('resident@example.com'), findsOneWidget);
      router.go('/register');
      await tester.pumpAndSettle();
      expect(find.text('Create Your Account'), findsOneWidget);
      router.go('/welcome');
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
      'resident tabs share one compact header with intact leaves and working actions',
      (tester) async {
    tester.view.physicalSize = const Size(320, 715);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final mood = SundoTimeMood(DateTime(2026, 10, 6, 11));
    final profilePreview = GlobalKey();
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
                    key: profilePreview,
                    child: ScenicBackdrop(
                        child: MainNavigationShell(onLogout: () {})))))));
    await tester.pump();
    await tester.tap(find.text('Profile').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final header = find.byType(SundoResidentHeader);
    expect(header, findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(SundoHeaderLeaves), findsOneWidget);
    final frame = tester.getRect(header);
    final leaf = tester.getRect(find.byType(LeafSprig));
    final title = tester
        .getRect(find.descendant(of: header, matching: find.text('Profile')));
    final edit = tester.getRect(find.byTooltip('Edit profile'));
    expect(frame.height, 56);
    expect(frame.top, greaterThanOrEqualTo(32));
    expect(leaf.left, greaterThanOrEqualTo(frame.left));
    expect(leaf.top, greaterThanOrEqualTo(frame.top));
    expect(leaf.bottom, lessThanOrEqualTo(frame.bottom));
    expect(leaf.size, const Size(48, 48));
    expect(leaf.right, closeTo(frame.right - 6, .1));
    expect(leaf.top, closeTo(frame.top + 2, .1));
    expect(leaf.overlaps(title), isFalse);
    expect(leaf.overlaps(edit), isFalse);
    expect(title.center.dx, closeTo(160, .1));
    if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
      await tester.runAsync(() async {
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(image.image, profilePreview.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      await expectLater(find.byKey(profilePreview),
          matchesGoldenFile('goldens/profile_shared_header.png'));
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
    final alertTitle = tester
        .getRect(find.descendant(of: header, matching: find.text('Alerts')));
    for (final tooltip in ['Mark all read', 'Notification settings']) {
      final action = tester.getRect(find.byTooltip(tooltip));
      expect(action.overlaps(alertTitle), isFalse);
      expect(action.overlaps(tester.getRect(find.byType(LeafSprig))), isFalse);
      expect(action.left, greaterThanOrEqualTo(0));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tabs fade, retain field state and block outgoing input',
      (tester) async {
    var oldPresses = 0;
    final tabs = [
      Column(children: [
        const TextField(key: ValueKey('saved-input')),
        TextButton(
            onPressed: () => oldPresses++, child: const Text('Outgoing action'))
      ]),
      const ColoredBox(
          color: Colors.blue, child: Center(child: Text('Second tab'))),
      const ColoredBox(
          color: Colors.orange, child: Center(child: Text('Third tab'))),
    ];
    Widget surface(int index, {bool reduced = false}) => MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child:
                Scaffold(body: SundoTabStack(index: index, children: tabs))));
    await tester.pumpWidget(surface(0));
    await tester.enterText(find.byType(TextField), 'Preserve this');
    final originalState = tester.state(find.byType(TextField));
    await tester.pumpWidget(surface(1));
    await tester.pump(const Duration(milliseconds: 100));
    final oldFade = tester.widget<FadeTransition>(find
        .ancestor(
            of: find.text('Outgoing action'),
            matching: find.byType(FadeTransition))
        .first);
    final newFade = tester.widget<FadeTransition>(find
        .ancestor(
            of: find.text('Second tab'), matching: find.byType(FadeTransition))
        .first);
    expect(oldFade.opacity.value, inExclusiveRange(0, 1));
    expect(newFade.opacity.value, inExclusiveRange(0, 1));
    await tester.tap(find.text('Outgoing action'), warnIfMissed: false);
    expect(oldPresses, 0);
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.semantics.byLabel('Outgoing action'), findsNothing);
    expect(find.semantics.byLabel('Second tab'), findsOneWidget);
    await tester.pumpWidget(surface(2));
    expect(newFade.opacity.value, inExclusiveRange(0, 1),
        reason: 'Rapid navigation must continue from current opacity.');
    await tester.pumpAndSettle();
    await tester.pumpWidget(surface(0));
    await tester.pumpAndSettle();
    expect(find.text('Preserve this'), findsOneWidget);
    expect(tester.state(find.byType(TextField)), same(originalState));
    await tester.pumpWidget(surface(1, reduced: true));
    await tester.pump();
    expect(find.text('Outgoing action'), findsNothing);
    expect(find.text('Second tab'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });
}

Future<double> _sceneryLuminance(WidgetTester tester, GlobalKey key) async =>
    (await tester.runAsync(() async {
      final image = await (key.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pixels = bytes!.buffer.asUint8List();
      var sum = 0.0;
      // The outer strip contains scenery alone, away from forms and buttons.
      for (var y = 300; y < 500; y++) {
        for (var x = 4; x < 14; x++) {
          final offset = (y * 390 + x) * 4;
          sum += pixels[offset] * .2126 +
              pixels[offset + 1] * .7152 +
              pixels[offset + 2] * .0722;
        }
      }
      image.dispose();
      return sum / 2000;
    }))!;
