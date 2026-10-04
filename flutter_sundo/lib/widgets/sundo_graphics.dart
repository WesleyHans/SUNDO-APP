import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sundo Garbage Truck Vector Graphic
class SundoTruckGraphic extends StatelessWidget {
  final double width;
  final double height;

  const SundoTruckGraphic({
    super.key,
    this.width = 120,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SundoTruckPainter(),
    );
  }
}

class _SundoTruckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 160.0;
    canvas.save();
    canvas.scale(scale);

    // 1. Sprouting Eco Leaves above cab
    final mainLeafPaint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.fill;
    final leafStrokePaint = Paint()
      ..color = const Color(0xFF059669)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leaf1 = Path()
      ..moveTo(52, 48)
      ..cubicTo(46, 22, 28, 8, 10, 12)
      ..cubicTo(6, 30, 20, 46, 44, 48)
      ..cubicTo(46.8, 48.2, 49.5, 48.2, 52, 48)
      ..close();
    canvas.drawPath(leaf1, mainLeafPaint);

    final leafStem1 = Path()
      ..moveTo(52, 48)
      ..cubicTo(36, 34, 26, 22, 10, 12);
    canvas.drawPath(leafStem1, leafStrokePaint);

    final leaf2Paint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    final leaf2 = Path()
      ..moveTo(50, 42)
      ..cubicTo(56, 24, 72, 15, 88, 20)
      ..cubicTo(90, 38, 78, 52, 56, 46)
      ..cubicTo(53.8, 45.4, 51.8, 43.8, 50, 42)
      ..close();
    canvas.drawPath(leaf2, leaf2Paint);

    final leafStem2 = Path()
      ..moveTo(50, 42)
      ..cubicTo(64, 33, 76, 26, 88, 20);
    canvas.drawPath(leafStem2, leafStrokePaint);

    // 2. Truck Body (Back Container)
    final outerContainerPaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(58, 44, 86, 54), const Radius.circular(10)),
      outerContainerPaint,
    );

    final innerContainerPaint = Paint()..color = const Color(0xFF059669);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(62, 48, 78, 46), const Radius.circular(7)),
      innerContainerPaint,
    );

    // 3. Truck Cab (Front)
    final cabPaint = Paint()..color = const Color(0xFF10B981);
    final cabPath = Path()
      ..moveTo(26, 62)
      ..cubicTo(26, 55.4, 31.4, 50, 38, 50)
      ..lineTo(58, 50)
      ..lineTo(58, 98)
      ..lineTo(26, 98)
      ..close();
    canvas.drawPath(cabPath, cabPaint);

    // Cab Windshield
    final windshieldPaint = Paint()..color = const Color(0xFFE0F2FE);
    final windshieldPath = Path()
      ..moveTo(32, 56)
      ..lineTo(52, 56)
      ..cubicTo(53.6, 56, 55, 57.3, 55, 59)
      ..lineTo(55, 76)
      ..lineTo(30, 76)
      ..cubicTo(30, 73, 30.5, 63, 32, 56)
      ..close();
    canvas.drawPath(windshieldPath, windshieldPaint);

    // Headlight
    final headlightPaint = Paint()..color = const Color(0xFFFDE047);
    canvas.drawCircle(const Offset(26, 84), 3.5, headlightPaint);

    // Front Bumper
    final bumperPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(22, 88, 8, 8), const Radius.circular(2)),
      bumperPaint,
    );

    // Recycle symbol simplified emblem inside container
    final emblemPaint = Paint()
      ..color = const Color(0xFFECFDF5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(101, 71), 11, Paint()..color = Colors.white.withValues(alpha: 0.2));
    canvas.drawCircle(const Offset(101, 71), 8, emblemPaint);
    canvas.drawCircle(const Offset(101, 71), 4, innerContainerPaint);

    // Chassis Under-rail
    final chassisPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(30, 96, 112, 7), const Radius.circular(3)),
      chassisPaint,
    );

    // Wheels helper
    void drawWheel(double cx, double cy) {
      canvas.drawCircle(Offset(cx, cy), 14, Paint()..color = const Color(0xFF1E293B));
      canvas.drawCircle(Offset(cx, cy), 8, Paint()..color = const Color(0xFF64748B));
      canvas.drawCircle(Offset(cx, cy), 3.5, Paint()..color = const Color(0xFFF8FAFC));
    }

    drawWheel(44, 103);
    drawWheel(104, 103);
    drawWheel(132, 103);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Sipalay City Skyline & Karst Hills Graphic
class CitySkylineGraphic extends StatelessWidget {
  final double height;

  const CitySkylineGraphic({super.key, this.height = 110});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CitySkylinePainter(),
      ),
    );
  }
}

class _CitySkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Distant Karst Mountains
    final mountainPath = Path()
      ..moveTo(0, h * 0.75)
      ..quadraticBezierTo(w * 0.2, h * 0.35, w * 0.45, h * 0.65)
      ..quadraticBezierTo(w * 0.65, h * 0.40, w * 0.85, h * 0.60)
      ..quadraticBezierTo(w * 0.95, h * 0.45, w, h * 0.70)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(mountainPath, Paint()..color = const Color(0xFFA7F3D0).withValues(alpha: 0.6));

    // Buildings Skyline
    final bldgPaint = Paint()..color = const Color(0xFF93C5FD).withValues(alpha: 0.6);
    final winPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);

    void drawBldg(double x, double y, double bw, double bh) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, bw, bh), const Radius.circular(3)),
        bldgPaint,
      );
      // windows
      for (double wy = y + 6; wy < y + bh - 10; wy += 10) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x + 4, wy, 5, 6), const Radius.circular(1)),
          winPaint,
        );
        if (bw > 18) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(x + bw - 9, wy, 5, 6), const Radius.circular(1)),
            winPaint,
          );
        }
      }
    }

    drawBldg(w * 0.08, h * 0.42, 26, h * 0.58);
    drawBldg(w * 0.18, h * 0.28, 32, h * 0.72);
    drawBldg(w * 0.30, h * 0.48, 24, h * 0.52);
    drawBldg(w * 0.65, h * 0.34, 30, h * 0.66);
    drawBldg(w * 0.76, h * 0.45, 26, h * 0.55);
    drawBldg(w * 0.86, h * 0.38, 28, h * 0.62);

    // Forefront Lush Green Hills
    final hillPath = Path()
      ..moveTo(0, h * 0.85)
      ..quadraticBezierTo(w * 0.25, h * 0.72, w * 0.5, h * 0.82)
      ..quadraticBezierTo(w * 0.75, h * 0.70, w, h * 0.80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final hillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF059669)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.7, w, h * 0.3));
    canvas.drawPath(hillPath, hillPaint);

    // Tree clusters
    void drawTree(double cx, double cy, double r, Color color) {
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);
    }

    drawTree(w * 0.08, h * 0.82, 14, const Color(0xFF047857));
    drawTree(w * 0.13, h * 0.80, 12, const Color(0xFF10B981));
    drawTree(w * 0.48, h * 0.82, 13, const Color(0xFF10B981));
    drawTree(w * 0.53, h * 0.79, 15, const Color(0xFF047857));
    drawTree(w * 0.90, h * 0.80, 14, const Color(0xFF047857));
    drawTree(w * 0.95, h * 0.83, 11, const Color(0xFF10B981));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full Welcome Scene Graphic (Sun, Clouds, Buildings, Trees, Street, Truck)
class WelcomeSceneGraphic extends StatelessWidget {
  final double height;

  const WelcomeSceneGraphic({super.key, this.height = 190});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFE0F2FE), Color(0xFFDCFCE7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.6), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1594A3B8),
            offset: Offset(4, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            // Background Sky elements & buildings
            Positioned.fill(
              child: CustomPaint(
                painter: _WelcomeScenePainter(),
              ),
            ),
            // The Driving Green SUNDO Truck
            Positioned(
              bottom: 22,
              left: 0,
              right: 0,
              child: Center(
                child: Transform.scale(
                  scale: 0.85,
                  child: const SundoTruckGraphic(width: 140, height: 95),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Sun
    canvas.drawCircle(Offset(w * 0.82, h * 0.22), 22, Paint()..color = const Color(0xFFFEF9C3).withValues(alpha: 0.8));
    canvas.drawCircle(Offset(w * 0.82, h * 0.22), 15, Paint()..color = const Color(0xFFFEF08A));

    // Clouds
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    void drawCloud(double x, double y) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 44, height: 20), cloudPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 12, y - 5), width: 30, height: 22), cloudPaint);
    }
    drawCloud(w * 0.2, h * 0.18);
    drawCloud(w * 0.55, h * 0.24);

    // City Buildings in background
    final bldgPaint = Paint()..color = const Color(0xFFBAE6FD).withValues(alpha: 0.7);
    final winPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);

    void drawBldg(double x, double y, double bw, double bh) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, bw, bh), const Radius.circular(3)),
        bldgPaint,
      );
      for (double wy = y + 7; wy < y + bh - 8; wy += 12) {
        canvas.drawRect(Rect.fromLTWH(x + 4, wy, 6, 7), winPaint);
        if (bw > 22) canvas.drawRect(Rect.fromLTWH(x + bw - 10, wy, 6, 7), winPaint);
      }
    }

    drawBldg(w * 0.1, h * 0.32, 34, h * 0.45);
    drawBldg(w * 0.24, h * 0.20, 42, h * 0.57);
    drawBldg(w * 0.68, h * 0.28, 38, h * 0.49);

    // Trees
    canvas.drawCircle(Offset(w * 0.42, h * 0.66), 18, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(Offset(w * 0.47, h * 0.64), 15, Paint()..color = const Color(0xFF059669));
    canvas.drawCircle(Offset(w * 0.62, h * 0.67), 16, Paint()..color = const Color(0xFF047857));

    // Road (Dark Asphalt)
    final roadRect = Rect.fromLTWH(0, h * 0.74, w, h * 0.26);
    canvas.drawRect(roadRect, Paint()..color = const Color(0xFF334155));

    // Road Curb
    canvas.drawRect(Rect.fromLTWH(0, h * 0.73, w, 3), Paint()..color = const Color(0xFF94A3B8));

    // Dashed Road Lanes
    final dashPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (double dx = 10; dx < w; dx += 30) {
      canvas.drawLine(Offset(dx, h * 0.88), Offset(dx + 16, h * 0.88), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Live GPS Tracking Scene Graphic for Walkthrough Slide 2
class GpsTrackingSceneGraphic extends StatelessWidget {
  final double height;

  const GpsTrackingSceneGraphic({super.key, this.height = 190});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30059669),
            offset: Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            // Radar Grid Custom Painter
            Positioned.fill(
              child: CustomPaint(
                painter: _GpsRadarPainter(),
              ),
            ),

            // Top Status Pill
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SATELLITE GPS ACTIVE',
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF34D399),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40059669),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '~8 MINS ETA',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Truck Graphic navigating the route
            Positioned(
              left: 38,
              bottom: 24,
              child: Transform.scale(
                scale: 0.8,
                child: const SundoTruckGraphic(width: 120, height: 80),
              ),
            ),

            // User GPS Location Pin on Route
            Positioned(
              right: 48,
              top: 58,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x662563EB),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_pin, color: Colors.white, size: 16),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'You (350m)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w * 0.72, h * 0.48);

    // Concentric Radar Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, 35, ringPaint);
    canvas.drawCircle(center, 65, ringPaint);
    canvas.drawCircle(center, 95, ringPaint);
    canvas.drawCircle(center, 130, ringPaint);

    // Glowing Sipalay Highway Polyline
    final glowPath = Path()
      ..moveTo(0, h * 0.82)
      ..cubicTo(w * 0.28, h * 0.85, w * 0.45, h * 0.65, w * 0.65, h * 0.48)
      ..cubicTo(w * 0.78, h * 0.38, w * 0.88, h * 0.32, w, h * 0.28);

    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawPath(glowPath, glowPaint);

    final corePathPaint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(glowPath, corePathPaint);

    // Waypoint dots
    final nodePaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawCircle(Offset(w * 0.35, h * 0.78), 4, nodePaint);
    canvas.drawCircle(Offset(w * 0.55, h * 0.58), 4, nodePaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.35), 4, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Community Report & Zero Waste Scene Graphic for Walkthrough Slide 3
class ReportCommunitySceneGraphic extends StatelessWidget {
  final double height;

  const ReportCommunitySceneGraphic({super.key, this.height = 190});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFEFF6FF), Color(0xFFECFDF5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.8), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18059669),
            offset: Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Achievement & Eco-Points Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 15),
                        const SizedBox(width: 5),
                        Text(
                          'CENRO Certified Report',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x30D97706), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+50 Eco-Points',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Middle: 3 Segregation Clay Bins
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBin(
                    label: 'Biodegradable',
                    sub: 'Malata',
                    color: const Color(0xFF10B981),
                    bgColor: const Color(0xFFD1FAE5),
                    icon: Icons.eco_rounded,
                  ),
                  _buildBin(
                    label: 'Recyclable',
                    sub: 'Mabaligya',
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFDBEAFE),
                    icon: Icons.recycling_rounded,
                  ),
                  _buildBin(
                    label: 'Residual',
                    sub: 'Di-malata',
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    icon: Icons.delete_outline_rounded,
                  ),
                ],
              ),

              // Bottom Snap & Report Helper Pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded, color: Color(0xFF059669), size: 15),
                    const SizedBox(width: 6),
                    Text(
                      '1-Tap Photo Report • Real GPS Auto-Tagged',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBin({
    required String label,
    required String sub,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 64,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          sub,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Sundo Logo with Official Brand Graphic
class SundoLogoGraphic extends StatelessWidget {
  final double size;
  final bool showSubtitle;

  const SundoLogoGraphic({
    super.key,
    this.size = 110,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30059669),
                offset: Offset(0, 8),
                blurRadius: 20,
              ),
              BoxShadow(
                color: Colors.white,
                offset: Offset(-2, -2),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.22),
            child: Image.asset(
              'assets/images/sundo_logo.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SundoTruckGraphic(width: size * 1.3, height: size),
            ),
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 12),
          Text(
            'Smart Urban Navigation',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          Text(
            'for Dynamic Waste Operations',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }
}


