# Changelog — flutter_review_kit

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-06-28

### Added
- `ReviewManager` — core class for managing review prompts
- `ReviewConfig` — immutable configuration with sensible defaults
- `ReviewState` — immutable state with `copyWith`
- `ReviewStore` — abstract persistence interface
- `SharedPreferencesStore` — production persistence via shared_preferences
- `MemoryStore` — in-memory store for testing
- `FakeReviewManager` — controllable mock for unit/widget tests
- `ReviewResult` enum — outcome of review requests
- Condition-based triggering (min launches, min days, min events)
- Cooldown period after prompting
- Per-version prompt cap
- Happy moment tracking
- Debug mode with condition logging
- `Stream<bool>` for reactive readiness updates
- Comprehensive test suite (90%+ coverage target)
