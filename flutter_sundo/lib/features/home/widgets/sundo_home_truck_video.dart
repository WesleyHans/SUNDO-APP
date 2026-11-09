import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays the bundled illustration; fleet location and status come from Home.
class SundoHomeTruckVideo extends StatefulWidget {
  const SundoHomeTruckVideo({super.key, required this.active});

  final bool active;

  @override
  State<SundoHomeTruckVideo> createState() => _SundoHomeTruckVideoState();
}

class _SundoHomeTruckVideoState extends State<SundoHomeTruckVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _player;
  bool _allowMotion = false;
  bool _ready = false;
  bool _failed = false;

  bool get _shouldPlay {
    final state = WidgetsBinding.instance.lifecycleState;
    return widget.active &&
        _allowMotion &&
        (state == null || state == AppLifecycleState.resumed);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _allowMotion = TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(covariant SundoHomeTruckVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _sync();

  void _sync() {
    if (_failed) return;
    final player = _player;
    if (player == null && _shouldPlay) {
      final controller = VideoPlayerController.asset(
        'assets/images/sundo-home-truck-loop.mp4',
        // This widget owns pause and resume, including switching tabs.
        videoPlayerOptions: VideoPlayerOptions(
            allowBackgroundPlayback: true, mixWithOthers: true),
      );
      _player = controller;
      unawaited(_initialize(controller));
    } else if (player != null && _ready) {
      unawaited(_setPlayback(player));
    }
  }

  Future<void> _initialize(VideoPlayerController player) async {
    try {
      await player.initialize();
      if (!mounted) return;
      await player.setLooping(true);
      if (!mounted) return;
      await player.setVolume(0);
      if (!mounted) return;
      setState(() => _ready = true);
      _sync();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _setPlayback(VideoPlayerController player) async {
    try {
      final play = _shouldPlay;
      if (play == player.value.isPlaying) return;
      await (play ? player.play() : player.pause());
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final player = _player;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    const parked = Image(
      image: AssetImage('assets/images/sundo-home-truck-parked.png'),
      fit: BoxFit.fill,
      excludeFromSemantics: true,
    );
    final showVideo = _ready && !_failed && widget.active && _allowMotion;
    return Semantics(
      image: true,
      label: 'SUNDO collection truck illustration',
      child: SizedBox(
        width: 124,
        height: 62,
        child: Center(
          child: SizedBox(
            width: 104,
            height: 52,
            child: ClipPath(
              clipper: const _TruckSilhouette(),
              child: showVideo && player != null
                  ? ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: player,
                      builder: (context, value, child) =>
                          value.hasError ? parked : child!,
                      child: VideoPlayer(player),
                    )
                  : parked,
            ),
          ),
        ),
      ),
    );
  }
}

/// The clip is in source-frame pixels. It removes the backdrop while leaving
/// the truck's dark wheels and chassis intact.
class _TruckSilhouette extends CustomClipper<Path> {
  const _TruckSilhouette();

  static final Path _outline = Path()
    ..moveTo(32, 147)
    ..lineTo(33, 101)
    ..lineTo(43, 85)
    ..quadraticBezierTo(55, 54, 64, 51)
    ..lineTo(72, 49)
    ..lineTo(72, 43)
    ..quadraticBezierTo(78, 39, 82, 44)
    ..lineTo(83, 48)
    ..lineTo(93, 46)
    ..lineTo(94, 36)
    ..lineTo(102, 35)
    ..lineTo(103, 29)
    ..lineTo(116, 26)
    ..lineTo(119, 29)
    ..lineTo(133, 24)
    ..lineTo(152, 23)
    ..lineTo(154, 21)
    ..lineTo(163, 21)
    ..lineTo(165, 23)
    ..lineTo(212, 21)
    ..lineTo(225, 20)
    ..lineTo(233, 23)
    ..lineTo(235, 17)
    ..lineTo(242, 16)
    ..quadraticBezierTo(250, 2, 262, 9)
    ..quadraticBezierTo(282, 20, 297, 52)
    ..quadraticBezierTo(311, 54, 308, 67)
    ..lineTo(306, 71)
    ..lineTo(318, 89)
    ..quadraticBezierTo(321, 98, 321, 105)
    ..lineTo(325, 110)
    ..lineTo(325, 123)
    ..lineTo(316, 131)
    ..lineTo(315, 138)
    ..lineTo(302, 142)
    ..cubicTo(304, 156, 291, 170, 275, 170)
    ..cubicTo(258, 170, 247, 159, 246, 148)
    ..lineTo(121, 150)
    ..cubicTo(118, 163, 108, 170, 95, 170)
    ..cubicTo(81, 170, 70, 163, 66, 151)
    ..lineTo(37, 151)
    ..quadraticBezierTo(32, 151, 32, 147)
    ..close();

  @override
  Path getClip(Size size) => _outline.transform(
      Matrix4.diagonal3Values(size.width / 352, size.height / 176, 1).storage);

  @override
  bool shouldReclip(_TruckSilhouette oldClipper) => false;
}
