import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/time_theme.dart';
import '../../core/utils/resident_area.dart';
import '../../repositories/schedule_repository.dart';
import '../../shared/widgets/resident_components.dart';
import 'widgets/sundo_dashboard_widgets.dart';
import 'widgets/sundo_card_scenery.dart';

/// Match the next Philippine calendar day, rather than a rolling 24 hours.
List<CollectionSchedule> tomorrowCollectionsForResidentArea(
    List<CollectionSchedule> schedules, String area, DateTime philippineTime,
    {bool datesAreInstants = false}) {
  final tomorrow = DateTime(
      philippineTime.year, philippineTime.month, philippineTime.day + 1);
  final matches = schedules.where((entry) {
    final pickup = datesAreInstants
        ? entry.pickupAt.toUtc().add(const Duration(hours: 8))
        : entry.pickupAt;
    return serviceAreaMatchesResident(entry.barangay, area) &&
        pickup.year == tomorrow.year &&
        pickup.month == tomorrow.month &&
        pickup.day == tomorrow.day &&
        entry.explicitStatus != 'Completed';
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
    final tomorrow = DateTime(
        mood.localTime.year, mood.localTime.month, mood.localTime.day + 1);
    final matches = tomorrowCollectionsForResidentArea(
        schedules, area, mood.localTime,
        datesAreInstants: !isDemo);
    final heading = failed
        ? "Tomorrow's schedule unavailable"
        : !loaded
            ? "Checking tomorrow's schedule…"
            : area.trim().isEmpty
                ? 'Choose your collection area'
                : matches.isEmpty
                    ? 'No collection scheduled tomorrow'
                    : 'Collection tomorrow in your area';
    final details = failed
        ? 'Pull down to retry.'
        : !loaded
            ? 'Loading published collection times.'
            : area.trim().isEmpty
                ? 'Set your barangay in Profile.'
                : '${DateFormat('EEE, MMM d').format(tomorrow)} · $area';
    if (dashboardStyle) {
      final pickupDetails = loaded && !failed && matches.isNotEmpty
          ? matches.take(2).map((entry) {
              final time = isDemo
                  ? entry.timeLabel
                  : DateFormat('h:mm a').format(
                      entry.pickupAt.toUtc().add(const Duration(hours: 8)));
              return '$time · ${entry.wasteType}';
            }).join('\n')
          : null;
      return SundoInfoCard(
        scenery: SundoCardScene.noCollectionStreet,
        title: heading,
        subtitle: details,
        icon: Icons.campaign_rounded,
        onTap: onOpenSchedule,
        footer: isDemo ? 'Sample schedule · Local demo' : null,
        additionalDetails: pickupDetails == null
            ? null
            : [
                pickupDetails,
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
                  Icon(Icons.campaign_rounded, size: 23, color: mood.accent)),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(heading,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: mood.textColor)),
              const SizedBox(height: 3),
              Text(details,
                  style: TextStyle(fontSize: 10, color: mood.mutedTextColor)),
              if (loaded && !failed && matches.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                    matches.take(2).map((entry) {
                      final time = isDemo
                          ? entry.timeLabel
                          : DateFormat('h:mm a').format(entry.pickupAt
                              .toUtc()
                              .add(const Duration(hours: 8)));
                      return '$time · ${entry.wasteType}';
                    }).join('\n'),
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
