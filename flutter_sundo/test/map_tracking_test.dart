import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sundo_sipalay/models/map_tracking.dart';
import 'package:sundo_sipalay/repositories/map_truck_repository.dart';

void main() {
  test('unpublished truck position and arrival remain unknown', () {
    final truck =
        MapTruckSnapshot.fromSupabase({'id': 'Truck 02', 'active': true});
    expect(truck.position, isNull);
    expect(truck.etaMinutes, isNull);
    expect(truck.distanceKm, isNull);
    expect(truck.route.waypoints, isEmpty);
    expect(truck.simulated, isFalse);
    expect(truck.freshAt(DateTime.now()), isFalse);
  });

  test('invalid coordinates are never used as real truck locations', () {
    expect(mapCoordinate(null, 122.4), isNull);
    expect(mapCoordinate(91, 122.4), isNull);
    expect(mapCoordinate(9.75, double.infinity), isNull);
    expect(mapCoordinate(9.75, 122.4), const LatLng(9.75, 122.4));
  });

  test('city route update preserves published ETA, stops and progress', () {
    final now = DateTime(2026, 10, 4, 18);
    final truck = MapTruckSnapshot.fromSupabase({
      'id': 'Truck 02',
      'latitude': 9.75,
      'longitude': 122.4,
      'active': true,
      'updated_at': now.toIso8601String(),
      'eta_minutes': 15,
      'status': 'Approaching',
      'progress': .5,
      'active_route': {
        'id': 'B',
        'name': 'Route B',
        'waypoints': [
          [9.75, 122.4],
          [9.751, 122.401]
        ],
        'collection_points': [
          {
            'number': 1,
            'name': 'Area stop',
            'latitude': 9.751,
            'longitude': 122.401
          }
        ],
      },
    });
    expect(truck.route.id, 'B');
    expect(truck.route.collectionPoints.single.number, 1);
    expect(truck.etaMinutes, 15);
    expect(truck.progress, .5);
    expect(truck.stage, MapTrackingStage.approaching);
    expect(truck.freshAt(now), isTrue);
    expect(truck.freshAt(now.add(const Duration(minutes: 3))), isFalse);
  });

  test('animation reaches the source fix without overshooting', () {
    const start = LatLng(9.75, 122.4), end = LatLng(9.76, 122.41);
    expect(interpolateMapPosition(start, end, -1), start);
    expect(interpolateMapPosition(start, end, 1.4), end);
    final middle = interpolateMapPosition(start, end, .5);
    expect(middle.latitude, closeTo(9.755, .00001));
    expect(middle.longitude, closeTo(122.405, .00001));
    expect(
        mapBearing(const LatLng(0, 0), const LatLng(1, 0)), closeTo(0, .001));
    expect(
        mapBearing(const LatLng(0, 0), const LatLng(0, 1)), closeTo(90, .001));
  });

  testWidgets('shared simulation replays state and stops after last listener',
      (tester) async {
    final repository = MockMapTruckRepository();
    final first = <MapTruckSnapshot>[];
    final second = <MapTruckSnapshot>[];
    final firstSubscription =
        repository.watchTrucks().listen((value) => first.add(value.single));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    final secondSubscription =
        repository.watchTrucks().listen((value) => second.add(value.single));
    await tester.pump();
    expect(first.last.position, second.last.position);
    expect(first.last.updatedAt, second.last.updatedAt);
    expect(first.last.simulated, isTrue);
    unawaited(firstSubscription.cancel());
    unawaited(secondSubscription.cancel());
    await tester.pump();
    final count = second.length;
    await tester.pump(const Duration(seconds: 30));
    expect(second.length, count);
  });

  test('simulated route changes share a contact point and never jump', () {
    const routes = MockMapTruckRepository.routes;
    for (var i = 0; i < routes.length; i++) {
      expect(routes[i].waypoints.last,
          routes[(i + 1) % routes.length].waypoints.first);
    }
  });
}
