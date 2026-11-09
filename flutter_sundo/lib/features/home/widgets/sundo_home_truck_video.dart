import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../shared/widgets/sundo_graphics.dart';

/// Plays the bundled illustration; fleet location and status come from Home.
class SundoHomeTruckVideo extends StatefulWidget {
  const SundoHomeTruckVideo({super.key, required this.active});

  final bool active;

  @override
  State<SundoHomeTruckVideo> createState() => _SundoHomeTruckVideoState();
}

class _SundoHomeTruckVideoState extends State<SundoHomeTruckVideo>
    with WidgetsBindingObserver {
  static const _fallback = SundoTruckGraphic(width: 124, height: 62);
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
    if (!_ready ||
        _failed ||
        !widget.active ||
        !_allowMotion ||
        player == null) {
      return _fallback;
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: player,
      builder: (context, value, child) => value.hasError ? _fallback : child!,
      child: Semantics(
        image: true,
        label: 'Animated SUNDO collection truck illustration',
        child: SizedBox(
          width: 124,
          height: 62,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: VideoPlayer(player),
          ),
        ),
      ),
    );
  }
}
