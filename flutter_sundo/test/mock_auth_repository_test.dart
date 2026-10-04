import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundo_sipalay/repositories/mock_auth_repository.dart';
import 'package:sundo_sipalay/core/storage/app_store.dart';
import 'package:sundo_sipalay/services/backend_service.dart';

Future<void> registerJuan() => MockAuthRepository.register(
    name: 'Juan Dela Cruz',
    email: 'juan@example.com',
    phone: '09123456789',
    barangay: 'Barangay 1 (Poblacion)',
    street: 'Near plaza',
    zone: 'Purok 2',
    password: 'demo-password');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    MockAuthRepository.secureStorage = const FlutterSecureStorage();
    MockAuthRepository.resetMemory();
    BackendService.demoMode = true;
  });

  test(
      'local registration persists identity; passwords do not enter preferences',
      () async {
    await registerJuan();
    expect(MockAuthRepository.hasSession, isTrue);
    expect(BackendService.live, isFalse);
    expect(await AppStore.getName(), 'Juan Dela Cruz');
    expect(await AppStore.getZone(), 'Purok 2');
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      expect(prefs.get(key).toString(), isNot(contains('demo-password')));
    }
    MockAuthRepository.resetMemory();
    expect(await MockAuthRepository.restoreSession(), isTrue);
    expect(await AppStore.getEmail(), 'juan@example.com');
  });

  test('demo login checks credentials and remember-me controls session restore',
      () async {
    await registerJuan();
    await MockAuthRepository.logout();
    await expectLater(MockAuthRepository.login('juan@example.com', 'wrong'),
        throwsStateError);
    expect(MockAuthRepository.hasSession, isFalse);
    await MockAuthRepository.login('0912 345 6789', 'demo-password',
        remember: false);
    expect(MockAuthRepository.hasSession, isTrue);
    MockAuthRepository.resetMemory();
    expect(await MockAuthRepository.restoreSession(), isFalse);
    await MockAuthRepository.login('JUAN@example.com', 'demo-password',
        remember: true);
    MockAuthRepository.resetMemory();
    expect(await MockAuthRepository.restoreSession(), isTrue);
  });

  test(
      'duplicate demo identifiers are rejected and edited profile survives login',
      () async {
    await registerJuan();
    await expectLater(registerJuan(), throwsStateError);
    await expectLater(
        MockAuthRepository.register(
            name: 'Another Resident',
            email: 'another@example.com',
            phone: '+639123456789',
            barangay: 'Barangay 1 (Poblacion)',
            street: '',
            zone: 'Purok 1',
            password: 'different-password'),
        throwsStateError);
    await MockAuthRepository.updateProfile(
        name: 'Juan Cruz',
        phone: '09187654321',
        barangay: 'Barangay 2 (Poblacion)',
        street: 'Market Road',
        zone: 'Zone 3');
    await MockAuthRepository.logout();
    await MockAuthRepository.login('09187654321', 'demo-password');
    expect(await AppStore.getName(), 'Juan Cruz');
    expect(await AppStore.getAddress(),
        'Market Road, Zone 3, Barangay 2 (Poblacion), Sipalay City');
  });

  test('accounts isolate local reports, GPS, saved addresses and preferences',
      () async {
    await registerJuan();
    await AppStore.setResidentLocation(
        latitude: 9.75, longitude: 122.40, accuracy: 5);
    await AppStore.addSavedAddress('Home', 'Purok 2');
    await AppStore.setNotificationEnabled('approaching', false);
    await AppStore.saveReport(GarbageReportItem(
        id: 'juan-report',
        concernType: 'Missed Collection',
        description: 'Waste left at home',
        photoPaths: [],
        locationAddress: 'Purok 2',
        createdAt: DateTime(2026, 10, 4)));
    await MockAuthRepository.logout();
    await MockAuthRepository.register(
        name: 'Maria Santos',
        email: 'maria@example.com',
        phone: '09181112222',
        barangay: 'Barangay 2 (Poblacion)',
        street: '',
        zone: 'Purok 1',
        password: 'maria-password');
    expect(await AppStore.getReports(), isEmpty);
    expect(await AppStore.getSavedAddresses(), isEmpty);
    expect(await AppStore.getResidentLocation(), isNull);
    expect(await AppStore.notificationEnabled('approaching'), isTrue);
    await MockAuthRepository.logout();
    await MockAuthRepository.login('juan@example.com', 'demo-password');
    expect((await AppStore.getReports()).single.id, 'juan-report');
    expect((await AppStore.getResidentLocation())?['accuracy'], 5);
    expect(await AppStore.notificationEnabled('approaching'), isFalse);
  });
}
