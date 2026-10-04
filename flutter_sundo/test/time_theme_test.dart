import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundo_sipalay/core/theme/time_theme.dart';

void main() {
  test(
      'device-time periods switch at 06:00,12:00,18:00 including after midnight',
      () {
    for (final hour in [0, 5, 6, 11, 12, 17, 18, 23]) {
      final mood = SundoTimeMood(DateTime(2026, 10, 4, hour));
      expect(mood.isNight, hour < 6 || hour >= 18);
      expect(
          mood.greeting,
          hour >= 6 && hour < 12
              ? 'Good Morning'
              : hour >= 12 && hour < 18
                  ? 'Good Afternoon'
                  : 'Good Evening');
    }
  });
  test(
      'theme controller refreshes after a local time change and disposes ticker',
      () {
    var clock = DateTime(2026, 10, 4, 17, 59);
    final container = ProviderContainer(
        overrides: [sundoClockProvider.overrideWithValue(() => clock)]);
    addTearDown(container.dispose);
    expect(container.read(sundoDayNightThemeProvider).isNight, isFalse);
    clock = DateTime(2026, 10, 4, 18);
    container.read(sundoDayNightThemeProvider.notifier).refresh();
    expect(container.read(sundoDayNightThemeProvider).isNight, isTrue);
    expect(container.read(sundoDayNightThemeProvider).greeting, 'Good Evening');
  });
}
