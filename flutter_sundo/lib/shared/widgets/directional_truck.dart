import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Nominal GPS headings and the illustrated front bearings measured during
/// artwork review. Calibration accounts for isometric projection: a world yaw
/// in generated artwork is not necessarily its front vector on a flat screen.
const truckDirectionFiles = [
  0,
  23,
  45,
  68,
  90,
  113,
  135,
  158,
  180,
  203,
  225,
  248,
  270,
  293,
  315,
  338
];
const truckIllustratedBearings = [
  359.01,
  62.76,
  69.19,
  65.67,
  95.09,
  123.85,
  123.00,
  128.50,
  179.49,
  235.33,
  237.42,
  248.02,
  269.60,
  293.37,
  296.60,
  299.42
];

// Centers of the alpha silhouettes in the original 1254px source canvases.
// Offset compensation keeps the GPS anchor stable without altering artwork.
const truckArtworkCenters = [
  Offset(627, 609),
  Offset(634, 638),
  Offset(638.5, 637),
  Offset(641.5, 653),
  Offset(630.5, 652.5),
  Offset(618.5, 636),
  Offset(629, 636.5),
  Offset(622.5, 629),
  Offset(626.5, 614),
  Offset(647.5, 632),
  Offset(637, 634),
  Offset(647, 653.5),
  Offset(645, 689.5),
  Offset(638.5, 649.5),
  Offset(643.5, 624),
  Offset(647.5, 638.5),
];

double truckScreenHeading(double heading, double mapRotation) =>
    ((heading.isFinite ? heading : 180) +
        (mapRotation.isFinite ? mapRotation : 0)) %
    360;

int truckDirectionIndex(double heading) =>
    (((heading.isFinite ? heading : 180) % 360) / 22.5).round() % 16;

String truckDirectionAsset(int index) =>
    'assets/images/truck_directions/truck_${truckDirectionFiles[index].toString().padLeft(3, '0')}.png';

double truckDirectionCorrection(double heading, int index) =>
    ((heading - truckIllustratedBearings[index] + 180) % 360 - 180) *
    math.pi /
    180;

/// Angle-specific artwork; position and heading interpolation belong to the
/// fleet controller. No GPS updates or independent motion are manufactured.
class SundoDirectionalTruck extends StatefulWidget {
  const SundoDirectionalTruck(
      {super.key,
      this.headingDegrees,
      this.mapRotationDegrees = 0,
      this.animate = true});
  final double? headingDegrees;
  final double mapRotationDegrees;
  final bool animate;

  @override
  State<SundoDirectionalTruck> createState() => _SundoDirectionalTruckState();
}

class _SundoDirectionalTruckState extends State<SundoDirectionalTruck> {
  bool _preloaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preloaded) return;
    _preloaded = true;
    // Decode at marker resolution: roughly 4MB for the complete set, rather
    // than retaining sixteen full-resolution source bitmaps on a phone.
    for (var index = 0; index < 16; index++) {
      unawaited(precacheImage(
          ResizeImage(AssetImage(truckDirectionAsset(index)), width: 256),
          context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final known = widget.headingDegrees?.isFinite == true;
    final heading = known
        ? truckScreenHeading(widget.headingDegrees!, widget.mapRotationDegrees)
        : 180.0;
    final index = truckDirectionIndex(heading);
    final image = Transform.rotate(
      key: ValueKey(index),
      angle: truckDirectionCorrection(heading, index),
      child: FractionalTranslation(
        translation: Offset((627 - truckArtworkCenters[index].dx) / 1254,
            (627 - truckArtworkCenters[index].dy) / 1254),
        child: Image.asset(truckDirectionAsset(index),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            cacheWidth: 256,
            excludeFromSemantics: true),
      ),
    );
    return AnimatedSwitcher(
      duration: !widget.animate || MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: image,
    );
  }
}
