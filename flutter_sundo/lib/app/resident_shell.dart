import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/live_map/live_map_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/profile_screen.dart';
import '../services/backend_service.dart';
import '../repositories/notification_repository.dart';
import '../shared/widgets/resident_components.dart';
import '../core/theme/time_theme.dart';
import '../shared/widgets/sundo_tab_stack.dart';
import '../shared/widgets/resident_header.dart';

class MainNavigationShell extends StatefulWidget {
  final VoidCallback onLogout;
  const MainNavigationShell({super.key, required this.onLogout});
  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _index = 0;
  int _unread = 0;
  final Set<int> _visited = {0};
  final _headerController = ResidentHeaderController();
  late final NotificationRepository _notifications;
  @override
  void initState() {
    super.initState();
    _notifications = BackendService.live
        ? LocalNotificationRepository.shared
        : MockNotificationRepository.shared;
    _notifications.revision.addListener(_refreshUnread);
    _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    final items = await _notifications.load();
    final read = await _notifications.readIds();
    if (mounted) {
      setState(() =>
          _unread = items.where((item) => !read.contains(item.id)).length);
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _notifications.revision.removeListener(_refreshUnread);
    super.dispose();
  }

  void _navigate(int index) => setState(() {
        _index = index;
        _visited.add(index);
      });
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final screens = [
      HomeScreen(onNavigate: _navigate),
      _visited.contains(1)
          ? LiveMapScreen(isActive: _index == 1)
          : const SizedBox.shrink(),
      _visited.contains(2) ? const ScheduleScreen() : const SizedBox.shrink(),
      _visited.contains(3)
          ? const NotificationsScreen()
          : const SizedBox.shrink(),
      _visited.contains(4)
          ? ProfileScreen(onLogout: widget.onLogout)
          : const SizedBox.shrink()
    ];
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
            bottom: false,
            child: Column(children: [
              if (!BackendService.live)
                Container(
                    width: double.infinity,
                    color: mood.isNight
                        ? const Color(0xFF34402A)
                        : const Color(0xFFEAF8EE),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Text(
                        'LOCAL DEMO · Sample fleet and schedules · Reports stay on this phone',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 9,
                            color: mood.isNight
                                ? const Color(0xFFD7E5B9)
                                : const Color(0xFF427045)))),
              SundoResidentHeader(controller: _headerController, index: _index),
              Expanded(
                  child: SundoTabStack(index: _index, children: [
                for (var i = 0; i < screens.length; i++)
                  ResidentHeaderScope(
                      controller: _headerController,
                      index: i,
                      active: i == _index,
                      child: screens[i])
              ]))
            ])),
        bottomNavigationBar: SundoBottomNavigation(
            index: _index, onChanged: _navigate, unread: _unread));
  }
}
