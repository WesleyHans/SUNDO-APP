import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/report_concern/report_concern_screen.dart';
import '../features/operations/operations_screen.dart';
import '../repositories/mock_auth_repository.dart';
import '../services/backend_service.dart';
import './resident_shell.dart';
import '../repositories/weather_repository.dart';
import '../services/weather_consent.dart';

final sundoNavigatorKey = GlobalKey<NavigatorState>();

final sundoRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
      navigatorKey: sundoNavigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(
            path: '/',
            builder: (context, state) => SplashScreen(onContinue: () async {
                  await ref.read(weatherStartupChoiceGateProvider).ready;
                  if (!context.mounted) return;
                  context.go(
                      BackendService.live || MockAuthRepository.hasSession
                          ? '/app'
                          : '/welcome');
                })),
        GoRoute(
            path: '/welcome',
            builder: (context, state) => WelcomeScreen(
                onGetStarted: () async {
                  await BackendService.logout();
                  await MockAuthRepository.logout();
                  await ref
                      .read(sundoWeatherProvider.notifier)
                      .refreshSavedArea();
                  if (context.mounted) context.go('/app');
                },
                onLogIn: () => context.go('/login'),
                onCreateAccount: () => context.go('/register'))),
        GoRoute(
            path: '/login',
            builder: (context, state) => LoginScreen(
                onLoginSuccess: () {
                  ref.read(sundoWeatherProvider.notifier).refreshSavedArea();
                  context.go('/app');
                },
                onCreateAccount: () => context.go('/register'),
                onBack: () => context.go('/welcome'))),
        GoRoute(
            path: '/register',
            builder: (context, state) => RegisterScreen(
                onBack: () => context.go('/welcome'),
                onRegisterSuccess: () {
                  ref.read(sundoWeatherProvider.notifier).refreshSavedArea();
                  context.go('/app');
                },
                onGoToLogin: () => context.go('/login'))),
        GoRoute(
            path: '/app', builder: (context, state) => const _AccountShell()),
        GoRoute(
            path: '/report',
            builder: (context, state) =>
                ReportGarbageScreen(onBack: () => context.pop())),
      ],
      errorBuilder: (context, state) => Scaffold(
          body: Center(
              child: FilledButton(
                  onPressed: () => context.go('/welcome'),
                  child: const Text('Return to SUNDO')))));
  ref.onDispose(router.dispose);
  return router;
});

class _AccountShell extends StatefulWidget {
  const _AccountShell();
  @override
  State<_AccountShell> createState() => _AccountShellState();
}

class _AccountShellState extends State<_AccountShell> {
  Future<Map<String, dynamic>>? _profile;
  @override
  void initState() {
    super.initState();
    if (BackendService.live) _profile = _loadProfile();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final profile = await BackendService.loadProfile();
    if (mounted) {
      // Restored sessions establish their local identity here, after startup.
      // Clear guest-area weather immediately without delaying the account UI
      // while the authenticated resident's new location request completes.
      unawaited(ProviderScope.containerOf(context, listen: false)
          .read(sundoWeatherProvider.notifier)
          .refreshSavedArea());
    }
    return profile;
  }

  void _logout() {
    ProviderScope.containerOf(context, listen: false)
        .read(sundoWeatherProvider.notifier)
        .refreshSavedArea();
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    if (!BackendService.live) return MainNavigationShell(onLogout: _logout);
    return FutureBuilder<Map<String, dynamic>>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
                body: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Could not load your city account.'),
              TextButton(
                  onPressed: () {
                    final retry = _loadProfile();
                    setState(() {
                      _profile = retry;
                    });
                  },
                  child: const Text('Retry')),
              TextButton(
                  onPressed: () async {
                    await BackendService.logout();
                    if (mounted) _logout();
                  },
                  child: const Text('Log out'))
            ])));
          }
          if (!snapshot.hasData) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data!['role'] == 'resident'
              ? MainNavigationShell(onLogout: _logout)
              : OperationsScreen(onLogout: _logout);
        });
  }
}
