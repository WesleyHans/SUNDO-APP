import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/time_theme.dart';
import './navigation_motion.dart';
import '../core/theme/app_theme.dart';
import './router.dart';
import '../repositories/weather_repository.dart';
import '../services/weather_consent.dart';

class SundoApp extends ConsumerStatefulWidget {
  const SundoApp({super.key});
  @override
  ConsumerState<SundoApp> createState() => _SundoAppState();
}

class _SundoAppState extends ConsumerState<SundoApp>
    with WidgetsBindingObserver {
  late final SundoWeatherController _weatherController;
  @override
  void initState() {
    super.initState();
    _weatherController = ref.read(sundoWeatherProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(sundoWeatherProvider.notifier).setForeground(
            WidgetsBinding.instance.lifecycleState == null ||
                WidgetsBinding.instance.lifecycleState ==
                    AppLifecycleState.resumed);
        _initializeWeatherAccess();
      }
    });
  }

  Future<void> _initializeWeatherAccess() async {
    final store = ref.read(weatherConsentStoreProvider);
    bool? enabled;
    try {
      enabled = await store.read();
    } catch (_) {
      enabled = null;
    }
    if (!mounted) return;
    final firstChoice = enabled == null;
    final navigatorContext = sundoNavigatorKey.currentContext;
    if (firstChoice && navigatorContext != null && navigatorContext.mounted) {
      enabled = await showDialog<bool>(
          context: navigatorContext,
          barrierDismissible: false,
          builder: (context) => PopScope(
              canPop: false,
              child: AlertDialog(
                icon: const Icon(Icons.wb_cloudy_outlined),
                title: const Text('Weather for your area'),
                content: const Text(
                    'SUNDO can use your location for local weather before you sign in. Your approximate coordinates are sent to Open-Meteo while the app is open. Weather is model-based; no background tracking is needed.\n\nYou can continue with time-based backgrounds and change this in Profile → Location Permission.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Use time only')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Enable local weather')),
                ],
              )));
      if (!mounted) return;
      // Only a button choice is consent. Route removal is not an opt-out.
      if (enabled == null) return;
      try {
        await store.write(enabled);
      } catch (_) {
        // A storage failure does not prevent this explicit session choice.
      }
    }
    if (!mounted) return;
    if (enabled != true) {
      ref.read(weatherStartupChoiceGateProvider).complete();
      _weatherController.useTimeOnly();
      return;
    }
    final locationService = ref.read(environmentLocationServiceProvider);
    // Keep splash navigation from removing the GPS-off settings offer, but
    // don't hold a normal startup for a weather network response.
    if (!firstChoice || await locationService.isLocationServiceEnabled()) {
      if (!mounted) return;
      ref.read(weatherStartupChoiceGateProvider).complete();
    }
    await _weatherController.initializeLocation(requestPermission: firstChoice);
    if (!mounted) return;
    if (firstChoice) {
      bool servicesDisabled = false;
      try {
        servicesDisabled = await locationService.deviceAccessStatus() ==
            EnvironmentLocationStatus.disabled;
      } catch (_) {
        // Location resolution will handle an unavailable platform.
      }
      if (!mounted) return;
      final activeContext = sundoNavigatorKey.currentContext;
      if (servicesDisabled && activeContext != null && activeContext.mounted) {
        final open = await showDialog<bool>(
            context: activeContext,
            builder: (context) => AlertDialog(
                  title: const Text('Turn on phone Location?'),
                  content: const Text(
                      'Location services are off. Turn them on for weather in your current area. Without a location, SUNDO uses a saved area when available or the current time.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Continue')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Open Location settings')),
                  ],
                ));
        if (open == true) {
          try {
            await locationService.openLocationSettings();
          } catch (_) {
            // Continue safely if the platform cannot open its settings.
          }
        }
      }
    }
    if (mounted) ref.read(weatherStartupChoiceGateProvider).complete();
  }

  @override
  void dispose() {
    _weatherController.setForeground(false);
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
    final checkingWeather = ref.watch(sundoWeatherLoadingProvider);
    final router = ref.watch(sundoRouterProvider);
    return MaterialApp.router(
      title: 'SUNDO - Sipalay Smart Waste',
      debugShowCheckedModeBanner: false,
      theme: buildSundoTheme(mood),
      routerConfig: router,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: (mood.isNight
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: mood.surface),
          child: SundoTimeScope(
              mood: mood,
              checkingWeather: checkingWeather,
              weatherEnabled: _weatherController.enabled,
              onWeatherRefresh: () => unawaited(_weatherController.refresh()),
              child: SundoNavigationBackdrop(
                  router: router, child: child ?? const SizedBox.shrink()))),
    );
  }
}
