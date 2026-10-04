import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/clay_theme.dart';
import '../../core/theme/time_theme.dart';
import './widgets/map_tracking_widgets.dart';
import '../../shared/widgets/sundo_graphics.dart';

class TruckAlertModal extends StatefulWidget {
  final int etaMinutes;
  final VoidCallback onViewTruck;
  final VoidCallback onDismiss;
  final bool isStandalone;
  final bool simulated;
  const TruckAlertModal(
      {super.key,
      this.etaMinutes = 10,
      required this.onViewTruck,
      required this.onDismiss,
      this.isStandalone = false,
      this.simulated = false});

  static Future<void> show(BuildContext context,
      {int etaMinutes = 10,
      bool simulated = false,
      required VoidCallback onViewTruck}) {
    // Dialog routes do not inherit scopes beneath Navigator, so capture mood.
    final mood = SundoTimeScope.of(context);
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .65),
      builder: (dialogContext) => SundoTimeScope(
          mood: mood,
          child: TruckAlertModal(
              etaMinutes: etaMinutes,
              simulated: simulated,
              onViewTruck: () {
                Navigator.pop(dialogContext);
                onViewTruck();
              },
              onDismiss: () => Navigator.pop(dialogContext))),
    );
  }

  @override
  State<TruckAlertModal> createState() => _TruckAlertModalState();
}

class _TruckAlertModalState extends State<TruckAlertModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bell;
  @override
  void initState() {
    super.initState();
    _bell = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() {
    _bell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final content = Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Center(
              child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
                decoration: mapSurfaceDecoration(mood, radius: 28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedBuilder(
                      animation: _bell,
                      builder: (context, _) => Transform.rotate(
                          angle: MediaQuery.disableAnimationsOf(context)
                              ? 0
                              : math.sin(_bell.value * math.pi * 4) * .13,
                          child: Container(
                              width: 64,
                              height: 64,
                              decoration: ClayTheme.amberBadge(radius: 32),
                              child: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: Color(0xFFB17A12),
                                  size: 34)))),
                  const SizedBox(height: 14),
                  const SundoTruckGraphic(width: 128, height: 95),
                  const SizedBox(height: 8),
                  Text('SUNDO Alert',
                      style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: mood.textColor)),
                  const SizedBox(height: 6),
                  Text('Garbage truck is approaching your area.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: mood.mutedTextColor,
                          fontWeight: FontWeight.w500)),
                  if (widget.simulated)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('DEMO · simulated arrival',
                            style: TextStyle(
                                fontSize: 10,
                                color: mood.accent,
                                fontWeight: FontWeight.w700))),
                  const SizedBox(height: 18),
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: ClayTheme.amberBadge(radius: 16),
                      child: Row(children: [
                        const Icon(Icons.access_time_filled,
                            color: Color(0xFFF4A623), size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Estimated arrival:',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF614116))),
                              Text('${widget.etaMinutes} minutes',
                                  style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF442A09))),
                            ]))
                      ])),
                  const SizedBox(height: 18),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: widget.onViewTruck,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52)),
                          child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(child: Text('View Truck')),
                                SizedBox(width: 16),
                                Icon(Icons.arrow_forward, size: 18)
                              ]))),
                  const SizedBox(height: 6),
                  TextButton(
                      onPressed: widget.onDismiss,
                      child: Text('Dismiss',
                          style: TextStyle(color: mood.accent))),
                ])),
          )),
        ));
    return widget.isStandalone
        ? Scaffold(backgroundColor: const Color(0xFF18344A), body: content)
        : content;
  }
}
