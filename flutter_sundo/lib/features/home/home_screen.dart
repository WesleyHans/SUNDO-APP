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
import '../../shared/widgets/time_based_background.dart';
import '../../shared/widgets/sundo_graphics.dart';
import '../live_map/widgets/map_tracking_widgets.dart';
import '../../shared/widgets/resident_components.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = 'Resident';
  String _barangay = '';
  int _unread = 0;
  String? _error;
  List<CollectionSchedule> _schedules = [];
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
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Collection information could not be refreshed.');
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
    final next = nextCollectionForResidentArea(_schedules, _barangay, mood.now);
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(padding: EdgeInsets.zero, children: [
                  SizedBox(
                      height: 142,
                      child: SundoTimeBasedBackground(
                          fullScene: true,
                          alignment: const Alignment(0, -.15),
                          child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: mood.isNight
                                          ? const [
                                              Color(0xEE142E35),
                                              Color(0x33233C48)
                                            ]
                                          : const [
                                              Color(0xCCF8FFF4),
                                              Color(0x11F4FFF2)
                                            ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight)),
                              padding:
                                  const EdgeInsets.fromLTRB(20, 22, 18, 22),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: SundoDynamicGreeting(
                                            firstName: firstName.isEmpty
                                                ? 'Resident'
                                                : firstName)),
                                    Semantics(
                                        label: 'Notifications, $_unread unread',
                                        button: true,
                                        child: IconButton(
                                            onPressed: () =>
                                                widget.onNavigate(3),
                                            icon: Badge(
                                                isLabelVisible: _unread > 0,
                                                label: Text(_unread.toString()),
                                                child: Icon(
                                                    Icons.notifications_rounded,
                                                    color: mood.textColor)))),
                                    const SizedBox(width: 5),
                                    InkWell(
                                        onTap: () => widget.onNavigate(4),
                                        borderRadius: BorderRadius.circular(30),
                                        child: CircleAvatar(
                                            radius: 22,
                                            backgroundColor:
                                                const Color(0xFF0B8F3E),
                                            foregroundColor: Colors.white,
                                            child: Text(initials,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w700))))
                                  ])))),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error != null)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(_error!,
                                      style: TextStyle(
                                          color: mood.accent, fontSize: 12))),
                            _nextCard(context, next),
                            const SizedBox(height: 14),
                            _truckCard(context),
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
                            SizedBox(
                                height: 103,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: SundoTimeBasedBackground(
                                        fullScene: true,
                                        child: Container(
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.all(17),
                                            color: mood.isNight
                                                ? const Color(0x99112E26)
                                                : const Color(0xAAEAF8EE),
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
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color:
                                                              mood.textColor)))
                                            ]))))),
                          ])),
                ]))));
  }

  Widget _nextCard(BuildContext context, CollectionSchedule? next) {
    final mood = SundoTimeScope.of(context);
    return InkWell(
        onTap: () => widget.onNavigate(2),
        borderRadius: BorderRadius.circular(18),
        child: SundoSurface(
            child: Row(children: [
          Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                  color: const Color(0xFF25B84A),
                  borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.calendar_month_rounded,
                  color: Colors.white, size: 28)),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Next Collection',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: mood.textColor)),
                const SizedBox(height: 3),
                Text(
                    next == null
                        ? (BackendService.live
                            ? 'No schedule published yet'
                            : 'No sample pickup for your area')
                        : DateFormat('EEEE, MMM d, yyyy').format(next.pickupAt),
                    style: TextStyle(fontSize: 11, color: mood.mutedTextColor)),
                if (next != null)
                  Text(next.timeLabel,
                      style: TextStyle(
                          fontSize: 12,
                          color: mood.accent,
                          fontWeight: FontWeight.w700))
              ])),
          Icon(Icons.chevron_right_rounded, color: mood.mutedTextColor)
        ])));
  }

  Widget _truckCard(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final truck = _truck;
    final fresh = truck?.freshAt(DateTime.now()) ?? false;
    final label = truck == null
        ? 'Awaiting fleet data'
        : fresh && (truck.active || truck.stage == MapTrackingStage.completed)
            ? switch (truck.stage) {
                MapTrackingStage.approaching => 'APPROACHING',
                MapTrackingStage.nearby => 'NEARBY',
                MapTrackingStage.completed => 'COMPLETED',
                MapTrackingStage.notStarted => 'NOT STARTED',
                _ => 'ON ROUTE'
              }
            : 'OFFLINE';
    final distance = truck?.distanceKm;
    final eta = truck?.etaMinutes;
    return SundoSurface(
        child: Column(children: [
      Row(children: [
        const SundoTruckGraphic(width: 45, height: 35),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Truck is $label',
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: mood.accent)),
          const SizedBox(height: 4),
          Text(
              truck == null
                  ? (BackendService.live
                      ? 'No position has been received.'
                      : 'Starting the sample route…')
                  : !fresh
                      ? 'Waiting for a current truck position.'
                      : '${distance == null ? 'Distance unavailable' : '${distance.toStringAsFixed(1)} km away'} · ${eta == null ? 'ETA unavailable' : 'ETA: $eta minutes'}',
              style: TextStyle(fontSize: 10, color: mood.mutedTextColor)),
          if (truck?.simulated ?? false)
            Text('Simulated collection · ${truck!.route.name}',
                style: TextStyle(fontSize: 9, color: mood.mutedTextColor))
        ]))
      ]),
      const SizedBox(height: 16),
      SundoRouteProgress(
          stage: truck?.stage ?? MapTrackingStage.notStarted,
          available: truck != null && fresh),
      const SizedBox(height: 16),
      SundoPrimaryButton(
          label: 'View Live Truck',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => widget.onNavigate(1))
    ]));
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
