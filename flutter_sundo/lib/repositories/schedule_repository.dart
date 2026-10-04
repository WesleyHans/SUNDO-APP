import '../services/backend_service.dart';

/// A resident-visible collection window. Sources can be swapped without UI changes.
class CollectionSchedule {
  final String id;
  final String barangay;
  final DateTime pickupAt;
  final String timeLabel;
  final String route;
  final String wasteType;
  final String? explicitStatus;
  final String note;

  const CollectionSchedule({
    required this.id,
    required this.barangay,
    required this.pickupAt,
    required this.timeLabel,
    required this.route,
    required this.wasteType,
    this.explicitStatus,
    this.note = '',
  });

  String statusAt(DateTime now) {
    if (explicitStatus != null) return explicitStatus!;
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(pickupAt.year, pickupAt.month, pickupAt.day);
    if (date == today) return 'Today';
    return date.isAfter(today) ? 'Upcoming' : 'Past';
  }

  bool isOn(DateTime date) =>
      pickupAt.year == date.year &&
      pickupAt.month == date.month &&
      pickupAt.day == date.day;
}

abstract interface class ScheduleRepository {
  bool get isDemo;
  Future<List<CollectionSchedule>> load();
}

class MockScheduleRepository implements ScheduleRepository {
  static final shared = MockScheduleRepository();
  final DateTime referenceDate;
  MockScheduleRepository({DateTime? now})
      : referenceDate = now ?? DateTime.now();

  @override
  bool get isDemo => true;

  late final List<CollectionSchedule> items = _buildSchedules();

  List<CollectionSchedule> _buildSchedules() {
    final today =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    const offsets = [-1, 0, 0, 1, 2, 3, 4, 6, 8, 12, 14, 18, 25];
    const areas = [
      'Barangay 1',
      'Barangay 2',
      'Barangay 3',
      'Gil Montilla',
      'Nauhang'
    ];
    return List.generate(offsets.length, (index) {
      final morning = index.isEven;
      return CollectionSchedule(
        id: 'demo-schedule-$index',
        barangay: areas[index % areas.length],
        pickupAt:
            today.add(Duration(days: offsets[index], hours: morning ? 8 : 13)),
        timeLabel: morning ? '8:00 AM – 12:00 PM' : '1:00 PM – 4:00 PM',
        route: 'Route ${(index % 4 + 1).toString().padLeft(2, '0')}',
        wasteType: index % 3 == 0 ? 'Recyclables' : 'General Waste',
        explicitStatus: index == 0
            ? 'Completed'
            : index == 2
                ? 'Delayed'
                : null,
        note: index == 2
            ? 'Sample delay: collection is running 15 minutes late.'
            : '',
      );
    });
  }

  @override
  Future<List<CollectionSchedule>> load() async => List.unmodifiable(items);
}

/// Uses the existing shared schedules table; unavailable operational status is
/// never inferred as "Completed" merely because a time has passed.
class SupabaseScheduleRepository implements ScheduleRepository {
  @override
  bool get isDemo => false;

  @override
  Future<List<CollectionSchedule>> load() async {
    final rows = await BackendService.client
        .from('schedules')
        .select()
        .order('pickup_at');
    return rows.map((row) {
      final pickup = DateTime.parse(row['pickup_at'] as String).toLocal();
      final hour = pickup.hour % 12 == 0 ? 12 : pickup.hour % 12;
      final minutes = pickup.minute.toString().padLeft(2, '0');
      return CollectionSchedule(
        id: '${row['id']}',
        barangay: row['barangay'] as String,
        pickupAt: pickup,
        timeLabel: '$hour:$minutes ${pickup.hour < 12 ? 'AM' : 'PM'}',
        route: row['truck_id'] as String? ?? 'Truck to be assigned',
        wasteType: row['waste_type'] as String,
        note: row['note'] as String? ?? '',
      );
    }).toList();
  }
}
