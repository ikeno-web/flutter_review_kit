import 'dart:async';

import 'review_config.dart';
import 'review_result.dart';
import 'review_state.dart';
import 'review_store.dart';
import 'memory_store.dart';
import 'review_manager.dart';

/// A fake [ReviewManager] for unit and widget testing.
///
/// Provides controllable behavior without platform channels:
///
/// ```dart
/// final fake = FakeReviewManager();
/// fake.fakeIsReady = true;
/// fake.fakeResult = ReviewResult.shown;
///
/// final result = await fake.requestReviewIfReady();
/// expect(result, ReviewResult.shown);
/// expect(fake.requestReviewCallCount, 1);
/// ```
class FakeReviewManager implements ReviewManager {
  /// Controls what [isReady] returns.
  bool fakeIsReady;

  /// Controls what [requestReview] and [requestReviewIfReady] return.
  ReviewResult fakeResult;

  /// Events tracked via [trackEvent].
  final List<String> trackedEvents = [];

  /// Happy moments tracked via [trackHappyMoment].
  final List<String> trackedHappyMoments = [];

  /// Number of times [trackLaunch] was called.
  int trackLaunchCallCount = 0;

  /// Number of times [requestReview] was called.
  int requestReviewCallCount = 0;

  /// Number of times [requestReviewIfReady] was called.
  int requestReviewIfReadyCallCount = 0;

  /// Whether [initialize] has been called.
  bool initializeCalled = false;

  /// Whether [reset] has been called.
  bool resetCalled = false;

  /// Whether [dispose] has been called.
  bool disposeCalled = false;

  ReviewState _state;
  final StreamController<bool> _readyController =
      StreamController<bool>.broadcast();

  /// Creates a fake review manager with controllable behavior.
  FakeReviewManager({
    this.fakeIsReady = false,
    this.fakeResult = ReviewResult.shown,
    ReviewState? initialState,
  }) : _state = initialState ?? const ReviewState();

  @override
  ReviewConfig get config => const ReviewConfig();

  late final ReviewStore _store = MemoryStore();

  @override
  ReviewStore get store => _store;

  @override
  String? get appVersion => null;

  @override
  ReviewRequester? get reviewRequester => null;

  @override
  DateTime Function() get clock => DateTime.now;

  @override
  Future<void> initialize() async {
    initializeCalled = true;
  }

  @override
  bool get isReady => fakeIsReady;

  @override
  Stream<bool> get readyStream => _readyController.stream;

  @override
  ReviewState get state => _state;

  @override
  Future<void> trackLaunch() async {
    trackLaunchCallCount++;
    _state = _state.copyWith(launchCount: _state.launchCount + 1);
  }

  @override
  Future<void> trackEvent(String eventName) async {
    trackedEvents.add(eventName);
    _state = _state.copyWith(eventCount: _state.eventCount + 1);
  }

  @override
  Future<ReviewResult?> trackHappyMoment(String name) async {
    trackedHappyMoments.add(name);
    await trackEvent(name);
    if (fakeIsReady) {
      return requestReview();
    }
    return null;
  }

  @override
  Future<ReviewResult> requestReview() async {
    requestReviewCallCount++;
    return fakeResult;
  }

  @override
  Future<ReviewResult> requestReviewIfReady() async {
    requestReviewIfReadyCallCount++;
    if (!fakeIsReady) {
      return ReviewResult.notReady;
    }
    return requestReview();
  }

  @override
  Future<void> reset() async {
    resetCalled = true;
    _state = const ReviewState();
    trackedEvents.clear();
    trackedHappyMoments.clear();
    trackLaunchCallCount = 0;
    requestReviewCallCount = 0;
    requestReviewIfReadyCallCount = 0;
  }

  @override
  void dispose() {
    disposeCalled = true;
    _readyController.close();
  }

  /// Emits a value on [readyStream]. Useful for testing stream listeners.
  void emitReady(bool ready) {
    fakeIsReady = ready;
    _readyController.add(ready);
  }
}
