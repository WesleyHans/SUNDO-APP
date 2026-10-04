import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/clay_theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _locationAllowed = true;

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'About SUNDO',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SUNDO (Smart Urban Navigation for Dynamic Waste Operations) is the official solid waste tracking platform for Sipalay City, Negros Occidental.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: ClayTheme.badge(bgColor: const Color(0xFFECFDF5), borderColor: const Color(0xFFA7F3D0)),
              child: Text(
                'Version 1.0.0 (Official Release)',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF065F46)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationToggle('Truck Approaching (10m)', true),
            _buildNotificationToggle('Route Rescheduling', true),
            _buildNotificationToggle('Weekly Schedule Reminder', true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Save Preferences', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF059669),
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Help & Support',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sipalay City Environment and Natural Resources Office (CENRO)',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text('📞 Hotline: (034) 473-2100', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569))),
            Text('✉️ Email: cenro@sipalaycity.gov.ph', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569))),
            Text('🏢 Office: City Hall Compound, Sipalay City', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF475569)),
            onPressed: _showAboutDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        child: Column(
          children: [
            // User Mint Card (.clay-card-mint)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: ClayTheme.cardMint(radius: 24),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x35059669),
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'JD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Juan Dela Cruz',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF064E3B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'juan@gmail.com',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF475569),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '0912 345 6789',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF059669),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Settings & Menu Items Card (.clay-card)
            Container(
              decoration: ClayTheme.card(radius: 22),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    subtitle: 'Barangay 1, Sipalay City',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Saved Addresses',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notification Settings',
                    onTap: _showNotificationDialog,
                  ),
                  const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.navigation_outlined,
                    title: 'Location Permission',
                    subtitle: _locationAllowed ? 'Allowed' : 'Disabled',
                    subtitleColor: _locationAllowed ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                    onTap: () {
                      setState(() {
                        _locationAllowed = !_locationAllowed;
                      });
                    },
                  ),
                  const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: _showHelpDialog,
                  ),
                  const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About SUNDO',
                    onTap: _showAboutDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button (.clay-button-secondary with red text)
            GestureDetector(
              onTap: widget.onLogout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: ClayTheme.buttonSecondary(radius: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFE11D48),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF059669), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: subtitleColor ?? const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
