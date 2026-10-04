import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_store.dart';
import '../theme/clay_theme.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String time;
  final String category; // 'Alerts' or 'Announcements'
  final String type; // 'alert', 'update', 'route', 'completed', 'special'

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.category,
    required this.type,
  });
}

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const NotificationsScreen({super.key, required this.onBack});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeFilter = 'All';
  Set<String> _readIds = {};

  final List<NotificationModel> _notifications = const [
    NotificationModel(
      id: '1',
      title: 'Truck Approaching',
      message: 'Truck #02 (Kuya Ronald) is ~8 mins away from Barangay 1. Please bring out segregated waste.',
      time: '5 mins ago',
      category: 'Alerts',
      type: 'alert',
    ),
    NotificationModel(
      id: '2',
      title: 'Route Delay Notice',
      message: 'Route Barangay Gil Montilla is experiencing a 15-minute delay due to rain.',
      time: '42 mins ago',
      category: 'Alerts',
      type: 'update',
    ),
    NotificationModel(
      id: '3',
      title: 'Collection Completed',
      message: 'Waste collection completed in Barangay 1 (Poblacion Central) on schedule.',
      time: '2 hours ago',
      category: 'Alerts',
      type: 'completed',
    ),
    NotificationModel(
      id: '4',
      title: 'Special Collection Scheduled',
      message: 'E-waste and hazardous materials collection this Saturday, 9 AM - 2 PM at CENRO depot.',
      time: 'Yesterday',
      category: 'Announcements',
      type: 'route',
    ),
    NotificationModel(
      id: '5',
      title: 'City Ordinance Reminder',
      message: 'No segregation, no collection policy strictly enforced by Sipalay City CENRO.',
      time: '2 days ago',
      category: 'Announcements',
      type: 'special',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadReadState();
  }

  Future<void> _loadReadState() async {
    final ids = await AppStore.getReadNotifications();
    if (mounted) {
      setState(() {
        _readIds = ids;
      });
    }
  }

  Widget _getIconForType(String type) {
    switch (type) {
      case 'alert':
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF1F2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF43F5E), size: 22),
        );
      case 'update':
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFECFDF5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF059669), size: 22),
        );
      case 'route':
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFFEF3C7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
        );
      case 'completed':
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFECFDF5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
        );
      case 'special':
      default:
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.campaign_rounded, color: Color(0xFF3B82F6), size: 22),
        );
    }
  }

  void _showNotificationDetail(NotificationModel item) async {
    await AppStore.markNotificationRead(item.id);
    await _loadReadState();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            _getIconForType(item.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(item.time, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          item.message,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: const Color(0xFF1E293B)),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _notifications.where((n) {
      if (_activeFilter == 'All') return true;
      return n.category == _activeFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28, color: Color(0xFF334155)),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AppStore.markAllNotificationsRead(_notifications.map((n) => n.id).toList());
              await _loadReadState();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read.')),
              );
            },
            child: Text(
              'Mark all read',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF059669),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Row(
              children: ['All', 'Alerts', 'Announcements'].map((tab) {
                final bool isActive = _activeFilter == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeFilter = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: isActive
                          ? ClayTheme.buttonPrimary(radius: 20)
                          : ClayTheme.buttonSecondary(radius: 20),
                      child: Text(
                        tab,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = filtered[index];
          final isRead = _readIds.contains(item.id);

          return GestureDetector(
            onTap: () => _showNotificationDetail(item),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFFA7F3D0),
                  width: isRead ? 1 : 1.5,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getIconForType(item.type),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.title,
                                      style: GoogleFonts.outfit(
                                        fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                        fontSize: 13.5,
                                        color: const Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isRead) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF059669),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              item.time,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.message,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
