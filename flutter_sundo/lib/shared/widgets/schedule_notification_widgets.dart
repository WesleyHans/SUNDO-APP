import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../repositories/schedule_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../core/theme/clay_theme.dart';
import '../../core/theme/time_theme.dart';
import './sundo_graphics.dart';

class SundoStatusChip extends StatelessWidget {
  final String status;
  const SundoStatusChip({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      'Delayed' => (const Color(0xFFFFE8E4), const Color(0xFFAC3625)),
      'Upcoming' => (const Color(0xFFFFF0C4), const Color(0xFF94600D)),
      'Completed' || 'Collected' => (
          const Color(0xFFE0F4E6),
          const Color(0xFF07652E)
        ),
      'Today' => (const Color(0xFFEAF8EE), const Color(0xFF0B8F3E)),
      _ => (const Color(0xFFF0F2F3), const Color(0xFF58636A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(8)),
      child: Text(status,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w800, color: foreground)),
    );
  }
}

class SundoScheduleCard extends StatelessWidget {
  final CollectionSchedule schedule;
  final DateTime now;
  final VoidCallback? onTap;
  final bool showWasteType;
  const SundoScheduleCard(
      {super.key,
      required this.schedule,
      required this.now,
      this.onTap,
      this.showWasteType = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label:
          '${schedule.barangay}, ${schedule.timeLabel}, ${schedule.route}, ${schedule.statusAt(now)}',
      child: Container(
        decoration: ClayTheme.card(radius: 16),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(children: [
                    const SundoTruckGraphic(width: 44, height: 36),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(schedule.barangay,
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF17251D))),
                          const SizedBox(height: 3),
                          Text(schedule.timeLabel,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF4C5C52))),
                          const SizedBox(height: 2),
                          Text(schedule.route,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: const Color(0xFF68786D))),
                          if (showWasteType) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.delete_outline_rounded,
                                  size: 17, color: Color(0xFF07652E)),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(schedule.wasteType,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFF32463A))))
                            ]),
                          ],
                        ])),
                    const SizedBox(width: 6),
                    SundoStatusChip(status: schedule.statusAt(now)),
                  ])),
            )),
      ),
    );
  }
}

class SundoSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;
  const SundoSegmentedTabs(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onSelected});
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return Row(
        children: labels.map((label) {
      final active = selected == label;
      return Expanded(
          child: Padding(
        padding: EdgeInsets.only(right: label == labels.last ? 0 : 6),
        child: Semantics(
            selected: active,
            button: true,
            child: Container(
              decoration: active
                  ? ClayTheme.buttonPrimary(radius: 10)
                  : BoxDecoration(
                      color: mood.isNight
                          ? const Color(0xFF213C31)
                          : const Color(0xFFF0F4F2),
                      borderRadius: BorderRadius.circular(10)),
              child: TextButton(
                style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    foregroundColor:
                        active ? Colors.white : mood.mutedTextColor),
                onPressed: () => onSelected(label),
                child: Text(label,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight:
                            active ? FontWeight.w800 : FontWeight.w600)),
              ),
            )),
      ));
    }).toList());
  }
}

class SundoNotificationCard extends StatelessWidget {
  final SundoNotification item;
  final bool isRead;
  final String timeLabel;
  final VoidCallback onTap;
  const SundoNotificationCard(
      {super.key,
      required this.item,
      required this.isRead,
      required this.timeLabel,
      required this.onTap});

  static (Color, Color, Widget) palette(String type) => switch (type) {
        'alert' => (
            const Color(0xFFFFE9E7),
            const Color(0xFFE44942),
            const Icon(Icons.notifications_active_rounded)
          ),
        'update' => (
            const Color(0xFFE5F7E9),
            const Color(0xFF17A846),
            const SundoTruckGraphic(width: 24, height: 24)
          ),
        'route' => (
            const Color(0xFFFFF2D6),
            const Color(0xFFF4A623),
            const Icon(Icons.warning_amber_rounded)
          ),
        'completed' => (
            const Color(0xFFE6F8ED),
            const Color(0xFF0B9F47),
            const Icon(Icons.check_rounded)
          ),
        _ => (
            const Color(0xFFE7F3FC),
            const Color(0xFF2F80ED),
            const Icon(Icons.campaign_rounded)
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (background, accent, icon) = palette(item.type);
    return Semantics(
      button: true,
      label: '${item.title}. ${isRead ? 'Read' : 'Unread'}. ${item.message}',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.white, background],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(15),
          border:
              Border.all(color: accent.withValues(alpha: isRead ? .12 : .25)),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: .09),
                offset: const Offset(0, 5),
                blurRadius: 12)
          ],
        ),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: accent.withValues(alpha: .2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ]),
                            child: IconTheme(
                                data: const IconThemeData(
                                    size: 24, color: Colors.white),
                                child: icon)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Expanded(
                                    child: Text(item.title,
                                        style: GoogleFonts.outfit(
                                            fontWeight: isRead
                                                ? FontWeight.w700
                                                : FontWeight.w800,
                                            fontSize: 13.5,
                                            color: const Color(0xFF1A2920)))),
                                if (!isRead)
                                  Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                          color: accent,
                                          shape: BoxShape.circle))
                              ]),
                              const SizedBox(height: 3),
                              Text(item.message,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: const Color(0xFF485A4F),
                                      height: 1.4)),
                              const SizedBox(height: 4),
                              Text(timeLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      color: const Color(0xFF78867E))),
                            ])),
                      ])),
            )),
      ),
    );
  }
}

class SundoConcernRadioOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SundoConcernRadioOption(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      button: true,
      label: label,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: ClayTheme.input(radius: 12),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(children: [
                    Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected
                            ? const Color(0xFF0B8F3E)
                            : const Color(0xFF85918A),
                        size: 21),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Text(label,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: const Color(0xFF283B2F)))),
                  ])),
            )),
      ),
    );
  }
}
