import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/clay_theme.dart';
import '../widgets/sundo_graphics.dart';
import 'notifications_screen.dart';

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
      duration: const Duration(milliseconds: 1500),
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
            // Top App Bar / Resident Header
            _buildHeader(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Next Collection Card
                    _buildNextCollectionCard(context),

                    const SizedBox(height: 16),

                    // 2. Truck is ON ROUTE Card with 4-step progress tracker
                    _buildTruckOnRouteCard(context),

                    const SizedBox(height: 20),

                    // Quick Actions Section Title
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. 2x2 Quick Actions Grid
                    _buildQuickActionsGrid(context),

                    const SizedBox(height: 20),

                    // 4. Together for a Cleaner Sipalay Banner
                    _buildTogetherBanner(context),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Native Resident Header: Good Morning Juan + Sun + Bell + Profile Avatar
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting with Morning Sun
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Juan!',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _MorningSunGraphic(size: 26),
                ],
              ),
            ],
          ),

          // Action Icons: Notification Bell + User Avatar
          Row(
            children: [
              // Notification Bell with Red Badge
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: Color(0xFF334155),
                      ),
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

              // Juan's Circular Avatar with Emerald Border
              GestureDetector(
                onTap: () => widget.onNavigate(4), // Profile Tab
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF059669), width: 2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x20059669),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'JU',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
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

  // 2. Next Collection Card
  Widget _buildNextCollectionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onNavigate(3), // Navigate to Schedule tab
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: ClayTheme.card(radius: 20),
        child: Row(
          children: [
            // Calendar Green Icon Box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x25059669),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Collection Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Collection',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tuesday, Nov 12, 2024',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '8:00 AM - 12:00 PM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),

            // Chevron Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // 3. Truck is ON ROUTE Card with 4-step progress tracker & View Live Truck button
  Widget _buildTruckOnRouteCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: ClayTheme.card(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Truck Header Row
          Row(
            children: [
              // Mini Truck Graphic Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Center(
                  child: SundoTruckGraphic(width: 32, height: 24),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Truck is ',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          TextSpan(
                            text: 'ON ROUTE',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '1.2 km away • ETA: 8 minutes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Pulsing Active Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.6 * _pulseController.value),
                                blurRadius: 6 * _pulseController.value,
                                spreadRadius: 2 * _pulseController.value,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Active',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 4-Step Progress Track
          _buildProgressTracker(),

          const SizedBox(height: 18),

          // Primary Button: View Live Truck ->
          GestureDetector(
            onTap: () => widget.onNavigate(1), // Live Map
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: ClayTheme.buttonPrimary(radius: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Live Truck',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4-Step Route Progress Tracker Widget
  Widget _buildProgressTracker() {
    return Column(
      children: [
        Row(
          children: [
            // Node 1: Depot (Completed)
            _buildNode(isCompleted: true, isActive: false, icon: Icons.check),

            // Line 1: Green
            Expanded(
              child: Container(
                height: 3,
                color: const Color(0xFF059669),
              ),
            ),

            // Node 2: Current Truck (Active Pulsing)
            _buildNode(isCompleted: false, isActive: true, icon: Icons.local_shipping),

            // Line 2: Inactive Gray
            Expanded(
              child: Container(
                height: 3,
                color: const Color(0xFFE2E8F0),
              ),
            ),

            // Node 3: Mid-point Stop
            _buildNode(isCompleted: false, isActive: false, icon: null),

            // Line 3: Inactive Gray
            Expanded(
              child: Container(
                height: 3,
                color: const Color(0xFFE2E8F0),
              ),
            ),

            // Node 4: Destination / Home
            _buildNode(isCompleted: false, isActive: false, icon: Icons.home_rounded),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStepLabel('Depot', isHighlighted: true),
            _buildStepLabel('En Route', isHighlighted: true),
            _buildStepLabel('Brgy 1', isHighlighted: false),
            _buildStepLabel('Your Street', isHighlighted: false),
          ],
        ),
      ],
    );
  }

  Widget _buildNode({required bool isCompleted, required bool isActive, IconData? icon}) {
    if (isActive) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.5 * _pulseController.value),
                  blurRadius: 8 * _pulseController.value,
                  spreadRadius: 3 * _pulseController.value,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.local_shipping_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    }

    if (isCompleted) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFF059669),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.check,
            size: 14,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 12, color: const Color(0xFF94A3B8))
            : Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLabel(String text, {required bool isHighlighted}) {
    return SizedBox(
      width: 64,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
          color: isHighlighted ? const Color(0xFF059669) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  // 4. 2x2 Quick Actions Grid
  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Action 1: Collection Schedule (Amber)
            Expanded(
              child: _buildQuickActionCard(
                title: 'Collection Schedule',
                subtitle: "View area schedule",
                icon: Icons.calendar_today_rounded,
                iconBgColor: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                onTap: () => widget.onNavigate(3), // Schedule Tab
              ),
            ),
            const SizedBox(width: 12),

            // Action 2: Report Concern (Red)
            Expanded(
              child: _buildQuickActionCard(
                title: 'Report Concern',
                subtitle: 'Submit missed pickup',
                icon: Icons.error_outline_rounded,
                iconBgColor: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFEF4444),
                onTap: () => widget.onNavigate(2), // Report Tab
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Action 3: Notifications (Blue)
            Expanded(
              child: _buildQuickActionCard(
                title: 'Notifications',
                subtitle: 'Truck alerts & notices',
                icon: Icons.notifications_none_rounded,
                iconBgColor: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF2563EB),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(onBack: () => Navigator.pop(context)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Action 4: Waste Guide (Green)
            Expanded(
              child: _buildQuickActionCard(
                title: 'Waste Guide',
                subtitle: 'Segregation tips',
                icon: Icons.recycling_rounded,
                iconBgColor: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF059669),
                onTap: () => _showWasteGuideModal(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: ClayTheme.card(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 5. Together for a Cleaner Sipalay Banner
  Widget _buildTogetherBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: ClayTheme.cardMint(radius: 22),
      child: Row(
        children: [
          // Eco Leaves Circle Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10059669),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Center(
              child: Text(
                '🌿',
                style: TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Text Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Together for a',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF065F46),
                  ),
                ),
                Text(
                  'Cleaner Sipalay',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF047857),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'City Environment & Natural Resources Office (CENRO)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF059669),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Waste Guide Modal Sheet
  void _showWasteGuideModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.recycling_rounded, color: Color(0xFF059669), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waste Segregation Guide',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Sipalay City Solid Waste Management Ordinance',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4 Categories
              _buildWasteCategoryItem(
                badge: 'BIODEGRADABLE (Nabubulok)',
                badgeColor: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                description: 'Food scraps, fruit peelings, garden leaves, left-overs.',
                schedule: 'Collected every Mon, Wed, Fri',
              ),
              const SizedBox(height: 10),
              _buildWasteCategoryItem(
                badge: 'RECYCLABLE (Nareresiklo)',
                badgeColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                description: 'Plastic bottles, glass containers, clean paper & cardboard, aluminum cans.',
                schedule: 'Collected every Tuesday & Thursday',
              ),
              const SizedBox(height: 10),
              _buildWasteCategoryItem(
                badge: 'RESIDUAL (Di-nabubulok)',
                badgeColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                description: 'Sachets, snack wrappers, soiled plastic, worn fabric, ceramics.',
                schedule: 'Collected every Saturday',
              ),
              const SizedBox(height: 10),
              _buildWasteCategoryItem(
                badge: 'SPECIAL / HAZARDOUS',
                badgeColor: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEF2F2),
                description: 'Batteries, electronics, paint cans, fluorescent tubes, broken glass.',
                schedule: 'Special designated drop-off or quarterly dispatch',
              ),

              const SizedBox(height: 20),

              // Action button
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      'Understood',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWasteCategoryItem({
    required String badge,
    required Color badgeColor,
    required Color bgColor,
    required String description,
    required String schedule,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.schedule, size: 12, color: badgeColor),
              const SizedBox(width: 4),
              Text(
                schedule,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter for radiant Morning Sun beside Juan's greeting
class _MorningSunGraphic extends StatelessWidget {
  final double size;

  const _MorningSunGraphic({this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MorningSunPainter(),
      ),
    );
  }
}

class _MorningSunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32;

    // Glowing Sun Ray Paint
    final rayPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw 8 stylized rays
    const int rays = 8;
    final rayStartDist = radius + 2.5;
    final rayLength = size.width * 0.14;

    for (int i = 0; i < rays; i++) {
      final angle = (i * 2 * math.pi) / rays;
      final start = Offset(
        center.dx + math.cos(angle) * rayStartDist,
        center.dy + math.sin(angle) * rayStartDist,
      );
      final end = Offset(
        center.dx + math.cos(angle) * (rayStartDist + rayLength),
        center.dy + math.sin(angle) * (rayStartDist + rayLength),
      );
      canvas.drawLine(start, end, rayPaint);
    }

    // Outer subtle sun glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 1.5, glowPaint);

    // Sun Core Gradient
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sunPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
