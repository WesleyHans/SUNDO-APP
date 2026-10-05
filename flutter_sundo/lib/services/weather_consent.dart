import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const weatherLocationConsentKey = 'sundo_weather_location_enabled_v1';

/// Device preference, independent of login. Coordinates are never persisted here.
class WeatherConsentStore {
  Future<bool?> read() async => (await SharedPreferences.getInstance())
      .getBool(weatherLocationConsentKey);

  Future<void> write(bool enabled) async {
    await (await SharedPreferences.getInstance())
        .setBool(weatherLocationConsentKey, enabled);
  }
}

final weatherConsentStoreProvider =
    Provider<WeatherConsentStore>((ref) => WeatherConsentStore());

/// Splash navigation waits for a saved setting or an explicit startup choice.
/// Normal startup does not wait for GPS or weather. A first-launch GPS-off
/// settings offer finishes before splash navigation can remove its dialog.
class WeatherStartupChoiceGate {
  final _ready = Completer<void>();

  Future<void> get ready => _ready.future;

  void complete() {
    if (!_ready.isCompleted) _ready.complete();
  }
}

final weatherStartupChoiceGateProvider =
    Provider<WeatherStartupChoiceGate>((ref) => WeatherStartupChoiceGate());
