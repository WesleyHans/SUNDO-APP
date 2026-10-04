import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_store.dart';
import '../theme/clay_theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Juan Dela Cruz';
  String _email = 'juan@gmail.com';
  String _phone = '0912 345 6789';
  String _barangay = 'Barangay 1';
  String _street = 'Poblacion Plaza Road';

  bool _locationAllowed = true;
  bool _truckApproachNotif = true;
  bool _rescheduleNotif = true;
  bool _weeklyReminderNotif = true;

  final List<String> _sipalayBarangays = [
    'Barangay 1 (Poblacion)',
    'Barangay 2 (Poblacion)',
    'Barangay 3 (Poblacion)',
    'Barangay 4 (Poblacion)',
    'Barangay 5 (Poblacion)',
    'Cabadiangan',
    'Camindangan',
    'Canturay',
    'Cartagena',
    'Cayhagan',
    'Gil Montilla',
    'Mambaroto',
    'Manlucahoc',
    'Maricalum',
    'Nabulao',
    'Nauhang',
    'San Jose',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _checkRealLocationPermission();
  }

  Future<void> _loadProfileData() async {
    final n = await AppStore.getName();
    final e = await AppStore.getEmail();
    final p = await AppStore.getPhone();
    final b = await AppStore.getBarangay();
    final s = await AppStore.getStreet();

    if (mounted) {
      setState(() {
        _name = n;
        _email = e;
        _phone = p;
        _barangay = b;
        _street = s;
      });
    }
  }

  Future<void> _checkRealLocationPermission() async {
    final perm = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        _locationAllowed = (perm == LocationPermission.always || perm == LocationPermission.whileInUse);
      });
    }
  }

  Future<void> _handleLocationPermissionTap() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    } else if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      await Future.delayed(const Duration(seconds: 1));
      perm = await Geolocator.checkPermission();
    }
    if (mounted) {
      setState(() {
        _locationAllowed = (perm == LocationPermission.always || perm == LocationPermission.whileInUse);
      });
    }
  }

  String _getInitials() {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'JU';
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Resident Profile', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newEmail = emailCtrl.text.trim();
                final newPhone = phoneCtrl.text.trim();
                if (newName.isNotEmpty) await AppStore.setName(newName);
                if (newEmail.isNotEmpty) await AppStore.setEmail(newEmail);
                if (newPhone.isNotEmpty) await AppStore.setPhone(newPhone);
                await _loadProfileData();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressDialog() {
    String selectedBgy = _barangay;
    final streetCtrl = TextEditingController(text: _street);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Edit Primary Address', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Barangay in Sipalay City:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _sipalayBarangays.contains(selectedBgy) ? selectedBgy : _sipalayBarangays[0],
                items: _sipalayBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedBgy = val);
                },
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              ),
              const SizedBox(height: 14),
              Text('Street / Sitio / Landmark:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: streetCtrl,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
              onPressed: () async {
                await AppStore.setBarangay(selectedBgy);
                await AppStore.setStreet(streetCtrl.text.trim());
                await _loadProfileData();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedAddressesSheet() async {
    final addresses = await AppStore.getSavedAddresses();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saved Addresses', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF059669)),
                    onPressed: () {
                      final labelCtrl = TextEditingController();
                      final addrCtrl = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Add Saved Address'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label (e.g. Work, Parents)')),
                              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address in Sipalay')),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () async {
                                if (labelCtrl.text.isNotEmpty && addrCtrl.text.isNotEmpty) {
                                  await AppStore.addSavedAddress(labelCtrl.text.trim(), addrCtrl.text.trim());
                                  final updated = await AppStore.getSavedAddresses();
                                  setSheetState(() => addresses..clear()..addAll(updated));
                                }
                                if (dCtx.mounted) Navigator.pop(dCtx);
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...addresses.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_rounded, color: Color(0xFF059669)),
                  title: Text(item['label'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['address'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                    onPressed: () async {
                      await AppStore.removeSavedAddress(idx);
                      final updated = await AppStore.getSavedAddresses();
                      setSheetState(() => addresses..clear()..addAll(updated));
                    },
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('About SUNDO', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Help & Support', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CENRO Sipalay City Hotline:\n(034) 473-0000 / 0917-123-4567', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Office: City Environment & Natural Resources Office, Sipalay City Hall.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: Color(0xFF059669)))),
        ],
      ),
    );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Notification Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationToggle('Truck Approaching (~8m)', _truckApproachNotif, (v) => setDialogState(() => _truckApproachNotif = v)),
              _buildNotificationToggle('Route Rescheduling', _rescheduleNotif, (v) => setDialogState(() => _rescheduleNotif = v)),
              _buildNotificationToggle('Weekly Schedule Reminder', _weeklyReminderNotif, (v) => setDialogState(() => _weeklyReminderNotif = v)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Save Preferences', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF059669),
            activeTrackColor: const Color(0xFFA7F3D0),
            onChanged: onChanged,
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Resident Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF059669), size: 26),
            onPressed: _showEditProfileSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        child: Column(
          children: [
            // Profile Header Card
            GestureDetector(
              onTap: _showEditProfileSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: ClayTheme.cardMint(radius: 24),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x35059669), offset: Offset(0, 4), blurRadius: 10),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _name,
                                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF064E3B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 14, color: Color(0xFF059669)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(_email, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569), fontSize: 11.5)),
                          const SizedBox(height: 2),
                          Text(_phone, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Settings & Menu Items
            Container(
              decoration: ClayTheme.card(radius: 22),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    subtitle: '$_street, $_barangay',
                    onTap: _showAddressDialog,
                  ),
                  const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Saved Addresses',
                    onTap: _showSavedAddressesSheet,
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
                    subtitleColor: _locationAllowed ? const Color(0xFF059669) : const Color(0xFFEF4444),
                    onTap: _handleLocationPermissionTap,
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

            // Logout Button
            GestureDetector(
              onTap: widget.onLogout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: ClayTheme.badge(
                  bgColor: const Color(0xFFFFF1F2),
                  borderColor: const Color(0xFFFECDD3),
                  radius: 20,
                ),
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor ?? const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
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
