import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/map_tracking.dart';

/// Replace this interface with PHP, Firebase or WebSocket transport as needed.
abstract interface class MapTruckRepository {
  Stream<List<MapTruckSnapshot>> watchTrucks();
}

class SupabaseMapTruckRepository implements MapTruckRepository {
  final SupabaseClient client;
  const SupabaseMapTruckRepository(this.client);

  @override
  Stream<List<MapTruckSnapshot>> watchTrucks() => client
      .from('trucks')
      .stream(primaryKey: ['id'])
      .order('id')
      .map((rows) => rows.map(MapTruckSnapshot.fromSupabase).toList());
}

/// These demonstration routes are sample paths, not city operating directions.
/// Every route closes at the same point, so changing routes never teleports.
class MockMapTruckRepository implements MapTruckRepository {
  static final shared = MockMapTruckRepository();
  late final StreamController<List<MapTruckSnapshot>> _updates =
      StreamController<List<MapTruckSnapshot>>.broadcast(
          onListen: _start, onCancel: _stop);
  Timer? _timer;
  List<MapTruckSnapshot>? _lastUpdate;
  var _routeIndex = 0;
  var _waypoint = 0;
  var _completed = false;
  static const _base = <LatLng>[
    LatLng(9.7540, 122.4026),
    LatLng(9.7534, 122.4030),
    LatLng(9.7527, 122.4034),
    LatLng(9.7520, 122.4038),
    LatLng(9.7514, 122.4042),
    LatLng(9.7508, 122.4046),
    LatLng(9.7503, 122.4050),
    LatLng(9.7507, 122.4055),
    LatLng(9.7513, 122.4051),
    LatLng(9.7520, 122.4046),
    LatLng(9.7527, 122.4041),
    LatLng(9.7534, 122.4034),
    LatLng(9.7540, 122.4026),
  ];

  static const routes = <MapOperatingRoute>[
    MapOperatingRoute(
      id: 'A',
      name: 'Route A · Recommended',
      waypoints: _base,
      collectionPoints: [
        MapCollectionPoint(
            1, 'Barangay 1 · sample stop', LatLng(9.7527, 122.4034)),
        MapCollectionPoint(
            2, 'Barangay 2 · sample stop', LatLng(9.7508, 122.4046)),
        MapCollectionPoint(
            3, 'Barangay 3 · sample stop', LatLng(9.7520, 122.4046)),
      ],
    ),
    MapOperatingRoute(
      id: 'B',
      name: 'Route B · Alternate',
      waypoints: [
        LatLng(9.7540, 122.4026),
        LatLng(9.7534, 122.4030),
        LatLng(9.7527, 122.4034),
        LatLng(9.7529, 122.4040),
        LatLng(9.7523, 122.4044),
        LatLng(9.7517, 122.4048),
        LatLng(9.7512, 122.4052),
        LatLng(9.7513, 122.4051),
        LatLng(9.7520, 122.4046),
        LatLng(9.7527, 122.4041),
        LatLng(9.7534, 122.4034),
        LatLng(9.7540, 122.4026),
      ],
      collectionPoints: [
        MapCollectionPoint(
            1, 'Barangay 1 · sample stop', LatLng(9.7527, 122.4034)),
        MapCollectionPoint(
            2, 'Barangay 2 · sample stop', LatLng(9.7512, 122.4052)),
      ],
    ),
    MapOperatingRoute(
      id: 'C',
      name: 'Route C · Delayed',
      waypoints: [
        LatLng(9.7540, 122.4026),
        LatLng(9.7534, 122.4034),
        LatLng(9.7527, 122.4041),
        LatLng(9.7520, 122.4046),
        LatLng(9.7513, 122.4051),
        LatLng(9.7507, 122.4055),
        LatLng(9.7503, 122.4050),
        LatLng(9.7508, 122.4046),
        LatLng(9.7514, 122.4042),
        LatLng(9.7520, 122.4038),
        LatLng(9.7527, 122.4034),
        LatLng(9.7534, 122.4030),
        LatLng(9.7540, 122.4026),
      ],
      collectionPoints: [
        MapCollectionPoint(
            1, 'Barangay 3 · sample stop', LatLng(9.7520, 122.4046)),
        MapCollectionPoint(
            2, 'Barangay 1 · sample stop', LatLng(9.7527, 122.4034)),
      ],
    ),
  ];

  @override
  Stream<List<MapTruckSnapshot>> watchTrucks() => Stream.multi((listener) {
        final subscription = _updates.stream.listen(listener.add,
            onError: listener.addError, onDone: listener.close);
        listener.add(_lastUpdate ??= _snapshot());
        listener.onCancel = subscription.cancel;
      });

  void _start() {
    _timer ??= Timer.periodic(const Duration(seconds: 6), (_) {
      if (_completed) {
        _routeIndex = (_routeIndex + 1) % routes.length;
        _waypoint = 0;
        _completed = false;
      } else {
        _waypoint++;
        if (_waypoint >= routes[_routeIndex].waypoints.length - 1) {
          _waypoint = routes[_routeIndex].waypoints.length - 1;
          _completed = true;
        }
      }
      _lastUpdate = _snapshot();
      _updates.add(_lastUpdate!);
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  List<MapTruckSnapshot> _snapshot() {
    final route = routes[_routeIndex];
    final progress = _waypoint / (route.waypoints.length - 1);
    final baseEta = [12, 15, 22][_routeIndex];
    final eta = ((1 - progress) * baseEta).ceil();
    final stage = _completed
        ? MapTrackingStage.completed
        : eta <= 2
            ? MapTrackingStage.nearby
            : eta <= 10
                ? MapTrackingStage.approaching
                : MapTrackingStage.onRoute;
    return [
      MapTruckSnapshot(
        id: 'Truck 02',
        route: route,
        position: route.waypoints[_waypoint],
        updatedAt: DateTime.now(),
        heading: _waypoint == route.waypoints.length - 1
            ? mapBearing(
                route.waypoints[_waypoint - 1], route.waypoints[_waypoint])
            : mapBearing(
                route.waypoints[_waypoint], route.waypoints[_waypoint + 1]),
        etaMinutes: eta,
        distanceKm: [3.2, 4.1, 5.0][_routeIndex] * (1 - progress),
        nextStop: _completed
            ? 'Collection complete'
            : route.collectionPoints.first.name,
        currentArea: 'Sipalay Poblacion',
        progress: progress,
        stage: stage,
        active: !_completed,
        simulated: true,
      )
    ];
  }
}
