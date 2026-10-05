import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/weather_repository.dart';
import '../../services/weather_consent.dart';

class WeatherLocationSettings extends ConsumerStatefulWidget {
  const WeatherLocationSettings({super.key, required this.onManagePermission});
  final Future<void> Function() onManagePermission;
  @override
  ConsumerState<WeatherLocationSettings> createState() =>
      _WeatherLocationSettingsState();
}

class _WeatherLocationSettingsState
    extends ConsumerState<WeatherLocationSettings> {
  bool? _enabled;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    bool enabled;
    try {
      enabled = await ref.read(weatherConsentStoreProvider).read() ?? false;
    } catch (_) {
      enabled = false;
    }
    if (mounted) setState(() => _enabled = enabled);
  }

  Future<void> _change(bool enabled) async {
    setState(() => _saving = true);
    final controller = ref.read(sundoWeatherProvider.notifier);
    try {
      await ref.read(weatherConsentStoreProvider).write(enabled);
      if (enabled) {
        await controller.initializeLocation(requestPermission: true);
      } else {
        controller.useTimeOnly();
      }
      if (mounted) setState(() => _enabled = enabled);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Weather preference could not be saved. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Location & weather',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Text(
                    'Local weather uses your approximate location with Open-Meteo while SUNDO is open. No account is needed. Weather is model-based and may differ from conditions on your street.'),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use local weather'),
                    subtitle: const Text(
                        'When off, backgrounds use time only. Map location permission is managed separately.'),
                    value: _enabled ?? false,
                    onChanged: _enabled == null || _saving ? null : _change),
                if (_saving) const LinearProgressIndicator(),
                TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await widget.onManagePermission();
                          },
                    icon: const Icon(Icons.my_location_outlined),
                    label: const Text('Manage phone location permission')),
                TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(environmentLocationServiceProvider)
                                  .openLocationSettings();
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Open Location in your phone settings.')));
                              }
                            }
                          },
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Open phone Location settings')),
              ]))));
}
