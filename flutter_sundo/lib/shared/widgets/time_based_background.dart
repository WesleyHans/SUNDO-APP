import 'package:flutter/material.dart';
import '../../core/theme/time_theme.dart';
import '../../repositories/weather_repository.dart';

/// All supplied illustrations use the same camera, truck and city composition.
String sundoEnvironmentArtwork(SundoEnvironment environment) =>
    // The wet-night variant reuses the matching rainy scene. Its lighting is
    // applied to scenery alone, preserving the original truck and city pixels.
    'assets/images/environment-${environment == SundoEnvironment.rainyNight ? 'rainy' : environment.name}.webp';

/// Scenery fills the available surface; branding and controls are separate.
class SundoTimeBasedBackground extends StatefulWidget {
  final Widget? child;
  final bool fullScene;
  final Alignment alignment;
  final BoxFit fit;
  const SundoTimeBasedBackground({
    super.key,
    this.child,
    this.fullScene = false,
    this.alignment = Alignment.bottomCenter,
    this.fit = BoxFit.cover,
  });

  static const sceneryFeather = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, .28, .58, .86, 1],
    colors: [
      Colors.transparent,
      Color(0x08FFFFFF),
      Color(0x14FFFFFF),
      Color(0x24FFFFFF),
      Color(0x18FFFFFF),
    ],
  );

  @override
  State<SundoTimeBasedBackground> createState() =>
      _SundoTimeBasedBackgroundState();
}

class _SundoTimeBasedBackgroundState extends State<SundoTimeBasedBackground> {
  SundoEnvironment? _displayedEnvironment;
  SundoTimeMood? _displayedMood;
  bool _displayedReady = false;
  bool _suppressOldScene = false;
  SundoEnvironment? _pendingEnvironment;
  SundoTimeMood? _requestedMood;
  ImageStream? _pendingStream;
  ImageStreamListener? _pendingListener;
  final _frameHandoffs = <ImageStream, ImageStreamListener>{};
  int _requestGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mood = SundoTimeScope.of(context);
    // Keep the original composition while fading a late first image. Further
    // scenes must decode before replacing this one.
    _displayedEnvironment ??= mood.environment;
    _displayedMood ??= mood;
    _requestScene(mood);
  }

  void _requestScene(SundoTimeMood mood) {
    final environment = mood.environment;
    // Expired rain and a daylight boundary must not leave obsolete scenery
    // behind the UI while its replacement is loading or cannot decode.
    if ((_displayedMood?.raining == true && !mood.raining) ||
        _displayedMood?.isNight != mood.isNight) {
      _suppressOldScene = true;
      _displayedMood = mood;
    }
    if (_pendingEnvironment == environment) {
      _requestedMood = mood;
      return;
    }
    if (_displayedEnvironment == environment && _displayedReady) {
      // Returning to the current scene invalidates an in-flight other scene.
      _cancelPending();
      _displayedMood = mood;
      _suppressOldScene = false;
      return;
    }
    _cancelPending();
    final generation = _requestGeneration;
    _pendingEnvironment = environment;
    _requestedMood = mood;
    final stream = AssetImage(sundoEnvironmentArtwork(environment))
        .resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, synchronousCall) {
      info.dispose();
      if (!mounted || generation != _requestGeneration) return;
      final readyMood = _requestedMood!;
      _handoffReadyScene();
      void displayReadyScene() {
        _displayedEnvironment = environment;
        _displayedMood = readyMood;
        _displayedReady = true;
        _suppressOldScene = false;
      }

      // A cached frame arrives inside didChangeDependencies, before its build.
      // A late first frame also needs a rebuild for the latest scene lighting.
      if (synchronousCall) {
        displayReadyScene();
      } else {
        setState(displayReadyScene);
      }
    }, onError: (error, stack) {
      if (!mounted || generation != _requestGeneration) return;
      // Keep safe existing scenery or the current mood's neutral fallback.
      // A later mood/dependency refresh can retry the requested asset.
      _cancelPending();
    });
    _pendingStream = stream;
    _pendingListener = listener;
    stream.addListener(listener);
  }

  void _cancelPending() {
    _requestGeneration++;
    if (_pendingStream != null && _pendingListener != null) {
      _pendingStream!.removeListener(_pendingListener!);
    }
    _pendingStream = null;
    _pendingListener = null;
    _pendingEnvironment = null;
    _requestedMood = null;
  }

  void _handoffReadyScene() {
    final stream = _pendingStream!;
    final listener = _pendingListener!;
    _requestGeneration++;
    _pendingStream = null;
    _pendingListener = null;
    _pendingEnvironment = null;
    _requestedMood = null;
    // Hold this decoded frame until Image attaches in the following build.
    // Otherwise a small/disabled image cache could discard it before the fade.
    _frameHandoffs[stream] = listener;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final heldListener = _frameHandoffs.remove(stream);
      if (heldListener != null) stream.removeListener(heldListener);
    });
  }

  @override
  void dispose() {
    _cancelPending();
    for (final entry in _frameHandoffs.entries) {
      entry.key.removeListener(entry.value);
    }
    _frameHandoffs.clear();
    super.dispose();
  }

  /// fitWidth preserves the whole truck. If a tall phone leaves space below
  /// the illustration, soften its last 48px into the surrounding surface.
  Shader _fullSceneMask(Rect bounds) {
    final fitted = applyBoxFit(widget.fit, const Size(1024, 1536), bounds.size);
    final imageRect = widget.alignment.inscribe(fitted.destination, bounds);
    if (imageRect.bottom >= bounds.bottom) {
      return const LinearGradient(colors: [Colors.white, Colors.white])
          .createShader(bounds);
    }
    final end =
        ((imageRect.bottom - bounds.top) / bounds.height).clamp(0.0, 1.0);
    final start = (end - 48 / bounds.height).clamp(0.0, end);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0, start, end, 1],
      colors: const [
        Colors.white,
        Colors.white,
        Colors.transparent,
        Colors.transparent
      ],
    ).createShader(bounds);
  }

  /// Lighting filters touch only the decorative illustration. They never
  /// recolor SUNDO branding, cards, text, controls, or functional map tiles.
  ColorFilter? _sceneLighting(SundoTimeMood mood) {
    if (mood.environment == SundoEnvironment.rainyNight) {
      return const ColorFilter.matrix([
        .45,
        0,
        0,
        0,
        0,
        0,
        .51,
        0,
        0,
        0,
        0,
        0,
        .64,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    if (mood.weatherCondition == WeatherCondition.thunderstorm) {
      return const ColorFilter.matrix([
        .72,
        0,
        0,
        0,
        0,
        0,
        .77,
        0,
        0,
        0,
        0,
        0,
        .86,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    if (mood.raining && mood.isSunset) {
      return const ColorFilter.matrix([
        .94,
        0,
        0,
        0,
        5,
        0,
        .87,
        0,
        0,
        2,
        0,
        0,
        .80,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    if (mood.raining && mood.period == SundoDayPeriod.morning) {
      return const ColorFilter.matrix([
        .91,
        0,
        0,
        0,
        3,
        0,
        .94,
        0,
        0,
        3,
        0,
        0,
        .98,
        0,
        2,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    if (mood.weatherCondition == WeatherCondition.cloudy) {
      return const ColorFilter.matrix([
        .63024,
        .26319,
        .02657,
        0,
        0,
        .07824,
        .81519,
        .02657,
        0,
        0,
        .07824,
        .26319,
        .62657,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mood = _displayedMood!;
    final environment = _displayedEnvironment!;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final currentMood = SundoTimeScope.of(context);
    final background =
        widget.fullScene ? mood.background : currentMood.innerBackground;
    final image = Image.asset(
      sundoEnvironmentArtwork(environment),
      key: ValueKey(environment),
      fit: widget.fit,
      alignment: widget.alignment,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stack) => const SizedBox.expand(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // Cached scenery is already part of the page transition. Only a
        // delayed decode needs its own fade to avoid popping in later.
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          key: const ValueKey('sundo-scene-first-frame'),
          opacity: frame == null ? 0 : 1,
          duration: reducedMotion
              ? Duration.zero
              : Duration(milliseconds: widget.fullScene ? 900 : 450),
          curve: Curves.easeOutCubic,
          child: child,
        );
      },
    );
    final lighting = _sceneLighting(mood);
    final scene = _suppressOldScene
        ? ColoredBox(color: background)
        : lighting == null
            ? image
            : ColorFiltered(colorFilter: lighting, child: image);
    return Stack(fit: StackFit.expand, children: [
      AnimatedContainer(
          duration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.fullScene
                ? [background, background, background]
                : [
                    background,
                    background,
                    Color.lerp(background, currentMood.sky, .18)!,
                  ],
            stops: const [0, .72, 1],
          ))),
      IgnorePointer(
          child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: widget.fullScene
                  ? _fullSceneMask
                  : SundoTimeBasedBackground.sceneryFeather.createShader,
              child: AnimatedSwitcher(
                duration: reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 900),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                // Keep the outgoing layer opaque below the arriving image. Normal
                // overlapping fades reduce combined alpha at midpoint, causing a flash.
                transitionBuilder: (child, animation) => AnimatedBuilder(
                    animation: animation,
                    child: child,
                    builder: (context, child) => Opacity(
                        opacity: animation.status == AnimationStatus.reverse
                            ? 1
                            : animation.value,
                        child: child)),
                layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, if (current != null) current]),
                child: KeyedSubtree(
                    key: ValueKey((mood.sceneryIdentity, _suppressOldScene)),
                    child: scene),
              ))),
      if (widget.child != null) widget.child!,
    ]);
  }
}
