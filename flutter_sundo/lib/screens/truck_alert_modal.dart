import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/clay_theme.dart';
import '../widgets/sundo_graphics.dart';

class TruckAlertModal extends StatelessWidget {
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
      barrierColor: Colors.black.withValues(alpha: 0.55),
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
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: ClayTheme.card(radius: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Amber Bell 3D Floating Circle
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x35F59E0B),
                      offset: Offset(0, 8),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFF78350F),
                  size: 34,
                ),
              ),

              const SizedBox(height: 16),

              // Truck Illustration
              const SundoTruckGraphic(width: 100, height: 75),

              const SizedBox(height: 8),

              // Title
              Text(
                'SUNDO Alert',
                style: GoogleFonts.outfit(
                  fontSize: 22,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),

              const SizedBox(height: 16),

              // Amber Clay ETA Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: ClayTheme.amberBadge(radius: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time_filled_rounded, color: Color(0xFFB45309), size: 18),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF78350F),
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          const TextSpan(text: 'Estimated arrival: '),
                          TextSpan(
                            text: '$etaMinutes minutes',
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
                onTap: onViewTruck,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: ClayTheme.buttonPrimary(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Truck',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Dismiss Text Button
              GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    'Dismiss',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
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

    if (isStandalone) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.7),
        body: content,
      );
    }

    return content;
  }
}
