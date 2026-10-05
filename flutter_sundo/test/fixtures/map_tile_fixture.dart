import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A canvas fixture for layout QA. Its roads/parks are synthetic, not OSM data.
/// Geographic points use the same Web Mercator tile grid as the real map.
class SipalayMapFixtureTileProvider extends TileProvider {
  SipalayMapFixtureTileProvider._(this._tiles, this._fallback);

  final Map<String, Uint8List> _tiles;
  final Uint8List _fallback;
  final requestedImages = <MemoryImage>[];
  int disposeCalls = 0;

  static Future<SipalayMapFixtureTileProvider> create() async {
    const center = LatLng(9.7525, 122.4038);
    final tiles = <String, Uint8List>{};
    const zoom = 16;
    final pixel = _worldPixel(center, zoom);
    final centerX = (pixel.dx / 256).floor();
    final centerY = (pixel.dy / 256).floor();
    for (var y = centerY - 4; y <= centerY + 4; y++) {
      for (var x = centerX - 4; x <= centerX + 4; x++) {
        tiles['$zoom/$x/$y'] = await _paintTile(x, y, zoom);
      }
    }
    return SipalayMapFixtureTileProvider._(
        tiles, tiles['$zoom/$centerX/$centerY']!);
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final bytes =
        _tiles['${coordinates.z}/${coordinates.x}/${coordinates.y}'] ??
            _fallback;
    final image = MemoryImage(bytes);
    requestedImages.add(image);
    return image;
  }

  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}

Offset _worldPixel(LatLng point, int zoom) {
  final worldSize = 256.0 * math.pow(2, zoom);
  final latitude = point.latitude * math.pi / 180;
  return Offset(
    (point.longitude + 180) / 360 * worldSize,
    (1 - math.log(math.tan(latitude) + 1 / math.cos(latitude)) / math.pi) /
        2 *
        worldSize,
  );
}

Future<Uint8List> _paintTile(int x, int y, int zoom) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.clipRect(const Rect.fromLTWH(0, 0, 256, 256));
  canvas.drawColor(const Color(0xFFF1EFE7), BlendMode.src);
  Offset project(LatLng point) =>
      _worldPixel(point, zoom) - Offset(x * 256.0, y * 256.0);
  ui.Path pathOf(List<LatLng> points, {bool close = false}) {
    final path = ui.Path();
    for (var index = 0; index < points.length; index++) {
      final point = project(points[index]);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    if (close) path.close();
    return path;
  }

  const coast = [
    LatLng(9.770, 122.3980),
    LatLng(9.760, 122.4000),
    LatLng(9.7545, 122.4011),
    LatLng(9.7505, 122.4019),
    LatLng(9.745, 122.4044),
    LatLng(9.735, 122.4055),
  ];
  canvas.drawPath(
      pathOf([
        const LatLng(9.780, 122.380),
        ...coast,
        const LatLng(9.730, 122.380),
      ], close: true),
      Paint()..color = const Color(0xFFADD3DB));
  canvas.drawPath(
      pathOf(coast),
      Paint()
        ..color = const Color(0xFFF8E8AF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10);

  // Small cadastral blocks and parks exercise visible marker contrast.
  for (var row = 0; row < 27; row++) {
    final latitude = 9.742 + row * .0007;
    for (var column = 0; column < 17; column++) {
      final longitude = 122.4018 + column * .0007;
      if (longitude < 122.402 - (latitude - 9.751) * .25) continue;
      final color = (row + column * 2) % 7 == 0
          ? const Color(0xFFC9DFBB)
          : (row + column) % 9 == 0
              ? const Color(0xFFDED2CB)
              : const Color(0xFFE5E2D8);
      final rectangle = Rect.fromPoints(
        project(LatLng(latitude + .00010, longitude + .00010)),
        project(LatLng(latitude + .00059, longitude + .00059)),
      );
      canvas.drawRRect(
          RRect.fromRectAndRadius(rectangle, const Radius.circular(2)),
          Paint()..color = color);
    }
  }
  final roads = <List<LatLng>>[
    for (var index = 0; index <= 28; index++)
      [
        LatLng(9.742 + index * .0007, 122.4013),
        LatLng(9.742 + index * .0007, 122.414),
      ],
    for (var index = 0; index <= 18; index++)
      [
        LatLng(9.742, 122.4018 + index * .0007),
        LatLng(9.762, 122.4018 + index * .0007),
      ],
    const [
      LatLng(9.757, 122.4009),
      LatLng(9.7540, 122.4026),
      LatLng(9.7520, 122.4038),
      LatLng(9.7503, 122.4050),
      LatLng(9.7470, 122.4072),
    ],
  ];
  for (final road in roads) {
    final path = pathOf(road);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFD4D7D0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFFEFA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(256, 256);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = png!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}
