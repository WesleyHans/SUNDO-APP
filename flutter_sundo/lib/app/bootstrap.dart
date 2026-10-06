import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/time_theme.dart';
import '../repositories/mock_auth_repository.dart';
import '../services/backend_service.dart';
import '../services/push_notification_service.dart';
import '../shared/widgets/sundo_graphics.dart';
import 'app.dart';

Future<void> _initializeServices() async {
  await BackendService.initialize();
  if (!BackendService.configured) await MockAuthRepository.restoreSession();
  await PushNotificationService.initialize();
}

/// Keeps storage or configuration errors recoverable before navigation starts.
class SundoBootstrap extends StatefulWidget {
  final Future<void> Function()? initialize;
  const SundoBootstrap({super.key, this.initialize});
  @override
  State<SundoBootstrap> createState() => _SundoBootstrapState();
}

class _SundoBootstrapState extends State<SundoBootstrap> {
  late Future<void> _startup;
  @override
  void initState() {
    super.initState();
    _startup = _start();
  }

  Future<void> _start() async =>
      await (widget.initialize ?? _initializeServices)();

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _startup,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) {
            return const SundoApp();
          }
          return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'SUNDO',
              theme: buildSundoTheme(SundoTimeMood.fromInstant(DateTime.now())),
              home: Scaffold(
                  body: SafeArea(
                      child: Center(
                          child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SundoBrandMark(width: 110),
                                    const SizedBox(height: 24),
                                    if (!snapshot.hasError)
                                      const CircularProgressIndicator()
                                    else ...[
                                      const Text('SUNDO could not start.',
                                          textAlign: TextAlign.center),
                                      const SizedBox(height: 8),
                                      const Text(
                                          'Check your connection and try again. Your saved data stays on this phone.',
                                          textAlign: TextAlign.center),
                                      const SizedBox(height: 20),
                                      FilledButton(
                                          onPressed: () {
                                            final retry = _start();
                                            setState(() {
                                              _startup = retry;
                                            });
                                          },
                                          child: const Text('Retry')),
                                    ]
                                  ]))))));
        },
      );
}
