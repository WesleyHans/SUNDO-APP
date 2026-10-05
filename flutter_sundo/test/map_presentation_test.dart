import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sundo_sipalay/features/live_map/map_presentation.dart';

void main() {
  group('Marker heading interpolation', () {
    test('crosses north by the shortest arc in either direction', () {
      expect(interpolateMapHeading(359, 1, 0.5), closeTo(0, 1e-9));
      expect(interpolateMapHeading(1, 359, 0.5), closeTo(0, 1e-9));
      expect(interpolateMapHeading(350, 10, 0.25), closeTo(355, 1e-9));
      expect(interpolateMapHeading(10, 350, 0.25), closeTo(5, 1e-9));
    });

    test('normalizes and clamps incoming presentation values', () {
      expect(interpolateMapHeading(-10, 370, -1), 350);
      expect(interpolateMapHeading(-10, 370, 2), 10);
      expect(interpolateMapHeading(double.nan, 90, 0.5), 90);
      expect(interpolateMapHeading(45, double.nan, 0.5), 45);
      expect(interpolateMapHeading(45, 90, double.nan), 45);
    });
  });

  group('Route flow', () {
    test('distributes indicators by distance, not waypoint count', () {
      final points = movingRouteIndicators(
        [const LatLng(0, 0), const LatLng(0, 1), const LatLng(0, 4)],
        0,
        count: 4,
      );
      expect(points.length, 4);
      for (var index = 0; index < points.length; index++) {
        expect(points[index].position.longitude, closeTo(index, 1e-7));
        expect(points[index].position.latitude, closeTo(0, 1e-7));
        expect(points[index].headingDegrees, closeTo(90, 1e-7));
      }
    });

    test('advances and wraps flow without changing the route', () {
      final route = [const LatLng(0, 0), const LatLng(0, 4)];
      final advanced = movingRouteIndicators(route, 0.125, count: 4);
      final wrapped = movingRouteIndicators(route, 1.125, count: 4);
      final reverse = movingRouteIndicators(route, -0.125, count: 4);
      for (var index = 0; index < advanced.length; index++) {
        expect(advanced[index].position.longitude, closeTo(index + 0.5, 1e-7));
        expect(wrapped[index].position, advanced[index].position);
      }
      expect(reverse.first.position.longitude, closeTo(3.5, 1e-7));
      expect(route, [const LatLng(0, 0), const LatLng(0, 4)]);
    });

    test('crosses the date line along the short arc', () {
      final points = movingRouteIndicators(
        [const LatLng(0, 179), const LatLng(0, -179)],
        0,
        count: 4,
      );
      expect(points.map((point) => point.position.longitude).toList(),
          orderedEquals([179.0, 179.5, -180.0, -179.5]));
      for (final point in points) {
        expect(point.headingDegrees, closeTo(90, 1e-7));
      }
    });

    test('keeps spacing geographical at high latitude', () {
      final points = movingRouteIndicators(
        [const LatLng(80, -20), const LatLng(80, 20)],
        0,
        count: 4,
      );
      const distance = DistanceHaversine(roundResult: false);
      final total = distance.as(
          LengthUnit.Meter, const LatLng(80, -20), const LatLng(80, 20));
      for (var index = 1; index < points.length; index++) {
        final gap = distance.as(LengthUnit.Meter, points[index - 1].position,
            points[index].position);
        expect(gap / total, closeTo(0.25, 1e-6));
      }
      expect(points[2].position.latitude, greaterThan(80));
    });

    test('skips duplicates and handles absent or degenerate routes', () {
      const point = LatLng(9.75, 122.4);
      expect(movingRouteIndicators([], 0), isEmpty);
      expect(movingRouteIndicators([point], 0), isEmpty);
      expect(movingRouteIndicators([point, point], 0), isEmpty);
      expect(
          movingRouteIndicators([point, const LatLng(9.76, 122.4)], 0,
              count: 0),
          isEmpty);
      final points =
          movingRouteIndicators([point, point, const LatLng(9.76, 122.4)], 0);
      expect(points.length, 6);
      expect(points.first.position, point);
      expect(points.every((point) => point.headingDegrees.isFinite), isTrue);
    });
  });
}
