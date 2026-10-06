import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/core/theme/app_theme.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';
import 'package:sundo_sipalay/features/operations/operations_screen.dart';
import 'package:sundo_sipalay/shared/widgets/scenic_backdrop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final hour in [9, 20]) {
    testWidgets(
        'city error state and all tabs remain usable at large text $hour',
        (tester) async {
      await _mount(tester, OperationsScreen(onLogout: () {}), hour: hour);
      await tester.pump();
      expect(
          find.text(
              'Could not refresh city data. Check your connection and retry.'),
          findsOneWidget);
      expect(find.text('Loading'), findsNothing);
      expect(tester.takeException(), isNull);
      for (final label in [
        'Live Map',
        'Reports',
        'Schedules',
        'Profile',
        'Home'
      ]) {
        await tester.tap(find.widgetWithText(NavigationDestination, label));
        await tester.pump();
        if (label == 'Live Map') expect(find.byType(LeafSprig), findsNothing);
        if (label == 'Profile') {
          expect(
              find.text('Account information unavailable. Refresh to retry.'),
              findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('city form shows required errors and saves above the keyboard',
      (tester) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final barangay = TextEditingController();
    addTearDown(name.dispose);
    addTearDown(phone.dispose);
    addTearDown(barangay.dispose);
    bool? result;
    await _mount(
        tester,
        Builder(
            builder: (context) => Scaffold(
                body: Center(
                    child: FilledButton(
                        onPressed: () async {
                          result = await showDialog<bool>(
                              context: context,
                              builder: (_) => OperationsFormDialog(
                                    title: 'Edit profile',
                                    acceptLabel: 'Save',
                                    fields: {
                                      'Name': name,
                                      'Phone': phone,
                                      'Barangay': barangay
                                    },
                                    requiredFields: const {'Name', 'Barangay'},
                                  ));
                        },
                        child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter name.'), findsOneWidget);
    expect(find.text('Enter barangay.'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('operation-field-Name')), 'Juan');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('operation-field-Barangay'));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Barangay 2');
    await tester.pumpAndSettle();
    expect(
        tester.getRect(find.text('Save')).bottom, lessThanOrEqualTo(640 - 300));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _mount(WidgetTester tester, Widget child, {int hour = 20}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewInsets);
  final mood = SundoTimeMood(DateTime(2026, 10, 6, hour));
  await tester.pumpWidget(MaterialApp(
      theme: buildSundoTheme(mood),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!),
      home: SundoTimeScope(mood: mood, child: child)));
  await tester.pump();
}
