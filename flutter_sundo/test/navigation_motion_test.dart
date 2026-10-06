import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sundo_sipalay/app/navigation_motion.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/shared/widgets/time_based_background.dart';

const _sceneryFadeKey = ValueKey('sundo-navigation-scenery-fade');
const _firstFrameKey = ValueKey('sundo-scene-first-frame');
const _pageFadeKey = ValueKey('sundo-page-fade');
const _outgoingFadeKey = ValueKey('sundo-page-outgoing-fade');
final _mood = SundoTimeMood(DateTime(2026, 10, 6, 11));
final _asset = sundoEnvironmentArtwork(_mood.environment);

void main() {
  for (final cached in [true, false]) {
    testWidgets(
        '${cached ? 'cached' : 'late'} scenery reveals smoothly on leaving welcome',
        (tester) async {
      final fixture = _NavigationFixture();
      final bundle = _DelayedSceneBundle();
      await tester.pumpWidget(_app(fixture.router, bundle));
      if (cached) await _releaseScene(tester, bundle);
      await tester.pump(const Duration(milliseconds: 500));

      fixture.router.go('/login');
      await tester.pump();
      expect(_sceneryOpacity(tester), 0);
      await tester.pump(const Duration(milliseconds: 225));
      expect(_sceneryOpacity(tester), greaterThan(0));
      expect(_sceneryOpacity(tester), lessThan(1));
      await tester.pump(const Duration(milliseconds: 225));
      expect(_sceneryOpacity(tester), 1);

      if (!cached) {
        // A decoded frame arriving after the navigation is also softened.
        await _releaseScene(tester, bundle);
        expect(_firstFrameOpacity(tester), 0);
        await tester.pump(const Duration(milliseconds: 150));
        expect(_firstFrameOpacity(tester), greaterThan(0));
        expect(_firstFrameOpacity(tester), lessThan(1));
        await tester.pump(const Duration(milliseconds: 450));
        expect(_firstFrameOpacity(tester), 1);
      }

      expect(tester.takeException(), isNull);
      await _close(tester, fixture.router);
    });
  }

  testWidgets('login, account creation and inner routes retain one scene',
      (tester) async {
    final fixture = _NavigationFixture();
    final bundle = _DelayedSceneBundle();
    await tester.pumpWidget(_app(fixture.router, bundle));
    await _releaseScene(tester, bundle);
    await tester.pump(const Duration(milliseconds: 500));
    final initialScene = tester.state(find.byType(SundoTimeBasedBackground));

    for (final path in ['/login', '/register', '/app']) {
      fixture.router.go(path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byType(SundoTimeBasedBackground), findsOneWidget);
      expect(tester.state(find.byType(SundoTimeBasedBackground)),
          same(initialScene));
      expect(_sceneryOpacity(tester), 1);
    }

    fixture.router.push('/report');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    expect(_sceneryOpacity(tester), 1);
    expect(tester.state(find.byType(SundoTimeBasedBackground)),
        same(initialScene));
    await tester.pump(const Duration(milliseconds: 225));
    fixture.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Home'), findsOneWidget);
    expect(tester.state(find.byType(SundoTimeBasedBackground)),
        same(initialScene));
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.router);
  });

  testWidgets('quick login to register navigation continues the scene reveal',
      (tester) async {
    final fixture = _NavigationFixture();
    final bundle = _DelayedSceneBundle();
    await tester.pumpWidget(_app(fixture.router, bundle));
    await _releaseScene(tester, bundle);
    await tester.pump(const Duration(milliseconds: 500));

    fixture.router.go('/login');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final opacityBefore = _sceneryOpacity(tester);
    expect(opacityBefore, greaterThan(0));
    expect(opacityBefore, lessThan(1));
    fixture.router.go('/register');
    await tester.pump();
    expect(_sceneryOpacity(tester), closeTo(opacityBefore, .0001));
    await tester.pump(const Duration(milliseconds: 225));
    expect(_sceneryOpacity(tester), greaterThan(opacityBefore));
    await tester.pump(const Duration(milliseconds: 450));
    expect(_sceneryOpacity(tester), 1);
    expect(find.text('Create account'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.router);
  });

  testWidgets('report push and pop fade Home while dialogs keep it visible',
      (tester) async {
    final fixture = _NavigationFixture();
    final bundle = _DelayedSceneBundle();
    await tester.pumpWidget(_app(fixture.router, bundle));
    await _releaseScene(tester, bundle);
    fixture.router.go('/app');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(_homeOutgoingOpacity(tester), 1);

    fixture.router.push('/report');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    expect(_homeOutgoingOpacity(tester), 0);
    expect(_sceneryOpacity(tester), 1);
    await tester.pump(const Duration(milliseconds: 241));

    fixture.router.pop();
    await tester.pump();
    await tester.pump();
    expect(_homeOutgoingOpacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 225));
    expect(_homeOutgoingOpacity(tester), lessThan(1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(_homeOutgoingOpacity(tester), greaterThan(0));
    expect(_homeOutgoingOpacity(tester), lessThan(1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_homeOutgoingOpacity(tester), 1);

    unawaited(showDialog<void>(
        context: tester.element(find.text('Home')),
        builder: (_) => const AlertDialog(title: Text('Details'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    expect(find.text('Details'), findsOneWidget);
    expect(_homeOutgoingOpacity(tester), 1);
    expect(_sceneryOpacity(tester), 1);
    Navigator.of(tester.element(find.text('Details'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    expect(_homeOutgoingOpacity(tester), 1);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.router);
  });

  testWidgets('fading pages ignore taps until they finish entering',
      (tester) async {
    final fixture = _NavigationFixture();
    final bundle = _DelayedSceneBundle();
    await tester.pumpWidget(_app(fixture.router, bundle));
    await _releaseScene(tester, bundle);
    await tester.pump(const Duration(milliseconds: 500));

    fixture.router.go('/login');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    final pageFade = tester.widget<FadeTransition>(find
        .ancestor(of: find.text('Log in'), matching: find.byKey(_pageFadeKey))
        .first);
    expect(pageFade.opacity.value, greaterThan(0));
    expect(pageFade.opacity.value, lessThan(1));
    await tester.tap(find.text('Log in'), warnIfMissed: false);
    expect(fixture.loginTaps, 0);
    await tester.pump(const Duration(milliseconds: 225));
    // The route reaches opacity 1 at 450 ms, then reports completion on the
    // following elapsed frame. Check interaction after that status change.
    await tester.pump(const Duration(milliseconds: 16));
    expect(pageFade.opacity.status, AnimationStatus.completed);
    await tester.tap(find.text('Log in'));
    expect(fixture.loginTaps, 1);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.router);
  });

  testWidgets('reduced motion reveals ready scenery and pages immediately',
      (tester) async {
    final fixture = _NavigationFixture();
    final bundle = _DelayedSceneBundle();
    await tester.pumpWidget(_app(fixture.router, bundle, reduceMotion: true));
    await _releaseScene(tester, bundle);
    fixture.router.go('/login');
    await tester.pump();
    await tester.pump();

    expect(_sceneryOpacity(tester), 1);
    expect(find.byKey(_pageFadeKey), findsNothing);
    await tester.tap(find.text('Log in'));
    expect(fixture.loginTaps, 1);
    fixture.router.go('/register');
    await tester.pump();
    await tester.pump();
    expect(_sceneryOpacity(tester), 1);
    expect(find.byKey(_pageFadeKey), findsNothing);
    expect(find.text('Create account'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.router);
  });

  testWidgets('enabling reduced motion completes an active scenery reveal',
      (tester) async {
    final fixture = _NavigationFixture();
    final bundle = _DelayedSceneBundle();
    await tester.pumpWidget(_app(fixture.router, bundle));
    await _releaseScene(tester, bundle);
    await tester.pump(const Duration(milliseconds: 500));
    fixture.router.go('/login');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final initialScene = tester.state(find.byType(SundoTimeBasedBackground));
    expect(_sceneryOpacity(tester), lessThan(1));

    await tester.pumpWidget(_app(fixture.router, bundle, reduceMotion: true));
    expect(_sceneryOpacity(tester), 1);
    expect(tester.state(find.byType(SundoTimeBasedBackground)),
        same(initialScene));
    await tester.tap(find.text('Log in'));
    expect(fixture.loginTaps, 1);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.router);
  });
}

Widget _app(GoRouter router, AssetBundle bundle, {bool reduceMotion = false}) =>
    MaterialApp.router(
      theme: ThemeData(scaffoldBackgroundColor: Colors.transparent),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: DefaultAssetBundle(
          bundle: bundle,
          child: SundoTimeScope(
            mood: _mood,
            child: SundoNavigationBackdrop(
                router: router, child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );

double _sceneryOpacity(WidgetTester tester) =>
    tester.widget<FadeTransition>(find.byKey(_sceneryFadeKey)).opacity.value;

double _homeOutgoingOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find
        .ancestor(
            of: find.text('Home', skipOffstage: false),
            matching: find.byKey(_outgoingFadeKey, skipOffstage: false))
        .first)
    .opacity
    .value;

double _firstFrameOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find.descendant(
        of: find.byKey(_firstFrameKey), matching: find.byType(FadeTransition)))
    .opacity
    .value;

Future<void> _releaseScene(
    WidgetTester tester, _DelayedSceneBundle bundle) async {
  final bytes = await tester.runAsync(() => rootBundle.load(_asset));
  bundle.release(bytes!);
  await tester.runAsync(() => precacheImage(AssetImage(_asset, bundle: bundle),
      tester.element(find.byType(SundoTimeBasedBackground))));
  await tester.pump();
}

Future<void> _close(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(const SizedBox.shrink());
  router.dispose();
}

class _NavigationFixture {
  late final GoRouter router = GoRouter(initialLocation: '/welcome', routes: [
    GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => sundoPage(
            state,
            const ColoredBox(
                color: Color(0xFFF8FCF9),
                child: Center(child: Text('Welcome full scene'))))),
    GoRoute(
        path: '/login',
        pageBuilder: (context, state) => sundoPage(
            state,
            Scaffold(
                body: Center(
                    child: TextButton(
                        onPressed: () => loginTaps++,
                        child: const Text('Log in')))))),
    GoRoute(
        path: '/register',
        pageBuilder: (context, state) => sundoPage(state,
            const Scaffold(body: Center(child: Text('Create account'))))),
    GoRoute(
        path: '/app',
        pageBuilder: (context, state) => sundoPage(
            state, const Scaffold(body: Center(child: Text('Home'))))),
    GoRoute(
        path: '/report',
        pageBuilder: (context, state) => sundoPage(
            state, const Scaffold(body: Center(child: Text('Report'))))),
  ]);
  int loginTaps = 0;
}

class _DelayedSceneBundle extends CachingAssetBundle {
  final _pending = Completer<ByteData>();

  void release(ByteData bytes) => _pending.complete(bytes);

  @override
  Future<ByteData> load(String key) =>
      key == _asset ? _pending.future : rootBundle.load(key);
}
