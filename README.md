# flutter_review_kit

[![pub.dev](https://img.shields.io/pub/v/flutter_review_kit.svg)](https://pub.dev/packages/flutter_review_kit)
[![CI](https://github.com/ikeno-web/flutter_review_kit/actions/workflows/ci.yaml/badge.svg)](https://github.com/ikeno-web/flutter_review_kit/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.0-blue.svg)](https://flutter.dev)

Condition-based app review prompting for Flutter. Prompt at the right moment — not just the first time a user opens the app.

---

## Why flutter_review_kit?

The platform `in_app_review` package provides the raw OS dialog. It does not decide *when* to show it. Calling it blindly on launch burns the prompt for users who haven't experienced your app yet, and calling it too often triggers platform-side suppression.

`flutter_review_kit` sits on top of `in_app_review` and handles the decision layer:

| Concern | Raw `in_app_review` | flutter_review_kit |
|---|---|---|
| Minimum launch count | You implement | Built-in |
| Minimum days since install | You implement | Built-in |
| Custom event threshold | You implement | Built-in |
| Cooldown between prompts | You implement | Built-in |
| Per-version prompt cap | You implement | Built-in |
| Happy moment triggers | You implement | Built-in |
| Persistent state | You implement | SharedPreferences, zero config |
| Testability | Difficult (platform channel) | `FakeReviewManager` drop-in |
| Stream-based readiness | You implement | `readyStream` built-in |

---

## Requirements

| Dependency | Version |
|---|---|
| Flutter | >= 3.0.0 |
| Dart | >= 3.0.0 |
| Android | API 21+ |
| iOS | 14.0+ |
| `in_app_review` | ^2.0.0 (peer dependency) |

---

## Installation

```yaml
dependencies:
  flutter_review_kit: ^0.1.0
  in_app_review: ^2.0.0
```

---

## Quick Start

```dart
import 'package:flutter_review_kit/flutter_review_kit.dart';
import 'package:in_app_review/in_app_review.dart';

// Create once and keep alive (singleton, provider, or service locator).
final reviewManager = ReviewManager(
  config: const ReviewConfig(
    minLaunches: 5,
    minDaysInstalled: 7,
    minEvents: 3,
    cooldownDays: 90,
    maxPromptsPerVersion: 1,
  ),
  reviewRequester: () async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
      return true;
    }
    return false;
  },
  appVersion: '1.2.0',
);

// Call once at startup, before any other method.
await reviewManager.initialize();
await reviewManager.trackLaunch();

// Later, after a positive user action:
final result = await reviewManager.requestReviewIfReady();
// result is ReviewResult.shown | notReady | cooldown | alreadyPromptedThisVersion | error
```

---

## Features

### Condition-based triggering

All configured thresholds must be satisfied before a prompt is shown. Each condition defaults to a sensible value and can be set to `0` to opt out.

```dart
const config = ReviewConfig(
  minLaunches: 5,        // user must open the app at least 5 times
  minDaysInstalled: 7,   // and have had it installed for at least 7 days
  minEvents: 3,          // and have completed at least 3 meaningful actions
);
```

Track launches and events wherever the logic lives in your app:

```dart
// In your app lifecycle (e.g., WidgetsBindingObserver.didChangeAppLifecycleState)
await reviewManager.trackLaunch();

// After any user action worth counting (item saved, level completed, export done, etc.)
await reviewManager.trackEvent('export_completed');
```

`trackEvent` accepts any string label; the label is logged in debug mode and all events contribute to the same `minEvents` counter.

---

### Happy moments

A happy moment is a named event that, when it occurs and all conditions are met, automatically requests a review. Define the names in config:

```dart
const config = ReviewConfig(
  happyMoments: ['goal_achieved', 'streak_7_days', 'purchase_completed'],
);
```

Then call `trackHappyMoment` at the relevant point:

```dart
// After the user hits a personal best, completes a streak, etc.
final result = await reviewManager.trackHappyMoment('goal_achieved');
// Returns ReviewResult? — non-null if a prompt was triggered, null otherwise.
```

Happy moments also count toward the `minEvents` threshold.

---

### Cooldown and per-version caps

After a prompt is shown, `cooldownDays` prevents another prompt regardless of conditions:

```dart
const config = ReviewConfig(
  cooldownDays: 90,           // wait 90 days before prompting again
  maxPromptsPerVersion: 1,    // and no more than once per app version
);
```

`maxPromptsPerVersion` resets automatically when `appVersion` changes, so a major update can prompt a previously-prompted user again.

Debug mode bypasses the cooldown check, making it easier to verify the flow during development:

```dart
const config = ReviewConfig(debug: true);
```

---

### Checking readiness

**Synchronous check** — guaranteed under 1 ms, uses cached state:

```dart
if (reviewManager.isReady) {
  // show a custom pre-prompt UI, then call requestReview()
}
```

**Stream-based** — reacts to state changes (launch tracked, event tracked, reset called):

```dart
reviewManager.readyStream.listen((ready) {
  setState(() => _showReviewBanner = ready);
});
```

**Combined check-and-request**:

```dart
final result = await reviewManager.requestReviewIfReady();

switch (result) {
  case ReviewResult.shown:
    // prompt was requested
  case ReviewResult.notReady:
    // conditions not yet met
  case ReviewResult.cooldown:
    // within cooldown window
  case ReviewResult.alreadyPromptedThisVersion:
    // cap reached for current version
  case ReviewResult.error:
    // platform call failed
}
```

---

### Debug mode

Enable `debug: true` in `ReviewConfig` to print condition checks to the console and bypass the cooldown. Each check logs the reason a prompt is or is not ready:

```
[ReviewKit] Initialized. State: ReviewState(launchCount: 3, ...)
[ReviewKit] Not ready: launches 3 < 5
[ReviewKit] trackLaunch: count=4
[ReviewKit] trackEvent("export_completed"): count=1
```

---

## Configuration Reference

| Parameter | Type | Default | Description |
|---|---|---|---|
| `minLaunches` | `int` | `5` | Minimum `trackLaunch` calls before prompting. |
| `minDaysInstalled` | `int` | `7` | Minimum days since first tracked launch. |
| `minEvents` | `int` | `3` | Minimum `trackEvent` (or `trackHappyMoment`) calls. |
| `cooldownDays` | `int` | `90` | Days to wait after a prompt before allowing another. |
| `maxPromptsPerVersion` | `int` | `1` | Maximum prompts per `appVersion` string. Resets on version change. |
| `happyMoments` | `List<String>` | `[]` | Event names that auto-trigger a review when conditions are met. |
| `debug` | `bool` | `false` | Logs condition checks to console; bypasses cooldown. |

---

## Testing

### FakeReviewManager

`FakeReviewManager` implements the full `ReviewManager` interface without platform channels. Swap it in during tests and widget tests:

```dart
final fake = FakeReviewManager(
  fakeIsReady: true,
  fakeResult: ReviewResult.shown,
);

await fake.trackLaunch();
await fake.trackEvent('export_completed');
final result = await fake.requestReviewIfReady();

expect(result, ReviewResult.shown);
expect(fake.requestReviewCallCount, 1);
expect(fake.trackedEvents, contains('export_completed'));
```

Available inspection properties on `FakeReviewManager`:

| Property | Type | Description |
|---|---|---|
| `fakeIsReady` | `bool` | Controls `isReady` return value. |
| `fakeResult` | `ReviewResult` | Controls `requestReview` / `requestReviewIfReady` return value. |
| `trackLaunchCallCount` | `int` | Number of `trackLaunch` calls received. |
| `requestReviewCallCount` | `int` | Number of `requestReview` calls received. |
| `requestReviewIfReadyCallCount` | `int` | Number of `requestReviewIfReady` calls received. |
| `trackedEvents` | `List<String>` | All event names passed to `trackEvent`. |
| `trackedHappyMoments` | `List<String>` | All names passed to `trackHappyMoment`. |
| `initializeCalled` | `bool` | Whether `initialize` was called. |

Use `fake.emitReady(true)` to push a value on `readyStream` and test stream listeners.

### MemoryStore

For lower-level tests that need a real `ReviewManager` without SharedPreferences, inject `MemoryStore`:

```dart
final store = MemoryStore();
final manager = ReviewManager(
  config: const ReviewConfig(minLaunches: 2, minDaysInstalled: 0, minEvents: 0),
  store: store,
);
await manager.initialize();
await manager.trackLaunch();
await manager.trackLaunch();

expect(manager.isReady, isTrue);
expect(store.currentState.launchCount, 2);
```

---

## How It Works

```
App startup
    |
    v
ReviewManager.initialize()
    Loads state from SharedPreferences (or custom store).
    Sets firstLaunchDate on first run.
    |
    v
trackLaunch() / trackEvent() / trackHappyMoment()
    Increments counters, persists state.
    Emits on readyStream if isReady changes.
    |
    v
requestReviewIfReady()
    1. Per-version cap check  -> alreadyPromptedThisVersion
    2. Cooldown check         -> cooldown
    3. All conditions check   -> notReady
    4. reviewRequester()      -> shown | error
    Updates lastPromptDate, promptCount, lastPromptVersion.
```

State is persisted after every mutation, so progress survives force-quits and OS kills.

---

## Before / After

**Without flutter_review_kit** — you write and maintain all of this:

```dart
// Somewhere in your app...
final prefs = await SharedPreferences.getInstance();
final launches = prefs.getInt('launches') ?? 0;
final firstLaunch = prefs.getString('first_launch');
final lastPrompt = prefs.getString('last_prompt');
final promptVersion = prefs.getString('prompt_version');

await prefs.setInt('launches', launches + 1);

final now = DateTime.now();
final daysSince = firstLaunch != null
    ? now.difference(DateTime.parse(firstLaunch)).inDays
    : 0;
final daysSincePrompt = lastPrompt != null
    ? now.difference(DateTime.parse(lastPrompt)).inDays
    : 999;

if (launches >= 5 &&
    daysSince >= 7 &&
    daysSincePrompt >= 90 &&
    promptVersion != appVersion) {
  final review = InAppReview.instance;
  if (await review.isAvailable()) {
    await review.requestReview();
    await prefs.setString('last_prompt', now.toIso8601String());
    await prefs.setString('prompt_version', appVersion);
  }
}
```

**With flutter_review_kit**:

```dart
await reviewManager.trackLaunch();
await reviewManager.requestReviewIfReady();
```

---

## Custom Store

Implement `ReviewStore` to use any persistence backend (Hive, Isar, SQLite, etc.):

```dart
class HiveReviewStore implements ReviewStore {
  @override
  Future<ReviewState> load() async {
    final box = Hive.box('review');
    final raw = box.get('state');
    return raw != null ? ReviewState.fromMap(Map<String, dynamic>.from(raw)) : ReviewState.empty;
  }

  @override
  Future<void> save(ReviewState state) async {
    await Hive.box('review').put('state', state.toMap());
  }

  @override
  Future<void> clear() async {
    await Hive.box('review').delete('state');
  }
}
```

Pass it to `ReviewManager`:

```dart
final manager = ReviewManager(
  config: const ReviewConfig(),
  store: HiveReviewStore(),
);
```

---

## License

MIT — see [LICENSE](LICENSE).
