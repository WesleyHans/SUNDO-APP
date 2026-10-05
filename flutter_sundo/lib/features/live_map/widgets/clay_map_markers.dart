import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/widgets/sundo_graphics.dart';

/// The supplied truck artwork faces southeast in its unrotated image.
/// Actual telemetry headings are clockwise from north; account for the asset's
/// intrinsic bearing before applying the map canvas rotation.
const sundoMapTruckIntrinsicHeading = 136.0;

/// A missing heading leaves the illustration upright, rather than inventing a
/// north-facing fix. The marker's semantics explicitly mark that heading unknown.
double sundoMapTruckRotationRadians(double? headingDegrees,
    {double mapRotationDegrees = 0}) {
  if (headingDegrees == null || !headingDegrees.isFinite) return 0;
  return (_finiteAngle(headingDegrees) +
          _finiteAngle(mapRotationDegrees) -
          sundoMapTruckIntrinsicHeading) *
      math.pi /
      180;
}

/// The resident's supplied isometric truck, anchored at the same GPS point and
/// controlled by the existing map animation phase. No autonomous timers or
/// position changes are introduced by this graphic.
class SundoMapTruckMarker extends StatelessWidget {
  const SundoMapTruckMarker({
    super.key,
    this.headingDegrees,
    this.mapRotationDegrees = 0,
    this.fresh = true,
    this.moving = false,
    this.pulse = 0,
  });

  final double? headingDegrees;
  final double mapRotationDegrees;
  final bool fresh;
  final bool moving;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final headingKnown = headingDegrees?.isFinite == true;
    final rolling = fresh && moving && !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      image: true,
      label: (fresh
              ? 'Collection truck, ${rolling ? 'moving' : 'stopped'}'
              : 'Collection truck, last known position') +
          (headingKnown ? '' : ', heading unavailable'),
      child: RepaintBoundary(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(fit: StackFit.expand, children: [
            CustomPaint(
              painter: _TruckGroundPainter(
                  fresh: fresh, phase: fresh ? _phase(pulse) : 0),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Transform.rotate(
                key: const ValueKey('supplied-truck-bearing'),
                angle: sundoMapTruckRotationRadians(headingDegrees,
                    mapRotationDegrees: mapRotationDegrees),
                child: Opacity(
                  opacity: fresh ? 1 : .58,
                  child: SundoVehicleGraphic(
                    mapView: true,
                    width: 100,
                    height: 100,
                    moving: rolling,
                    wheelPhase: rolling ? _phase(pulse) : 0,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// An elevated collection pavilion. Its ground contact is at (36, 80) in a
/// 72×90 footprint; the numeric badge stays clearly visible above the roof.
class SundoClayCollectionMarker extends StatelessWidget {
  const SundoClayCollectionMarker({
    super.key,
    required this.number,
    this.name,
    this.selected = false,
    this.pulse = 0,
  });

  final int number;
  final String? name;
  final bool selected;
  final double pulse;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        selected: selected,
        label: 'Collection point $number${name == null ? '' : ', $name'}',
        child: RepaintBoundary(
          child: SizedBox(
            width: 72,
            height: 90,
            child: CustomPaint(
              painter: _CollectionPavilionPainter(
                number: number,
                selected: selected,
                phase: _phase(pulse),
                textDirection: Directionality.of(context),
                textStyle:
                    Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
              ),
            ),
          ),
        ),
      );
}

/// The private GPS marker. Its animation does not imply an accuracy reading;
/// the map's separately measured accuracy circle remains the source of that.
class SundoResidentBeacon extends StatelessWidget {
  const SundoResidentBeacon({super.key, this.pulse = 0});

  final double pulse;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: 'Your private GPS location',
        child: RepaintBoundary(
          child: SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(painter: _ResidentBeaconPainter(_phase(pulse))),
          ),
        ),
      );
}

double _finiteAngle(double value) => value.isFinite ? value % 360 : 0;
double _phase(double value) => value.isFinite ? value.clamp(0, 1) : 0;

class _TruckGroundPainter extends CustomPainter {
  const _TruckGroundPainter({required this.fresh, required this.phase});

  final bool fresh;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final status = fresh ? const Color(0xFF119447) : const Color(0xFF708678);
    final wave = math.sin(phase * math.pi);
    final ground = Rect.fromCenter(
        center: const Offset(50, 61), width: 70 + wave * 5, height: 48);
    canvas.drawOval(
        ground.inflate(5 + phase * 8),
        Paint()
          ..color = status.withValues(alpha: fresh ? .09 * (1 - phase) : .04));
    canvas.drawOval(
        ground,
        Paint()
          ..color = status.withValues(alpha: .12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(53, 65), width: 51, height: 38),
        Paint()
          ..color = const Color(0xFF183A24).withValues(alpha: .25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TruckGroundPainter oldDelegate) =>
      fresh != oldDelegate.fresh || phase != oldDelegate.phase;
}

class _CollectionPavilionPainter extends CustomPainter {
  const _CollectionPavilionPainter({
    required this.number,
    required this.selected,
    required this.phase,
    required this.textDirection,
    required this.textStyle,
  });

  final int number;
  final bool selected;
  final double phase;
  final TextDirection textDirection;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 72, size.height / 90);
    if (selected) {
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(36, 77),
              width: 54 + 10 * phase,
              height: 23 + 4 * phase),
          Paint()
            ..color =
                const Color(0xFFF9BC42).withValues(alpha: .18 * (1 - phase)));
      canvas.drawOval(
          const Rect.fromLTWH(10, 67, 53, 22),
          Paint()
            ..color = const Color(0xFFE4AA2F).withValues(alpha: .7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
    canvas.drawOval(
        const Rect.fromLTWH(13, 66, 49, 17),
        Paint()
          ..color = const Color(0xFF163B29).withValues(alpha: .24)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    _facet(
        canvas,
        const [Offset(13, 61), Offset(40, 51), Offset(63, 63), Offset(36, 74)],
        const [Color(0xFFEBD7A1), Color(0xFFBAA36D)]);
    _facet(
        canvas,
        const [Offset(13, 61), Offset(36, 72), Offset(36, 78), Offset(13, 68)],
        const [Color(0xFFD6C38B), Color(0xFFBCA36A)]);
    _facet(
        canvas,
        const [Offset(36, 72), Offset(63, 63), Offset(63, 68), Offset(36, 78)],
        const [Color(0xFFAF945F), Color(0xFF8D794F)]);

    // Warm walls contrast with the green raised roof, as in the supplied map.
    _facet(
        canvas,
        const [Offset(16, 33), Offset(37, 42), Offset(37, 66), Offset(16, 57)],
        const [Color(0xFFFFF6D6), Color(0xFFEAD7A2)]);
    _facet(
        canvas,
        const [Offset(37, 42), Offset(59, 33), Offset(59, 57), Offset(37, 66)],
        const [Color(0xFFD8E2BC), Color(0xFFADC490)]);

    _facet(
        canvas,
        const [Offset(22, 39), Offset(32, 43), Offset(32, 55), Offset(22, 51)],
        const [Color(0xFF318A70), Color(0xFF174E40)]);
    _facet(
        canvas,
        const [Offset(24, 41), Offset(29, 43), Offset(29, 50), Offset(24, 48)],
        const [Color(0xFFABDBCF), Color(0xFF77BAA9)]);
    _facet(
        canvas,
        const [Offset(42, 43), Offset(53, 39), Offset(53, 56), Offset(42, 60)],
        const [Color(0xFF176D46), Color(0xFF0A5035)]);
    _line(canvas, const Offset(44, 45), const Offset(50, 43),
        const Color(0xFF82CD9B), 1.5);
    canvas.drawCircle(
        const Offset(50, 50), 1, Paint()..color = const Color(0xFFFFDB78));

    _facet(
        canvas,
        const [Offset(10, 28), Offset(38, 17), Offset(64, 28), Offset(36, 41)],
        const [Color(0xFF39BD84), Color(0xFF088458), Color(0xFF086444)]);
    _facet(
        canvas,
        const [Offset(10, 28), Offset(36, 39), Offset(36, 45), Offset(10, 34)],
        const [Color(0xFF0A8151), Color(0xFF075135)]);
    _facet(
        canvas,
        const [Offset(36, 39), Offset(64, 28), Offset(64, 34), Offset(36, 45)],
        const [Color(0xFF0C6E49), Color(0xFF034A33)]);
    _line(canvas, const Offset(13, 28), const Offset(38, 19),
        const Color(0xFF9BE8BE), 1.6);
    _facet(
        canvas,
        const [Offset(24, 26), Offset(38, 21), Offset(49, 26), Offset(35, 32)],
        const [Color(0xFF76DBB1), Color(0xFF25A775)]);

    // A short flagpole and clearly numbered badge remain above the roofline.
    _line(canvas, const Offset(48, 24), const Offset(48, 9),
        const Color(0xFFC9AC66), 2.6);
    _facet(
        canvas,
        const [Offset(48, 10), Offset(42, 10), Offset(42, 17), Offset(48, 16)],
        const [Color(0xFFFFDD64), Color(0xFFEDB82F)]);
    canvas.drawCircle(
        const Offset(56, 13),
        13,
        Paint()
          ..color = const Color(0xFF163B29).withValues(alpha: .20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(
        const Offset(55, 11), 12.3, Paint()..color = Colors.white);
    canvas.drawCircle(
        const Offset(55, 11),
        10.3,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: selected
                      ? [const Color(0xFFFFDA72), const Color(0xFFEBA725)]
                      : [const Color(0xFF15976A), const Color(0xFF08603E)])
              .createShader(const Rect.fromLTWH(44, 0, 22, 22)));
    final text = TextPainter(
      text: TextSpan(
          text: '$number',
          style: textStyle.copyWith(
              fontSize: number.abs() > 99
                  ? 9
                  : number.abs() > 9
                      ? 11
                      : 13,
              height: 1,
              fontWeight: FontWeight.w800,
              color: selected ? const Color(0xFF453611) : Colors.white)),
      textDirection: textDirection,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 19);
    text.paint(canvas, Offset(55 - text.width / 2, 11 - text.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CollectionPavilionPainter oldDelegate) =>
      number != oldDelegate.number ||
      selected != oldDelegate.selected ||
      phase != oldDelegate.phase ||
      textDirection != oldDelegate.textDirection ||
      textStyle != oldDelegate.textStyle;
}

class _ResidentBeaconPainter extends CustomPainter {
  const _ResidentBeaconPainter(this.phase);
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    const center = Offset(32, 32);
    const blue = Color(0xFF1D92F3);
    canvas.drawCircle(
        center,
        17 + phase * 12,
        Paint()
          ..color = blue.withValues(alpha: .15 * (1 - phase))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(center, 20, Paint()..color = blue.withValues(alpha: .10));
    canvas.drawOval(
        const Rect.fromLTWH(17, 33, 30, 15),
        Paint()
          ..color = const Color(0xFF14598F).withValues(alpha: .25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(center, 13.5, Paint()..color = Colors.white);
    canvas.drawCircle(
        center,
        10.6,
        Paint()
          ..shader = const RadialGradient(
                  center: Alignment(-.4, -.55),
                  colors: [Color(0xFF8AE5FF), blue, Color(0xFF1460C6)])
              .createShader(const Rect.fromLTWH(21, 21, 22, 22)));
    canvas.drawOval(const Rect.fromLTWH(26, 24, 8, 4),
        Paint()..color = Colors.white.withValues(alpha: .72));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ResidentBeaconPainter oldDelegate) =>
      phase != oldDelegate.phase;
}

void _facet(Canvas canvas, List<Offset> vertices, List<Color> colors) {
  final path = Path()..addPolygon(vertices, true);
  canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors)
            .createShader(path.getBounds()));
}

void _line(Canvas canvas, Offset from, Offset to, Color color, double width) =>
    canvas.drawLine(
        from,
        to,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round);
