import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_review_kit/flutter_review_kit.dart';

void main() {
  late MemoryStore store;
  late DateTime fakeNow;

  DateTime fakeClock() => fakeNow;

  ReviewManager createManager({
    ReviewConfig? config,
    String? appVersion,
    ReviewRequester? reviewRequester,
  }) {
    return ReviewManager(
      config: config ?? const ReviewConfig(),
      store: store,
      appVersion: appVersion,
      reviewRequester: reviewRequester,
      clock: fakeClock,
    );
  }

  /// Helper: creates a manager, initializes, and tracks enough launches/events
  /// to make it ready (with enough days passed).
  Future<ReviewManager> createReadyManager({
    ReviewConfig? config,
    String? appVersion,
    ReviewRequester? reviewRequester,
  }) async {
    final c = config ?? const ReviewConfig();
    final manager = createManager(
      config: c,
      appVersion: appVersion,
      reviewRequester: reviewRequester,
    );
    await manager.initialize();

    for (int i = 0; i < c.minLaunches; i++) {
      await manager.trackLaunch();
    }
    for (int i = 0; i < c.minEvents; i++) {
      await manager.trackEvent('event_$i');
    }

    // Advance past minDaysInstalled
    fakeNow = fakeNow.add(Duration(days: c.minDaysInstalled + 1));

    return manager;
  }

  setUp(() {
    store = MemoryStore();
    fakeNow = DateTime(2026, 6, 1);
  });

  group('ReviewManager initialization', () {
    test('throws if methods called before initialize', () {
      final manager = createManager();
      expect(() => manager.state, throwsStateError);
    });

    test('initialize loads state and sets firstLaunchDate', () async {
      final manager = createManager();
      await manager.initialize();

      expect(manager.state.firstLaunchDate, fakeNow);
      expect(manager.state.launchCount, 0);
    });

    test('initialize preserves existing firstLaunchDate', () async {
      final existingDate = DateTime(2026, 1, 1);
      await store.save(ReviewState(firstLaunchDate: existingDate));

      final manager = createManager();
      await manager.initialize();

      expect(manager.state.firstLaunchDate, existingDate);
    });

    test('throws if used after dispose', () async {
      final manager = createManager();
      await manager.initialize();
      manager.dispose();

      expect(() async => manager.trackLaunch(), throwsStateError);
    });
  });

  group('ReviewManager tracking', () {
    test('trackLaunch increments launch count', () async {
      final manager = createManager();
      await manager.initialize();

      await manager.trackLaunch();
      expect(manager.state.launchCount, 1);

      await manager.trackLaunch();
      expect(manager.state.launchCount, 2);
    });

    test('trackLaunch persists to store', () async {
      final manager = createManager();
      await manager.initialize();

      await manager.trackLaunch();
      final stored = await store.load();
      expect(stored.launchCount, 1);
    });

    test('trackEvent increments event count', () async {
      final manager = createManager();
      await manager.initialize();

      await manager.trackEvent('level_complete');
      expect(manager.state.eventCount, 1);

      await manager.trackEvent('purchase');
      expect(manager.state.eventCount, 2);
    });

    test('trackEvent persists to store', () async {
      final manager = createManager();
      await manager.initialize();

      await manager.trackEvent('test');
      final stored = await store.load();
      expect(stored.eventCount, 1);
    });
  });

  group('ReviewManager condition checking', () {
    test('isReady false when launches below minimum', () async {
      final manager = createManager(
        config: const ReviewConfig(
          minLaunches: 5,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
      );
      await manager.initialize();

      for (int i = 0; i < 4; i++) {
        await manager.trackLaunch();
      }
      expect(manager.isReady, false);

      await manager.trackLaunch();
      expect(manager.isReady, true);
    });

    test('isReady false when days below minimum', () async {
      final manager = createManager(
        config: const ReviewConfig(
          minLaunches: 0,
          minDaysInstalled: 7,
          minEvents: 0,
        ),
      );
      await manager.initialize();

      // Still day 0
      expect(manager.isReady, false);

      // Advance to day 6 — still not enough
      fakeNow = fakeNow.add(const Duration(days: 6));
      expect(manager.isReady, false);

      // Advance to day 7 — now ready
      fakeNow = fakeNow.add(const Duration(days: 1));
      expect(manager.isReady, true);
    });

    test('isReady false when events below minimum', () async {
      final manager = createManager(
        config: const ReviewConfig(
          minLaunches: 0,
          minDaysInstalled: 0,
          minEvents: 3,
        ),
      );
      await manager.initialize();

      await manager.trackEvent('a');
      await manager.trackEvent('b');
      expect(manager.isReady, false);

      await manager.trackEvent('c');
      expect(manager.isReady, true);
    });

    test('isReady requires ALL conditions met', () async {
      final manager = createManager(
        config: const ReviewConfig(
          minLaunches: 2,
          minDaysInstalled: 3,
          minEvents: 1,
        ),
      );
      await manager.initialize();

      // Meet launches and events but not days
      await manager.trackLaunch();
      await manager.trackLaunch();
      await manager.trackEvent('test');
      expect(manager.isReady, false);

      // Meet days too
      fakeNow = fakeNow.add(const Duration(days: 3));
      expect(manager.isReady, true);
    });

    test('isReady false when not initialized', () {
      final manager = createManager();
      expect(manager.isReady, false);
    });

    test('isReady at exact threshold values', () async {
      final manager = createManager(
        config: const ReviewConfig(
          minLaunches: 3,
          minDaysInstalled: 5,
          minEvents: 2,
        ),
      );
      await manager.initialize();

      // Exactly at launch threshold
      for (int i = 0; i < 3; i++) {
        await manager.trackLaunch();
      }
      // Exactly at event threshold
      await manager.trackEvent('a');
      await manager.trackEvent('b');
      // Exactly at day threshold
      fakeNow = fakeNow.add(const Duration(days: 5));

      expect(manager.isReady, true);
    });
  });

  group('ReviewManager cooldown', () {
    test('isReady false during cooldown period', () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
          cooldownDays: 30,
        ),
      );

      expect(manager.isReady, true);

      // Trigger a review
      await manager.requestReview();

      // Still in cooldown
      expect(manager.isReady, false);

      // Advance 29 days — still in cooldown
      fakeNow = fakeNow.add(const Duration(days: 29));
      expect(manager.isReady, false);

      // Advance to 30 days — cooldown over
      fakeNow = fakeNow.add(const Duration(days: 1));
      expect(manager.isReady, true);
    });

    test('debug mode bypasses cooldown', () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
          cooldownDays: 30,
          debug: true,
        ),
      );

      await manager.requestReview();

      // Even though we just prompted, debug mode bypasses cooldown
      expect(manager.isReady, true);
    });
  });

  group('ReviewManager per-version cap', () {
    test('isReady false when max prompts for version reached', () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
          cooldownDays: 0,
          maxPromptsPerVersion: 1,
        ),
        appVersion: '1.0.0',
      );

      expect(manager.isReady, true);
      await manager.requestReview();
      expect(manager.isReady, false);
    });

    test('isReady true for new version after max prompts', () async {
      // First version
      var manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
          cooldownDays: 0,
          maxPromptsPerVersion: 1,
        ),
        appVersion: '1.0.0',
      );
      await manager.requestReview();
      manager.dispose();

      // "Upgrade" to new version — same store
      manager = createManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
          cooldownDays: 0,
          maxPromptsPerVersion: 1,
        ),
        appVersion: '2.0.0',
      );
      await manager.initialize();
      // State already has enough launches/events from before
      await manager.trackLaunch();
      expect(manager.isReady, true);
      manager.dispose();
    });

    test('no version cap when appVersion is null', () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
          cooldownDays: 0,
          maxPromptsPerVersion: 1,
        ),
      );

      await manager.requestReview();
      // No version tracking, so no cap
      expect(manager.isReady, true);
    });
  });

  group('ReviewManager requestReview', () {
    test('requestReview calls reviewRequester', () async {
      var requesterCalled = false;
      final manager = await createReadyManager(
        reviewRequester: () async {
          requesterCalled = true;
          return true;
        },
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
      );

      await manager.requestReview();
      expect(requesterCalled, true);
    });

    test('requestReview returns shown on success', () async {
      final manager = await createReadyManager(
        reviewRequester: () async => true,
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
      );

      final result = await manager.requestReview();
      expect(result, ReviewResult.shown);
    });

    test('requestReview returns error when requester returns false',
        () async {
      final manager = await createReadyManager(
        reviewRequester: () async => false,
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
      );

      final result = await manager.requestReview();
      expect(result, ReviewResult.error);
    });

    test('requestReview returns error when requester throws', () async {
      final manager = await createReadyManager(
        reviewRequester: () async => throw Exception('platform error'),
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
      );

      final result = await manager.requestReview();
      expect(result, ReviewResult.error);
    });

    test('requestReview updates prompt state', () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
        appVersion: '1.0.0',
      );

      await manager.requestReview();

      expect(manager.state.promptCount, 1);
      expect(manager.state.lastPromptDate, fakeNow);
      expect(manager.state.lastPromptVersion, '1.0.0');
    });

    test('requestReview without reviewRequester returns shown', () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
      );

      final result = await manager.requestReview();
      expect(result, ReviewResult.shown);
    });
  });

  group('ReviewManager requestReviewIfReady', () {
    test('returns notReady when conditions not met', () async {
      final manager = createManager();
      await manager.initialize();
      // No launches, events, etc.
      final result = await manager.requestReviewIfReady();
      expect(result, ReviewResult.notReady);
    });

    test('returns shown when all conditions met', () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
      );

      final result = await manager.requestReviewIfReady();
      expect(result, ReviewResult.shown);
    });

    test('returns cooldown when in cooldown period', () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
          cooldownDays: 30,
        ),
      );

      await manager.requestReview();

      final result = await manager.requestReviewIfReady();
      expect(result, ReviewResult.cooldown);
    });

    test('returns alreadyPromptedThisVersion when maxed', () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
          cooldownDays: 0,
          maxPromptsPerVersion: 1,
        ),
        appVersion: '1.0.0',
      );

      await manager.requestReview();

      final result = await manager.requestReviewIfReady();
      expect(result, ReviewResult.alreadyPromptedThisVersion);
    });
  });

  group('ReviewManager readyStream', () {
    test('emits when readiness changes', () async {
      final manager = createManager(
        config: const ReviewConfig(
          minLaunches: 2,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
      );
      await manager.initialize();

      final emissions = <bool>[];
      final sub = manager.readyStream.listen(emissions.add);

      await manager.trackLaunch(); // count=1, not ready
      await manager.trackLaunch(); // count=2, ready!

      // Allow stream to emit
      await Future<void>.delayed(Duration.zero);

      expect(emissions, contains(true));

      await sub.cancel();
      manager.dispose();
    });

    test('does not emit when readiness unchanged', () async {
      final manager = createManager(
        config: const ReviewConfig(
          minLaunches: 5,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
      );
      await manager.initialize();

      final emissions = <bool>[];
      final sub = manager.readyStream.listen(emissions.add);

      await manager.trackLaunch(); // 1, not ready
      await manager.trackLaunch(); // 2, still not ready

      await Future<void>.delayed(Duration.zero);

      // Should not have emitted because readiness didn't change (stayed false)
      expect(emissions, isEmpty);

      await sub.cancel();
      manager.dispose();
    });
  });

  group('ReviewManager happy moments', () {
    test('trackHappyMoment triggers review when ready and configured',
        () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
          happyMoments: ['purchase_complete'],
        ),
      );

      final result = await manager.trackHappyMoment('purchase_complete');
      expect(result, ReviewResult.shown);
    });

    test('trackHappyMoment returns null for unconfigured moment', () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
          happyMoments: ['purchase_complete'],
        ),
      );

      final result = await manager.trackHappyMoment('random_event');
      expect(result, isNull);
    });

    test('trackHappyMoment returns null when not ready', () async {
      final manager = createManager(
        config: const ReviewConfig(
          minLaunches: 100,
          happyMoments: ['purchase_complete'],
        ),
      );
      await manager.initialize();

      final result = await manager.trackHappyMoment('purchase_complete');
      expect(result, isNull);
    });

    test('trackHappyMoment also increments event count', () async {
      final manager = createManager();
      await manager.initialize();

      await manager.trackHappyMoment('achievement');
      expect(manager.state.eventCount, 1);
    });
  });

  group('ReviewManager reset', () {
    test('reset clears all state', () async {
      final manager = await createReadyManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
      );
      await manager.requestReview();

      await manager.reset();

      expect(manager.state.launchCount, 0);
      expect(manager.state.eventCount, 0);
      expect(manager.state.promptCount, 0);
      expect(manager.state.firstLaunchDate, isNull);
      expect(manager.state.lastPromptDate, isNull);
    });

    test('reset clears store', () async {
      final manager = createManager();
      await manager.initialize();
      await manager.trackLaunch();

      await manager.reset();

      final stored = await store.load();
      expect(stored, const ReviewState());
    });
  });

  group('ReviewManager state persistence', () {
    test('state survives manager recreation', () async {
      // First manager
      var manager = createManager(
        config: const ReviewConfig(
          minLaunches: 1,
          minDaysInstalled: 0,
          minEvents: 0,
        ),
      );
      await manager.initialize();
      await manager.trackLaunch();
      await manager.trackLaunch();
      await manager.trackEvent('test');
      manager.dispose();

      // Second manager with same store
      manager = createManager();
      await manager.initialize();

      expect(manager.state.launchCount, 2);
      expect(manager.state.eventCount, 1);
      manager.dispose();
    });
  });
}
