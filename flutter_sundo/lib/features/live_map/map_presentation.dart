import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../models/map_tracking.dart';

/// A decorative route-flow indicator. This position is never a truck GPS fix.
class RouteFlowPoint {
  final LatLng position;
  final double headingDegrees;

  const RouteFlowPoint(this.position, this.headingDegrees);
}

/// Turns a marker by the shortest arc, including crossings through north.
double interpolateMapHeading(double start, double end, double fraction) {
  final from = _normalizeHeading(start.isFinite ? start : end);
  final to = _normalizeHeading(end.isFinite ? end : start);
  final progress = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);
  final delta = ((to - from + 540) % 360) - 180;
  return _normalizeHeading(from + delta * progress);
}

/// Samples moving chevrons evenly along the supplied route's total distance.
///
/// [phase] advances one complete cycle from zero to one and wraps in either
/// direction. Only adjacent, valid source waypoints define route segments;
/// repeated points do not consume distance. Interpolation follows the shorter
/// great-circle arc, so longitude crossings do not travel around the globe.
List<RouteFlowPoint> movingRouteIndicators(
  List<LatLng> route,
  double phase, {
  int count = 6,
}) {
  if (count <= 0 || route.length < 2) return const [];

  final legs = <_RouteLeg>[];
  var totalAngle = 0.0;
  for (var index = 1; index < route.length; index++) {
    final start = route[index - 1];
    final end = route[index];
    if (!_validCoordinate(start) || !_validCoordinate(end)) continue;
    final angle = _centralAngle(start, end);
    if (angle <= 1e-12) continue;
    legs.add(_RouteLeg(start, end, totalAngle, angle));
    totalAngle += angle;
  }
  if (legs.isEmpty) return const [];

  final cycle = phase.isFinite ? phase % 1.0 : 0.0;
  final points = <RouteFlowPoint>[];
  for (var index = 0; index < count; index++) {
    final distance = ((cycle + index / count) % 1.0) * totalAngle;
    final leg = legs.firstWhere(
      (candidate) => distance < candidate.offset + candidate.angle,
      orElse: () => legs.last,
    );
    final progress = ((distance - leg.offset) / leg.angle).clamp(0.0, 1.0);
    final position = _alongLeg(leg, progress);
    // The bearing from an interpolated point to the leg's end is the local
    // tangent, which stays correct on routes near the poles or date line.
    final heading = mapBearing(position, leg.end);
    points.add(RouteFlowPoint(position, heading));
  }
  return points;
}

double _normalizeHeading(double value) => value.isFinite ? value % 360 : 0;

bool _validCoordinate(LatLng point) =>
    point.latitude.isFinite &&
    point.longitude.isFinite &&
    point.latitude.abs() <= 90 &&
    point.longitude.abs() <= 180;

double _centralAngle(LatLng start, LatLng end) {
  final latitude1 = _radians(start.latitude);
  final latitude2 = _radians(end.latitude);
  final deltaLatitude = latitude2 - latitude1;
  final deltaLongitude = _radians(end.longitude - start.longitude);
  final haversine = math.pow(math.sin(deltaLatitude / 2), 2) +
      math.cos(latitude1) *
          math.cos(latitude2) *
          math.pow(math.sin(deltaLongitude / 2), 2);
  return 2 * math.asin(math.sqrt(haversine.clamp(0.0, 1.0)));
}

LatLng _alongLeg(_RouteLeg leg, double progress) {
  if (progress <= 0) return leg.start;
  if (progress >= 1) return leg.end;
  final startLatitude = _radians(leg.start.latitude);
  final startLongitude = _radians(leg.start.longitude);
  final bearing = _radians(mapBearing(leg.start, leg.end));
  final angularDistance = leg.angle * progress;
  final latitude = math.asin(
      (math.sin(startLatitude) * math.cos(angularDistance) +
              math.cos(startLatitude) *
                  math.sin(angularDistance) *
                  math.cos(bearing))
          .clamp(-1.0, 1.0));
  final longitude = startLongitude +
      math.atan2(
        math.sin(bearing) * math.sin(angularDistance) * math.cos(startLatitude),
        math.cos(angularDistance) -
            math.sin(startLatitude) * math.sin(latitude),
      );
  return LatLng(
    latitude * 180 / math.pi,
    ((longitude * 180 / math.pi + 540) % 360) - 180,
  );
}

double _radians(double degrees) => degrees * math.pi / 180;

class _RouteLeg {
  final LatLng start;
  final LatLng end;
  final double offset;
  final double angle;

  const _RouteLeg(this.start, this.end, this.offset, this.angle);
}
