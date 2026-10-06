import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../models/map_tracking.dart';
import '../../repositories/map_truck_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../core/storage/app_store.dart';
import '../../services/backend_service.dart';
import '../../core/theme/time_theme.dart';
import '../../core/utils/resident_area.dart';
import '../../core/utils/resident_location.dart';
import './widgets/map_tracking_widgets.dart';
import './truck_alert_modal.dart';
import './map_presentation.dart';
import './osm_tile_provider.dart';
import './widgets/clay_map_markers.dart';
import './widgets/map_scene_controls.dart';

class LiveMapScreen extends StatefulWidget {
  final bool isActive;
  final MapTruckRepository? repository;
  final bool enableTiles;
  final bool enableGps;
  final TileProvider? tileProvider;
  const LiveMapScreen(
      {super.key,
      this.isActive = true,
      this.repository,
      this.enableTiles = true,
      this.enableGps = true,
      this.tileProvider});
  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _sipalay = LatLng(9.7525, 122.4038);
  final _mapController = MapController();
  late final AnimationController _truckMotion;
  late final AnimationController _flowMotion;
  late final AnimationController _cameraMotion;
  final _mapRotation = ValueNotifier<double>(-18);
  late final TileProvider _tileProvider;
  StreamSubscription<MapEvent>? _cameraEvents;
  LatLng? _cameraStart, _cameraTarget;
  double _cameraZoomStart = 16, _cameraZoomTarget = 16;
  double _cameraAngleStart = -18, _cameraAngleTarget = -18;
  DateTime? _lastFollowFrame;
  StreamSubscription<List<MapTruckSnapshot>>? _trucksSubscription;
  StreamSubscription<Position>? _residentSubscription;
  Timer? _freshnessTimer;
  MapTruckSnapshot? _truck;
  LatLng? _truckStart, _truckTarget;
  LatLng? _residentPosition;
  LatLng _areaCenter = _sipalay;
  double? _residentAccuracy;
  DateTime? _residentUpdatedAt;
  double? _headingStart, _headingTarget;
  double _sheetFraction = .30;
  int? _selectedStop;
  bool _motionEnabled = true;
  bool _reduceMotion = false;
  String _barangay = 'Sipalay City';
  String _locationMessage = 'Use location to see your private GPS marker';
  String? _trackingError;
  bool _loading = true;
  bool _mapReady = false;
  bool _showRoute = true, _showStops = true, _angled = true;
  bool _followTruck = false;
  bool _locating = false;
  bool _alertVisible = false;
  bool _demo = true;
  bool _foreground = true;

  LatLng? get _displayTruck => _truckStart != null && _truckTarget != null
      ? interpolateMapPosition(_truckStart!, _truckTarget!, _truckMotion.value)
      : _truck?.position;
  bool get _truckFresh => _truck?.freshAt(DateTime.now()) == true;
  double? get _displayHeading => _headingTarget == null
      ? null
      : interpolateMapHeading(_headingStart ?? _headingTarget!, _headingTarget!,
          _truckMotion.value);
  bool get _truckMoving =>
      _truckFresh &&
      _truck?.active == true &&
      _truckMotion.isAnimating &&
      _visualMotion;
  bool get _visualMotion =>
      widget.isActive && _foreground && _motionEnabled && !_reduceMotion;
  NotificationRepository get _notifications => _demo
      ? MockNotificationRepository.shared
      : LocalNotificationRepository.shared;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tileProvider = widget.tileProvider ?? CachedOsmTileProvider();
    _flowMotion =
        AnimationController(vsync: this, duration: const Duration(seconds: 14));
    _cameraMotion = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..addListener(_animateCameraFrame);
    _cameraEvents = _mapController.mapEventStream.listen((event) {
      if ((_mapRotation.value - event.camera.rotation).abs() > .02) {
        _mapRotation.value = event.camera.rotation;
      }
    });
    _truckMotion = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5400))
      ..value = 1;
    _truckMotion.addListener(() {
      if (_followTruck &&
          _mapReady &&
          _displayTruck != null &&
          _visualMotion &&
          !_cameraMotion.isAnimating) {
        final now = DateTime.now();
        if (_lastFollowFrame != null &&
            now.difference(_lastFollowFrame!).inMilliseconds < 42) {
          return;
        }
        _lastFollowFrame = now;
        _mapController.move(_displayTruck!, _mapController.camera.zoom);
      }
    });
    _loadArea();
    _subscribeTrucks();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      if (_residentUpdatedAt != null &&
          !residentFixIsFresh(_residentUpdatedAt!, DateTime.now())) {
        _clearResidentLocation();
        _setLocationMessage('GPS fix expired · showing $_barangay area');
        // Refresh stationary devices too: a distance-filtered stream may not
        // emit another fix until the resident moves.
        if (widget.isActive && widget.enableGps && _foreground) {
          unawaited(_readResidentLocation(requestPermission: false));
        }
      } else {
        setState(() {
          if (!_truckFresh) {
            _followTruck = false;
            _cameraMotion.stop();
          }
        });
      }
    });
    if (widget.enableGps && widget.isActive) {
      _readResidentLocation(requestPermission: false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncVisualMotion();
  }

  void _syncVisualMotion() {
    if (_visualMotion) {
      if (!_flowMotion.isAnimating) _flowMotion.repeat();
    } else {
      _flowMotion.stop();
      _cameraMotion.stop();
      _truckMotion.stop();
      _truckMotion.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant LiveMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadArea();
      _truckMotion.value = 1;
      if (widget.enableGps) {
        _readResidentLocation(requestPermission: false);
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      _residentSubscription?.cancel();
      _residentSubscription = null;
      _followTruck = false;
    }
    _syncVisualMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _foreground = false;
    }
    if (state == AppLifecycleState.resumed &&
        widget.isActive &&
        widget.enableGps) {
      _readResidentLocation(requestPermission: false);
    } else if (!_foreground) {
      _residentSubscription?.cancel();
      _residentSubscription = null;
    }
    _syncVisualMotion();
  }

  Future<void> _loadArea() async {
    final barangay = await AppStore.getBarangay();
    final saved = await AppStore.getResidentLocation();
    if (!mounted) return;
    // Coarse area fallback; never labeled as the resident's GPS location.
    const centers = <String, LatLng>{
      'Barangay 1': LatLng(9.7525, 122.4038),
      'Barangay 2': LatLng(9.7508, 122.4050),
      'Barangay 3': LatLng(9.7540, 122.4040),
      'Barangay 4': LatLng(9.7560, 122.4050),
      'Barangay 5': LatLng(9.7485, 122.4065),
    };
    setState(() {
      _barangay = barangay;
      final key = centers.keys.where((key) =>
          canonicalResidentArea(key) == canonicalResidentArea(barangay));
      final savedCenter = saved == null
          ? null
          : mapCoordinate(saved['latitude'], saved['longitude']);
      _areaCenter =
          key.isNotEmpty ? centers[key.first]! : savedCenter ?? _sipalay;
    });
  }

  void _subscribeTrucks() {
    _trucksSubscription?.cancel();
    _demo = !BackendService.live;
    final repository = widget.repository ??
        (_demo
            ? MockMapTruckRepository.shared
            : SupabaseMapTruckRepository(BackendService.client));
    _trucksSubscription = repository.watchTrucks().listen(_receiveTrucks,
        onError: (Object error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _trackingError =
            'Could not load city tracking. Check your connection and retry.';
      });
    });
  }

  void _receiveTrucks(List<MapTruckSnapshot> trucks) {
    if (!mounted) return;
    trucks.sort((a, b) {
      final aLive = a.active && a.freshAt(DateTime.now());
      final bLive = b.active && b.freshAt(DateTime.now());
      if (aLive != bLive) return aLive ? -1 : 1;
      return a.id.compareTo(b.id);
    });
    MapTruckSnapshot? next;
    if (trucks.isNotEmpty) {
      next = trucks.where((truck) => truck.id == _truck?.id).firstOrNull;
      next ??= trucks.first;
    }
    final previous = _truck;
    final sameTruck = next != null && previous?.id == next.id;
    final priorSourcePosition = previous?.position;
    final priorPosition = _displayTruck;
    final target = next?.position;
    final priorHeading = _displayHeading;
    _truckMotion.stop();
    setState(() {
      _truck = next;
      _loading = false;
      _trackingError = null;
      if (next == null || !next.freshAt(DateTime.now())) {
        _followTruck = false;
      }
      if (previous?.route.id != next?.route.id) _selectedStop = null;
      _truckStart = sameTruck ? priorPosition ?? target : target;
      _truckTarget = target;
      _headingStart = sameTruck ? priorHeading : null;
      if (next?.heading?.isFinite == true) {
        _headingTarget = next!.heading!;
      } else if (sameTruck &&
          priorSourcePosition != null &&
          target != null &&
          priorSourcePosition != target) {
        _headingTarget = mapBearing(priorSourcePosition, target);
      } else {
        _headingTarget = sameTruck ? priorHeading : null;
      }
    });
    if (_visualMotion &&
        sameTruck &&
        next.freshAt(DateTime.now()) &&
        priorPosition != null &&
        target != null &&
        priorPosition != target) {
      _truckMotion.duration =
          Duration(milliseconds: next.simulated ? 5400 : 1400);
      _truckMotion.forward(from: 0);
    } else {
      _truckMotion.value = 1;
      if (_followTruck && _mapReady && target != null) {
        _mapController.move(target, _mapController.camera.zoom);
      }
    }
    if (next == null) return;
    if (previous != null &&
        previous.id == next.id &&
        previous.route.id != next.route.id) {
      _recordRouteChange(next);
    }
    if (next.freshAt(DateTime.now()) &&
        next.stage == MapTrackingStage.approaching &&
        previous?.stage != MapTrackingStage.approaching &&
        next.etaMinutes != null) {
      _approaching(next);
    }
  }

  Future<void> _recordRouteChange(MapTruckSnapshot truck) async {
    if (!await AppStore.notificationEnabled('route')) return;
    await _notifications.recordEvent(
      id: 'route-${truck.id}-${truck.updatedAt?.millisecondsSinceEpoch}',
      title: 'Route Changed',
      type: 'route',
      message:
          '${truck.simulated ? "Demo: " : ""}${truck.route.name.isEmpty ? "The active collection route" : truck.route.name} has been updated.'
          '${truck.etaMinutes == null ? "" : " ETA: ${truck.etaMinutes} minutes."}',
    );
    if (!mounted || !widget.isActive) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('The active route has changed. Tracking is updated.')));
  }

  Future<void> _approaching(MapTruckSnapshot truck) async {
    final residentArea = canonicalResidentArea(_barangay);
    final collectionArea =
        '${truck.nextStop ?? ""} ${truck.currentArea ?? ""}'.toLowerCase();
    if (!truck.simulated &&
        (residentArea.isEmpty ||
            !serviceAreaMatchesResident(collectionArea, residentArea))) {
      return;
    }
    if (!await _notifications.remindersEnabled()) return;
    await _notifications.recordEvent(
      id: 'approach-${truck.id}-${truck.updatedAt?.millisecondsSinceEpoch}',
      title: 'Truck Approaching',
      type: 'alert',
      message:
          '${truck.simulated ? "Demo: " : ""}Garbage truck is ${truck.etaMinutes} minutes from its collection area.',
    );
    if (!mounted ||
        !widget.isActive ||
        _alertVisible ||
        !await _notifications.remindersEnabled()) {
      return;
    }
    if (!mounted || !widget.isActive) return;
    await _showAlert(truck);
  }

  Future<void> _showAlert(MapTruckSnapshot truck) async {
    _alertVisible = true;
    await TruckAlertModal.show(context,
        etaMinutes: truck.etaMinutes ?? 10,
        simulated: truck.simulated,
        onViewTruck: _follow);
    _alertVisible = false;
  }

  Future<void> _readResidentLocation(
      {required bool requestPermission, bool recenter = false}) async {
    if (_locating || !widget.enableGps || !_foreground) return;
    _locating = true;
    if (mounted) {
      setState(() {
        _locationMessage = 'Finding your device location…';
      });
    }
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _clearResidentLocation();
        _setLocationMessage('Location is off · showing $_barangay area');
        if (requestPermission) await Geolocator.openLocationSettings();
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _clearResidentLocation();
        _setLocationMessage(
            'Location permission denied · showing $_barangay area');
        if (requestPermission) await Geolocator.openAppSettings();
        return;
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        _clearResidentLocation();
        _setLocationMessage('Location is private · showing $_barangay area');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15));
      if (!mounted || !widget.isActive || !_foreground) return;
      _receiveResidentPosition(position);
      if (recenter && _mapReady && _residentPosition != null) {
        _flyTo(_residentPosition!, 16);
      }
      await _residentSubscription?.cancel();
      if (!mounted || !widget.isActive || !_foreground) return;
      _residentSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      )).listen(_receiveResidentPosition, onError: (Object error) {
        _clearResidentLocation();
        _setLocationMessage('GPS update unavailable · showing $_barangay area');
      });
    } catch (_) {
      _clearResidentLocation();
      _setLocationMessage('Could not get GPS · showing $_barangay area');
    } finally {
      _locating = false;
      if (mounted) setState(() {});
    }
  }

  void _receiveResidentPosition(Position position) {
    if (!mounted || !_foreground || !widget.isActive) return;
    final coordinates = mapCoordinate(position.latitude, position.longitude);
    if (coordinates == null ||
        !residentFixIsFresh(position.timestamp, DateTime.now())) {
      _clearResidentLocation();
      _setLocationMessage('Fresh GPS unavailable · showing $_barangay area');
      return;
    }
    setState(() {
      _residentPosition = coordinates;
      _residentAccuracy = position.accuracy.isFinite && position.accuracy >= 0
          ? position.accuracy
          : null;
      _residentUpdatedAt = position.timestamp;
      _locationMessage = _residentAccuracy == null
          ? 'Your private GPS location'
          : 'Your private GPS · ±${_residentAccuracy!.round()} m';
    });
    // Device position is deliberately never written to a shared truck source.
  }

  void _setLocationMessage(String message) {
    if (mounted) {
      setState(() {
        _locationMessage = message;
      });
    }
  }

  void _clearResidentLocation() {
    _residentSubscription?.cancel();
    _residentSubscription = null;
    if (!mounted) return;
    setState(() {
      _residentPosition = null;
      _residentAccuracy = null;
      _residentUpdatedAt = null;
    });
  }

  void _recenter() {
    if (!_mapReady) return;
    setState(() {
      _followTruck = false;
      _selectedStop = null;
    });
    final route = _truck?.route.waypoints ?? [];
    if (route.length > 1) {
      final height = _mapController.camera.nonRotatedSize.y;
      final fitted = CameraFit.coordinates(
              coordinates: route,
              padding: EdgeInsets.fromLTRB(
                  45, 160, 70, height * _sheetFraction + 45),
              maxZoom: 16.4)
          .fit(_mapController.camera);
      _flyTo(fitted.center, fitted.zoom);
    } else {
      _flyTo(_areaCenter, 16.1);
    }
  }

  void _follow() {
    if (!_mapReady || _displayTruck == null) return;
    setState(() {
      _followTruck = !_followTruck && _truckFresh;
      _selectedStop = null;
    });
    if (_followTruck) _flyTo(_displayTruck!, 16.5);
  }

  void _flyTo(LatLng target, double zoom, {double? rotation}) {
    if (!_mapReady) return;
    _cameraStart = _mapController.camera.center;
    _cameraTarget = target;
    _cameraZoomStart = _mapController.camera.zoom;
    _cameraZoomTarget = zoom;
    _cameraAngleStart = _mapController.camera.rotation;
    _cameraAngleTarget = rotation ?? _cameraAngleStart;
    if (!_visualMotion) {
      _mapController.moveAndRotate(target, zoom, _cameraAngleTarget);
    } else {
      _cameraMotion.forward(from: 0);
    }
  }

  void _animateCameraFrame() {
    if (!_mapReady || _cameraStart == null || _cameraTarget == null) return;
    final progress = Curves.easeInOutCubic.transform(_cameraMotion.value);
    final target =
        _followTruck ? _displayTruck ?? _cameraTarget! : _cameraTarget!;
    _mapController.moveAndRotate(
        interpolateMapPosition(_cameraStart!, target, progress),
        _cameraZoomStart + (_cameraZoomTarget - _cameraZoomStart) * progress,
        interpolateMapHeading(_cameraAngleStart, _cameraAngleTarget, progress));
  }

  void _setView(bool angled) {
    if (_angled == angled) return;
    setState(() => _angled = angled);
    if (_mapReady) {
      _flyTo(_mapController.camera.center, _mapController.camera.zoom,
          rotation: angled ? -18 : 0);
    }
  }

  void _selectStop(MapCollectionPoint point) {
    setState(() {
      _selectedStop = point.number;
      _followTruck = false;
    });
    _flyTo(point.position, 16.8);
  }

  void _zoom(double change) {
    if (!_mapReady) return;
    _flyTo(_mapController.camera.center,
        (_mapController.camera.zoom + change).clamp(11, 19));
  }

  Future<void> _layers() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
            builder: (sheetContext, updateSheet) => SafeArea(
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
              const ListTile(
                  title: Text('Map layers'),
                  subtitle: Text('OpenStreetMap · Sipalay City')),
              SwitchListTile(
                  title: const Text('Active route'),
                  value: _showRoute,
                  onChanged: (value) {
                    setState(() => _showRoute = value);
                    updateSheet(() {});
                  }),
              SwitchListTile(
                  title: const Text('Numbered collection points'),
                  value: _showStops,
                  onChanged: (value) {
                    setState(() => _showStops = value);
                    updateSheet(() {});
                  }),
              SwitchListTile(
                  title: const Text('3D city perspective'),
                  value: _angled,
                  onChanged: (value) {
                    _setView(value);
                    updateSheet(() {});
                  }),
              SwitchListTile(
                  title: const Text('Animate route and beacons'),
                  subtitle: const Text(
                      'Pause the visual effects while inspecting the map.'),
                  value: _motionEnabled && !_reduceMotion,
                  onChanged: _reduceMotion
                      ? null
                      : (value) {
                          setState(() => _motionEnabled = value);
                          _syncVisualMotion();
                          updateSheet(() {});
                        }),
              const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                      'Collection routes are read only. The city manages operating route changes.',
                      textAlign: TextAlign.center)),
            ]))),
          ));

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trucksSubscription?.cancel();
    _residentSubscription?.cancel();
    _freshnessTimer?.cancel();
    _cameraEvents?.cancel();
    _mapRotation.dispose();
    _truckMotion.dispose();
    _flowMotion.dispose();
    _cameraMotion.dispose();
    if (!widget.enableTiles) _tileProvider.dispose();
    _mapController.dispose();
    super.dispose();
  }

  LatLng? get _visibleResident => _residentUpdatedAt != null &&
          residentFixIsFresh(_residentUpdatedAt!, DateTime.now())
      ? _residentPosition
      : null;

  Widget _mapPlane(SundoTimeMood mood) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: _angled ? 1 : 0),
        duration:
            _reduceMotion ? Duration.zero : const Duration(milliseconds: 750),
        curve: Curves.easeInOutCubic,
        child: _buildMap(mood),
        builder: (context, tilt, child) => LayoutBuilder(
            builder: (context, size) => Transform(
                key: const ValueKey('map-perspective'),
                alignment: Alignment.center,
                transformHitTests: true,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, tilt * .9 / size.maxHeight)
                  ..rotateX(-.58 * tilt)
                  ..scaleByDouble(1 + .32 * tilt, 1 + .55 * tilt, 1, 1),
                child: _MapPitchScope(pitch: .58 * tilt, child: child!))),
      );

  Widget _buildMap(SundoTimeMood mood) {
    final route = _truck?.route;
    final resident = _visibleResident;
    final routeColor =
        _truckFresh ? const Color(0xFF0B8F3E) : const Color(0xFF758579);
    final tiles = ColorFiltered(
        // Keep TileLayer mounted across automatic day/night changes.
        colorFilter: ColorFilter.mode(
            mood.isNight ? const Color(0x9913262C) : Colors.white,
            BlendMode.multiply),
        child: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            tileProvider: _tileProvider,
            userAgentPackageName: 'com.sundo.sipalay',
            maxNativeZoom: 19));
    return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          backgroundColor:
              mood.isNight ? const Color(0xFF1B3533) : const Color(0xFFE3EEE3),
          initialCenter: _areaCenter,
          initialZoom: 16.1,
          initialRotation: -18,
          minZoom: 11,
          maxZoom: 19,
          onMapReady: () {
            _mapReady = true;
          },
          onPositionChanged: (_, gesture) {
            if (!gesture) return;
            _cameraMotion.stop();
            if (_followTruck || _selectedStop != null) {
              setState(() {
                _followTruck = false;
                _selectedStop = null;
              });
            }
          },
        ),
        children: [
          if (widget.enableTiles) tiles,
          if (_showRoute && route != null && route.waypoints.length > 1)
            PolylineLayer(polylines: [
              Polyline(
                  points: route.waypoints,
                  strokeWidth: 17,
                  color: const Color(0x33052F1C)),
              Polyline(
                  points: route.waypoints,
                  strokeWidth: 13,
                  color: Colors.white.withValues(alpha: .92)),
              Polyline(
                  points: route.waypoints,
                  strokeWidth: 8,
                  gradientColors: _truckFresh
                      ? const [
                          Color(0xFF087C3B),
                          Color(0xFF59BE39),
                          Color(0xFF008D54)
                        ]
                      : [routeColor, routeColor],
                  colorsStop: const [0, .5, 1]),
            ]),
          if (resident != null && _residentAccuracy != null)
            CircleLayer(circles: [
              CircleMarker(
                  point: resident,
                  radius: _residentAccuracy!,
                  useRadiusInMeter: true,
                  color: const Color(0x222F80ED),
                  borderColor: const Color(0x882F80ED),
                  borderStrokeWidth: 1),
            ]),
          AnimatedBuilder(
              animation:
                  Listenable.merge([_truckMotion, _flowMotion, _mapRotation]),
              builder: (context, _) {
                final pulse = (_flowMotion.value * 4) % 1;
                final arrows = _showRoute &&
                        _truckFresh &&
                        _truck?.active == true &&
                        route != null
                    ? movingRouteIndicators(route.waypoints, _flowMotion.value)
                    : <RouteFlowPoint>[];
                return RepaintBoundary(
                    child: Stack(children: [
                  MarkerLayer(rotate: false, markers: [
                    for (final arrow in arrows)
                      Marker(
                          point: arrow.position,
                          width: 20,
                          height: 20,
                          child: ExcludeSemantics(
                              child: Transform.rotate(
                                  angle: arrow.headingDegrees * math.pi / 180,
                                  child: const Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      size: 21,
                                      color: Color(0xFFE6FFE2))))),
                  ]),
                  MarkerLayer(rotate: true, markers: [
                    if (_showStops && route != null)
                      for (final point in route.collectionPoints)
                        Marker(
                            point: point.position,
                            width: _angled ? 72 : 54,
                            height: _angled ? 90 : 67.5,
                            alignment: const Alignment(0, -7 / 9),
                            child: _MapBillboard(
                                alignment: const Alignment(0, 7 / 9),
                                child: Tooltip(
                                    message: point.name,
                                    child: GestureDetector(
                                        key: ValueKey(
                                            'collection-stop-${point.number}'),
                                        onTap: () => _selectStop(point),
                                        child: SundoClayCollectionMarker(
                                            number: point.number,
                                            name: point.name,
                                            selected:
                                                _selectedStop == point.number,
                                            pulse: pulse))))),
                    if (resident != null)
                      Marker(
                          point: resident,
                          width: 64,
                          height: 64,
                          child: _MapBillboard(
                              child: Semantics(
                                  label: 'Your private GPS location',
                                  child: SundoResidentBeacon(pulse: pulse)))),
                    if (_displayTruck != null)
                      Marker(
                          point: _displayTruck!,
                          width: _angled ? 84 : 68,
                          height: _angled ? 84 : 68,
                          child: _MapBillboard(
                              child: Semantics(
                                  label: (_truck?.id ?? 'Truck') +
                                      (_truckFresh
                                          ? ' position'
                                          : ' last known position'),
                                  child: SundoMapTruckMarker(
                                      headingDegrees: _displayHeading,
                                      mapRotationDegrees: _mapRotation.value,
                                      fresh: _truckFresh,
                                      moving: _truckMoving,
                                      pulse: pulse)))),
                  ]),
                ]));
              }),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final resident = _visibleResident;
    return Scaffold(
        backgroundColor: mood.background,
        body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => ClipRect(
                      child: Stack(fit: StackFit.expand, children: [
                    _mapPlane(mood),
                    IgnorePointer(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [
                          0,
                          .25,
                          .72,
                          1
                        ],
                                    colors: [
                          mood.sky.withValues(alpha: .3),
                          Colors.transparent,
                          Colors.transparent,
                          mood.background.withValues(alpha: .25),
                        ])))),
                    Positioned(
                        top: 12,
                        left: 16,
                        child: Row(children: [
                          ValueListenableBuilder<double>(
                              valueListenable: _mapRotation,
                              builder: (context, angle, _) => Transform.rotate(
                                  angle: angle * math.pi / 180,
                                  child: SundoMapControlButton(
                                      tooltip: 'Reset map north',
                                      icon: Icons.navigation_rounded,
                                      onPressed: () {
                                        setState(() => _followTruck = false);
                                        if (_mapReady) {
                                          _flyTo(_mapController.camera.center,
                                              _mapController.camera.zoom,
                                              rotation: 0);
                                        }
                                      }))),
                          const SizedBox(width: 8),
                          SundoMapControlButton(
                              tooltip: 'Fit active route',
                              icon: Icons.center_focus_strong,
                              onPressed: _recenter),
                        ])),
                    Positioned(
                        top: 82,
                        left: 16,
                        right: 72,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration:
                                  mapSurfaceDecoration(mood, radius: 12),
                              child: Row(children: [
                                Icon(
                                    resident == null
                                        ? Icons.location_off_outlined
                                        : Icons.my_location,
                                    size: 14,
                                    color: resident == null
                                        ? mood.mutedTextColor
                                        : const Color(0xFF2F80ED)),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: Text(_locationMessage,
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: mood.textColor))),
                              ])),
                          const SizedBox(height: 8),
                          SundoMapViewBar(
                              angled: _angled,
                              following: _followTruck,
                              canFollow: _truckFresh && _displayTruck != null,
                              onViewChanged: _setView,
                              onWatch: _follow),
                        ])),
                    Positioned(
                        top: 82,
                        right: 16,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          SundoMapControlButton(
                              icon: Icons.add,
                              tooltip: 'Zoom in',
                              onPressed: () => _zoom(1)),
                          SizedBox(height: constraints.maxHeight < 520 ? 4 : 8),
                          SundoMapControlButton(
                              icon: Icons.remove,
                              tooltip: 'Zoom out',
                              onPressed: () => _zoom(-1)),
                          SizedBox(height: constraints.maxHeight < 520 ? 4 : 8),
                          SundoMapControlButton(
                              icon: Icons.my_location,
                              tooltip: 'Use my current location',
                              selected: resident != null,
                              onPressed: () {
                                setState(() => _followTruck = false);
                                _readResidentLocation(
                                    requestPermission: true, recenter: true);
                              }),
                          SizedBox(height: constraints.maxHeight < 520 ? 4 : 8),
                          SundoMapControlButton(
                              icon: Icons.layers_outlined,
                              tooltip: 'Map layers',
                              onPressed: _layers),
                        ])),
                    Positioned(
                        left: 8,
                        bottom: constraints.maxHeight * _sheetFraction + 7,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            color: mood.surface.withValues(alpha: .92),
                            child: Text('© OpenStreetMap contributors',
                                style: TextStyle(
                                    fontSize: 9, color: mood.textColor)))),
                    if (resident != null)
                      Positioned(
                          left: 16,
                          bottom: constraints.maxHeight * _sheetFraction + 29,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                  color: mood.surface,
                                  borderRadius: BorderRadius.circular(9)),
                              child: Text('Your Location · private',
                                  style: TextStyle(
                                      color: mood.textColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)))),
                    NotificationListener<DraggableScrollableNotification>(
                        onNotification: (notification) {
                          if ((_sheetFraction - notification.extent).abs() >
                              .005) {
                            setState(
                                () => _sheetFraction = notification.extent);
                          }
                          return false;
                        },
                        child: DraggableScrollableSheet(
                            initialChildSize: .30,
                            minChildSize: .22,
                            maxChildSize: .72,
                            snap: true,
                            snapSizes: const [.30, .55],
                            builder: (context, scrollController) =>
                                SundoTrackingBottomSheet(
                                  truck: _truck,
                                  error: _trackingError,
                                  loading: _loading,
                                  fresh: _truckFresh,
                                  scrollController: scrollController,
                                  onFollow: _follow,
                                  onRefresh: () {
                                    setState(() => _loading = true);
                                    _subscribeTrucks();
                                  },
                                  onAlertPreview: _truck?.simulated == true
                                      ? () => _showAlert(_truck!)
                                      : null,
                                ))),
                  ]))),
        ));
  }
}

/// Keeps raised markers facing the viewer while the map ground plane tilts.
class _MapPitchScope extends InheritedWidget {
  final double pitch;
  const _MapPitchScope({required this.pitch, required super.child});
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MapPitchScope>()?.pitch ?? 0;
  @override
  bool updateShouldNotify(_MapPitchScope oldWidget) => oldWidget.pitch != pitch;
}

class _MapBillboard extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  const _MapBillboard({required this.child, this.alignment = Alignment.center});
  @override
  Widget build(BuildContext context) {
    final pitch = _MapPitchScope.of(context);
    final tilt = pitch / .58;
    return Transform(
        alignment: alignment,
        transform: Matrix4.identity()
          ..scaleByDouble(1 / (1 + .32 * tilt), 1 / (1 + .55 * tilt), 1, 1)
          ..rotateX(pitch),
        child: child);
  }
}
