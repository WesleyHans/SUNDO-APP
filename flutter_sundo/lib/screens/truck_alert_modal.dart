import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/clay_theme.dart';
import '../widgets/sundo_graphics.dart';

class TruckAlertModal extends StatefulWidget {
  final int etaMinutes;
  final VoidCallback onViewTruck;
  final VoidCallback onDismiss;
  final bool isStandalone;

  const TruckAlertModal({
    super.key,
    this.etaMinutes = 10,
    required this.onViewTruck,
    required this.onDismiss,
    this.isStandalone = false,
  });

  static Future<void> show(
    BuildContext context, {
    int etaMinutes = 10,
    required VoidCallback onViewTruck,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => TruckAlertModal(
        etaMinutes: etaMinutes,
        onViewTruck: () {
          Navigator.pop(ctx);
          onViewTruck();
        },
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  State<TruckAlertModal> createState() => _TruckAlertModalState();
}

class _TruckAlertModalState extends State<TruckAlertModal> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: ClayTheme.card(radius: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Animated Amber Bell with Radiating Soundwaves
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  // Rocking bell rotation oscillation
                  final double angle = math.sin(_animController.value * 2 * math.pi * 2) * 0.22;
                  final double waveScale = 1.0 + (_animController.value * 0.6);
                  final double waveOpacity = (1.0 - _animController.value).clamp(0.0, 1.0);

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soundwave 1
                      Transform.scale(
                        scale: waveScale,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: waveOpacity * 0.7),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                      // Soundwave 2
                      Transform.scale(
                        scale: 1.0 + (_animController.value * 0.9),
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFBBF24).withValues(alpha: waveOpacity * 0.4),
                              width: 1.8,
                            ),
                          ),
                        ),
                      ),
                      // Rocking 3D Amber Bell Sphere
                      Transform.rotate(
                        angle: angle,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFEF3C7), Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x45F59E0B),
                                offset: Offset(0, 8),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFF78350F),
                            size: 34,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              // Animated Gentle Bobbing Truck
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final dy = math.sin(_animController.value * 2 * math.pi) * 3.5;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: const SundoTruckGraphic(width: 105, height: 78),
                  );
                },
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                'SUNDO Alert',
                style: GoogleFonts.outfit(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 4),

              // Subtitle
              Text(
                'Garbage truck is approaching your area.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),

              const SizedBox(height: 16),

              // Amber Clay ETA Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                decoration: ClayTheme.amberBadge(radius: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time_filled_rounded, color: Color(0xFFB45309), size: 19),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF78350F),
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          const TextSpan(text: 'Estimated arrival: '),
                          TextSpan(
                            text: '${widget.etaMinutes} minutes',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF451A03)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Primary Clay Button: View Truck
              GestureDetector(
                onTap: widget.onViewTruck,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: ClayTheme.buttonPrimary(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Truck Live',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Dismiss Text Button
              GestureDetector(
                onTap: widget.onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    'Dismiss',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isStandalone) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.75),
        body: content,
      );
    }

    return content;
  }
}
