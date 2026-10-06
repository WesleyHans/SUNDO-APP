import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/time_theme.dart';
import '../../repositories/weather_repository.dart';
import 'resident_components.dart';

/// Shows only fresh conditions with a known location, never an offline guess.
class SundoWeatherStatusBanner extends StatelessWidget {
  const SundoWeatherStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final scope = context.dependOnInheritedWidgetOfExactType<SundoTimeScope>();
    final weather = mood.weather;
    final location = weather?.location;
    if (weather == null ||
        !weather.isFreshAt(mood.now) ||
        weather.condition == WeatherCondition.unknown ||
        location == null ||
        location.label.trim().isEmpty) {
      if (scope?.weatherEnabled != true) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: SundoSurface(
            radius: 16,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(Icons.cloud_outlined, size: 22, color: mood.mutedTextColor),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      scope!.checkingWeather
                          ? 'Checking weather for your area…'
                          : 'Weather unavailable · Using time-based scenery',
                      style:
                          TextStyle(fontSize: 12, color: mood.mutedTextColor))),
              _weatherRefresh(scope),
            ])),
      );
    }

    final place = location.isDeviceLocation
        ? 'at your location'
        : 'in ${location.label.trim()}';
    final (description, icon) = switch (weather.condition) {
      WeatherCondition.clear => (
          'Clear weather',
          mood.isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
        ),
      WeatherCondition.cloudy => ('Cloudy', Icons.cloud_rounded),
      WeatherCondition.rain => ('Rainy', Icons.umbrella_rounded),
      WeatherCondition.drizzle => ('Light rain', Icons.grain_rounded),
      WeatherCondition.thunderstorm => (
          'Thunderstorms',
          Icons.thunderstorm_rounded,
        ),
      WeatherCondition.unknown => ('', Icons.cloud_outlined),
    };
    final headline = '$description $place';
    final age = mood.now.toUtc().difference(weather.validAt.toUtc());
    final updated = age.inMinutes <= 1
        ? 'Updated just now'
        : 'Updated ${age.inMinutes} min ago';
    final source = 'Model-based current conditions · $updated';
    final caution = weather.condition == WeatherCondition.thunderstorm
        ? 'Collection may be affected. Take care outdoors.'
        : weather.isRaining
            ? 'Collection may be affected by rain.'
            : null;
    final iconColor = switch (weather.condition) {
      WeatherCondition.clear =>
        mood.isNight ? const Color(0xFFFFE4A4) : const Color(0xFFAD7200),
      WeatherCondition.thunderstorm =>
        mood.isNight ? const Color(0xFFFFDEA0) : const Color(0xFF956200),
      _ => mood.isNight ? const Color(0xFFA2D6F3) : const Color(0xFF2D6E8F),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        container: true,
        liveRegion: true,
        explicitChildNodes: true,
        child: SundoSurface(
          radius: 16,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  excludeSemantics: true,
                  label: [headline, source, if (caution != null) caution]
                      .join('. '),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(headline,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: mood.textColor,
                          )),
                      const SizedBox(height: 3),
                      Text(source,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.35,
                            color: mood.mutedTextColor,
                          )),
                      if (caution != null) ...[
                        const SizedBox(height: 4),
                        Text(caution,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              color: mood.textColor,
                            )),
                      ],
                    ],
                  ),
                ),
              ),
              if (scope?.onWeatherRefresh != null) _weatherRefresh(scope!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weatherRefresh(SundoTimeScope scope) => scope.checkingWeather
      ? const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, semanticsLabel: 'Checking local weather')))
      : IconButton(
          onPressed: scope.onWeatherRefresh,
          tooltip: 'Refresh local weather',
          icon: const Icon(Icons.refresh_rounded, size: 20));
}
