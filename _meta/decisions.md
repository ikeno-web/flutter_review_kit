# Decisions Log — flutter_review_kit

## D-001: Dart/Flutter minimum versions
- **Decision**: Dart 3.4+, Flutter 3.22+
- **Rationale**: Aligns with flutter_admob_kit sibling project. Dart 3.4 provides stable sealed classes, pattern matching. Flutter 3.22 is the current stable baseline.
- **Date**: 2026-06-28

## D-002: Wrap in_app_review as peer dependency
- **Decision**: Use `in_app_review` package as a peer dependency, not bundled.
- **Rationale**: Consumers control the version. Avoids version conflicts. Standard pattern for wrapper libraries.
- **Date**: 2026-06-28

## D-003: Instance-based architecture (no singletons)
- **Decision**: `ReviewManager` is a plain class instantiated by the consumer. No static instance, no service locator.
- **Rationale**: Consistent with flutter_admob_kit. Testable. Works with any DI approach (Provider, Riverpod, get_it, manual).
- **Date**: 2026-06-28

## D-004: Condition-based triggering
- **Decision**: Prompt only when configurable conditions are met (min launches, min days since install, min events, cooldown, per-version cap).
- **Rationale**: Google/Apple guidelines recommend non-intrusive prompting. Condition-based approach prevents review fatigue and maximizes positive review likelihood.
- **Date**: 2026-06-28

## D-005: SharedPreferences for persistence
- **Decision**: Use `shared_preferences` to persist review state (launch count, event count, dates, prompt history).
- **Rationale**: Lightweight, already a transitive dependency in most Flutter apps. No database overhead for simple key-value state.
- **Date**: 2026-06-28

## D-006: State-management neutral
- **Decision**: Expose `ChangeNotifier`-compatible getters and `Stream<bool>` for readiness. No dependency on Provider, Riverpod, Bloc, etc.
- **Rationale**: Library consumers choose their own state management. Streams and getters integrate with anything.
- **Date**: 2026-06-28

## D-007: FakeReviewManager for testing
- **Decision**: Ship a `FakeReviewManager` that implements `ReviewManager` interface without platform channels.
- **Rationale**: Consumers need to test review flows in unit/widget tests. Platform channels fail in test environments.
- **Date**: 2026-06-28

## D-008: MIT license
- **Decision**: MIT license.
- **Rationale**: Maximally permissive. Standard for Flutter ecosystem packages. Matches flutter_admob_kit.
- **Date**: 2026-06-28

## D-009: 90%+ test coverage target
- **Decision**: Maintain 90%+ line coverage.
- **Rationale**: Library code must be reliable. High coverage catches regressions early. Achievable since the library has no UI and minimal platform interaction (abstracted behind interfaces).
- **Date**: 2026-06-28
