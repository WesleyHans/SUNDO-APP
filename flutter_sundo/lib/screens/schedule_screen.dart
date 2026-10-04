import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/clay_theme.dart';
import '../widgets/sundo_graphics.dart';

class ScheduleScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ScheduleScreen({super.key, this.onBack});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _activeTab = 'Today'; // 'Today', 'This Week', 'Calendar'
  DateTime _selectedMonth = DateTime(2024, 11);
  int _selectedDay = 12;

  final List<Map<String, dynamic>> _schedules = const [
    {
      'id': 1,
      'barangay': 'Barangay 1 (Poblacion Central)',
      'time': '7:00 AM - 10:30 AM',
      'route': 'Main St. to Coastal Blvd',
      'wasteType': 'Biodegradable & Household Waste',
      'status': 'Today',
      'dayOfMonth': 12,
    },
    {
      'id': 2,
      'barangay': 'Barangay Gil Montilla',
      'time': '7:00 AM - 10:30 AM',
      'route': 'National Hwy North Route',
      'wasteType': 'Biodegradable & Household Waste',
      'status': 'Today',
      'dayOfMonth': 13,
    },
    {
      'id': 3,
      'barangay': 'Barangay Poblacion (Market)',
      'time': '5:00 AM - 8:00 AM & 5:00 PM',
      'route': 'Public Market Commercial Loop',
      'wasteType': 'Commercial & General Solid Waste',
      'status': 'Upcoming',
      'dayOfMonth': 14,
    },
    {
      'id': 4,
      'barangay': 'Barangay San Jose & Nauhang Coastal',
      'time': '8:00 AM - 12:00 PM',
      'route': 'Coastal Access Road',
      'wasteType': 'Recyclables & Dry Residuals',
      'status': 'Upcoming',
      'dayOfMonth': 19,
    },
    {
      'id': 5,
      'barangay': 'Barangay Cayhagan & Canturay',
      'time': '1:00 PM - 5:00 PM',
      'route': 'Southern Farm-to-Market',
      'wasteType': 'Household Waste & Agriculture Residuals',
      'status': 'Upcoming',
      'dayOfMonth': 26,
    },
  ];

  List<Map<String, dynamic>> _getDynamicCalendarDays() {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInPrevMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 0).day;

    final List<Map<String, dynamic>> result = [];
    for (int i = startingWeekday - 1; i >= 0; i--) {
      result.add({'day': daysInPrevMonth - i, 'currentMonth': false, 'hasCollection': false});
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, d);
      final hasCollection = (date.weekday >= 1 && date.weekday <= 6); // Mon-Sat
      result.add({'day': d, 'currentMonth': true, 'hasCollection': hasCollection});
    }
    int remaining = (7 - (result.length % 7)) % 7;
    for (int i = 1; i <= remaining; i++) {
      result.add({'day': i, 'currentMonth': false, 'hasCollection': false});
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28, color: Color(0xFF334155)),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          'Collection Schedule',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: ['Today', 'This Week', 'Calendar'].map((tab) {
                  final bool isSelected = _activeTab == tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: isSelected
                            ? ClayTheme.buttonPrimary(radius: 24)
                            : const BoxDecoration(color: Colors.transparent),
                        child: Center(
                          child: Text(
                            tab,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        child: _activeTab == 'Calendar' ? _buildCalendarView() : _buildListView(),
      ),
    );
  }

  // VIEW 1: Schedule List (Screen 8)
  Widget _buildListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tuesday, Nov 12, 2024',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF334155),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _schedules.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final s = _schedules[index];
            final bool isToday = s['status'] == 'Today';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: ClayTheme.card(radius: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Truck icon inside clay mint square
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Center(
                      child: SundoTruckGraphic(width: 38, height: 30),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['barangay'] as String,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['time'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['route'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: isToday
                        ? ClayTheme.badge(
                            bgColor: const Color(0xFFECFDF5),
                            borderColor: const Color(0xFFA7F3D0),
                          )
                        : ClayTheme.amberBadge(radius: 12),
                    child: Text(
                      s['status'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isToday ? const Color(0xFF065F46) : const Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // VIEW 2: Calendar View (Screen 9)
  Widget _buildCalendarView() {
    final selectedSchedule = _schedules.firstWhere(
      (s) => s['dayOfMonth'] == _selectedDay,
      orElse: () => _schedules[0],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar Month Container Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: ClayTheme.card(radius: 24),
          child: Column(
            children: [
              // Month Header with Prev/Next
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B), size: 24),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                        _selectedDay = 1;
                      });
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 24),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                        _selectedDay = 1;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Days of week header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) {
                  return SizedBox(
                    width: 38,
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Calendar Days Grid
              Builder(
                builder: (context) {
                  final days = _getDynamicCalendarDays();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: days.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = days[index];
                  final int day = item['day'] as int;
                  final bool isCurrentMonth = item['currentMonth'] as bool;
                  final bool hasCollection = item['hasCollection'] as bool;
                  final bool isSelected = isCurrentMonth && day == _selectedDay;

                  return GestureDetector(
                    onTap: isCurrentMonth
                        ? () {
                            setState(() {
                              _selectedDay = day;
                            });
                          }
                        : null,
                    child: Container(
                      decoration: isSelected
                          ? ClayTheme.buttonPrimary(radius: 20)
                          : isCurrentMonth && hasCollection
                              ? BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                )
                              : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$day',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : isCurrentMonth
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFCBD5E1),
                            ),
                          ),
                          if (hasCollection && !isSelected)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 4.5,
                                height: 4.5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF059669),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    );
                  },
                );
              },
            ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Collection Details Card
        Text(
          'COLLECTION DETAILS',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF334155),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: ClayTheme.cardMint(radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: const Center(
                      child: SundoTruckGraphic(width: 34, height: 26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedSchedule['barangay']} - ${selectedSchedule['route']}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: const Color(0xFF064E3B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, color: Color(0xFF059669), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    selectedSchedule['time'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, color: Color(0xFF059669), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedSchedule['wasteType'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
