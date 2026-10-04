import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../shared/widgets/sundo_graphics.dart';
import './truck_alert_modal.dart';

class LiveMapScreen extends StatefulWidget {
  final bool isActive;
  final MapTruckRepository? repository;
  final bool enableTiles;
  final bool enableGps;
  const LiveMapScreen(
      {super.key,
      this.isActive = true,
      this.repository,
      this.enableTiles = true,
      this.enableGps = true});
  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _sipalay = LatLng(9.7525, 122.4038);
  final _mapController = MapController();
  late final AnimationController _truckMotion;
  StreamSubscription<List<MapTruckSnapshot>>? _trucksSubscription;
  StreamSubscription<Position>? _residentSubscription;
  Timer? _freshnessTimer;
  MapTruckSnapshot? _truck;
  LatLng? _truckStart, _truckTarget;
  LatLng? _residentPosition;
  LatLng _areaCenter = _sipalay;
  double? _residentAccuracy;
  DateTime? _residentUpdatedAt;
  double _heading = 0;
  double _sheetFraction = .32;
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
  NotificationRepository get _notifications => _demo
      ? MockNotificationRepository.shared
      : LocalNotificationRepository.shared;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _truckMotion = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5400))
      ..value = 1;
    _truckMotion.addListener(() {
      if (_followTruck &&
          _mapReady &&
          _displayTruck != null &&
          widget.isActive) {
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
        setState(() {});
      }
    });
    if (widget.enableGps && widget.isActive) {
      _readResidentLocation(requestPermission: false);
    }
  }

  @override
  void didUpdateWidget(covariant LiveMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadArea();
      if (widget.enableGps) {
        _readResidentLocation(requestPermission: false);
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      _residentSubscription?.cancel();
      _residentSubscription = null;
      _followTruck = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
    } else if (state == AppLifecycleState.paused ||
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
    final priorPosition = _displayTruck;
    final target = next?.position;
    _truckMotion.stop();
    setState(() {
      _truck = next;
      _loading = false;
      _trackingError = null;
      _truckStart = priorPosition ?? target;
      _truckTarget = target;
      if (next?.heading != null) {
        _heading = next!.heading!;
      } else if (priorPosition != null &&
          target != null &&
          priorPosition != target) {
        _heading = mapBearing(priorPosition, target);
      }
    });
    if (priorPosition != null && target != null && priorPosition != target) {
      _truckMotion.duration =
          Duration(milliseconds: next!.simulated ? 5400 : 1400);
      _truckMotion.forward(from: 0);
    } else {
      _truckMotion.value = 1;
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
        _mapController.move(_residentPosition!, 16);
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
    _followTruck = false;
    final route = _truck?.route.waypoints ?? [];
    if (route.length > 1) {
      _mapController.fitCamera(CameraFit.coordinates(
          coordinates: route,
          padding: const EdgeInsets.fromLTRB(45, 115, 65, 230),
          maxZoom: 16));
    } else {
      _mapController.move(_areaCenter, 15.3);
    }
  }

  void _follow() {
    if (!_mapReady || _displayTruck == null) return;
    setState(() {
      _followTruck = true;
    });
    _mapController.move(_displayTruck!, 16.2);
  }

  void _zoom(double change) {
    if (!_mapReady) return;
    _mapController.move(_mapController.camera.center,
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
                  title: const Text('Angled map with elevated markers'),
                  value: _angled,
                  onChanged: (value) {
                    setState(() => _angled = value);
                    updateSheet(() {});
                    if (_mapReady) _mapController.rotate(value ? -18 : 0);
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
    _truckMotion.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final route = _truck?.route;
    final resident = _residentUpdatedAt != null &&
            residentFixIsFresh(_residentUpdatedAt!, DateTime.now())
        ? _residentPosition
        : null;
    return Scaffold(
        backgroundColor: mood.background,
        body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => Stack(children: [
                    FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _areaCenter,
                          initialZoom: 15.3,
                          initialRotation: -18,
                          minZoom: 11,
                          maxZoom: 19,
                          onMapReady: () {
                            _mapReady = true;
                          },
                          onPositionChanged: (_, gesture) {
                            if (gesture) _followTruck = false;
                          },
                        ),
                        children: [
                          if (widget.enableTiles)
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.sundo.sipalay',
                              maxNativeZoom: 19,
                            ),
                          if (_showRoute &&
                              route != null &&
                              route.waypoints.length > 1)
                            PolylineLayer(polylines: [
                              Polyline(
                                  points: route.waypoints,
                                  strokeWidth: 11,
                                  color: Colors.white.withValues(alpha: .9)),
                              Polyline(
                                  points: route.waypoints,
                                  strokeWidth: 6,
                                  color: const Color(0xFF0B8F3E)),
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
                          MarkerLayer(rotate: true, markers: [
                            if (_showStops && route != null)
                              for (final point in route.collectionPoints)
                                Marker(
                                    point: point.position,
                                    width: 54,
                                    height: 57,
                                    alignment: Alignment.topCenter,
                                    child: Tooltip(
                                        message: point.name,
                                        child: SundoCollectionPointMarker(
                                            point: point))),
                            if (resident != null)
                              Marker(
                                  point: resident,
                                  width: 34,
                                  height: 34,
                                  child: Semantics(
                                      label: 'Your private GPS location',
                                      child: Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFF2F80ED)
                                                  .withValues(alpha: .2)),
                                          padding: const EdgeInsets.all(8),
                                          child: Container(
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      const Color(0xFF2F80ED),
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 3),
                                                  boxShadow: const [
                                                BoxShadow(
                                                    color: Color(0x442F80ED),
                                                    blurRadius: 8)
                                              ]))))),
                          ]),
                          AnimatedBuilder(
                              animation: _truckMotion,
                              builder: (context, _) => MarkerLayer(markers: [
                                    if (_displayTruck != null)
                                      Marker(
                                          point: _displayTruck!,
                                          width: 66,
                                          height: 66,
                                          rotate: false,
                                          child: Semantics(
                                              label:
                                                  '${_truck?.id ?? "Truck"} ${_truckFresh ? "position" : "last known position"}',
                                              child: Transform.rotate(
                                                  angle: (_heading + 90) *
                                                      math.pi /
                                                      180,
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha: _truckFresh
                                                                      ? .95
                                                                      : .65),
                                                          shape: BoxShape.circle,
                                                          border: Border.all(color: const Color(0xFF0B8F3E), width: 2),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                                color: Color(
                                                                    0x4407652E),
                                                                blurRadius: 12,
                                                                offset: Offset(
                                                                    0, 6))
                                                          ]),
                                                      child:
                                                          const SundoTruckGraphic(
                                                              width: 58,
                                                              height: 44))))),
                                  ])),
                        ]),
                    Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 5, 4, 5),
                            decoration: mapSurfaceDecoration(mood),
                            child: Row(children: [
                              Icon(Icons.search,
                                  color: mood.textColor, size: 21),
                              const SizedBox(width: 9),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('Live Truck Tracking',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: mood.textColor)),
                                    Text(
                                        _demo
                                            ? 'DEMO · simulated truck and route'
                                            : 'Sipalay City · city tracking',
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: mood.mutedTextColor)),
                                  ])),
                              IconButton(
                                  tooltip: 'Fit active route',
                                  onPressed: _recenter,
                                  icon: Icon(Icons.chevron_right,
                                      color: mood.accent)),
                            ]))),
                    Positioned(
                        top: 78,
                        left: 16,
                        right: 72,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: mapSurfaceDecoration(mood, radius: 12),
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
                                          fontSize: 9, color: mood.textColor)))
                            ]))),
                    Positioned(
                        top: 78,
                        right: 16,
                        child: Column(children: [
                          SundoMapControlButton(
                              icon: Icons.center_focus_strong,
                              tooltip: 'Re-center active route',
                              onPressed: _recenter),
                          const SizedBox(height: 8),
                          SundoMapControlButton(
                              icon: Icons.add,
                              tooltip: 'Zoom in',
                              onPressed: () => _zoom(1)),
                          const SizedBox(height: 8),
                          SundoMapControlButton(
                              icon: Icons.remove,
                              tooltip: 'Zoom out',
                              onPressed: () => _zoom(-1)),
                          const SizedBox(height: 8),
                          SundoMapControlButton(
                              icon: Icons.my_location,
                              tooltip: 'Use my current location',
                              selected: resident != null,
                              onPressed: () {
                                _followTruck = false;
                                _readResidentLocation(
                                    requestPermission: true, recenter: true);
                              }),
                          const SizedBox(height: 8),
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
                    if (resident != null && _residentUpdatedAt != null)
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
                            initialChildSize: .32,
                            minChildSize: .24,
                            maxChildSize: .72,
                            snap: true,
                            snapSizes: const [.32, .55],
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
                  ])),
        ));
  }
}
