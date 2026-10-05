import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Small link-only attribution; it adds no button padding or minimum height.
class WeatherAttribution extends StatelessWidget {
  const WeatherAttribution({super.key, this.compact = true, this.color});

  final bool compact;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontSize: compact ? 9 : 12,
        height: 1.0,
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant);
    return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _WeatherLink(
              label: 'Weather by Open-Meteo',
              url: 'https://open-meteo.com/',
              style: style),
          Text(' · ', style: style),
          _WeatherLink(
              label: 'CC BY 4.0',
              url: 'https://creativecommons.org/licenses/by/4.0/',
              style: style),
        ]);
  }
}

class _WeatherLink extends StatelessWidget {
  const _WeatherLink({
    required this.label,
    required this.url,
    required this.style,
  });

  final String label;
  final String url;
  final TextStyle style;

  Future<void> _open(BuildContext context) async {
    try {
      if (await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Keep this optional external link from interrupting the app.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text('Could not open $label. $url')));
  }

  @override
  Widget build(BuildContext context) {
    void follow() => unawaited(_open(context));
    return Semantics(
        link: true,
        label: label,
        hint: 'Open in your browser',
        onTap: follow,
        excludeSemantics: true,
        child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.click,
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            },
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
                follow();
                return null;
              }),
            },
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: follow,
                child: Text(label,
                    style: style.copyWith(
                        decoration: TextDecoration.underline)))));
  }
}
