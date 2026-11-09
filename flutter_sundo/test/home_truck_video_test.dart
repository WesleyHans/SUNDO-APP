import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/features/home/widgets/sundo_home_truck_video.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _VideoPlatform extends VideoPlayerPlatform {
  final events = StreamController<VideoEvent>.broadcast();
  DataSource? source;
  bool playing = false;
  bool looping = false;
  double volume = 1;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    source = options.dataSource;
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    this.looping = looping;
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    this.volume = volume;
  }

  @override
  Future<void> play(int playerId) async => playing = true;

  @override
  Future<void> pause(int playerId) async => playing = false;

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox(key: ValueKey('truck-video-view'));
}

void main() {
  testWidgets('the Home truck plays the bundled muted loop only when active',
      (tester) async {
    final previous = VideoPlayerPlatform.instance;
    final player = _VideoPlatform();
    VideoPlayerPlatform.instance = player;
    addTearDown(() async {
      VideoPlayerPlatform.instance = previous;
      await player.events.close();
    });
    const asset = 'assets/images/sundo-home-truck-loop.mp4';
    const parkedAsset = AssetImage('assets/images/sundo-home-truck-parked.png');
    final bytes = await tester.runAsync(() => rootBundle.load(asset));
    expect(bytes?.lengthInBytes, greaterThan(10000));

    Future<void> show({bool active = true, bool reduceMotion = false}) async {
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: Center(child: SundoHomeTruckVideo(active: active)))));
      await tester.pump();
    }

    try {
      await show();
      player.events.add(VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(milliseconds: 3033),
          size: const Size(352, 176)));
      await tester.pump();
      await tester.pump();
      expect(player.source?.sourceType, DataSourceType.asset);
      expect(player.source?.asset, asset);
      expect(player.looping, isTrue);
      expect(player.volume, 0);
      expect(player.playing, isTrue);
      expect(find.image(parkedAsset), findsNothing);
      expect(tester.getSize(find.byKey(const ValueKey('truck-video-view'))),
          const Size(104, 52));
      final videoFrame = tester.getRect(find.byType(ClipPath));
      final clip = tester.widget<ClipPath>(find.byType(ClipPath)).clipper!;
      final silhouette = clip.getClip(videoFrame.size);
      expect(silhouette.contains(const Offset(1, 1)), isFalse);
      expect(silhouette.contains(const Offset(103, 51)), isFalse);
      expect(silhouette.contains(const Offset(28, 43)), isTrue);
      expect(silhouette.contains(const Offset(82, 43)), isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(player.playing, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(player.playing, isTrue);
      await show(active: false);
      expect(player.playing, isFalse);
      expect(find.byKey(const ValueKey('truck-video-view')), findsNothing);
      expect(find.image(parkedAsset), findsOneWidget);
      await show(reduceMotion: true);
      expect(player.playing, isFalse);
      expect(find.image(parkedAsset), findsOneWidget);
      expect(tester.getRect(find.image(parkedAsset)), videoFrame);
      expect(
          tester.widget<ClipPath>(find.byType(ClipPath)).clipper, same(clip));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    expect(find.byType(SundoHomeTruckVideo), findsNothing);
  });
}
