import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_review_kit/flutter_review_kit.dart';

void main() {
  group('FakeReviewManager', () {
    late FakeReviewManager fake;

    setUp(() {
      fake = FakeReviewManager();
    });

    tearDown(() {
      fake.dispose();
    });

    test('defaults to not ready', () {
      expect(fake.isReady, false);
    });

    test('fakeIsReady controls isReady', () {
      fake.fakeIsReady = true;
      expect(fake.isReady, true);

      fake.fakeIsReady = false;
      expect(fake.isReady, false);
    });

    test('initialize sets flag', () async {
      expect(fake.initializeCalled, false);
      await fake.initialize();
      expect(fake.initializeCalled, true);
    });

    test('trackLaunch increments counter and state', () async {
      await fake.trackLaunch();
      expect(fake.trackLaunchCallCount, 1);
      expect(fake.state.launchCount, 1);

      await fake.trackLaunch();
      expect(fake.trackLaunchCallCount, 2);
      expect(fake.state.launchCount, 2);
    });

    test('trackEvent records events and increments state', () async {
      await fake.trackEvent('level_complete');
      await fake.trackEvent('purchase');

      expect(fake.trackedEvents, ['level_complete', 'purchase']);
      expect(fake.state.eventCount, 2);
    });

    test('trackHappyMoment records and tracks event', () async {
      await fake.trackHappyMoment('achievement');
      expect(fake.trackedHappyMoments, ['achievement']);
      expect(fake.trackedEvents, ['achievement']);
      expect(fake.state.eventCount, 1);
    });

    test('trackHappyMoment triggers review when ready', () async {
      fake.fakeIsReady = true;
      fake.fakeResult = ReviewResult.shown;

      final result = await fake.trackHappyMoment('purchase');
      expect(result, ReviewResult.shown);
      expect(fake.requestReviewCallCount, 1);
    });

    test('trackHappyMoment returns null when not ready', () async {
      fake.fakeIsReady = false;

      final result = await fake.trackHappyMoment('purchase');
      expect(result, isNull);
      expect(fake.requestReviewCallCount, 0);
    });

    test('requestReview returns fakeResult and increments counter',
        () async {
      fake.fakeResult = ReviewResult.shown;
      final result = await fake.requestReview();
      expect(result, ReviewResult.shown);
      expect(fake.requestReviewCallCount, 1);
    });

    test('requestReviewIfReady returns notReady when not ready', () async {
      fake.fakeIsReady = false;
      final result = await fake.requestReviewIfReady();
      expect(result, ReviewResult.notReady);
      expect(fake.requestReviewIfReadyCallCount, 1);
      expect(fake.requestReviewCallCount, 0); // Should not call requestReview
    });

    test('requestReviewIfReady calls requestReview when ready', () async {
      fake.fakeIsReady = true;
      fake.fakeResult = ReviewResult.shown;

      final result = await fake.requestReviewIfReady();
      expect(result, ReviewResult.shown);
      expect(fake.requestReviewIfReadyCallCount, 1);
      expect(fake.requestReviewCallCount, 1);
    });

    test('reset clears all counters and events', () async {
      await fake.trackLaunch();
      await fake.trackEvent('test');
      await fake.trackHappyMoment('moment');

      await fake.reset();

      expect(fake.resetCalled, true);
      expect(fake.trackLaunchCallCount, 0);
      expect(fake.trackedEvents, isEmpty);
      expect(fake.trackedHappyMoments, isEmpty);
      expect(fake.requestReviewCallCount, 0);
      expect(fake.requestReviewIfReadyCallCount, 0);
      expect(fake.state, const ReviewState());
    });

    test('dispose sets flag', () {
      final f = FakeReviewManager();
      expect(f.disposeCalled, false);
      f.dispose();
      expect(f.disposeCalled, true);
    });

    test('emitReady emits on readyStream', () async {
      final emissions = <bool>[];
      final sub = fake.readyStream.listen(emissions.add);

      fake.emitReady(true);
      fake.emitReady(false);

      await Future<void>.delayed(Duration.zero);

      expect(emissions, [true, false]);
      expect(fake.isReady, false);

      await sub.cancel();
    });

    test('custom initial state', () {
      final custom = FakeReviewManager(
        initialState: const ReviewState(launchCount: 10, eventCount: 5),
        fakeIsReady: true,
      );
      expect(custom.state.launchCount, 10);
      expect(custom.state.eventCount, 5);
      expect(custom.isReady, true);
      custom.dispose();
    });

    test('config returns default config', () {
      expect(fake.config, isA<ReviewConfig>());
    });

    test('store returns a MemoryStore', () {
      expect(fake.store, isA<MemoryStore>());
    });

    test('appVersion returns null', () {
      expect(fake.appVersion, isNull);
    });

    test('reviewRequester returns null', () {
      expect(fake.reviewRequester, isNull);
    });

    test('clock returns a DateTime', () {
      expect(fake.clock(), isA<DateTime>());
    });
  });
}
