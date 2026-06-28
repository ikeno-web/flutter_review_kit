import 'dart:async';

import 'review_config.dart';
import 'review_result.dart';
import 'review_state.dart';
import 'review_store.dart';
import 'shared_preferences_store.dart';

/// Callback type for requesting the platform review dialog.
///
/// Returns true if the request was made successfully.
/// This abstraction allows testing without platform channels.
typedef ReviewRequester = Future<bool> Function();

/// Manages review prompt conditions, tracking, and triggering.
///
/// Create an instance with a [ReviewConfig] and call [initialize] before
/// using any other methods:
///
/// ```dart
/// final manager = ReviewManager(
///   config: const ReviewConfig(minLaunches: 5, minDaysInstalled: 7),
/// );
/// await manager.initialize();
/// await manager.trackLaunch();
///
/// final result = await manager.requestReviewIfReady();
/// ```
class ReviewManager {
  /// The configuration controlling when reviews are prompted.
  final ReviewConfig config;

  /// The persistence store for review state.
  final ReviewStore store;

  /// The current app version, used for per-version prompt caps.
  final String? appVersion;

  /// Optional callback to request the platform review dialog.
  ///
  /// If null, [requestReview] will return [ReviewResult.shown] when
  /// conditions are met (useful for testing without in_app_review).
  final ReviewRequester? reviewRequester;

  /// Clock function for testability. Returns current time.
  final DateTime Function() clock;

  ReviewState _state = const ReviewState();
  bool _initialized = false;
  final StreamController<bool> _readyController =
      StreamController<bool>.broadcast();
  bool _lastReady = false;
  bool _disposed = false;

  /// Creates a review manager.
  ///
  /// [config] controls when review prompts are shown.
  /// [store] defaults to [SharedPreferencesStore] if not provided.
  /// [reviewRequester] is the callback to show the platform review dialog.
  /// [appVersion] is used for per-version prompt caps.
  /// [clock] is injectable for testing; defaults to [DateTime.now].
  ReviewManager({
    required this.config,
    ReviewStore? store,
    this.reviewRequester,
    this.appVersion,
    DateTime Function()? clock,
  })  : store = store ?? SharedPreferencesStore(),
        clock = clock ?? DateTime.now;

  /// Loads persisted state. Must be called before other methods.
  ///
  /// If this is the first launch, sets [ReviewState.firstLaunchDate] to now.
  Future<void> initialize() async {
    _state = await store.load();

    if (_state.firstLaunchDate == null) {
      _state = _state.copyWith(firstLaunchDate: clock());
      await store.save(_state);
    }

    _initialized = true;
    _lastReady = isReady;
    _debugLog('Initialized. State: $_state');
    _debugLog('isReady: $_lastReady');
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'ReviewManager.initialize() must be called before using other methods.',
      );
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('ReviewManager has been disposed.');
    }
  }

  /// The current review tracking state.
  ReviewState get state {
    _ensureInitialized();
    return _state;
  }

  /// Whether all conditions for showing a review prompt are met.
  ///
  /// This is a synchronous check that uses cached state. Guaranteed <1ms.
  bool get isReady {
    if (!_initialized) return false;

    final now = clock();

    // Check minimum launches
    if (_state.launchCount < config.minLaunches) {
      _debugLog('Not ready: launches ${_state.launchCount} < ${config.minLaunches}');
      return false;
    }

    // Check minimum days installed
    if (_state.firstLaunchDate != null) {
      final daysSinceInstall =
          now.difference(_state.firstLaunchDate!).inDays;
      if (daysSinceInstall < config.minDaysInstalled) {
        _debugLog(
            'Not ready: days installed $daysSinceInstall < ${config.minDaysInstalled}');
        return false;
      }
    }

    // Check minimum events
    if (_state.eventCount < config.minEvents) {
      _debugLog(
          'Not ready: events ${_state.eventCount} < ${config.minEvents}');
      return false;
    }

    // Check cooldown (skip in debug mode)
    if (!config.debug && _state.lastPromptDate != null) {
      final daysSincePrompt =
          now.difference(_state.lastPromptDate!).inDays;
      if (daysSincePrompt < config.cooldownDays) {
        _debugLog(
            'Not ready: cooldown $daysSincePrompt < ${config.cooldownDays} days');
        return false;
      }
    }

    // Check per-version cap
    if (appVersion != null &&
        _state.lastPromptVersion == appVersion &&
        _state.promptCount >= config.maxPromptsPerVersion) {
      _debugLog(
          'Not ready: already prompted ${_state.promptCount} times for version $appVersion');
      return false;
    }

    _debugLog('Ready!');
    return true;
  }

  /// A broadcast stream that emits whenever [isReady] changes.
  Stream<bool> get readyStream => _readyController.stream;

  /// Records an app launch and increments the launch counter.
  Future<void> trackLaunch() async {
    _ensureInitialized();
    _ensureNotDisposed();

    _state = _state.copyWith(launchCount: _state.launchCount + 1);
    await store.save(_state);
    _debugLog('trackLaunch: count=${_state.launchCount}');
    _emitReadyIfChanged();
  }

  /// Records a custom event and increments the event counter.
  ///
  /// [eventName] is logged in debug mode but does not affect the count
  /// differently per event type.
  Future<void> trackEvent(String eventName) async {
    _ensureInitialized();
    _ensureNotDisposed();

    _state = _state.copyWith(eventCount: _state.eventCount + 1);
    await store.save(_state);
    _debugLog('trackEvent("$eventName"): count=${_state.eventCount}');
    _emitReadyIfChanged();
  }

  /// Records a happy moment event.
  ///
  /// If [name] is in [ReviewConfig.happyMoments] and conditions are met,
  /// automatically requests a review.
  ///
  /// Returns the review result if a prompt was triggered, or null otherwise.
  Future<ReviewResult?> trackHappyMoment(String name) async {
    _ensureInitialized();
    _ensureNotDisposed();

    _debugLog('trackHappyMoment("$name")');

    // Track as a regular event too
    await trackEvent(name);

    // If this is a configured happy moment and we're ready, prompt
    if (config.happyMoments.contains(name) && isReady) {
      _debugLog('Happy moment triggered review!');
      return requestReview();
    }

    return null;
  }

  /// Requests the platform review dialog.
  ///
  /// Returns [ReviewResult.shown] if the request was made successfully.
  /// Returns [ReviewResult.error] if the platform call fails.
  ///
  /// This does NOT check conditions. Use [requestReviewIfReady] for a
  /// combined check-and-request.
  Future<ReviewResult> requestReview() async {
    _ensureInitialized();
    _ensureNotDisposed();

    try {
      if (reviewRequester != null) {
        final success = await reviewRequester!();
        if (!success) {
          return ReviewResult.error;
        }
      }

      // Update state — reset per-version counter when version changes
      final isNewVersion =
          appVersion != null && _state.lastPromptVersion != appVersion;
      _state = _state.copyWith(
        lastPromptDate: clock(),
        promptCount: isNewVersion ? 1 : _state.promptCount + 1,
        lastPromptVersion: appVersion,
      );
      await store.save(_state);
      _debugLog('Review requested. promptCount=${_state.promptCount}');
      _emitReadyIfChanged();

      return ReviewResult.shown;
    } catch (e) {
      _debugLog('Review request error: $e');
      return ReviewResult.error;
    }
  }

  /// Checks conditions and requests a review if ready.
  ///
  /// Returns the appropriate [ReviewResult] based on the current state.
  Future<ReviewResult> requestReviewIfReady() async {
    _ensureInitialized();
    _ensureNotDisposed();

    // Check per-version cap first (more specific)
    if (appVersion != null &&
        _state.lastPromptVersion == appVersion &&
        _state.promptCount >= config.maxPromptsPerVersion) {
      return ReviewResult.alreadyPromptedThisVersion;
    }

    // Check cooldown
    if (!config.debug && _state.lastPromptDate != null) {
      final daysSincePrompt =
          clock().difference(_state.lastPromptDate!).inDays;
      if (daysSincePrompt < config.cooldownDays) {
        return ReviewResult.cooldown;
      }
    }

    // Check all conditions
    if (!isReady) {
      return ReviewResult.notReady;
    }

    return requestReview();
  }

  /// Clears all persisted state and resets to initial values.
  Future<void> reset() async {
    _ensureInitialized();
    _ensureNotDisposed();

    await store.clear();
    _state = const ReviewState();
    _debugLog('State reset.');
    _emitReadyIfChanged();
  }

  /// Releases resources. The manager must not be used after disposal.
  void dispose() {
    _disposed = true;
    _readyController.close();
  }

  void _emitReadyIfChanged() {
    final currentReady = isReady;
    if (currentReady != _lastReady) {
      _lastReady = currentReady;
      if (!_readyController.isClosed) {
        _readyController.add(currentReady);
      }
    }
  }

  void _debugLog(String message) {
    if (config.debug) {
      // ignore: avoid_print
      print('[ReviewKit] $message');
    }
  }
}
