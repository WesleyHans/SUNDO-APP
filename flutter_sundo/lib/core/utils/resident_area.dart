import '../../repositories/schedule_repository.dart';

String canonicalResidentArea(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'\([^)]*\)'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// With [afterToday], [now] contains Philippine wall-clock fields and the
/// earliest eligible day is tomorrow. This keeps Home's two cards distinct.
CollectionSchedule? nextCollectionForResidentArea(
    List<CollectionSchedule> schedules, String area, DateTime now,
    {bool afterToday = false, bool datesAreInstants = false}) {
  final normalized = canonicalResidentArea(area);
  if (normalized.isEmpty) return null;
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final matches = schedules
      .where((entry) {
        final pickup = residentCollectionTime(entry,
            datesAreInstants: datesAreInstants);
        final status = entry.explicitStatus?.trim().toLowerCase();
        return serviceAreaMatchesResident(entry.barangay, area) &&
            !(afterToday
                ? DateTime(pickup.year, pickup.month, pickup.day)
                    .isBefore(tomorrow)
                : entry.pickupAt.isBefore(now)) &&
            status != 'completed' &&
            status != 'cancelled' &&
            status != 'canceled';
      })
      .toList()
    ..sort((a, b) => a.pickupAt.compareTo(b.pickupAt));
  return matches.isEmpty ? null : matches.first;
}

/// Live pickup values are absolute instants; sample schedules already use
/// Philippine calendar fields and must not receive another eight-hour shift.
DateTime residentCollectionTime(CollectionSchedule schedule,
        {bool datesAreInstants = false}) =>
    datesAreInstants
        ? schedule.pickupAt.toUtc().add(const Duration(hours: 8))
        : schedule.pickupAt;

bool serviceAreaMatchesResident(String collectionArea, String residentArea) {
  final target = canonicalResidentArea(collectionArea);
  final resident = canonicalResidentArea(residentArea);
  if (resident.isEmpty) return false;
  final escaped = RegExp.escape(resident);
  return RegExp('(^|[^a-z0-9])$escaped' r'(?=$|[^a-z0-9])').hasMatch(target);
}
