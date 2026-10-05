import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/map_tracking.dart';
import '../../../core/theme/time_theme.dart';
import '../../../shared/widgets/sundo_graphics.dart';

String mapStageLabel(MapTrackingStage stage) => switch (stage) {
      MapTrackingStage.notStarted => 'Not Started',
      MapTrackingStage.onRoute => 'On Route',
      MapTrackingStage.approaching => 'Approaching',
      MapTrackingStage.nearby => 'Nearby',
      MapTrackingStage.completed => 'Completed',
    };

BoxDecoration mapSurfaceDecoration(SundoTimeMood mood, {double radius = 18}) =>
    BoxDecoration(
      gradient: LinearGradient(
        colors: mood.isNight
            ? [mood.surface, const Color(0xFF143126)]
            : [Colors.white, const Color(0xFFF2FAEF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
          color:
              mood.isNight ? const Color(0xFF365543) : const Color(0xFFF0F7EF)),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: .15),
            offset: const Offset(0, 6),
            blurRadius: 14)
      ],
    );

class SundoMapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;
  const SundoMapControlButton(
      {super.key,
      required this.icon,
      required this.tooltip,
      required this.onPressed,
      this.selected = false});
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return Container(
      width: 46,
      height: 46,
      decoration: mapSurfaceDecoration(mood, radius: 23),
      child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon,
              size: 22, color: selected ? mood.accent : mood.textColor)),
    );
  }
}

class SundoRouteProgress extends StatelessWidget {
  final MapTrackingStage stage;
  final bool available;
  const SundoRouteProgress(
      {super.key, required this.stage, this.available = true});
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return Semantics(
        label: available
            ? 'Collection status: ${mapStageLabel(stage)}'
            : 'Collection status unavailable',
        child: Column(children: [
          Row(children: [
            for (var i = 0; i < 5; i++) ...[
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: available && i <= stage.index
                          ? mood.accent
                          : mood.mutedTextColor.withValues(alpha: .3),
                      border: Border.all(color: mood.surface, width: 2))),
              if (i < 4)
                Expanded(
                    child: Container(
                        height: 3,
                        color: available && i < stage.index
                            ? mood.accent
                            : mood.mutedTextColor.withValues(alpha: .2))),
            ]
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final value in MapTrackingStage.values)
              Expanded(
                  child: Text(mapStageLabel(value),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          color: available && value == stage
                              ? mood.accent
                              : mood.mutedTextColor,
                          fontWeight: available && value == stage
                              ? FontWeight.w800
                              : FontWeight.w500))),
          ]),
        ]));
  }
}

class SundoTrackingBottomSheet extends StatelessWidget {
  final MapTruckSnapshot? truck;
  final String? error;
  final bool loading;
  final bool fresh;
  final VoidCallback onFollow;
  final VoidCallback onRefresh;
  final VoidCallback? onAlertPreview;
  final ScrollController scrollController;
  const SundoTrackingBottomSheet(
      {super.key,
      this.truck,
      this.error,
      required this.loading,
      required this.fresh,
      required this.onFollow,
      required this.onRefresh,
      this.onAlertPreview,
      required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final snapshot = truck;
    return Container(
      decoration: mapSurfaceDecoration(mood, radius: 26),
      child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          children: [
            Center(
                child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: mood.mutedTextColor.withValues(alpha: .3),
                        borderRadius: BorderRadius.circular(2)))),
            if (snapshot == null) ...[
              Row(children: [
                const SundoTruckGraphic(width: 64, height: 46),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        loading
                            ? 'Finding your truck…'
                            : error != null
                                ? 'Tracking unavailable'
                                : 'No truck location yet',
                        style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: mood.textColor)))
              ]),
              const SizedBox(height: 12),
              Text(
                  error ??
                      'Your city has not published a truck position. Your location stays private.',
                  style: TextStyle(color: mood.mutedTextColor, fontSize: 12)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh tracking')),
            ] else ...[
              Row(children: [
                const SundoTruckGraphic(width: 62, height: 46),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(snapshot.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: mood.textColor)),
                      Text(
                          snapshot.simulated
                              ? 'Simulated collection'
                              : fresh
                                  ? 'Live city update'
                                  : 'Last known position',
                          style: TextStyle(
                              color: mood.mutedTextColor, fontSize: 11)),
                    ])),
                const SizedBox(width: 8),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                        color: fresh ? mood.accent : mood.mutedTextColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        fresh ? mapStageLabel(snapshot.stage) : 'Offline',
                        style: TextStyle(
                            color: mood.isNight && fresh
                                ? const Color(0xFF143126)
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 14, runSpacing: 4, children: [
                Text(
                    snapshot.distanceKm != null
                        ? '${snapshot.distanceKm!.toStringAsFixed(1)} km away'
                        : 'Distance not published',
                    style: TextStyle(color: mood.mutedTextColor, fontSize: 12)),
                Text(
                    fresh && snapshot.etaMinutes != null
                        ? 'ETA: ${snapshot.etaMinutes} minutes'
                        : 'ETA unavailable',
                    style: TextStyle(
                        color: mood.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 14),
              SundoRouteProgress(stage: snapshot.stage, available: fresh),
              const SizedBox(height: 14),
              _detail(
                  context,
                  Icons.route_rounded,
                  'Active route',
                  snapshot.route.name.isEmpty
                      ? 'Not published'
                      : snapshot.route.name),
              _detail(context, Icons.location_on_outlined, 'Next stop',
                  snapshot.nextStop ?? 'Not published'),
              _detail(context, Icons.map_outlined, 'Current area',
                  snapshot.currentArea ?? 'Not published'),
              _detail(
                  context,
                  Icons.update,
                  'Updated',
                  snapshot.updatedAt == null
                      ? 'Unavailable'
                      : DateFormat('h:mm:ss a')
                          .format(snapshot.updatedAt!.toLocal())),
              const SizedBox(height: 6),
              FilledButton.icon(
                  onPressed: snapshot.position == null ? null : onFollow,
                  icon: const SundoTruckGraphic(width: 24, height: 20),
                  label: const Text('Follow Truck')),
              if (onAlertPreview != null)
                TextButton.icon(
                    onPressed: onAlertPreview,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Preview simulated alert')),
              Text('Operational routes are managed by the city.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: mood.mutedTextColor)),
            ],
          ]),
    );
  }

  Widget _detail(
      BuildContext context, IconData icon, String label, String value) {
    final mood = SundoTimeScope.of(context);
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: mood.accent),
          const SizedBox(width: 8),
          SizedBox(
              width: 78,
              child: Text(label,
                  style: TextStyle(fontSize: 11, color: mood.mutedTextColor))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 11,
                      color: mood.textColor,
                      fontWeight: FontWeight.w600))),
        ]));
  }
}

class SundoCollectionPointMarker extends StatelessWidget {
  final MapCollectionPoint point;
  const SundoCollectionPointMarker({super.key, required this.point});
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Collection point ${point.number}: ${point.name}',
      child: Stack(children: [
        const Positioned(
            left: 5,
            bottom: 0,
            width: 44,
            height: 51,
            child: CustomPaint(painter: _MapCollectionPointPainter())),
        Positioned(
            right: 0,
            top: 0,
            child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFF07652E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: Text('${point.number}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)))),
      ]));
}

class _MapCollectionPointPainter extends CustomPainter {
  const _MapCollectionPointPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawOval(Rect.fromLTWH(w * .1, h * .86, w * .8, h * .14),
        Paint()..color = const Color(0x450F1E1A));
    final front = Path()
      ..moveTo(w * .13, h * .34)
      ..lineTo(w * .56, h * .47)
      ..lineTo(w * .56, h * .87)
      ..lineTo(w * .13, h * .75)
      ..close();
    final side = Path()
      ..moveTo(w * .56, h * .47)
      ..lineTo(w * .86, h * .32)
      ..lineTo(w * .86, h * .73)
      ..lineTo(w * .56, h * .87)
      ..close();
    final roof = Path()
      ..moveTo(w * .05, h * .27)
      ..lineTo(w * .43, h * .09)
      ..lineTo(w * .94, h * .26)
      ..lineTo(w * .56, h * .48)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFFF1E8BC));
    canvas.drawPath(side, Paint()..color = const Color(0xFFE0CD91));
    canvas.drawPath(
        roof,
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFF21B55E), Color(0xFF07652E)])
              .createShader(Offset.zero & size));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .24, h * .47, w * .19, h * .21),
            const Radius.circular(1)),
        Paint()..color = const Color(0xFF07652E));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .65, h * .49, w * .12, h * .22),
            const Radius.circular(1)),
        Paint()..color = const Color(0xFF07652E));
    canvas.drawCircle(
        Offset(w * .53, h * .2), 2, Paint()..color = const Color(0xFFEAF8EE));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
