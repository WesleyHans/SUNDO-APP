import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/sundo_graphics.dart';
import '../../shared/widgets/scenic_backdrop.dart';
import '../../core/theme/clay_theme.dart';
import '../../core/theme/time_theme.dart';
import '../../shared/widgets/time_based_background.dart';
import '../../shared/widgets/weather_attribution.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const SplashScreen({super.key, required this.onContinue});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _brandingColor = Color(0xFFFAFFF2);
  // This scope preserves the existing daytime wordmark and subtitle colors.
  static final _brandingMood = SundoTimeMood(DateTime(2000, 1, 1, 9));
  Timer? _timer;

  double _brandingHeight(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    double textHeight(String text, TextStyle style) {
      final painter = TextPainter(
          text: TextSpan(
              text: text,
              style: DefaultTextStyle.of(context).style.merge(style)),
          textScaler: scaler,
          textDirection: Directionality.of(context))
        ..layout(maxWidth: width);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    return 202.5 * 1049 / 1499 +
        textHeight(
            'SUNDO',
            GoogleFonts.outfit(
                fontSize: 135 * .43,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1)) +
        12 +
        textHeight(
            'Smart Urban Navigation',
            GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700)) +
        textHeight(
            'for Dynamic Waste Operations',
            GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w500));
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) widget.onContinue();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: _brandingColor,
          systemNavigationBarIconBrightness: Brightness.dark),
      child: GestureDetector(
        onTap: widget.onContinue,
        child: Scaffold(
            backgroundColor: _brandingColor,
            body: LayoutBuilder(builder: (context, bounds) {
              final padding = MediaQuery.paddingOf(context);
              // Match the existing logo layout, including accessibility text
              // scaling, without changing its position, fonts or dimensions.
              final brandingEnd = padding.top +
                  55 +
                  _brandingHeight(
                      context, bounds.maxWidth - padding.horizontal);
              final solidEnd =
                  ((brandingEnd + 8) / bounds.maxHeight).clamp(0.0, 1.0);
              final featherEnd =
                  ((brandingEnd + 68) / bounds.maxHeight).clamp(solidEnd, 1.0);
              return Stack(fit: StackFit.expand, children: [
                const SundoTimeBasedBackground(
                    fullScene: true,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment(0, .35)),
                _NightMoon(environment: SundoTimeScope.of(context).environment),
                IgnorePointer(
                    child: DecoratedBox(
                        key: const ValueKey('splash-branding-plate'),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, solidEnd, featherEnd, 1],
                          colors: const [
                            _brandingColor,
                            _brandingColor,
                            Color(0x00FAFFF2),
                            Color(0x00FAFFF2),
                          ],
                        )))),
                const Positioned(
                    left: -22,
                    top: 25,
                    child: LeafSprig(size: 120, flipped: true)),
                const Positioned(
                    right: -35, top: 100, child: LeafSprig(size: 85)),
                SafeArea(
                    child: Column(children: [
                  const SizedBox(height: 55),
                  SundoTimeScope(
                      mood: _brandingMood,
                      child: const SundoLogoGraphic(
                          key: ValueKey('splash-fixed-branding'),
                          size: 135,
                          showSubtitle: true)),
                  const Spacer(),
                  Container(
                      key: const ValueKey('splash-slogan-card'),
                      margin: const EdgeInsets.all(26),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 18),
                      decoration: ClayTheme.card(radius: 28),
                      child: Column(children: [
                        Text('Track. Prepare. Collect.',
                            style: GoogleFonts.outfit(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF185632))),
                        const SizedBox(height: 8),
                        Text('Together for a cleaner Sipalay',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, color: const Color(0xFF567060))),
                      ])),
                ])),
                Positioned(
                    left: 0,
                    right: 0,
                    bottom: padding.bottom + 6,
                    child: const WeatherAttribution(color: Color(0xFF567060))),
              ]);
            })),
      ));
}

/// Twilight uses the existing small moon. The supplied later-night scene has
/// its own moon, so no extra moon is painted over it. This moon is placed
/// in its sky coordinates, beneath the fixed branding plate, and never changes
/// the truck, road, vegetation or camera framing.
class _NightMoon extends StatelessWidget {
  const _NightMoon({required this.environment});
  final SundoEnvironment environment;

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: AnimatedOpacity(
          opacity: environment == SundoEnvironment.twilight ? 1 : 0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          child: LayoutBuilder(builder: (context, bounds) {
            final sceneHeight = bounds.maxWidth * 1.5;
            final sceneTop = (bounds.maxHeight - sceneHeight) * .675;
            final diameter = bounds.maxWidth * .045;
            return Stack(children: [
              Positioned(
                  left: bounds.maxWidth * .855 - diameter / 2,
                  top: sceneTop + sceneHeight * .39 - diameter / 2,
                  width: diameter,
                  height: diameter,
                  child: const CustomPaint(painter: _MoonPainter())),
            ]);
          })));
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.drawCircle(
        center,
        radius * 2,
        Paint()
          ..shader = const RadialGradient(colors: [
            Color(0x44DFEBFF),
            Color(0x00DFEBFF),
          ]).createShader(Rect.fromCircle(center: center, radius: radius * 2)));
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFECF2FF));
    final crater = Paint()..color = const Color(0x22A7BBDF);
    canvas.drawCircle(
        center + Offset(-radius * .32, radius * .18), radius * .2, crater);
    canvas.drawCircle(
        center + Offset(radius * .28, -radius * .35), radius * .13, crater);
  }

  @override
  bool shouldRepaint(_MoonPainter oldDelegate) => false;
}
