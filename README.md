# flutter_review_kit

Smart app review prompting for Flutter. Condition-based triggering with launch count, days since install, custom events, and happy moments.

## Features

- Condition-based review prompting (launches, days, events)
- Cooldown period to prevent review fatigue
- Per-version prompt cap
- Happy moment triggers (prompt after positive events)
- Persistent state via SharedPreferences
- Stream-based readiness for reactive UI
- Debug mode with detailed logging
- `FakeReviewManager` for testing
- Instance-based, state-management neutral

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_review_kit: ^0.1.0
  in_app_review: ^2.0.0  # peer dependency
```

## Quick Start

```dart
import 'package:flutter_review_kit/flutter_review_kit.dart';
import 'package:in_app_review/in_app_review.dart';

final manager = ReviewManager(
  config: const ReviewConfig(
    minLaunches: 5,
    minDaysInstalled: 7,
    minEvents: 3,
  ),
  reviewRequester: () async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
      return true;
    }
    return false;
  },
  appVersion: '1.0.0',
);

await manager.initialize();
await manager.trackLaunch();

// Later, after positive user action:
final result = await manager.requestReviewIfReady();
```

## Testing

```dart
final fake = FakeReviewManager();
fake.fakeIsReady = true;
fake.fakeResult = ReviewResult.shown;

final result = await fake.requestReviewIfReady();
expect(result, ReviewResult.shown);
```

## License

MIT
