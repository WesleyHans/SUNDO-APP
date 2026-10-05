import 'package:flutter/material.dart';
import '../../core/theme/time_theme.dart';

/// All five illustrations use the same camera, truck and city composition.
String sundoEnvironmentArtwork(SundoEnvironment environment) =>
    'assets/images/environment-${environment.name}.webp';

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
      Color(0x0FFFFFFF),
      Color(0x38FFFFFF),
      Color(0x66FFFFFF),
      Color(0x58FFFFFF),
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
    // The first scene is mounted immediately, without fading from an empty
    // previous image. Further scenes must decode before replacing this one.
    _displayedEnvironment ??= mood.environment;
    _displayedMood ??= mood;
    _requestScene(mood);
  }

  void _requestScene(SundoTimeMood mood) {
    final environment = mood.environment;
    if (_pendingEnvironment == environment) {
      _requestedMood = mood;
      return;
    }
    if (_displayedEnvironment == environment && _displayedReady) {
      // Returning to the current scene invalidates an in-flight other scene.
      _cancelPending();
      _displayedMood = mood;
      return;
    }
    _cancelPending();
    final generation = _requestGeneration;
    _pendingEnvironment = environment;
    _requestedMood = mood;
    final stream = AssetImage(sundoEnvironmentArtwork(environment))
        .resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      info.dispose();
      if (!mounted || generation != _requestGeneration) return;
      final readyMood = _requestedMood!;
      _handoffReadyScene();
      if (_displayedEnvironment == environment) {
        _displayedReady = true;
        _displayedMood = readyMood;
        return;
      }
      setState(() {
        _displayedEnvironment = environment;
        _displayedMood = readyMood;
        _displayedReady = true;
      });
    }, onError: (error, stack) {
      if (!mounted || generation != _requestGeneration) return;
      // Keep the last available scene. A later mood/dependency refresh can
      // retry this requested asset instead of displaying an empty transition.
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

  @override
  Widget build(BuildContext context) {
    final mood = _displayedMood!;
    final environment = _displayedEnvironment!;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final scene = Image.asset(
      sundoEnvironmentArtwork(environment),
      key: ValueKey(environment),
      fit: widget.fit,
      alignment: widget.alignment,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stack) => const SizedBox.expand(),
    );
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
                ? [mood.background, mood.background, mood.background]
                : [mood.background, mood.background, mood.sky],
            stops: const [0, .72, 1],
          ))),
      IgnorePointer(
          child: AnimatedSwitcher(
        duration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 900),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [...previous, if (current != null) current]),
        child: ShaderMask(
            key: ValueKey(environment),
            blendMode: BlendMode.dstIn,
            shaderCallback: widget.fullScene
                ? _fullSceneMask
                : SundoTimeBasedBackground.sceneryFeather.createShader,
            child: scene),
      )),
      if (widget.child != null) widget.child!,
    ]);
  }
}
