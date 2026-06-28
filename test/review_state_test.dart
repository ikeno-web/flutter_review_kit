import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_review_kit/flutter_review_kit.dart';

void main() {
  group('ReviewState', () {
    test('empty has zero defaults', () {
      const state = ReviewState();
      expect(state.launchCount, 0);
      expect(state.eventCount, 0);
      expect(state.firstLaunchDate, isNull);
      expect(state.lastPromptDate, isNull);
      expect(state.promptCount, 0);
      expect(state.lastPromptVersion, isNull);
      expect(state.hasReviewed, false);
    });

    test('ReviewState.empty is a const empty state', () {
      expect(ReviewState.empty.launchCount, 0);
      expect(ReviewState.empty.eventCount, 0);
    });

    test('copyWith replaces specified fields', () {
      const state = ReviewState(launchCount: 3, eventCount: 5);
      final copy = state.copyWith(launchCount: 10);
      expect(copy.launchCount, 10);
      expect(copy.eventCount, 5); // unchanged
    });

    test('copyWith with all fields', () {
      final now = DateTime(2026, 6, 28);
      final copy = const ReviewState().copyWith(
        launchCount: 5,
        eventCount: 3,
        firstLaunchDate: now,
        lastPromptDate: now,
        promptCount: 1,
        lastPromptVersion: '1.0.0',
        hasReviewed: true,
      );
      expect(copy.launchCount, 5);
      expect(copy.eventCount, 3);
      expect(copy.firstLaunchDate, now);
      expect(copy.lastPromptDate, now);
      expect(copy.promptCount, 1);
      expect(copy.lastPromptVersion, '1.0.0');
      expect(copy.hasReviewed, true);
    });

    test('toMap serializes all fields', () {
      final now = DateTime(2026, 6, 28, 12, 0, 0);
      final state = ReviewState(
        launchCount: 5,
        eventCount: 3,
        firstLaunchDate: now,
        lastPromptDate: now,
        promptCount: 1,
        lastPromptVersion: '1.0.0',
        hasReviewed: true,
      );
      final map = state.toMap();
      expect(map['launchCount'], 5);
      expect(map['eventCount'], 3);
      expect(map['firstLaunchDate'], now.toIso8601String());
      expect(map['lastPromptDate'], now.toIso8601String());
      expect(map['promptCount'], 1);
      expect(map['lastPromptVersion'], '1.0.0');
      expect(map['hasReviewed'], true);
    });

    test('toMap handles null dates', () {
      const state = ReviewState();
      final map = state.toMap();
      expect(map['firstLaunchDate'], isNull);
      expect(map['lastPromptDate'], isNull);
      expect(map['lastPromptVersion'], isNull);
    });

    test('fromMap deserializes all fields', () {
      final now = DateTime(2026, 6, 28, 12, 0, 0);
      final map = {
        'launchCount': 5,
        'eventCount': 3,
        'firstLaunchDate': now.toIso8601String(),
        'lastPromptDate': now.toIso8601String(),
        'promptCount': 1,
        'lastPromptVersion': '1.0.0',
        'hasReviewed': true,
      };
      final state = ReviewState.fromMap(map);
      expect(state.launchCount, 5);
      expect(state.eventCount, 3);
      expect(state.firstLaunchDate, now);
      expect(state.promptCount, 1);
      expect(state.lastPromptVersion, '1.0.0');
      expect(state.hasReviewed, true);
    });

    test('fromMap handles missing/null fields', () {
      final state = ReviewState.fromMap({});
      expect(state.launchCount, 0);
      expect(state.eventCount, 0);
      expect(state.firstLaunchDate, isNull);
      expect(state.hasReviewed, false);
    });

    test('fromMap round-trips with toMap', () {
      final now = DateTime(2026, 6, 28);
      final original = ReviewState(
        launchCount: 10,
        eventCount: 7,
        firstLaunchDate: now,
        promptCount: 2,
        lastPromptVersion: '2.0.0',
      );
      final roundTripped = ReviewState.fromMap(original.toMap());
      expect(roundTripped, original);
    });

    test('equality works', () {
      final now = DateTime(2026, 6, 28);
      final a = ReviewState(launchCount: 5, firstLaunchDate: now);
      final b = ReviewState(launchCount: 5, firstLaunchDate: now);
      final c = ReviewState(launchCount: 6, firstLaunchDate: now);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final now = DateTime(2026, 6, 28);
      final a = ReviewState(launchCount: 5, firstLaunchDate: now);
      final b = ReviewState(launchCount: 5, firstLaunchDate: now);
      expect(a.hashCode, b.hashCode);
    });

    test('toString includes fields', () {
      const state = ReviewState(launchCount: 3);
      final str = state.toString();
      expect(str, contains('launchCount: 3'));
    });
  });
}
