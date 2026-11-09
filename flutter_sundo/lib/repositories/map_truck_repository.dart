import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/storage/app_store.dart';
import '../core/utils/resident_area.dart';
import '../models/map_tracking.dart';
import 'schedule_repository.dart';

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
  static const waypointInterval = Duration(seconds: 6);
  static final shared = MockMapTruckRepository();
  late final StreamController<List<MapTruckSnapshot>> _updates =
      StreamController<List<MapTruckSnapshot>>.broadcast(
          onListen: _start, onCancel: _stop);
  Timer? _timer;
  List<MapTruckSnapshot>? _lastUpdate;
  var _routeIndex = 0;
  var _waypoint = 0;
  var _completed = false;
  // Road geometry © OpenStreetMap contributors (ODbL), Sipalay Poblacion.
  // Consecutive points are adjacent way nodes in the direction of travel.
  static const _routeStart =
      LatLng(9.751955, 122.403779); // OSM node 2824836369.

  // OSM ways: 80607428, 80558708, 80607419, 80558717.
  static const _base = <LatLng>[
    _routeStart,
    LatLng(9.7510442, 122.4037501),
    LatLng(9.7496379, 122.4036725),
    LatLng(9.7496473, 122.4029403),
    LatLng(9.7511405, 122.402985),
    LatLng(9.7510442, 122.4037501),
    _routeStart,
  ];

  static const routes = <MapOperatingRoute>[
    MapOperatingRoute(
      id: 'A',
      name: 'Route A · Recommended',
      waypoints: _base,
      collectionPoints: [
        MapCollectionPoint(1, 'Barangay 1 · sample stop', _routeStart),
        MapCollectionPoint(
            2, 'Barangay 2 · sample stop', LatLng(9.7496379, 122.4036725)),
        MapCollectionPoint(
            3, 'Barangay 3 · sample stop', LatLng(9.7511405, 122.402985)),
      ],
    ),
    MapOperatingRoute(
      id: 'B',
      name: 'Route B · Alternate',
      // OSM ways: 80607428, 80558717, 80558741, 80558708.
      waypoints: [
        _routeStart,
        LatLng(9.7510442, 122.4037501),
        LatLng(9.7508194, 122.4049138),
        LatLng(9.7495982, 122.4046708),
        LatLng(9.7496379, 122.4036725),
        LatLng(9.7510442, 122.4037501),
        _routeStart,
      ],
      collectionPoints: [
        MapCollectionPoint(
            1, 'Barangay 1 · sample stop', LatLng(9.7510442, 122.4037501)),
        MapCollectionPoint(
            2, 'Barangay 2 · sample stop', LatLng(9.7508194, 122.4049138)),
      ],
    ),
    MapOperatingRoute(
      id: 'C',
      name: 'Route C · Delayed',
      // OSM ways: 278054122, 278054210, 80558717, 80607428.
      waypoints: [
        _routeStart,
        LatLng(9.7519676, 122.4030254),
        LatLng(9.7519487, 122.4026848),
        LatLng(9.751955, 122.4023846),
        LatLng(9.7519424, 122.4019823),
        LatLng(9.751913, 122.4015395),
        LatLng(9.7512629, 122.4015455),
        LatLng(9.7512286, 122.4022388),
        LatLng(9.7511405, 122.402985),
        LatLng(9.7510442, 122.4037501),
        _routeStart,
      ],
      collectionPoints: [
        MapCollectionPoint(
            1, 'Barangay 3 · sample stop', LatLng(9.751913, 122.4015395)),
        MapCollectionPoint(
            2, 'Barangay 1 · sample stop', LatLng(9.7511405, 122.402985)),
      ],
    ),
  ];

  @override
  Stream<List<MapTruckSnapshot>> watchTrucks() => Stream.multi((listener) {
        final subscription = _updates.stream.listen(listener.add,
            onError: listener.addError, onDone: listener.close);
        final lastUpdate = _lastUpdate;
        if (lastUpdate != null) listener.add(lastUpdate);
        listener.onCancel = subscription.cancel;
      });

  void _start() {
    final timer = Timer.periodic(
        waypointInterval, (timer) => _update(timer, advance: true));
    _timer = timer;
    unawaited(_update(timer, advance: false));
  }

  Future<void> _update(Timer timer, {required bool advance}) async {
    var area = '';
    try {
      area = await AppStore.getBarangay();
    } catch (_) {
      // Stay parked when the collection area cannot be read.
    }
    if (!timer.isActive) return;

    final now = DateTime.now();
    final today = now.toUtc().add(const Duration(hours: 8));
    final scheduled = MockScheduleRepository.shared.items.any((entry) =>
        entry.isOn(today) &&
        serviceAreaMatchesResident(entry.barangay, area) &&
        !const ['completed', 'cancelled', 'canceled']
            .contains(entry.explicitStatus?.trim().toLowerCase()));
    if (scheduled && advance) {
      if (_completed) {
        _routeIndex = (_routeIndex + 1) % routes.length;
        _waypoint = 0;
        _completed = false;
      } else {
        _waypoint++;
        _completed = _waypoint == routes[_routeIndex].waypoints.length - 1;
      }
    }
    final update = _snapshot(now, scheduled: scheduled);
    _lastUpdate = update;
    _updates.add(update);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _lastUpdate = null;
  }

  List<MapTruckSnapshot> _snapshot(DateTime now, {required bool scheduled}) {
    final route = routes[_routeIndex];
    final progress = _waypoint / (route.waypoints.length - 1);
    final baseEta = [12, 15, 22][_routeIndex];
    final eta = ((1 - progress) * baseEta).ceil();
    final stage = !scheduled
        ? MapTrackingStage.notStarted
        : _completed
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
        updatedAt: now,
        heading: _waypoint == route.waypoints.length - 1
            ? mapBearing(
                route.waypoints[_waypoint - 1], route.waypoints[_waypoint])
            : mapBearing(
                route.waypoints[_waypoint], route.waypoints[_waypoint + 1]),
        etaMinutes: scheduled ? eta : null,
        distanceKm:
            scheduled ? [3.2, 4.1, 5.0][_routeIndex] * (1 - progress) : null,
        nextStop: !scheduled
            ? 'No collection scheduled for your area today'
            : _completed
                ? 'Collection complete'
                : route.collectionPoints.first.name,
        currentArea: 'Sipalay Poblacion',
        progress: scheduled ? progress : 0,
        stage: stage,
        active: scheduled && !_completed,
        simulated: true,
      )
    ];
  }
}
