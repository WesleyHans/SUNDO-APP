import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sundo_sipalay/main.dart';
import 'package:sundo_sipalay/screens/clay_welcome_screen.dart';
import 'package:sundo_sipalay/screens/login_screen.dart';
import 'package:sundo_sipalay/screens/register_screen.dart';
import 'package:sundo_sipalay/screens/home_screen.dart';
import 'package:sundo_sipalay/widgets/scenic_backdrop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final screens = <String, Widget>{
    'welcome': WelcomeScreen(
        onGetStarted: () {}, onLogIn: () {}, onCreateAccount: () {}),
    'login': LoginScreen(
        onLoginSuccess: () {}, onCreateAccount: () {}, onBack: () {}),
    'register': RegisterScreen(
        onBack: () {}, onRegisterSuccess: () {}, onGoToLogin: () {}),
    'home': HomeScreen(onNavigate: (_) {}),
  };
  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders on a mobile viewport', (tester) async {
      final originalShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = originalShadows);
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
      await tester.pumpWidget(Builder(builder: (context) {
        final app = const SundoApp().build(context) as MaterialApp;
        return MaterialApp(
            theme: app.theme,
            home: RepaintBoundary(
                key: const ValueKey('preview'),
                child: ScenicBackdrop(child: entry.value)));
      }));
      await tester.runAsync(() async {
        await GoogleFonts.pendingFonts();
        final context = tester.element(find.byKey(const ValueKey('preview')));
        await precacheImage(const AssetImage(clayHeroAsset), context);
        await precacheImage(
            const AssetImage('assets/images/sundo_logo.png'), context);
      });
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('GENERATE_PREVIEWS')) {
        await expectLater(find.byKey(const ValueKey('preview')),
            matchesGoldenFile('goldens/${entry.key}.png'));
      }
      debugDisableShadows = originalShadows;
      tester.view.physicalSize = const Size(320, 640);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
