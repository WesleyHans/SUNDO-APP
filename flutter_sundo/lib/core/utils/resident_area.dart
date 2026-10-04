import '../../repositories/schedule_repository.dart';

String canonicalResidentArea(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'\([^)]*\)'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
CollectionSchedule? nextCollectionForResidentArea(
    List<CollectionSchedule> schedules, String area, DateTime now) {
  final normalized = canonicalResidentArea(area);
  if (normalized.isEmpty) return null;
  final matches = schedules
      .where((entry) =>
          canonicalResidentArea(entry.barangay) == normalized &&
          !entry.pickupAt.isBefore(now) &&
          entry.explicitStatus != 'Completed')
      .toList()
    ..sort((a, b) => a.pickupAt.compareTo(b.pickupAt));
  return matches.isEmpty ? null : matches.first;
}

bool serviceAreaMatchesResident(String collectionArea, String residentArea) {
  final target = canonicalResidentArea(collectionArea);
  final resident = canonicalResidentArea(residentArea);
  if (resident.isEmpty) return false;
  final escaped = RegExp.escape(resident);
  return RegExp('(^|[^a-z0-9])$escaped' r'(?=$|[^a-z0-9])').hasMatch(target);
}
