import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/time_theme.dart';
import 'map_tracking_widgets.dart';

class SundoMapSceneHeader extends StatelessWidget {
  final bool demo;
  final ValueListenable<double> rotation;
  final VoidCallback onNorth;
  final VoidCallback onFit;
  const SundoMapSceneHeader(
      {super.key,
      required this.demo,
      required this.rotation,
      required this.onNorth,
      required this.onFit});
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
      decoration: mapSurfaceDecoration(mood, radius: 20),
      child: Row(children: [
        Icon(Icons.route_rounded, size: 24, color: mood.accent),
        const SizedBox(width: 9),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Live Truck Tracking',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: mood.textColor)),
          const SizedBox(height: 3),
          Text(
              demo
                  ? 'DEMO · Sample fleet · Sipalay City'
                  : 'Sipalay City · City tracking',
              style: TextStyle(fontSize: 9, color: mood.mutedTextColor)),
        ])),
        ValueListenableBuilder<double>(
            valueListenable: rotation,
            builder: (context, angle, _) => IconButton(
                  tooltip: 'Reset map north',
                  onPressed: onNorth,
                  icon: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('N',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: mood.textColor)),
                    Transform.rotate(
                        angle: angle * 3.141592653589793 / 180,
                        child: Icon(Icons.navigation_rounded,
                            size: 20, color: mood.accent)),
                  ]),
                )),
        IconButton(
            tooltip: 'Fit active route',
            onPressed: onFit,
            icon:
                Icon(Icons.center_focus_strong, color: mood.accent, size: 22)),
      ]),
    );
  }
}

class SundoMapViewBar extends StatelessWidget {
  final bool angled, following, canFollow;
  final ValueChanged<bool> onViewChanged;
  final VoidCallback onWatch;
  const SundoMapViewBar(
      {super.key,
      required this.angled,
      required this.following,
      required this.canFollow,
      required this.onViewChanged,
      required this.onWatch});
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    Widget option(String label, bool value) => Semantics(
        selected: angled == value,
        child: TextButton(
          onPressed: () => onViewChanged(value),
          style: TextButton.styleFrom(
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: angled == value ? Colors.white : mood.textColor,
              backgroundColor: angled == value
                  ? const Color(0xFF0B8F3E)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13))),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ));
    return Container(
      decoration: mapSurfaceDecoration(mood, radius: 17),
      padding: const EdgeInsets.all(4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        option('2D', false),
        option('3D', true),
        Container(
            height: 22,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: mood.mutedTextColor.withValues(alpha: .2)),
        Flexible(
            child: TextButton.icon(
          onPressed: canFollow ? onWatch : null,
          style: TextButton.styleFrom(
              minimumSize: const Size(74, 44),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              foregroundColor: mood.accent),
          icon: Icon(
              following
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              size: 21),
          label: Text(following ? 'Watching' : 'Watch',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        )),
      ]),
    );
  }
}
