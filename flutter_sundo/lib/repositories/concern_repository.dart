import '../core/storage/app_store.dart';
import '../services/backend_service.dart';

abstract interface class ConcernRepository {
  bool get isDemo;
  bool get requiresGps;
  Future<List<GarbageReportItem>> load();
  Future<void> submit(GarbageReportItem report);
}

/// Demo concerns remain local, including photos; they are never presented as
/// received by the city.
class MockConcernRepository implements ConcernRepository {
  @override
  bool get isDemo => true;
  @override
  bool get requiresGps => false;
  @override
  Future<List<GarbageReportItem>> load() => AppStore.getReports();
  @override
  Future<void> submit(GarbageReportItem report) => AppStore.saveReport(report);
}

class SupabaseConcernRepository implements ConcernRepository {
  @override
  bool get isDemo => false;
  @override
  bool get requiresGps => true;
  @override
  Future<List<GarbageReportItem>> load() => BackendService.reports();
  @override
  Future<void> submit(GarbageReportItem report) =>
      BackendService.submitReport(report);
}
