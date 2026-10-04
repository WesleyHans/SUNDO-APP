import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../repositories/notification_repository.dart';
import '../../services/backend_service.dart';
import '../../core/theme/time_theme.dart';
import '../../shared/widgets/schedule_notification_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final NotificationRepository? repository;
  const NotificationsScreen({super.key, this.onBack, this.repository});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeFilter = 'All';
  Set<String> _readIds = {};
  List<SundoNotification> _notifications = [];
  late final NotificationRepository _repository;
  bool _loading = true;
  bool _remindersEnabled = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        (BackendService.live
            ? LocalNotificationRepository.shared
            : MockNotificationRepository.shared);
    _repository.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _repository.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await _repository.load();
      final read = await _repository.readIds();
      final reminders = await _repository.remindersEnabled();
      if (mounted) {
        setState(() {
          _notifications = rows;
          _readIds = read;
          _remindersEnabled = reminders;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load your notifications. Please retry.';
        });
      }
    }
  }

  String _timeLabel(DateTime time) {
    final duration = DateTime.now().difference(time);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes} minutes ago';
    if (duration.inHours < 24) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    if (duration.inDays == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(time)}';
    }
    return DateFormat('MMM d, h:mm a').format(time);
  }

  Future<void> _showDetail(SundoNotification item) async {
    await _repository.markRead(item.id);
    if (!mounted) return;
    final mood = SundoTimeScope.of(context);
    final (_, accent, icon) = SundoNotificationCard.palette(item.type);
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: mood.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              title: Row(children: [
                Icon(icon, color: accent),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(item.title,
                        style: GoogleFonts.outfit(
                            color: mood.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)))
              ]),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.message,
                        style: GoogleFonts.plusJakartaSans(
                            color: mood.textColor, fontSize: 13, height: 1.6)),
                    const SizedBox(height: 14),
                    Text(_timeLabel(item.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: mood.mutedTextColor)),
                    if (_repository.isDemo)
                      Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text('Sample notification for the demo.',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11, color: mood.mutedTextColor))),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ],
            ));
  }

  Future<void> _settings() async {
    final mood = SundoTimeScope.of(context);
    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: mood.surface,
        builder: (context) => StatefulBuilder(
            builder: (context, setSheetState) => SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notification Settings',
                                style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: mood.textColor)),
                            const SizedBox(height: 12),
                            SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Truck approaching alerts',
                                    style: GoogleFonts.plusJakartaSans(
                                        color: mood.textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                    'Show an alert while you track the truck.',
                                    style: GoogleFonts.plusJakartaSans(
                                        color: mood.mutedTextColor,
                                        fontSize: 11)),
                                value: _remindersEnabled,
                                activeTrackColor: const Color(0xFF0B8F3E),
                                onChanged: (value) async {
                                  await _repository.setRemindersEnabled(value);
                                  if (context.mounted) {
                                    setSheetState(
                                        () => _remindersEnabled = value);
                                  }
                                }),
                            const SizedBox(height: 8),
                            Text(
                                'You can still read collection and route updates here when alerts are off.',
                                style: GoogleFonts.plusJakartaSans(
                                    color: mood.mutedTextColor,
                                    fontSize: 11,
                                    height: 1.5)),
                          ])),
                )));
  }

  Future<void> _markAllRead() async {
    await _repository.markAllRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final filtered = _notifications
        .where(
            (item) => _activeFilter == 'All' || item.category == _activeFilter)
        .toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: mood.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: widget.onBack == null
            ? null
            : IconButton(
                tooltip: 'Back',
                onPressed: widget.onBack,
                icon: Icon(Icons.chevron_left_rounded, color: mood.textColor)),
        title: Text('Notifications',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: mood.textColor)),
        actions: [
          IconButton(
              tooltip: 'Mark all read',
              onPressed: _notifications.isEmpty ? null : _markAllRead,
              icon: Icon(Icons.done_all_rounded, size: 20, color: mood.accent)),
          IconButton(
              tooltip: 'Notification settings',
              onPressed: _settings,
              icon: Icon(Icons.tune_rounded, size: 20, color: mood.accent))
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: SundoSegmentedTabs(
                    labels: const ['All', 'Alerts', 'Announcements'],
                    selected: _activeFilter,
                    onSelected: (tab) => setState(() => _activeFilter = tab)))),
      ),
      body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                if (_repository.isDemo)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text('Demo notifications · sample messages',
                          style: GoogleFonts.plusJakartaSans(
                              color: mood.mutedTextColor, fontSize: 10.5))),
                if (_loading)
                  const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()))
                else if (_error != null)
                  Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        Text(_error!, style: TextStyle(color: mood.textColor)),
                        TextButton(onPressed: _load, child: const Text('Retry'))
                      ]))
                else if (filtered.isEmpty)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Column(children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 44, color: mood.accent),
                        const SizedBox(height: 12),
                        Text('No notifications yet',
                            style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: mood.textColor)),
                        const SizedBox(height: 8),
                        Text('Collection updates will appear here.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: mood.mutedTextColor))
                      ]))
                else
                  for (final item in filtered) ...[
                    SundoNotificationCard(
                        item: item,
                        isRead: _readIds.contains(item.id),
                        timeLabel: _timeLabel(item.createdAt),
                        onTap: () => _showDetail(item)),
                    const SizedBox(height: 12),
                  ],
              ])),
    );
  }
}
