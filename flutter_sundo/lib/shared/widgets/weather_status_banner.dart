import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/time_theme.dart';
import '../../features/home/widgets/sundo_dashboard_widgets.dart';
import '../../features/home/widgets/sundo_card_scenery.dart';
import '../../repositories/weather_repository.dart';
import 'sundo_card_illustration.dart';
import 'resident_components.dart';

/// Shows only fresh conditions with a known location, never an offline guess.
class SundoWeatherStatusBanner extends StatelessWidget {
  const SundoWeatherStatusBanner({super.key, this.dashboardStyle = false});

  final bool dashboardStyle;

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
      if (dashboardStyle) {
        final enabled = scope?.weatherEnabled == true;
        return _dashboardStatus(
          context,
          scope: scope,
          title: enabled
              ? scope!.checkingWeather
                  ? 'Checking weather…'
                  : 'Weather unavailable'
              : 'Time-based scenery',
          subtitle: enabled
              ? 'Using time-based scenery'
              : 'Weather is off in Settings',
          icon: Icons.cloud_outlined,
          iconColor: mood.accent,
          illustration: SundoCardIllustration.cloud,
        );
      }
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

    if (dashboardStyle) {
      return _dashboardStatus(
        context,
        scope: scope,
        title: headline,
        subtitle: source,
        icon: icon,
        iconColor: iconColor,
        illustration: sundoWeatherIllustration(weather.condition,
            isNight: mood.isNight),
        caution: caution,
      );
    }

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

  Widget _dashboardStatus(
    BuildContext context, {
    required SundoTimeScope? scope,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required SundoCardIllustration illustration,
    String? caution,
  }) {
    final mood = SundoTimeScope.of(context);
    final secondaryColor = mood.isNight
        ? mood.mutedTextColor
        : const Color(0xFF345244);
    final canRefresh =
        scope?.weatherEnabled == true && scope?.onWeatherRefresh != null;
    final statusDetails = scope?.weatherEnabled == true
        ? '$subtitle\nAuto-refresh · Every 5 min'
        : subtitle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        container: true,
        liveRegion: true,
        explicitChildNodes: true,
        child: SundoDashboardCard(
          decoration: SundoDashboardDecoration.weather,
          scenery: SundoCardScene.weatherRiverside,
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 280;
            final iconSize = compact ? 44.0 : 52.0;
            final iconTextGap = compact ? 10.0 : 12.0;
            final titleSize = compact ? 15.0 : 16.0;
            final titleScale =
                MediaQuery.textScalerOf(context).scale(titleSize) / titleSize;
            final textWidth = constraints.maxWidth -
                iconSize -
                iconTextGap -
                (canRefresh ? 50 : 0);
            final illustrationWidget = Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        mood.isNight
                            ? const Color(0xFF294536)
                            : const Color(0xFFF0FFEF),
                        iconColor.withValues(alpha: .17),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                        color: Colors.white
                            .withValues(alpha: mood.isNight ? .08 : .7)),
                  ),
                  child: Center(
                    child: SundoCardIllustratedIcon(
                      illustration: illustration,
                      fallbackIcon: icon,
                      fallbackColor: iconColor,
                      size: compact ? 38 : 46,
                    ),
                  ),
                );
            final description = Semantics(
                    excludeSemantics: true,
                    label: [title, statusDetails, if (caution != null) caution]
                        .join('. '),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.outfit(
                              fontSize: titleSize,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: mood.textColor,
                            )),
                        const SizedBox(height: 5),
                        Text(statusDetails,
                            style: TextStyle(
                              fontSize: compact ? 11 : 12,
                              height: 1.35,
                              color: secondaryColor,
                            )),
                        if (caution != null) ...[
                          const SizedBox(height: 4),
                          Text(caution,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: mood.textColor,
                              )),
                        ],
                      ],
                    ),
                  );
            final refresh = !canRefresh
                ? null
                : scope!.checkingWeather
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: 'Checking local weather',
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: scope.onWeatherRefresh,
                          tooltip: 'Refresh local weather',
                          style: IconButton.styleFrom(
                            backgroundColor: mood.accent.withValues(alpha: .08),
                            foregroundColor: mood.accent,
                            minimumSize: const Size.square(44),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 25),
                        );
            if (textWidth / titleScale < 140) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    illustrationWidget,
                    const Spacer(),
                    if (refresh != null) refresh,
                  ]),
                  const SizedBox(height: 10),
                  description,
                ],
              );
            }
            return Row(
              children: [
                illustrationWidget,
                SizedBox(width: iconTextGap),
                Expanded(child: description),
                if (refresh != null) ...[
                  const SizedBox(width: 6),
                  refresh,
                ],
              ],
            );
          }),
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
