import 'package:flutter/material.dart';

import '../../../core/theme/time_theme.dart';
import '../../../repositories/weather_repository.dart';

enum SundoCardScene { weatherRiverside, noCollectionStreet, nextCollectionPark }

enum SundoCardSceneryState {
  morning,
  noon,
  sunset,
  earlyEvening,
  evening,
  night,
  cloudy,
  rainy
}

/// Card lighting follows the Philippine clock independently of the greeting.
/// Clouds replace daylight/twilight; a cloudy midnight must still look like night.
SundoCardSceneryState sundoCardSceneryState(SundoTimeMood mood) {
  if (mood.raining) return SundoCardSceneryState.rainy;
  if (mood.isDarkNight) return SundoCardSceneryState.night;
  final time = mood.localTime;
  if (time.hour >= 19) return SundoCardSceneryState.night;
  if (mood.weatherCondition == WeatherCondition.cloudy) {
    return SundoCardSceneryState.cloudy;
  }
  if (time.hour == 18) {
    return time.minute < 30
        ? SundoCardSceneryState.earlyEvening
        : SundoCardSceneryState.evening;
  }
  if (time.hour == 17) return SundoCardSceneryState.sunset;
  return time.hour < 11
      ? SundoCardSceneryState.morning
      : SundoCardSceneryState.noon;
}

String sundoCardSceneryArtwork(
    SundoCardScene scene, SundoCardSceneryState state) {
  final folder = switch (scene) {
    SundoCardScene.weatherRiverside => 'weather_riverside',
    SundoCardScene.noCollectionStreet => 'no_collection_street',
    SundoCardScene.nextCollectionPark => 'next_collection_park',
  };
  final name = state == SundoCardSceneryState.earlyEvening
      ? 'early_evening_1800'
      : state.name;
  return 'assets/images/card_scenery/$folder/$name.webp';
}

/// Bundled scenery is decoded before a crossfade starts. Fixed fitting and
/// alignment keep each location still as only the lighting/weather changes.
class SundoCardScenery extends StatefulWidget {
  final SundoCardScene scene;
  const SundoCardScenery({super.key, required this.scene});

  @override
  State<SundoCardScenery> createState() => _SundoCardSceneryState();
}

class _SundoCardSceneryState extends State<SundoCardScenery> {
  (String, double)? _displayed;
  (String, double)? _pending;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  final _handoffs = <ImageStream, ImageStreamListener>{};
  int _generation = 0;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _requestScene();
  }

  @override
  void didUpdateWidget(SundoCardScenery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) _requestScene();
  }

  void _requestScene() {
    final mood = SundoTimeScope.of(context);
    final state = sundoCardSceneryState(mood);
    // The wet artwork also stays dark before sunrise/after 7 PM. This filter
    // belongs to the image only; labels and the card surface are unaffected.
    final rainLight = state == SundoCardSceneryState.rainy ||
            state == SundoCardSceneryState.cloudy
        ? (mood.isDarkNight
            ? .30
            : mood.localTime.hour >= 18
                ? (mood.localTime.minute < 30 ? .72 : .55)
                : 1.0)
        : 1.0;
    final target = (sundoCardSceneryArtwork(widget.scene, state), rainLight);
    if (_pending == target) return;
    if (_displayed == target) {
      _cancelPending();
      return;
    }
    _cancelPending();
    final generation = _generation;
    _pending = target;
    final stream = AssetImage(target.$1)
        .resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, synchronousCall) {
      info.dispose();
      if (!mounted || generation != _generation) return;
      final first = _displayed == null;
      _handoffFrame();
      void display() => _displayed = target;
      if (synchronousCall) {
        display();
      } else {
        setState(display);
      }
      if (first) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _visible = true);
        });
      }
    }, onError: (_, __) {
      if (!mounted || generation != _generation) return;
      // Retain the decoded current frame or the clay surface; a later minute
      // update retries failed loading without a blank flash or uncaught error.
      _cancelPending();
    });
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _cancelPending() {
    _generation++;
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
    _pending = null;
  }

  void _handoffFrame() {
    final stream = _stream!;
    final listener = _listener!;
    _generation++;
    _stream = null;
    _listener = null;
    _pending = null;
    _handoffs[stream] = listener;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final held = _handoffs.remove(stream);
      if (held != null) stream.removeListener(held);
    });
  }

  @override
  void dispose() {
    _cancelPending();
    for (final entry in _handoffs.entries) {
      entry.key.removeListener(entry.value);
    }
    _handoffs.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _displayed;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 900);
    Widget? image;
    if (scene != null) {
      image = Image.asset(scene.$1,
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          gaplessPlayback: true,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => const SizedBox.expand());
      if (scene.$2 < 1) {
        final light = scene.$2;
        image = ColorFiltered(
            colorFilter: ColorFilter.matrix([
              light * .85, 0, 0, 0, 0,
              0, light * .95, 0, 0, 0,
              0, 0, light, 0, 3,
              0, 0, 0, 1, 0
            ]),
            child: image);
      }
      image = SizedBox.expand(key: ValueKey(scene), child: image);
    }
    return IgnorePointer(
        child: ExcludeSemantics(
            child: AnimatedOpacity(
                key: const ValueKey('sundo-card-scenery-first-frame'),
                opacity: _visible ? 1 : 0,
                duration: duration,
                curve: Curves.easeInOutCubic,
                child: AnimatedSwitcher(
                    duration: duration,
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, if (current != null) current]),
                    child: image))));
  }
}
