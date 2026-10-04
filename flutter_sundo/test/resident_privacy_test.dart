import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/core/utils/resident_area.dart';
import 'package:sundo_sipalay/repositories/schedule_repository.dart';
import 'package:sundo_sipalay/services/push_notification_service.dart';

void main() {
  test(
      'next collection matches resident area without borrowing another barangay pickup',
      () {
    final date = DateTime(2026, 10, 5, 9);
    final schedules = [
      CollectionSchedule(
          id: 'neighbor',
          barangay: 'Barangay 2',
          pickupAt: date.add(const Duration(hours: 1)),
          timeLabel: '10 AM',
          route: 'Route 1',
          wasteType: 'General'),
      CollectionSchedule(
          id: 'own',
          barangay: 'Barangay 1',
          pickupAt: date.add(const Duration(days: 1)),
          timeLabel: '9 AM',
          route: 'Route 2',
          wasteType: 'General'),
    ];
    expect(
        nextCollectionForResidentArea(schedules, 'Barangay 1 (Poblacion)', date)
            ?.id,
        'own');
    expect(
        nextCollectionForResidentArea(schedules, 'Camindangan', date), isNull);
    expect(
        nextCollectionForResidentArea(schedules, 'Barangay 11', date), isNull);
  });
  test(
      'approaching notices match area labels without matching Barangay 11 to Barangay 1',
      () {
    expect(
        serviceAreaMatchesResident(
            'Barangay 1 · sample stop', 'Barangay 1 (Poblacion)'),
        isTrue);
    expect(serviceAreaMatchesResident('Barangay 11', 'Barangay 1'), isFalse);
  });
  test(
      'push delivery gate rejects another resident, signed-out state and automatic-display payloads',
      () {
    final data = <String, dynamic>{'resident_id': 'resident-A'};
    expect(pushBelongsToResident(data, 'resident-A'), isTrue);
    expect(pushBelongsToResident(data, 'resident-B'), isFalse);
    expect(pushBelongsToResident(data, null), isFalse);
    expect(pushBelongsToResident({}, 'resident-A'), isFalse);
    expect(
        pushBelongsToResident(data, 'resident-A', hasNotificationPayload: true),
        isFalse);
  });
}
