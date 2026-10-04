import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new installations have no invented reports; saved reports persist',
      () async {
    SharedPreferences.setMockInitialValues({});
    expect(await AppStore.getReports(), isEmpty);
    final report = GarbageReportItem(
      id: 'SUNDO-test',
      concernType: 'Illegal Dumping',
      description: 'Waste beside the road',
      photoPaths: ['/documents/reports/photo.jpg'],
      latitude: 9.75,
      longitude: 122.40,
      locationAddress: 'GPS location',
      createdAt: DateTime.utc(2026, 10, 4),
    );
    await AppStore.saveReport(report);
    final saved = await AppStore.getReports();
    expect(saved, hasLength(1));
    expect(saved.single.toJson(), report.toJson());
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('sundo_reports'), hasLength(1));
  });

  test(
      'report serialization preserves absent GPS without inventing coordinates',
      () {
    final report = GarbageReportItem.fromJson({
      'id': 'legacy-report',
      'createdAt': '2026-10-04T00:00:00.000Z',
    });
    expect(report.latitude, isNull);
    expect(report.longitude, isNull);
    expect(report.photoPaths, isEmpty);
    expect(report.status, 'Pending');
  });
}
