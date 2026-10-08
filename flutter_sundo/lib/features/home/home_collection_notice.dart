import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/time_theme.dart';
import '../../core/utils/resident_area.dart';
import '../../repositories/schedule_repository.dart';
import '../../shared/widgets/resident_components.dart';
import 'widgets/sundo_dashboard_widgets.dart';
import 'widgets/sundo_card_scenery.dart';

/// Show the whole Philippine day, including already completed or cancelled
/// windows. An elapsed start time alone does not establish collection status.
List<CollectionSchedule> todayCollectionsForResidentArea(
    List<CollectionSchedule> schedules, String area, DateTime philippineTime,
    {bool datesAreInstants = false}) {
  final today = DateTime(
      philippineTime.year, philippineTime.month, philippineTime.day);
  final matches = schedules.where((entry) {
    final pickup = residentCollectionTime(entry,
        datesAreInstants: datesAreInstants);
    return serviceAreaMatchesResident(entry.barangay, area) &&
        pickup.year == today.year &&
        pickup.month == today.month &&
        pickup.day == today.day;
  }).toList()
    ..sort((a, b) => a.pickupAt.compareTo(b.pickupAt));
  return matches;
}

class HomeCollectionNotice extends StatelessWidget {
  const HomeCollectionNotice({
    super.key,
    required this.schedules,
    required this.area,
    required this.isDemo,
    required this.loaded,
    required this.onOpenSchedule,
    this.failed = false,
    this.dashboardStyle = false,
  });

  final List<CollectionSchedule> schedules;
  final String area;
  final bool isDemo;
  final bool loaded;
  final bool failed;
  final VoidCallback onOpenSchedule;
  final bool dashboardStyle;

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final today = DateTime(
        mood.localTime.year, mood.localTime.month, mood.localTime.day);
    final matches = todayCollectionsForResidentArea(
        schedules, area, mood.localTime,
        datesAreInstants: !isDemo);
    final summary = failed
        ? 'Schedule unavailable'
        : !loaded
            ? 'Checking today’s schedule…'
            : area.trim().isEmpty
                ? 'Choose your collection area'
                : matches.isEmpty
                    ? 'No collection scheduled today'
                    : matches.every((entry) =>
                            entry.explicitStatus?.trim().toLowerCase() ==
                            'completed')
                        ? 'Collection completed today'
                        : matches.every((entry) => const ['cancelled', 'canceled']
                            .contains(entry.explicitStatus?.trim().toLowerCase()))
                            ? 'Collection cancelled today'
                            : matches.every((entry) => const [
                                  'completed',
                                  'cancelled',
                                  'canceled'
                                ].contains(
                                    entry.explicitStatus?.trim().toLowerCase()))
                                ? 'No remaining collection today'
                                : 'Collection scheduled today';
    final details = failed
        ? 'Pull down to retry.'
        : !loaded
            ? 'Loading published collection times.'
            : area.trim().isEmpty
                ? 'Set your barangay in Profile.'
                : '${DateFormat('EEE, MMM d').format(today)} · $area';
    String pickupDetails(CollectionSchedule entry) {
      final time = isDemo
          ? entry.timeLabel
          : DateFormat('h:mm a').format(
              residentCollectionTime(entry, datesAreInstants: true));
      final status = entry.explicitStatus?.trim();
      return '$time · ${entry.wasteType} · ${status == null || status.isEmpty ? 'Scheduled' : status}';
    }
    if (dashboardStyle) {
      final pickups = loaded && !failed && matches.isNotEmpty
          ? matches.take(2).map(pickupDetails).join('\n')
          : null;
      return SundoInfoCard(
        scenery: SundoCardScene.noCollectionStreet,
        title: 'Today',
        subtitle: '$summary\n$details',
        icon: Icons.today_rounded,
        onTap: onOpenSchedule,
        footer: isDemo ? 'Sample schedule · Local demo' : null,
        additionalDetails: pickups == null
            ? null
            : [
                pickups,
                if (matches.length > 2)
                  '+${matches.length - 2} more · View schedule',
              ].join('\n'),
      );
    }
    return InkWell(
      onTap: onOpenSchedule,
      borderRadius: BorderRadius.circular(18),
      child: SundoSurface(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: mood.accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  Icon(Icons.today_rounded, size: 23, color: mood.accent)),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Today',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: mood.textColor)),
              const SizedBox(height: 3),
              Text(summary,
                  style: TextStyle(fontSize: 11, color: mood.textColor)),
              const SizedBox(height: 3),
              Text(details,
                  style: TextStyle(fontSize: 10, color: mood.mutedTextColor)),
              if (loaded && !failed && matches.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                    matches.take(2).map(pickupDetails).join('\n'),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: mood.accent)),
                if (matches.length > 2)
                  Text('+${matches.length - 2} more · View schedule',
                      style:
                          TextStyle(fontSize: 10, color: mood.mutedTextColor)),
              ],
              if (isDemo)
                Text('Sample schedule · Local demo',
                    style: TextStyle(fontSize: 9, color: mood.mutedTextColor)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 20, color: mood.mutedTextColor),
        ]),
      ),
    );
  }
}
