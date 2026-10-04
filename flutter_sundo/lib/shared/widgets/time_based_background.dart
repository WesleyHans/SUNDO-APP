import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/time_theme.dart';

const sundoCityArtwork = 'assets/images/clay-city-hero.png';

/// Uses the illustrated city as scenery while all controls remain Flutter widgets.
class SundoTimeBasedBackground extends StatelessWidget {
  final Widget? child;
  final bool fullScene;
  final Alignment alignment;
  const SundoTimeBasedBackground({
    super.key,
    this.child,
    this.fullScene = false,
    this.alignment = Alignment.bottomCenter,
  });
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return Stack(fit: StackFit.expand, children: [
      DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [mood.sky, mood.background],
      ))),
      Opacity(
          opacity: fullScene ? 1 : (mood.isNight ? .22 : .18),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              mood.isNight
                  ? const Color(0xFF294363)
                  : mood.period == SundoDayPeriod.afternoon
                      ? const Color(0xFFFFEBC5)
                      : Colors.white,
              BlendMode.modulate,
            ),
            child: Image.asset(sundoCityArtwork,
                fit: BoxFit.cover, alignment: alignment),
          )),
      if (mood.isNight) ...[
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, .46, 1],
          colors: [Color(0xDD132C47), Color(0x44152B35), Color(0x55122425)],
        ))),
        const IgnorePointer(
            child: CustomPaint(painter: _EveningSceneryPainter())),
      ],
      if (child != null) child!,
    ]);
  }
}

class _EveningSceneryPainter extends CustomPainter {
  const _EveningSceneryPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final stars = Paint()..color = const Color(0xBBD4E4EC);
    for (var i = 0; i < 24; i++) {
      final x = ((i * 97 + 31) % 347) / 347 * size.width;
      final y = ((i * 43 + 17) % 127) / 127 * size.height * .37;
      canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 1.1 : .65, stars);
    }
    final center = Offset(size.width * .8, size.height * .13);
    canvas.drawCircle(center, 16, Paint()..color = const Color(0xFFF5F0CE));
    canvas.drawCircle(center + const Offset(7, -4), 14,
        Paint()..color = const Color(0xFF193650));
    // Warm windows on the city band, independent of the interactive content.
    final windows = Paint()..color = const Color(0x99FFD78A);
    for (var i = 0; i < 18; i++) {
      final x = size.width * (.16 + (i % 6) * .125);
      final y = size.height * (.63 + (i ~/ 6) * .025);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, math.max(2.0, size.width * .009), 5),
              const Radius.circular(1)),
          windows);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
