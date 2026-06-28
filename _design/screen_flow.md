# API Design — flutter_review_kit

## Public API Surface

```dart
// ─── Configuration ───────────────────────────────────────

/// Immutable configuration for review prompting behavior.
class ReviewConfig {
  const ReviewConfig({
    this.minLaunches = 5,
    this.minDaysInstalled = 7,
    this.minEvents = 3,
    this.cooldownDays = 90,
    this.maxPromptsPerVersion = 1,
    this.happyMoments = const [],
    this.debug = false,
  });
}

// ─── State ───────────────────────────────────────────────

/// Immutable snapshot of review tracking state.
class ReviewState {
  final int launchCount;
  final int eventCount;
  final DateTime? firstLaunchDate;
  final DateTime? lastPromptDate;
  final int promptCount;
  final String? lastPromptVersion;
  final bool hasReviewed;

  ReviewState copyWith({...});
}

// ─── Result ──────────────────────────────────────────────

enum ReviewResult {
  shown,         // Review dialog was requested successfully
  notReady,      // Conditions not met
  cooldown,      // Within cooldown period
  alreadyPromptedThisVersion, // Max prompts for this version reached
  error,         // Platform error
}

// ─── Store Interface ─────────────────────────────────────

/// Abstract persistence layer. Implement for custom storage.
abstract class ReviewStore {
  Future<ReviewState> load();
  Future<void> save(ReviewState state);
  Future<void> clear();
}

/// Production store using SharedPreferences.
class SharedPreferencesStore implements ReviewStore { ... }

/// In-memory store for testing.
class MemoryStore implements ReviewStore { ... }

// ─── Core Manager ────────────────────────────────────────

/// Manages review prompt conditions, tracking, and triggering.
class ReviewManager {
  ReviewManager({
    required ReviewConfig config,
    ReviewStore? store,          // defaults to SharedPreferencesStore
    InAppReview? inAppReview,    // injectable for testing
    String? appVersion,          // current app version for per-version cap
  });

  /// Load persisted state. Must be called before other methods.
  Future<void> initialize();

  // ── Tracking ──
  Future<void> trackLaunch();
  Future<void> trackEvent(String eventName);
  Future<void> trackHappyMoment(String name);

  // ── Checking ──
  bool get isReady;
  Stream<bool> get readyStream;
  ReviewState get state;

  // ── Prompting ──
  Future<ReviewResult> requestReview();
  Future<ReviewResult> requestReviewIfReady();

  // ── Debug/testing ──
  Future<void> reset();
  void dispose();
}

// ─── Testing ─────────────────────────────────────────────

/// Fake implementation for unit/widget tests.
class FakeReviewManager implements ReviewManager {
  bool fakeIsReady;
  ReviewResult fakeResult;
  // All tracking methods are no-ops that record calls.
  List<String> trackedEvents;
  int trackLaunchCount;
}
```

## Flow Diagram

```
App Start
  │
  ├─ ReviewManager(config: ..., store: ...) 
  │
  ├─ await manager.initialize()    ← loads persisted state
  │
  ├─ await manager.trackLaunch()   ← increments launch count
  │
  │  ... user uses app ...
  │
  ├─ await manager.trackEvent('level_complete')
  │
  ├─ if (manager.isReady)          ← sync check, <1ms
  │     await manager.requestReview()
  │
  │  OR
  │
  ├─ await manager.requestReviewIfReady()  ← combined check+prompt
  │
  └─ manager.dispose()            ← clean up streams
```

## SharedPreferences Key Schema

All keys prefixed with `flutter_review_kit_`:

| Key | Type | Description |
|-----|------|-------------|
| `flutter_review_kit_launch_count` | int | Total app launches tracked |
| `flutter_review_kit_event_count` | int | Total custom events tracked |
| `flutter_review_kit_first_launch` | String (ISO 8601) | First launch timestamp |
| `flutter_review_kit_last_prompt` | String (ISO 8601) | Last review prompt timestamp |
| `flutter_review_kit_prompt_count` | int | Total times review was prompted |
| `flutter_review_kit_last_prompt_version` | String | App version at last prompt |
| `flutter_review_kit_has_reviewed` | bool | Whether user has reviewed |
