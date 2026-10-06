import '../../shared/widgets/resident_content.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../repositories/schedule_repository.dart';
import '../../services/backend_service.dart';
import '../../core/theme/clay_theme.dart';
import '../../core/theme/time_theme.dart';
import '../../shared/widgets/schedule_notification_widgets.dart';

class ScheduleScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final ScheduleRepository? repository;
  final String initialTab;
  const ScheduleScreen(
      {super.key, this.onBack, this.repository, this.initialTab = 'Today'});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _activeTab = 'Today';
  late DateTime _selectedDate;
  late DateTime _selectedMonth;
  late final ScheduleRepository _repository;
  List<CollectionSchedule> _schedules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    final now = widget.repository is MockScheduleRepository
        ? (widget.repository as MockScheduleRepository).referenceDate
        : DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedMonth = DateTime(now.year, now.month);
    _repository = widget.repository ??
        (BackendService.live
            ? SupabaseScheduleRepository()
            : MockScheduleRepository.shared);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repository.load();
      if (mounted) setState(() => _schedules = rows);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Could not load collection schedules. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return SundoResidentContent(
      actions: [
        if (widget.onBack != null)
          IconButton(
              tooltip: 'Back',
              onPressed: widget.onBack,
              icon: Icon(Icons.chevron_left_rounded, color: mood.textColor)),
        IconButton(
            tooltip: 'Refresh schedules',
            onPressed: _loading ? null : _load,
            icon: Icon(Icons.refresh_rounded, size: 20, color: mood.accent))
      ],
      filters: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: SundoSegmentedTabs(
              labels: const ['Today', 'This Week', 'Calendar'],
              selected: _activeTab,
              onSelected: (tab) => setState(() => _activeTab = tab))),
      body: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_repository.isDemo)
                Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text('Demo schedule · sample collection times',
                        style: GoogleFonts.plusJakartaSans(
                            color: mood.mutedTextColor, fontSize: 10.5))),
              if (_loading)
                const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                _empty(_error!, retry: true)
              else if (_activeTab == 'Calendar')
                _calendar()
              else
                _list(),
            ]),
          )),
    );
  }

  Widget _list() {
    final mood = SundoTimeScope.of(context);
    final now = mood.now;
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    final rows = _schedules
        .where((schedule) => _activeTab == 'Today'
            ? schedule.isOn(today)
            : !schedule.pickupAt.isBefore(monday) &&
                schedule.pickupAt.isBefore(nextMonday))
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
          child: Text(
              _activeTab == 'Today'
                  ? DateFormat('EEEE, MMM d, yyyy').format(today)
                  : '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d, yyyy').format(nextMonday.subtract(const Duration(days: 1)))}',
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: mood.textColor))),
      const SizedBox(height: 18),
      if (rows.isEmpty)
        _empty(_activeTab == 'Today'
            ? 'No collections scheduled today.'
            : 'No collections scheduled this week.'),
      for (final schedule in rows) ...[
        if (_activeTab == 'This Week')
          Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 7),
              child: Text(DateFormat('EEE, MMM d').format(schedule.pickupAt),
                  style: GoogleFonts.plusJakartaSans(
                      color: mood.mutedTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700))),
        SundoScheduleCard(
            schedule: schedule,
            now: now,
            onTap: () {
              setState(() {
                _selectedDate = DateTime(schedule.pickupAt.year,
                    schedule.pickupAt.month, schedule.pickupAt.day);
                _selectedMonth =
                    DateTime(schedule.pickupAt.year, schedule.pickupAt.month);
                _activeTab = 'Calendar';
              });
            }),
        const SizedBox(height: 13),
      ],
    ]);
  }

  void _changeMonth(int amount) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + amount);
      _selectedDate = _selectedMonth;
    });
  }

  Widget _calendar() {
    final mood = SundoTimeScope.of(context);
    final first = DateTime(_selectedMonth.year, _selectedMonth.month);
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final leading = first.weekday % 7;
    final slots = ((leading + daysInMonth) / 7).ceil() * 7;
    final selected =
        _schedules.where((schedule) => schedule.isOn(_selectedDate)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          decoration: ClayTheme.card(radius: 18),
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              IconButton(
                  tooltip: 'Previous month',
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: Color(0xFF304539))),
              Expanded(
                  child: Center(
                      child: Text(DateFormat('MMMM yyyy').format(first),
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1D3023))))),
              IconButton(
                  tooltip: 'Next month',
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF304539)))
            ]),
            const SizedBox(height: 5),
            Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => Expanded(
                        child: Center(
                            child: Text(day,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: const Color(0xFF7C8981))))))
                    .toList()),
            const SizedBox(height: 10),
            GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: slots,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: .85,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2),
                itemBuilder: (context, index) {
                  final day = index - leading + 1;
                  if (day < 1 || day > daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime(first.year, first.month, day);
                  final isSelected = date == _selectedDate;
                  final hasPickup =
                      _schedules.any((schedule) => schedule.isOn(date));
                  return Semantics(
                      selected: isSelected,
                      button: true,
                      label:
                          '${DateFormat('EEEE, MMMM d').format(date)}${hasPickup ? ', collection scheduled' : ''}',
                      child: Container(
                        decoration: isSelected
                            ? ClayTheme.buttonPrimary(radius: 11)
                            : null,
                        child: InkWell(
                            borderRadius: BorderRadius.circular(11),
                            onTap: () => setState(() => _selectedDate = date),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('$day',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF203527),
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: hasPickup
                                              ? isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF0B8F3E)
                                              : Colors.transparent)),
                                ])),
                      ));
                }),
          ])),
      const SizedBox(height: 22),
      Text('Collection Details',
          style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: mood.textColor)),
      const SizedBox(height: 4),
      Text(DateFormat('EEEE, MMM d').format(_selectedDate),
          style: GoogleFonts.plusJakartaSans(
              fontSize: 11, color: mood.mutedTextColor)),
      const SizedBox(height: 13),
      if (selected.isEmpty) _empty('No collection scheduled for this date.'),
      for (final schedule in selected) ...[
        SundoScheduleCard(
            schedule: schedule, now: mood.now, showWasteType: true),
        if (schedule.note.isNotEmpty)
          Padding(
              padding: const EdgeInsets.fromLTRB(5, 8, 5, 0),
              child: Text(schedule.note,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: mood.mutedTextColor, height: 1.4))),
        const SizedBox(height: 13),
      ],
    ]);
  }

  Widget _empty(String message, {bool retry = false}) {
    final mood = SundoTimeScope.of(context);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: Column(children: [
          Icon(Icons.event_available_outlined, size: 34, color: mood.accent),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  color: mood.mutedTextColor, fontSize: 12, height: 1.5)),
          if (retry) TextButton(onPressed: _load, child: const Text('Retry')),
        ])));
  }
}
