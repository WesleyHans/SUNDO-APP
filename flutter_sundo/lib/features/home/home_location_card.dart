import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/storage/app_store.dart';
import '../../core/theme/time_theme.dart';
import '../../core/utils/resident_location.dart';
import '../../services/environment_location_service.dart';
import '../../shared/widgets/resident_components.dart';
import '../live_map/osm_tile_provider.dart';

bool _homeFixIsFresh(Position fix, DateTime now) =>
    residentFixIsFresh(fix.timestamp, now) &&
    now.isBefore(fix.timestamp.add(const Duration(seconds: 60)));

class HomeLocationResult {
  const HomeLocationResult(this.status,
      {this.fix, this.savedCenter, this.savedArea});

  final EnvironmentLocationStatus status;
  final Position? fix;
  final LatLng? savedCenter;
  final String? savedArea;

  LatLng? get center =>
      fix == null ? savedCenter : LatLng(fix!.latitude, fix!.longitude);
}

/// Reuse the location access checks without ever opening a permission dialog.
/// The precise foreground fix stays in memory and is never sent to weather.
class HomeLocationService {
  HomeLocationService({
    EnvironmentLocationService? access,
    Future<Position?> Function()? lastKnownPosition,
    Future<Position> Function()? fetchPosition,
    DateTime Function()? clock,
  })  : _access = access ?? EnvironmentLocationService(),
        _lastKnownPosition =
            lastKnownPosition ?? Geolocator.getLastKnownPosition,
        _fetchPosition = fetchPosition ??
            (() => Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 12))),
        _clock = clock ?? DateTime.now;

  final EnvironmentLocationService _access;
  final Future<Position?> Function() _lastKnownPosition;
  final Future<Position> Function() _fetchPosition;
  final DateTime Function() _clock;
  Position? _cached;
  Future<Position>? _pendingFix;
  DateTime get now => _clock();

  Future<Position> _currentFix() =>
      _pendingFix ??= Future<Position>.sync(_fetchPosition)
          .timeout(const Duration(seconds: 12))
          .whenComplete(() => _pendingFix = null);

  bool _valid(Position position) =>
      position.latitude.isFinite &&
      position.longitude.isFinite &&
      position.latitude.abs() <= 90 &&
      position.longitude.abs() <= 180 &&
      position.accuracy.isFinite &&
      position.accuracy >= 0 &&
      position.accuracy <= 5000 &&
      _homeFixIsFresh(position, now);

  Future<HomeLocationResult> resolve({bool Function()? canContinue}) async {
    final identity = AppStore.identity;
    bool active() =>
        AppStore.identity == identity && (canContinue?.call() ?? true);
    String? savedArea;
    LatLng? savedCenter;
    try {
      savedArea = await AppStore.getSavedWeatherArea();
      final saved = await AppStore.getResidentLocation();
      final latitude = saved?['latitude'];
      final longitude = saved?['longitude'];
      if (latitude is num &&
          longitude is num &&
          latitude.isFinite &&
          longitude.isFinite &&
          latitude.abs() <= 90 &&
          longitude.abs() <= 180) {
        savedCenter = LatLng(latitude.toDouble(), longitude.toDouble());
      } else {
        // This is explicitly an area overview, never a fabricated GPS pin.
        final area = EnvironmentLocationService.savedAreaLocation(savedArea);
        if (area != null) savedCenter = LatLng(area.latitude, area.longitude);
      }
    } catch (_) {
      // An unreadable local address must not prevent a genuine GPS fix.
    }
    HomeLocationResult fallback(EnvironmentLocationStatus status) =>
        HomeLocationResult(status,
            savedArea: active() ? savedArea : null,
            savedCenter: active() ? savedCenter : null);
    try {
      if (!active()) return fallback(EnvironmentLocationStatus.unavailable);
      final access = await _access.deviceAccessStatus();
      if (!active()) return fallback(EnvironmentLocationStatus.unavailable);
      if (access != EnvironmentLocationStatus.device) {
        _cached = null;
        return fallback(access);
      }
      Position? position = _cached;
      if (position == null || !_valid(position)) {
        try {
          position =
              await _lastKnownPosition().timeout(const Duration(seconds: 4));
        } catch (_) {
          // A platform without a cached fix may still provide a current one.
          position = null;
        }
      }
      if (!active()) return fallback(EnvironmentLocationStatus.unavailable);
      if (position == null || !_valid(position)) {
        // A quick tab round-trip shares an already running native one-shot.
        // Each caller still independently validates access and its lifecycle.
        position = await _currentFix();
      }
      if (!active() || !_valid(position)) {
        _cached = null;
        return fallback(EnvironmentLocationStatus.unavailable);
      }
      // Permission and service state can change while obtaining a slow fix.
      final stillAllowed = await _access.deviceAccessStatus();
      if (!active()) return fallback(EnvironmentLocationStatus.unavailable);
      if (stillAllowed != EnvironmentLocationStatus.device) {
        _cached = null;
        return fallback(stillAllowed);
      }
      if (!_valid(position)) {
        return fallback(EnvironmentLocationStatus.unavailable);
      }
      _cached = position;
      return HomeLocationResult(EnvironmentLocationStatus.device,
          fix: position, savedArea: savedArea, savedCenter: savedCenter);
    } catch (_) {
      _cached = null;
      return fallback(EnvironmentLocationStatus.unavailable);
    }
  }
}

class HomeLocationCard extends StatefulWidget {
  const HomeLocationCard({
    super.key,
    required this.onOpenMap,
    this.isActive = true,
    this.enableTiles = true,
    this.service,
  });

  final VoidCallback onOpenMap;
  final bool isActive;
  final bool enableTiles;
  final HomeLocationService? service;

  @override
  State<HomeLocationCard> createState() => _HomeLocationCardState();
}

class _HomeLocationCardState extends State<HomeLocationCard>
    with WidgetsBindingObserver {
  late HomeLocationService _service;
  HomeLocationResult _location =
      const HomeLocationResult(EnvironmentLocationStatus.checking);
  Timer? _refreshTimer;
  Timer? _fixExpiryTimer;
  bool _foreground = true;
  bool _loading = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? HomeLocationService();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _syncActivity();
  }

  void _syncActivity() {
    _refreshTimer?.cancel();
    _fixExpiryTimer?.cancel();
    if (!_foreground || !widget.isActive) {
      _generation++;
      _loading = false;
      return;
    }
    _refresh();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  void _scheduleFixExpiry() {
    _fixExpiryTimer?.cancel();
    final fix = _location.fix;
    if (fix == null || !_foreground || !widget.isActive) return;
    final remaining =
        fix.timestamp.add(const Duration(seconds: 60)).difference(_service.now);
    _fixExpiryTimer =
        Timer(remaining.isNegative ? Duration.zero : remaining, () {
      if (!mounted || !_foreground || !widget.isActive) return;
      setState(() => _location = HomeLocationResult(
          EnvironmentLocationStatus.checking,
          savedArea: _location.savedArea,
          savedCenter: _location.savedCenter));
      // Remove the marker at its own deadline, even if the next native fix
      // is pending. A normal poll must never extend a position's lifetime.
      _refresh();
    });
  }

  Future<void> _refresh() async {
    if (_loading || !_foreground || !widget.isActive) return;
    _loading = true;
    final generation = ++_generation;
    if (_location.fix != null &&
        !_homeFixIsFresh(_location.fix!, _service.now)) {
      setState(() => _location = HomeLocationResult(
          EnvironmentLocationStatus.checking,
          savedArea: _location.savedArea,
          savedCenter: _location.savedCenter));
    }
    final result = await _service.resolve(
        canContinue: () =>
            mounted &&
            widget.isActive &&
            _foreground &&
            generation == _generation);
    if (!mounted || generation != _generation) return;
    setState(() {
      _location =
          result.fix != null && !_homeFixIsFresh(result.fix!, _service.now)
              ? HomeLocationResult(EnvironmentLocationStatus.unavailable,
                  savedArea: result.savedArea, savedCenter: result.savedCenter)
              : result;
      _loading = false;
    });
    _scheduleFixExpiry();
  }

  @override
  void didUpdateWidget(covariant HomeLocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _generation++;
      _loading = false;
      _service = widget.service ?? HomeLocationService();
    }
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.service != widget.service) {
      _syncActivity();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncActivity();
  }

  @override
  void dispose() {
    _generation++;
    _refreshTimer?.cancel();
    _fixExpiryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final location = _location;
    final current = location.fix != null;
    final title = current ? 'Your current location' : 'Your location';
    final description = current
        ? 'GPS · ±${location.fix!.accuracy.round()} m'
        : location.savedCenter != null
            ? '${location.savedArea ?? 'Saved location'} · not current GPS'
            : switch (location.status) {
                EnvironmentLocationStatus.checking =>
                  'Checking phone location…',
                EnvironmentLocationStatus.disabled => 'Phone Location is off',
                EnvironmentLocationStatus.denied ||
                EnvironmentLocationStatus.deniedForever =>
                  'Location permission is off',
                _ => 'Current location unavailable',
              };
    return SundoSurface(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.my_location_rounded, color: mood.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: mood.textColor))),
            IconButton(
                tooltip: 'Open location map',
                onPressed: widget.onOpenMap,
                icon: Icon(Icons.open_in_full_rounded,
                    color: mood.accent, size: 18)),
          ]),
          Text(description,
              style: TextStyle(fontSize: 10, color: mood.mutedTextColor)),
          const SizedBox(height: 10),
          ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                  height: 132,
                  width: double.infinity,
                  child: ColoredBox(
                      color: mood.sky.withValues(alpha: .22),
                      child: location.center == null
                          ? Center(
                              child: TextButton.icon(
                                  onPressed: widget.onOpenMap,
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Open Live Map')))
                          : _HomeMiniMap(
                              center: location.center!,
                              fix: location.fix,
                              enableTiles: widget.enableTiles,
                              onOpenMap: widget.onOpenMap)))),
        ]));
  }
}

/// Only geographical map content is painted here; corner leaves remain outside.
class _HomeMiniMap extends StatefulWidget {
  const _HomeMiniMap(
      {required this.center,
      required this.fix,
      required this.enableTiles,
      required this.onOpenMap});
  final LatLng center;
  final Position? fix;
  final bool enableTiles;
  final VoidCallback onOpenMap;

  @override
  State<_HomeMiniMap> createState() => _HomeMiniMapState();
}

class _HomeMiniMapState extends State<_HomeMiniMap> {
  final _controller = MapController();
  late final _tiles = CachedOsmTileProvider();
  bool _ready = false;
  double get _zoom => widget.fix == null
      ? 12
      : widget.fix!.accuracy > 1000
          ? 12
          : widget.fix!.accuracy > 300
              ? 14
              : 16;

  @override
  void didUpdateWidget(covariant _HomeMiniMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready &&
        (widget.center != oldWidget.center || widget.fix != oldWidget.fix)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.move(widget.center, _zoom);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // TileLayer disposes the provider when present. An unused provider still
    // owns its small HTTP client, so release it in the no-tiles test mode too.
    if (!widget.enableTiles) _tiles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: Stack(fit: StackFit.expand, children: [
          Semantics(
              label: widget.fix == null
                  ? 'Map of saved area, not a current GPS location'
                  : 'Map of your current GPS location',
              child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                      backgroundColor: mood.isNight
                          ? const Color(0xFF1B3533)
                          : const Color(0xFFE3EEE3),
                      initialCenter: widget.center,
                      initialZoom: _zoom,
                      onMapReady: () => _ready = true,
                      interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none)),
                  children: [
                    if (widget.enableTiles)
                      ColorFiltered(
                          colorFilter: ColorFilter.mode(
                              mood.isNight
                                  ? const Color(0x9913262C)
                                  : Colors.white,
                              BlendMode.multiply),
                          child: TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.sundo.sipalay',
                              tileProvider: _tiles,
                              tileDisplay: reducedMotion
                                  ? const TileDisplay.instantaneous()
                                  : const TileDisplay.fadeIn(
                                      duration: Duration(milliseconds: 450)),
                              maxNativeZoom: 19)),
                    if (widget.fix != null) ...[
                      CircleLayer(circles: [
                        CircleMarker(
                            point: widget.center,
                            radius: widget.fix!.accuracy,
                            useRadiusInMeter: true,
                            color: const Color(0x222F80ED),
                            borderColor: const Color(0x662F80ED),
                            borderStrokeWidth: 1)
                      ]),
                      MarkerLayer(markers: [
                        Marker(
                            point: widget.center,
                            width: 22,
                            height: 22,
                            child: Container(
                                decoration: BoxDecoration(
                                    color: const Color(0xFF2F80ED),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3))))
                      ])
                    ],
                  ])),
          Positioned(
              bottom: 4,
              right: 5,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: mood.surface.withValues(alpha: .9),
                  child: Text('© OpenStreetMap contributors',
                      style:
                          TextStyle(fontSize: 8, color: mood.mutedTextColor)))),
          Positioned.fill(
              child: Semantics(
                  button: true,
                  label: 'Open Live Map',
                  child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: widget.onOpenMap)))),
        ]));
  }
}
