import 'package:latlong2/latlong.dart';

enum ReportStatus { pending, inProgress, verified, resolved }

class TruckData {
  final String id;
  final String plateNumber;
  final String driverName;
  final String routeName;
  final LatLng position;
  final double speedKmh;
  final int etaMinutes;
  final int capacityPercent;
  final bool isCollecting;

  TruckData({
    required this.id,
    required this.plateNumber,
    required this.driverName,
    required this.routeName,
    required this.position,
    required this.speedKmh,
    required this.etaMinutes,
    required this.capacityPercent,
    required this.isCollecting,
  });

  TruckData copyWith({
    LatLng? position,
    double? speedKmh,
    int? etaMinutes,
    int? capacityPercent,
    bool? isCollecting,
  }) {
    return TruckData(
      id: id,
      plateNumber: plateNumber,
      driverName: driverName,
      routeName: routeName,
      position: position ?? this.position,
      speedKmh: speedKmh ?? this.speedKmh,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      capacityPercent: capacityPercent ?? this.capacityPercent,
      isCollecting: isCollecting ?? this.isCollecting,
    );
  }
}

class GarbageReport {
  final String id;
  final String title;
  final String description;
  final String category;
  final LatLng location;
  final String barangay;
  final String? imagePath;
  final ReportStatus status;
  final DateTime timestamp;

  GarbageReport({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.barangay,
    this.imagePath,
    this.status = ReportStatus.pending,
    required this.timestamp,
  });
}

class CollectionSchedule {
  final String barangay;
  final String dayOfWeek;
  final String timeWindow;
  final String wasteType;
  final String truckAssigned;

  CollectionSchedule({
    required this.barangay,
    required this.dayOfWeek,
    required this.timeWindow,
    required this.wasteType,
    required this.truckAssigned,
  });
}
