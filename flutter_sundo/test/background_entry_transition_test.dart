import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/shared/widgets/time_based_background.dart';

const _entryKey = ValueKey('sundo-scene-first-frame');
final _mood = SundoTimeMood(DateTime(2026, 10, 6, 11));
final _asset = sundoEnvironmentArtwork(_mood.environment);

void main() {
  testWidgets('late soft scenery fades in without moving foreground controls',
      (tester) async {
    final bundle = _DelayedSceneBundle(_asset);
    var taps = 0;
    await tester.pumpWidget(_surface(bundle,
        foreground:
            TextButton(onPressed: () => taps++, child: const Text('Log In'))));
    final original = tester.getRect(find.text('Log In'));
    expect(_entryOpacity(tester), 0);
    await tester.pump(const Duration(seconds: 2));
    expect(_entryOpacity(tester), 0);
    await tester.tap(find.text('Log In'));
    expect(taps, 1);

    await _releaseScene(tester, bundle);
    expect(_entryOpacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 150));
    expect(_entryOpacity(tester), greaterThan(0));
    expect(_entryOpacity(tester), lessThan(1));
    expect(tester.getRect(find.text('Log In')), original);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_entryOpacity(tester), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cached scenery relies on page transition without a second fade',
      (tester) async {
    final bundle = _DelayedSceneBundle(_asset);
    await tester.pumpWidget(_surface(bundle));
    await _releaseScene(tester, bundle);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(_surface(bundle, backdropKey: const ValueKey(2)));
    expect(find.byKey(_entryKey), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('late full-scene artwork fades without changing its composition',
      (tester) async {
    final bundle = _DelayedSceneBundle(_asset);
    await tester.pumpWidget(_surface(bundle, fullScene: true));
    expect(_entryOpacity(tester), 0);
    await _releaseScene(tester, bundle);
    expect(_entryOpacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 450));
    expect(_entryOpacity(tester), greaterThan(0));
    expect(_entryOpacity(tester), lessThan(1));
    await tester.pump(const Duration(milliseconds: 450));
    expect(_entryOpacity(tester), 1);
    expect(
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
        const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion shows a ready soft backdrop immediately',
      (tester) async {
    final bundle = _DelayedSceneBundle(_asset);
    await tester.pumpWidget(_surface(bundle, reduceMotion: true));
    await _releaseScene(tester, bundle);
    await tester.pump();
    expect(_entryOpacity(tester), 1);
    expect(tester.widget<AnimatedOpacity>(find.byKey(_entryKey)).duration,
        Duration.zero);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _surface(AssetBundle bundle,
        {bool fullScene = false,
        bool reduceMotion = false,
        Key? backdropKey,
        Widget? foreground}) =>
    MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: DefaultAssetBundle(
                bundle: bundle,
                child: SundoTimeScope(
                    mood: _mood,
                    child: SundoTimeBasedBackground(
                        key: backdropKey,
                        fullScene: fullScene,
                        child: Center(child: foreground))))));

double _entryOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find.descendant(
        of: find.byKey(_entryKey), matching: find.byType(FadeTransition)))
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

class _DelayedSceneBundle extends CachingAssetBundle {
  final String asset;
  final _pending = Completer<ByteData>();
  _DelayedSceneBundle(this.asset);

  void release(ByteData bytes) => _pending.complete(bytes);

  @override
  Future<ByteData> load(String key) =>
      key == asset ? _pending.future : rootBundle.load(key);
}
