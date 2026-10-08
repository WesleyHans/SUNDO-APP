import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/map_tracking.dart';
import '../../repositories/map_truck_repository.dart';
import '../../repositories/schedule_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../core/storage/app_store.dart';
import '../../services/backend_service.dart';
import '../../core/theme/time_theme.dart';
import '../../core/utils/resident_area.dart';
import '../../shared/widgets/resident_components.dart';
import '../../shared/widgets/weather_status_banner.dart';
import 'home_collection_notice.dart';
import 'home_location_card.dart';
import 'widgets/sundo_dashboard_widgets.dart';
import 'widgets/sundo_card_scenery.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  final bool isActive;
  const HomeScreen({super.key, required this.onNavigate, this.isActive = true});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = 'Resident';
  String _barangay = '';
  int _unread = 0;
  String? _error;
  List<CollectionSchedule> _schedules = [];
  bool _schedulesLoaded = false;
  bool _schedulesFailed = false;
  MapTruckSnapshot? _truck;
  StreamSubscription<List<MapTruckSnapshot>>? _fleet;
  Timer? _refreshTimer;
  late final NotificationRepository _notifications;
  @override
  void initState() {
    super.initState();
    _notifications = BackendService.live
        ? LocalNotificationRepository.shared
        : MockNotificationRepository.shared;
    _notifications.revision.addListener(_loadUnread);
    _load();
    _loadUnread();
    final MapTruckRepository repository = BackendService.live
        ? SupabaseMapTruckRepository(BackendService.client)
        : MockMapTruckRepository.shared;
    _fleet = repository.watchTrucks().listen((trucks) {
      if (mounted) {
        setState(() => _truck = trucks.isEmpty ? null : trucks.first);
      }
    }, onError: (_) {
      if (mounted) {
        setState(
            () => _error = 'Fleet update unavailable. Pull down to retry.');
      }
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  Future<void> _load() async {
    try {
      final name = await AppStore.getName();
      final barangay = await AppStore.getBarangay();
      final ScheduleRepository repo = BackendService.live
          ? SupabaseScheduleRepository()
          : MockScheduleRepository.shared;
      final rows = await repo.load();
      if (mounted) {
        setState(() {
          _name = name;
          _barangay = barangay;
          _schedules = rows;
          _schedulesLoaded = true;
          _schedulesFailed = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _schedulesLoaded = true;
          _schedulesFailed = true;
          _error = 'Collection information could not be refreshed.';
        });
      }
    }
  }

  Future<void> _loadUnread() async {
    final items = await _notifications.load();
    final read = await _notifications.readIds();
    if (mounted) {
      setState(() =>
          _unread = items.where((notice) => !read.contains(notice.id)).length);
    }
  }

  @override
  void dispose() {
    _fleet?.cancel();
    _refreshTimer?.cancel();
    _notifications.revision.removeListener(_loadUnread);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final firstName = _name.trim().split(' ').first;
    final initials = _name.trim().isEmpty
        ? 'S'
        : _name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part[0])
            .join()
            .toUpperCase();
    final next = nextCollectionForResidentArea(_schedules, _barangay,
        BackendService.live ? mood.now : mood.localTime);
    return SundoDashboardMotion(
        isActive: widget.isActive,
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
                // The demo banner in the shell already reserves the status bar.
                top: BackendService.live,
                bottom: false,
                child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(padding: EdgeInsets.zero, children: [
                      Container(
                          constraints: const BoxConstraints(minHeight: 104),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [
                                mood.sky.withValues(alpha: .24),
                                mood.sky.withValues(alpha: 0)
                              ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter)),
                          padding: EdgeInsets.zero,
                          child: SundoGreetingHeader(
                              firstName:
                                  firstName.isEmpty ? 'Resident' : firstName,
                              initials: initials,
                              unread: _unread,
                              onNotifications: () => widget.onNavigate(3),
                              onProfile: () => widget.onNavigate(4))),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SundoDashboardEntrance(
                                    key: const ValueKey('sundo-weather-entrance'),
                                    isActive: widget.isActive,
                                    child: const SundoWeatherStatusBanner(
                                        dashboardStyle: true)),
                                if (_error != null)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Text(_error!,
                                          style: TextStyle(
                                              color: mood.accent,
                                              fontSize: 12))),
                                SundoDashboardEntrance(
                                    key: const ValueKey('sundo-info-entrance'),
                                    order: 1,
                                    isActive: widget.isActive,
                                    child: _collectionCards(context, next)),
                                const SizedBox(height: 12),
                                SundoDashboardEntrance(
                                    key: const ValueKey('sundo-truck-entrance'),
                                    order: 2,
                                    isActive: widget.isActive,
                                    child: SundoLiveTruckCard(
                                        truck: _truck,
                                        onViewMap: () => widget.onNavigate(1))),
                                const SizedBox(height: 14),
                                HomeLocationCard(
                                    key: const ValueKey('sundo-home-location'),
                                    isActive: widget.isActive,
                                    onOpenMap: () => widget.onNavigate(1)),
                                const SizedBox(height: 20),
                                Text('Quick Actions',
                                    style: GoogleFonts.outfit(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: mood.textColor)),
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(
                                      child: SundoQuickActionCard(
                                          title: 'Collection Schedule',
                                          icon: Icons.calendar_month_rounded,
                                          color: const Color(0xFFF4A623),
                                          onTap: () => widget.onNavigate(2))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: SundoQuickActionCard(
                                          title: 'Report Concern',
                                          icon: Icons.error_outline_rounded,
                                          color: const Color(0xFFDC3B3B),
                                          onTap: () => context.push('/report')))
                                ]),
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(
                                      child: SundoQuickActionCard(
                                          title: 'Notifications',
                                          icon: Icons.notifications_rounded,
                                          color: const Color(0xFF2F80ED),
                                          onTap: () => widget.onNavigate(3))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: SundoQuickActionCard(
                                          title: 'Waste Guide',
                                          icon: Icons.menu_book_rounded,
                                          color: const Color(0xFF25B84A),
                                          onTap: () => _wasteGuide(context)))
                                ]),
                                const SizedBox(height: 22),
                                SundoSurface(
                                    radius: 20,
                                    padding: const EdgeInsets.all(17),
                                    child: Row(children: [
                                      Icon(Icons.eco_rounded,
                                          size: 40, color: mood.accent),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(
                                              'Together for a\nCleaner Sipalay',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 19,
                                                  height: 1.15,
                                                  fontWeight: FontWeight.w800,
                                                  color: mood.textColor)))
                                    ])),
                              ])),
                    ])))));
  }

  Widget _collectionCards(BuildContext context, CollectionSchedule? next) {
    final notice = HomeCollectionNotice(
        schedules: _schedules,
        area: _barangay,
        isDemo: !BackendService.live,
        loaded: _schedulesLoaded,
        failed: _schedulesFailed,
        dashboardStyle: true,
        onOpenSchedule: () => widget.onNavigate(2));
    final collection = _nextCard(context, next);
    return LayoutBuilder(builder: (context, constraints) {
      // Preserve the reference row at phone widths. Large accessibility text
      // gets full-width cards instead of cramped columns or clipped labels.
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      if (constraints.maxWidth / scale < 245) {
        return Column(
            key: const ValueKey('sundo-home-info-stack'),
            children: [notice, const SizedBox(height: 12), collection]);
      }
      return IntrinsicHeight(
          child: Row(
              key: const ValueKey('sundo-home-info-row'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Expanded(child: notice),
            const SizedBox(width: 10),
            Expanded(child: collection)
          ]));
    });
  }

  Widget _nextCard(BuildContext context, CollectionSchedule? next) {
    final pickup = next == null
        ? null
        : BackendService.live
            ? next.pickupAt.toUtc().add(const Duration(hours: 8))
            : next.pickupAt;
    return SundoInfoCard(
        scenery: SundoCardScene.nextCollectionPark,
        title: 'Next Collection',
        subtitle: _schedulesFailed
            ? 'Schedule unavailable. Pull down to retry.'
            : !_schedulesLoaded
                ? 'Checking your collection schedule…'
                : next == null
                    ? (BackendService.live
                        ? 'No schedule published yet'
                        : 'No sample pickup for your area')
                    : DateFormat('EEEE, MMM d, yyyy').format(pickup!),
        icon: Icons.calendar_month_rounded,
        timeLabel: next == null
            ? null
            : BackendService.live
                ? DateFormat('h:mm a').format(pickup!)
                : next.timeLabel,
        onTap: () => widget.onNavigate(2));
  }

  void _wasteGuide(BuildContext context) {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Waste Segregation Guide',
                          style: GoogleFonts.outfit(
                              fontSize: 23, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text(
                          'Separate waste before collection and follow your barangay’s published instructions.'),
                      const SizedBox(height: 12),
                      const ListTile(
                          leading: Icon(Icons.eco, color: Colors.green),
                          title: Text('Biodegradable'),
                          subtitle: Text(
                              'Food scraps, leaves and compostable garden waste.')),
                      const ListTile(
                          leading: Icon(Icons.recycling, color: Colors.blue),
                          title: Text('Recyclable'),
                          subtitle: Text(
                              'Clean paper, cardboard, glass, cans and accepted plastics.')),
                      const ListTile(
                          leading:
                              Icon(Icons.delete_outline, color: Colors.orange),
                          title: Text('Residual'),
                          subtitle: Text(
                              'Non-recyclable packaging and other ordinary dry waste.')),
                      const ListTile(
                          leading: Icon(Icons.warning_amber, color: Colors.red),
                          title: Text('Special waste'),
                          subtitle: Text(
                              'Keep batteries, chemicals, sharp objects and e-waste separate. Ask city staff about safe drop-off.')),
                      const SizedBox(height: 14),
                      SundoPrimaryButton(
                          label: 'Got it',
                          onPressed: () => Navigator.pop(context))
                    ]))));
  }
}
