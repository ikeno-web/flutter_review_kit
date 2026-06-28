# Constraints — flutter_review_kit

## Technical Constraints
- **C-01**: Dart SDK >= 3.4.0, Flutter SDK >= 3.22.0
- **C-02**: Must not depend on any state management package (Provider, Riverpod, Bloc, etc.)
- **C-03**: `in_app_review` is a peer dependency — consumer adds it to their pubspec
- **C-04**: All SharedPreferences reads must be cached in memory after `initialize()`
- **C-05**: Condition checks (`isReady`) must complete in <1ms (no async, no I/O)
- **C-06**: No UI code in the library — review dialog is platform-native via in_app_review

## Platform Constraints
- **C-07**: Android: Google Play In-App Review API (one prompt per session, no guarantee of display)
- **C-08**: iOS: SKStoreReviewController (3 prompts per 365-day period, system-controlled)
- **C-09**: No way to know if user actually left a review (platform limitation)

## Design Constraints
- **C-10**: Instance-based — no singletons, no global state
- **C-11**: All public API methods must be documented with dartdoc
- **C-12**: Breaking changes require major version bump (semver)
- **C-13**: SharedPreferences keys must be prefixed to avoid collisions (`flutter_review_kit_`)

## Quality Constraints
- **C-14**: 90%+ test coverage
- **C-15**: Zero analyzer warnings (flutter_lints)
- **C-16**: All public types exported from barrel file
