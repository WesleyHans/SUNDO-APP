import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

enum MapTrackingStage { notStarted, onRoute, approaching, nearby, completed }

class MapCollectionPoint {
  final int number;
  final String name;
  final LatLng position;
  const MapCollectionPoint(this.number, this.name, this.position);
}

class MapOperatingRoute {
  final String id;
  final String name;
  final List<LatLng> waypoints;
  final List<MapCollectionPoint> collectionPoints;
  const MapOperatingRoute({
    required this.id,
    required this.name,
    this.waypoints = const [],
    this.collectionPoints = const [],
  });
}

/// An operational update from a truck source. Unknown values remain unknown.
class MapTruckSnapshot {
  final String id;
  final LatLng? position;
  final MapOperatingRoute route;
  final DateTime? updatedAt;
  final double? heading;
  final int? etaMinutes;
  final double? distanceKm;
  final String? nextStop;
  final String? currentArea;
  final double? progress;
  final MapTrackingStage stage;
  final bool active;
  final bool simulated;

  const MapTruckSnapshot({
    required this.id,
    required this.route,
    this.position,
    this.updatedAt,
    this.heading,
    this.etaMinutes,
    this.distanceKm,
    this.nextStop,
    this.currentArea,
    this.progress,
    this.stage = MapTrackingStage.notStarted,
    this.active = false,
    this.simulated = false,
  });

  bool freshAt(DateTime now) =>
      position != null &&
      updatedAt != null &&
      now.difference(updatedAt!).abs() <= const Duration(minutes: 2);

  factory MapTruckSnapshot.fromSupabase(Map<String, dynamic> row) {
    final routeData = row['active_route'];
    final routeMap = routeData is Map ? routeData : const {};
    final points = <LatLng>[];
    final waypoints = routeMap['waypoints'];
    for (final point in waypoints is List ? waypoints : const []) {
      if (point is List && point.length >= 2) {
        final position = mapCoordinate(point[0], point[1]);
        if (position != null) points.add(position);
      }
    }
    final stops = <MapCollectionPoint>[];
    final collectionPoints = routeMap['collection_points'];
    for (final point
        in collectionPoints is List ? collectionPoints : const []) {
      if (point is Map) {
        final position = mapCoordinate(point['latitude'], point['longitude']);
        if (position != null) {
          stops.add(MapCollectionPoint(
            (point['number'] as num?)?.toInt() ?? stops.length + 1,
            point['name'] as String? ?? 'Collection point',
            position,
          ));
        }
      }
    }
    final eta = (row['eta_minutes'] as num?)?.toInt();
    final stage = switch (row['status']) {
      'Not Started' => MapTrackingStage.notStarted,
      'On Route' => MapTrackingStage.onRoute,
      'Approaching' => MapTrackingStage.approaching,
      'Nearby' => MapTrackingStage.nearby,
      'Completed' => MapTrackingStage.completed,
      _ => row['active'] == true
          ? MapTrackingStage.onRoute
          : MapTrackingStage.notStarted,
    };
    return MapTruckSnapshot(
      id: row['id'] as String,
      position: mapCoordinate(row['latitude'], row['longitude']),
      route: MapOperatingRoute(
        id: routeMap['id'] as String? ?? row['route_name'] as String? ?? '',
        name: routeMap['name'] as String? ?? row['route_name'] as String? ?? '',
        waypoints: points,
        collectionPoints: stops,
      ),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
      heading: (row['heading'] as num?)?.toDouble(),
      etaMinutes: eta != null && eta >= 0 ? eta : null,
      distanceKm: (row['distance_km'] as num?)?.toDouble(),
      nextStop: row['next_stop'] as String?,
      currentArea: row['current_area'] as String?,
      progress: (row['progress'] as num?)?.toDouble().clamp(0, 1),
      stage: stage,
      active: row['active'] == true,
    );
  }
}

LatLng? mapCoordinate(dynamic latitude, dynamic longitude) {
  if (latitude is! num || longitude is! num) return null;
  final lat = latitude.toDouble();
  final lng = longitude.toDouble();
  if (!lat.isFinite || !lng.isFinite || lat.abs() > 90 || lng.abs() > 180) {
    return null;
  }
  return LatLng(lat, lng);
}

/// Linear interpolation for short GPS segments; it never alters a source fix.
LatLng interpolateMapPosition(LatLng start, LatLng end, double fraction) {
  final t = fraction.clamp(0.0, 1.0);
  return LatLng(
    start.latitude + (end.latitude - start.latitude) * t,
    start.longitude + (end.longitude - start.longitude) * t,
  );
}

double mapBearing(LatLng start, LatLng end) {
  final lat1 = start.latitude * math.pi / 180;
  final lat2 = end.latitude * math.pi / 180;
  final delta = (end.longitude - start.longitude) * math.pi / 180;
  final y = math.sin(delta) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(delta);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}
