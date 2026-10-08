import 'package:flutter/material.dart';

import '../../repositories/weather_repository.dart';

enum SundoCardIllustration { sun, moon, cloud, rain, storm, today, calendar }

String sundoCardIllustrationAsset(SundoCardIllustration illustration) {
  final name = switch (illustration) {
    SundoCardIllustration.sun => 'weather_sun',
    SundoCardIllustration.moon => 'weather_moon',
    SundoCardIllustration.cloud => 'weather_cloud',
    SundoCardIllustration.rain => 'weather_rain',
    SundoCardIllustration.storm => 'weather_storm',
    SundoCardIllustration.today => 'collection_today',
    SundoCardIllustration.calendar => 'collection_calendar',
  };
  return 'assets/images/card_icons/$name.webp';
}

SundoCardIllustration sundoWeatherIllustration(
    WeatherCondition condition, {required bool isNight}) => switch (condition) {
      WeatherCondition.clear =>
        isNight ? SundoCardIllustration.moon : SundoCardIllustration.sun,
      WeatherCondition.cloudy || WeatherCondition.unknown =>
        SundoCardIllustration.cloud,
      WeatherCondition.rain || WeatherCondition.drizzle =>
        SundoCardIllustration.rain,
      WeatherCondition.thunderstorm => SundoCardIllustration.storm,
    };

/// Small bundled illustrations retain the current decoded icon while a weather
/// change loads. Their first frame fades in without animating the card layout.
class SundoCardIllustratedIcon extends StatefulWidget {
  const SundoCardIllustratedIcon({
    super.key,
    required this.illustration,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.size = 44,
  });

  final SundoCardIllustration illustration;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double size;

  @override
  State<SundoCardIllustratedIcon> createState() =>
      _SundoCardIllustratedIconState();
}

class _SundoCardIllustratedIconState extends State<SundoCardIllustratedIcon> {
  bool _hasFrame = false;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Image.asset(
          sundoCardIllustrationAsset(widget.illustration),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, synchronous) {
            _hasFrame = _hasFrame || frame != null;
            return AnimatedOpacity(
              opacity: _hasFrame ? 1 : 0,
              duration: synchronous || MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: child,
            );
          },
          errorBuilder: (_, __, ___) => Icon(widget.fallbackIcon,
              size: widget.size * .7, color: widget.fallbackColor),
        ),
      );
}
