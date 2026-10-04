import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/clay_theme.dart';
import 'notifications_screen.dart';
import 'truck_alert_modal.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Native Resident Mobile Header (Frosted White with Clay Buttons)
            _buildMobileHeader(context),

            // 2. Scrollable Claymorphic Feed
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Card: Dynamic Waste Operations (.clay-card-mint)
                    _buildHeroMintCard(context),

                    const SizedBox(height: 18),

                    // Collection Activity (.clay-card)
                    _buildCollectionActivityCard(context),

                    const SizedBox(height: 18),

                    // My Reports Summary (.clay-card with tactile chips)
                    _buildReportsSummaryCard(context),

                    const SizedBox(height: 18),

                    // Collection Schedule (.clay-card)
                    _buildScheduleCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Clean Native Resident Header
  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    'SIPALAY RESIDENT',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF065F46),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Good day, Juan!',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Color(0xFF059669)),
                  const SizedBox(width: 3),
                  Text(
                    'Barangay 1, Sipalay City',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Clay Buttons: Notifications + Profile
          Row(
            children: [
              // Notification Bell (.clay-button-secondary)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(onBack: () => Navigator.pop(context)),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: ClayTheme.buttonSecondary(radius: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_outlined, size: 22, color: Color(0xFF334155)),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // User Avatar JU
              GestureDetector(
                onTap: () => widget.onNavigate(4), // Profile
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40059669),
                        offset: Offset(4, 4),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.white,
                        offset: Offset(-2, -2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'JU',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Hero Card (.clay-card-mint) with large 3D Clay Button
  Widget _buildHeroMintCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: ClayTheme.cardMint(radius: 26),
      child: Column(
        children: [
          Text(
            'DYNAMIC WASTE OPERATIONS',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF065F46),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Spotted uncollected garbage?',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Submit photo and GPS location to trigger dispatch and route scheduling.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF475569),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Prominent Clay Button Primary (.clay-button-primary)
          GestureDetector(
            onTap: () => widget.onNavigate(2), // Report Screen
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: ClayTheme.buttonPrimary(radius: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle, size: 22, color: Colors.white),
                  const SizedBox(width: 9),
                  Text(
                    'REPORT GARBAGE',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Collection Activity Card (.clay-card)
  Widget _buildCollectionActivityCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: ClayTheme.card(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Animated Pulsing Radar Beacon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.6 * _pulseController.value),
                              blurRadius: 8 * _pulseController.value,
                              spreadRadius: 2.5 * _pulseController.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'COLLECTION ACTIVITY',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: ClayTheme.badge(
                  bgColor: const Color(0xFFECFDF5),
                  borderColor: const Color(0xFFA7F3D0),
                ),
                child: Text(
                  'Vehicle Active',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF065F46),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Inner Truck Card (.clay-input / inset box)
          InkWell(
            onTap: () {
              TruckAlertModal.show(
                context,
                etaMinutes: 10,
                onViewTruck: () => widget.onNavigate(1), // Live Map
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: ClayTheme.insetBox(radius: 18),
              child: Row(
                children: [
                  // Emerald Truck Icon Container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Color(0xFF059669),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Truck 02 (Kuya Ronald)',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Currently near Barangay 1',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ETA to your street: ~8 minutes',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF059669),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow Button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: ClayTheme.buttonSecondary(radius: 18),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. My Reports Summary (.clay-card with tactile status chips)
  Widget _buildReportsSummaryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: ClayTheme.card(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MY REPORTS SUMMARY',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: () => widget.onNavigate(2),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFF059669)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5 Tactile Status Chips
          Row(
            children: [
              _buildClayChip('1', 'Pending', const Color(0xFFFFFBEB), const Color(0xFFFDE68A), const Color(0xFFF59E0B), const Color(0xFF92400E)),
              const SizedBox(width: 7),
              _buildClayChip('1', 'Verified', const Color(0xFFEFF6FF), const Color(0xFFBFDBFE), const Color(0xFF3B82F6), const Color(0xFF1E40AF)),
              const SizedBox(width: 7),
              _buildClayChip('1', 'Scheduled', const Color(0xFFECFDF5), const Color(0xFFA7F3D0), const Color(0xFF10B981), const Color(0xFF065F46)),
              const SizedBox(width: 7),
              _buildClayChip('1', 'Collected', const Color(0xFFF0FDF4), const Color(0xFFBBF7D0), const Color(0xFF22C55E), const Color(0xFF166534)),
              const SizedBox(width: 7),
              _buildClayChip('0', 'Rejected', const Color(0xFFFFF1F2), const Color(0xFFFECDD3), const Color(0xFFF43F5E), const Color(0xFF9F1239)),
            ],
          ),
          const SizedBox(height: 14),

          // Recent Report Preview Card (.clay-input / inset box)
          GestureDetector(
            onTap: () => widget.onNavigate(2),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: ClayTheme.insetBox(radius: 18),
              child: Row(
                children: [
                  // Colored Waste Bins Thumbnail Box
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.delete_outline, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Report details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUNDO-2026-000120 • Household Waste',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Poblacion Plaza Road, Barangay 1',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Scheduled Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                    decoration: ClayTheme.badge(
                      bgColor: const Color(0xFFCCFBF1),
                      borderColor: const Color(0xFF99F6E4),
                    ),
                    child: Text(
                      'Scheduled',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF0F766E),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Status Chip Builder
  Widget _buildClayChip(
    String count,
    String label,
    Color bgColor,
    Color borderColor,
    Color shadowColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: ClayTheme.statusChip(
          bgColor: bgColor,
          borderColor: borderColor,
          shadowColor: shadowColor,
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: textColor.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Collection Schedule Card (.clay-card)
  Widget _buildScheduleCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: ClayTheme.card(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COLLECTION SCHEDULE',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Barangay 1',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          InkWell(
            onTap: () => widget.onNavigate(3), // Schedules
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: ClayTheme.insetBox(radius: 18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mon, Wed, Fri • 7:00 AM - 10:30 AM',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Biodegradable & Household Waste',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Truck 02 (Kuya Ronald)',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF059669),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
