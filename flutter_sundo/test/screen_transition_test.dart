import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/shared/widgets/screen_transition.dart';

void main() {
  testWidgets('screen changes at zero opacity and fades back in',
      (tester) async {
    await tester.pumpWidget(_surface(0));
    expect(_opacity(tester), 1);
    expect(_ignoresPointer(tester), isFalse);
    await tester.pumpWidget(_surface(1));
    expect(find.text('Screen 0'), findsOneWidget);
    expect(find.text('Screen 1'), findsNothing);
    expect(_ignoresPointer(tester), isTrue);
    await tester.pump(const Duration(milliseconds: 70));
    expect(_opacity(tester), greaterThan(0));
    expect(_opacity(tester), lessThan(1));
    expect(find.text('Screen 0'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Screen 1'), findsOneWidget);
    expect(_opacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 130));
    expect(_opacity(tester), greaterThan(0));
    expect(_opacity(tester), lessThan(1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(_opacity(tester), 1);
    expect(_ignoresPointer(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid selections use the latest screen without opacity jumps',
      (tester) async {
    await tester.pumpWidget(_surface(0));
    await tester.pumpWidget(_surface(1));
    await tester.pump(const Duration(milliseconds: 50));
    final outgoingOpacity = _opacity(tester);
    await tester.pumpWidget(_surface(2));
    expect(_opacity(tester), outgoingOpacity);
    expect(find.text('Screen 0'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Screen 1'), findsNothing);
    expect(find.text('Screen 2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 130));
    final incomingOpacity = _opacity(tester);
    await tester.pumpWidget(_surface(3));
    expect(_opacity(tester), incomingOpacity);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Screen 3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_opacity(tester), 1);
    expect(_ignoresPointer(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tab subtree retains its state through screen fades',
      (tester) async {
    final initializations = [0, 0];
    Widget surface(int index) => _surface(index,
        builder: (context, value) => IndexedStack(index: value, children: [
              for (var page = 0; page < 2; page++)
                _CounterPage(
                    key: ValueKey(page),
                    page: page,
                    onInit: () => initializations[page]++),
            ]));
    await tester.pumpWidget(surface(0));
    await tester.tap(find.text('Page 0: 0'));
    await tester.pump();
    expect(find.text('Page 0: 1'), findsOneWidget);
    await tester.pumpWidget(surface(1));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Page 1: 0'));
    await tester.pump();
    await tester.pumpWidget(surface(0));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Page 0: 1'), findsOneWidget);
    expect(initializations, [1, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fading screens cannot receive accidental taps', (tester) async {
    final taps = <int>[];
    Widget surface(int value) => _surface(value,
        builder: (context, displayed) => Center(
            child: GestureDetector(
                onTap: () => taps.add(displayed),
                child: Text('Screen $displayed'))));
    await tester.pumpWidget(surface(0));
    await tester.tap(find.text('Screen 0'));
    await tester.pumpWidget(surface(1));
    await tester.pump(const Duration(milliseconds: 70));
    await tester.tap(find.text('Screen 0'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 130));
    await tester.tap(find.text('Screen 1'), warnIfMissed: false);
    expect(taps, [0]);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('Screen 1'));
    expect(taps, [0, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion immediately completes an active screen change',
      (tester) async {
    await tester.pumpWidget(_surface(0));
    await tester.pumpWidget(_surface(1));
    await tester.pump(const Duration(milliseconds: 70));
    expect(_ignoresPointer(tester), isTrue);
    await tester.pumpWidget(_surface(2, reduceMotion: true));
    expect(find.text('Screen 2'), findsOneWidget);
    expect(_opacity(tester), 1);
    expect(_ignoresPointer(tester), isFalse);
    await tester.pumpWidget(_surface(3, reduceMotion: true));
    expect(find.text('Screen 3'), findsOneWidget);
    expect(_opacity(tester), 1);
    expect(tester.takeException(), isNull);
  });
}

Widget _surface(int value,
        {bool reduceMotion = false,
        Widget Function(BuildContext, int)? builder}) =>
    MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: SundoFadeThrough<int>(
                value: value,
                builder: builder ??
                    (context, value) => Center(child: Text('Screen $value')))));

Finder get _transition => find.byType(SundoFadeThrough<int>);

double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
        find.descendant(of: _transition, matching: find.byType(FadeTransition)))
    .opacity
    .value;

bool _ignoresPointer(WidgetTester tester) => tester
    .widget<IgnorePointer>(find
        .descendant(of: _transition, matching: find.byType(IgnorePointer))
        .first)
    .ignoring;

class _CounterPage extends StatefulWidget {
  final int page;
  final VoidCallback onInit;
  const _CounterPage({super.key, required this.page, required this.onInit});

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  var _count = 0;

  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => Center(
      child: GestureDetector(
          onTap: () => setState(() => _count++),
          child: Text('Page ${widget.page}: $_count')));
}
