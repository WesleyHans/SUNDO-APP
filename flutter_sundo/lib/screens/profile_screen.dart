import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/clay_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Resident Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar & Badge Card (.clay-card)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: ClayTheme.card(radius: 26),
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40059669),
                          offset: Offset(4, 6),
                          blurRadius: 14,
                        ),
                        BoxShadow(
                          color: Colors.white,
                          offset: Offset(-3, -3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'JU',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Juan Dela Cruz',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'juan.delacruz@sipalaycity.gov.ph',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                    decoration: ClayTheme.badge(
                      bgColor: const Color(0xFFECFDF5),
                      borderColor: const Color(0xFFA7F3D0),
                    ),
                    child: Text(
                      'Verified Citizen • Resident ID #SP-9921',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF065F46),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings Tiles (.clay-card)
            _clayTile(Icons.location_on_outlined, 'Registered Address', 'Purok Mangga, Barangay 1'),
            _clayTile(Icons.notifications_active_outlined, 'Proximity Alerts', 'Active (500m radius)'),
            _clayTile(Icons.history_rounded, 'My Submitted Reports', '3 Resolved • 1 Scheduled'),
            _clayTile(Icons.eco_rounded, 'Eco-Citizen Points', '240 Green Points (Level 3)'),
            _clayTile(Icons.shield_outlined, 'Privacy & City Terms', 'RA 9003 Solid Waste Management Act'),

            const SizedBox(height: 24),
            Text(
              'SUNDO Mobile v1.0.0 (Official Native APK)\nCity Environment and Natural Resources Office (CENRO)\nCity Government of Sipalay, Negros Occidental',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF94A3B8),
                fontSize: 11,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _clayTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: ClayTheme.card(radius: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF059669), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}
