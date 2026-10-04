import 'package:flutter/material.dart';
import '../../core/theme/time_theme.dart';
import './time_based_background.dart';

const clayHeroAsset = 'assets/images/clay-city-hero.png';

class ScenicBackdrop extends StatelessWidget {
  final Widget child;
  const ScenicBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: mood.isNight
            ? const [Color(0xFF11231C), Color(0xFF10201B), Color(0xFF193C2C)]
            : const [Color(0xFFF8FCF9), Color(0xFFF9FCF8), Color(0xFFEAF8EE)],
      )),
      child: Stack(fit: StackFit.expand, children: [
        const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220,
            child: SundoTimeBasedBackground()),
        const Positioned(right: -22, top: -10, child: LeafSprig(size: 110)),
        const Positioned(
            left: -35, bottom: 25, child: LeafSprig(size: 95, flipped: true)),
        child,
      ]),
    );
  }
}

class LeafSprig extends StatelessWidget {
  final double size;
  final bool flipped;
  const LeafSprig({super.key, this.size = 100, this.flipped = false});
  @override
  Widget build(BuildContext context) => IgnorePointer(
          child: Transform.flip(
        flipX: flipped,
        child: CustomPaint(size: Size(size, size), painter: _LeafPainter()),
      ));
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    canvas.drawPath(
        Path()
          ..moveTo(98, 1)
          ..quadraticBezierTo(58, 45, 44, 95),
        Paint()
          ..color = const Color(0xFF4B8E34)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(94 - i * 15.0, i * 26.0);
      final leaf = Path()
        ..moveTo(0, 0)
        ..cubicTo(-42, -6, -49, 21, -47, 37)
        ..cubicTo(-22, 37, -2, 21, 0, 0)
        ..close();
      canvas.drawShadow(leaf, const Color(0xFF53782F), 3, false);
      canvas.drawPath(
          leaf,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFB3DD58), Color(0xFF55AF39), Color(0xFF25813D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(const Rect.fromLTWH(-49, -6, 50, 43)));
      canvas.drawPath(
          Path()
            ..moveTo(-2, 2)
            ..quadraticBezierTo(-24, 17, -44, 34),
          Paint()
            ..color = const Color(0x88D9F6AC)
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
