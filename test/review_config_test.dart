import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_review_kit/flutter_review_kit.dart';

void main() {
  group('ReviewConfig', () {
    test('has sensible defaults', () {
      const config = ReviewConfig();
      expect(config.minLaunches, 5);
      expect(config.minDaysInstalled, 7);
      expect(config.minEvents, 3);
      expect(config.cooldownDays, 90);
      expect(config.maxPromptsPerVersion, 1);
      expect(config.happyMoments, isEmpty);
      expect(config.debug, false);
    });

    test('accepts custom values', () {
      const config = ReviewConfig(
        minLaunches: 10,
        minDaysInstalled: 14,
        minEvents: 5,
        cooldownDays: 60,
        maxPromptsPerVersion: 2,
        happyMoments: ['purchase', 'level_up'],
        debug: true,
      );
      expect(config.minLaunches, 10);
      expect(config.minDaysInstalled, 14);
      expect(config.minEvents, 5);
      expect(config.cooldownDays, 60);
      expect(config.maxPromptsPerVersion, 2);
      expect(config.happyMoments, ['purchase', 'level_up']);
      expect(config.debug, true);
    });

    test('copyWith replaces fields', () {
      const original = ReviewConfig(minLaunches: 5);
      final copy = original.copyWith(minLaunches: 10, debug: true);
      expect(copy.minLaunches, 10);
      expect(copy.debug, true);
      // Unchanged fields preserved
      expect(copy.minDaysInstalled, original.minDaysInstalled);
      expect(copy.minEvents, original.minEvents);
    });

    test('copyWith with no args returns equivalent config', () {
      const original = ReviewConfig(minLaunches: 3, debug: true);
      final copy = original.copyWith();
      expect(copy.minLaunches, 3);
      expect(copy.debug, true);
    });

    test('toString includes all fields', () {
      const config = ReviewConfig();
      final str = config.toString();
      expect(str, contains('minLaunches'));
      expect(str, contains('minDaysInstalled'));
      expect(str, contains('cooldownDays'));
    });
  });
}
