import 'package:flutter_test/flutter_test.dart';
import 'package:sundo_sipalay/core/utils/resident_location.dart';

void main() {
  final now = DateTime.utc(2026, 10, 5, 9);

  test('current fixes expire after one minute', () {
    expect(residentFixIsFresh(now, now), isTrue);
    expect(residentFixIsFresh(now.subtract(const Duration(seconds: 60)), now),
        isTrue);
    expect(
        residentFixIsFresh(
            now.subtract(const Duration(seconds: 60, milliseconds: 1)), now),
        isFalse);
  });

  test('small native clock skew is accepted but future fixes are rejected', () {
    expect(
        residentFixIsFresh(now.add(const Duration(seconds: 5)), now), isTrue);
    expect(
        residentFixIsFresh(now.add(const Duration(seconds: 6)), now), isFalse);
  });
}
