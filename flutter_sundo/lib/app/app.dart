import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/time_theme.dart';
import '../shared/widgets/scenic_backdrop.dart';
import '../core/theme/app_theme.dart';
import './router.dart';
import '../repositories/weather_repository.dart';

class SundoApp extends ConsumerStatefulWidget {
  const SundoApp({super.key});
  @override
  ConsumerState<SundoApp> createState() => _SundoAppState();
}

class _SundoAppState extends ConsumerState<SundoApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(sundoWeatherProvider.notifier).setForeground(
            WidgetsBinding.instance.lifecycleState == null ||
                WidgetsBinding.instance.lifecycleState ==
                    AppLifecycleState.resumed);
      }
    });
  }

  @override
  void dispose() {
    ref.read(sundoWeatherProvider.notifier).setForeground(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(sundoWeatherProvider.notifier)
        .setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) {
      ref.read(sundoDayNightThemeProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(sundoDayNightThemeProvider);
    return MaterialApp.router(
      title: 'SUNDO - Sipalay Smart Waste',
      debugShowCheckedModeBanner: false,
      theme: buildSundoTheme(mood),
      routerConfig: ref.watch(sundoRouterProvider),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: (mood.isNight
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: mood.surface),
          child: SundoTimeScope(
              mood: mood,
              child: ScenicBackdrop(child: child ?? const SizedBox.shrink()))),
    );
  }
}
