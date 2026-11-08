import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/onboarding/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> mountWelcome(WidgetTester tester,
      {GlobalKey<NavigatorState>? navigator, bool reduceMotion = false}) async {
    await tester.runAsync(() async {
      GoogleFonts.outfit(fontWeight: FontWeight.w800);
      GoogleFonts.plusJakartaSans();
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800);
      await GoogleFonts.pendingFonts();
    });
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reduceMotion),
          child: child!),
      home: SundoTimeScope(
        mood: SundoTimeMood(DateTime(2026, 10, 5, 9)),
        child: WelcomeScreen(
            onGetStarted: () {}, onLogIn: () {}, onCreateAccount: () {}),
      ),
    ));
    await tester.pump();
  }

  Finder dot(int index) => find.byWidgetPredicate((widget) =>
      widget is Semantics &&
      widget.properties.label == 'Introduction ${index + 1}');

  void expectSlide(WidgetTester tester, int selected) {
    for (var index = 0; index < 3; index++) {
      expect(tester.widget<Semantics>(dot(index)).properties.selected,
          index == selected);
    }
  }

  testWidgets('welcome loops all three slides and a dot tap resets its delay',
      (tester) async {
    await mountWelcome(tester);
    expectSlide(tester, 0);
    final centers = <double>[];
    for (var index = 0; index < 3; index++) {
      final button = dot(index);
      centers.add(tester.getCenter(button).dx);
      expect(tester.getSize(button), const Size(44, 44));
      final mark = find.descendant(of: button, matching: find.byType(Container));
      expect(tester.getSize(mark), const Size(8, 8));
    }
    expect(centers[1] - centers[0], centers[2] - centers[1]);

    for (final selected in [1, 2, 0]) {
      await tester.pump(const Duration(seconds: 6));
      expectSlide(tester, selected);
    }
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(dot(1));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expectSlide(tester, 1);
    await tester.pump(const Duration(seconds: 1));
    expectSlide(tester, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('welcome autoplay pauses while covered or backgrounded',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await mountWelcome(tester, navigator: navigator);
    unawaited(navigator.currentState!.push<void>(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Over Welcome')))));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 7));
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expectSlide(tester, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 7));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expectSlide(tester, 0);
    await tester.pump(const Duration(seconds: 6));
    expectSlide(tester, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion keeps the welcome slides manually selectable',
      (tester) async {
    await mountWelcome(tester, reduceMotion: true);
    await tester.pump(const Duration(seconds: 12));
    expectSlide(tester, 0);
    await tester.tap(dot(2));
    await tester.pump();
    expectSlide(tester, 2);
    await tester.pump(const Duration(seconds: 12));
    expectSlide(tester, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
