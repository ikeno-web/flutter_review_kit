# Code Review: flutter_review_kit

**Reviewer**: Reviewer Agent (Opus 4.6)
**Date**: 2026-06-28
**Scope**: All source files (`lib/src/`), barrel export, tests (`test/`), design doc, constraints

---

## Checklist

| # | Area | Status |
|---|------|--------|
| 1 | SharedPreferences key naming (prefix `flutter_review_kit_`) | PASS |
| 2 | SharedPreferences data format (types match design doc) | PASS |
| 3 | State persistence round-trip (no data loss) | ISSUE |
| 4 | Cooldown calculation (timezone / DST edge cases) | ISSUE |
| 5 | Stream lifecycle (broadcast controller leaks) | PASS |
| 6 | FakeReviewManager completeness | ISSUE |
| 7 | Dispose safety | PASS |
| 8 | Constraint C-04 (cached reads, no async in isReady) | PASS |
| 9 | Constraint C-05 (isReady < 1 ms) | PASS |
| 10 | Constraint C-10 (no singletons / global state) | PASS |
| 11 | Constraint C-11 (dartdoc on all public API) | PASS |
| 12 | Constraint C-13 (SP key prefix) | PASS |
| 13 | Constraint C-16 (barrel file exports all public types) | PASS |
| 14 | API surface matches design doc | ISSUE |
| 15 | Test coverage completeness | ISSUE |

---

## Issues

### I-01 [High] SharedPreferencesStore.save() does not clear nullable fields when set to null

**File**: `D:/アプリ開発/flutter_review_kit/lib/src/shared_preferences_store.dart` lines 39-60

`save()` only writes `firstLaunchDate`, `lastPromptDate`, and `lastPromptVersion` when they are non-null. If a field was previously persisted and later becomes null (e.g., after `reset()` which sets state to `ReviewState()` then calls `store.clear()`), the `save()` path itself is not affected because `reset()` correctly calls `clear()`. However, if a consumer implements a custom flow that saves a state with a null date after previously having a non-null date, the old value persists. This is an API contract violation: `save(state)` should produce a state that round-trips through `load()` identically.

**Recommendation**: When a nullable field is null, call `prefs.remove()` for that key inside `save()`.

```dart
if (state.firstLaunchDate != null) {
  await prefs.setString(_keyFirstLaunch, state.firstLaunchDate!.toIso8601String());
} else {
  await prefs.remove(_keyFirstLaunch);
}
```

Apply the same pattern to `lastPromptDate` and `lastPromptVersion`.

---

### I-02 [Medium] Cooldown and day calculations use `Duration.inDays` which is DST/timezone-fragile

**File**: `D:/アプリ開発/flutter_review_kit/lib/src/review_manager.dart` lines 125-126, 141-143, 268-270

`DateTime.now()` (the default clock) returns local time. `Duration.inDays` is purely arithmetic (microseconds / 86400000000). When a DST transition occurs, a 7-calendar-day span might compute as 6 or 7 `inDays` depending on the 1-hour shift. For cooldown of 90 days this is negligible, but for short `minDaysInstalled` values (e.g. 1) it could cause a one-day-early trigger.

**Recommendation**: Either:
- Document that the clock should return UTC (and default to `DateTime.now().toUtc()`), or
- Compare calendar dates instead of Duration:
  ```dart
  final daysDiff = DateTime(now.year, now.month, now.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
  ```

---

### I-03 [Medium] FakeReviewManager.store creates a new MemoryStore on every access

**File**: `D:/アプリ開発/flutter_review_kit/lib/src/fake_review_manager.dart` line 69

```dart
@override
ReviewStore get store => MemoryStore();
```

Every call to `.store` returns a brand-new `MemoryStore` instance. If any consumer code reads `manager.store` twice expecting the same instance (or calls `store.load()` to inspect state), it gets a fresh empty store each time.

**Recommendation**: Cache the store in a final field:
```dart
@override
final ReviewStore store = MemoryStore();
```

---

### I-04 [Medium] FakeReviewManager does not check happyMoments config for trigger

**File**: `D:/アプリ開発/flutter_review_kit/lib/src/fake_review_manager.dart` lines 107-114

The real `ReviewManager.trackHappyMoment` only triggers a review if the event name is in `config.happyMoments`. The fake triggers review for ANY happy moment as long as `fakeIsReady` is true. This divergence could mask bugs in consumer code that passes unconfigured event names.

**Recommendation**: Either document this as intentional simplification, or mirror the real logic:
```dart
if (fakeIsReady && config.happyMoments.contains(name)) {
  return requestReview();
}
```
(Would also require making `config` settable or accepting it in the constructor.)

---

### I-05 [Medium] Per-version cap logic uses cumulative `promptCount` instead of per-version count

**File**: `D:/アプリ開発/flutter_review_kit/lib/src/review_manager.dart` lines 152-157

The version cap check is:
```dart
if (appVersion != null &&
    _state.lastPromptVersion == appVersion &&
    _state.promptCount >= config.maxPromptsPerVersion)
```

`promptCount` is a cumulative total across all versions. If a user was prompted once on v1.0.0, then upgrades to v2.0.0 and gets prompted, `promptCount` becomes 2. If `maxPromptsPerVersion` is 1, the check passes because `lastPromptVersion` changed. But if `maxPromptsPerVersion` is 2 and the user was prompted once on v1 and once on v2, `promptCount` = 2 which would falsely block v2 from getting a second prompt.

This currently works for the default `maxPromptsPerVersion: 1` because the `lastPromptVersion` gate catches it, but is incorrect for `maxPromptsPerVersion > 1`.

**Recommendation**: Either:
- Track a `promptCountForCurrentVersion` field, or
- Reset `promptCount` to 0 when `lastPromptVersion` changes, or
- Document that `maxPromptsPerVersion` must be 1 (and assert it).

---

### I-06 [Low] No test for SharedPreferencesStore

**File**: `D:/アプリ開発/flutter_review_kit/test/` (missing `shared_preferences_store_test.dart`)

The `SharedPreferencesStore` has no dedicated test file. The issues in I-01 (nullable field persistence) would be caught by such tests. While the class is indirectly exercised if integration tests exist, unit-level coverage is missing per constraint C-14 (90%+ coverage).

**Recommendation**: Add `shared_preferences_store_test.dart` using `SharedPreferences.setMockInitialValues({})` to test:
- load() from empty prefs
- save() then load() round-trip with all fields
- save() with null fields overwrites previously-set values
- clear() removes all keys

---

### I-07 [Low] ReviewState.copyWith cannot clear nullable fields back to null

**File**: `D:/アプリ開発/flutter_review_kit/lib/src/review_state.dart` lines 45-63

The `copyWith` pattern `firstLaunchDate: firstLaunchDate ?? this.firstLaunchDate` means once a DateTime is set, it cannot be reset to null via `copyWith`. The `reset()` method works around this by creating a fresh `const ReviewState()`, but the API is incomplete.

This is a common Dart `copyWith` limitation. Since `reset()` bypasses `copyWith`, the impact is low, but consumers who might want to clear a single field cannot.

**Recommendation**: Accept this as a known limitation and document it, or use a sentinel pattern / `Object?` wrapper for nullable fields.

---

### I-08 [Low] Design doc specifies `InAppReview?` parameter but implementation uses `ReviewRequester` callback

**File**: `D:/アプリ開発/flutter_review_kit/_design/screen_flow.md` line 69 vs `D:/アプリ開発/flutter_review_kit/lib/src/review_manager.dart` line 43

The design doc shows:
```dart
ReviewManager({
  ...
  InAppReview? inAppReview,  // injectable for testing
});
```

The implementation uses:
```dart
final ReviewRequester? reviewRequester;
```

The implementation is arguably better (decouples from in_app_review types), but it diverges from the approved API surface.

**Recommendation**: Update the design doc to match the implementation, since the callback approach is cleaner and avoids a hard dependency on `in_app_review` types inside the library.

---

### I-09 [Info] `hasReviewed` is set via `ReviewResult.shown` comment but never actually set to `true`

**File**: `D:/アプリ開発/flutter_review_kit/lib/src/review_state.dart` line 28, `review_manager.dart` lines 236-240

The dartdoc on `hasReviewed` says "This is set via ReviewManager when the prompt completes without error." However, `requestReview()` never sets `hasReviewed = true`. Since platforms cannot reliably report whether a review was submitted (constraint C-09), this field is inert. The dartdoc is misleading.

**Recommendation**: Either:
- Remove `hasReviewed` entirely (since it can never be accurately set), or
- Provide a public method `markReviewed()` for apps that detect reviews through other means, or
- Fix the dartdoc to clarify it must be set manually.

---

### I-10 [Info] `requestReview()` does not guard against concurrent calls

**File**: `D:/アプリ開発/flutter_review_kit/lib/src/review_manager.dart` lines 223-250

If `requestReview()` is called twice concurrently (e.g., from a happy moment callback and a manual trigger), both calls will increment `promptCount` and save. The second save overwrites the first. Because the in-memory `_state` is updated before `await store.save()`, and Dart is single-threaded, this is safe from race conditions in practice. No action needed, but worth documenting.

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 1 |
| Medium | 4 |
| Low | 3 |
| Info | 2 |

**Architecture**: Clean, well-structured. Separation of config/state/store/manager is textbook. The `ReviewRequester` callback typedef is a good design choice that avoids coupling to `in_app_review` types. Broadcast stream for readiness is correctly implemented with deduplication.

**Testing**: Good coverage of core paths (67 assertions across 6 test files). Missing: SharedPreferencesStore unit tests, DST edge case tests, `maxPromptsPerVersion > 1` test, concurrent request test.

**Constraints compliance**: C-01 through C-13 all satisfied. C-14 (90% coverage) likely not met due to missing SharedPreferencesStore tests. C-15 and C-16 appear satisfied.

---

## Verdict: **PASS** (conditional)

The library is well-designed and correctly implements the core review-prompting workflow. No critical bugs. The High-severity issue (I-01: nullable field persistence in SharedPreferencesStore) should be fixed before v1.0.0 release. The Medium issues (I-02 through I-05) should be addressed or explicitly documented as accepted trade-offs. The remaining items are low-risk improvements.

**Required before merge**:
- Fix I-01 (SharedPreferencesStore.save nullable field handling)

**Recommended before v1.0.0**:
- Fix I-05 (per-version prompt count logic)
- Add SharedPreferencesStore unit tests (I-06)
- Update design doc to match implementation (I-08)
- Clarify or remove `hasReviewed` (I-09)
