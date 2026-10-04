import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/services/backend_service.dart';

void main() {
  test('unconfigured app cannot turn arbitrary credentials into a live session',
      () async {
    expect(BackendService.configured, isFalse);
    expect(BackendService.live, isFalse);
    await expectLater(
        BackendService.login('fake@example.com', 'anything'), throwsStateError);
    await expectLater(
        BackendService.register('Fake', 'fake@example.com', '09123456789',
            'Barangay 1', 'anything'),
        throwsStateError);
    expect(BackendService.live, isFalse);
  });
}
