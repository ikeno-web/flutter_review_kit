# Requirements — flutter_review_kit

## User Stories

### MUST (P0)

| ID | Story | Acceptance Criteria |
|----|-------|-------------------|
| US-01 | As a developer, I can configure review conditions (min launches, min days, min events) so that users are prompted at the right moment. | `ReviewConfig` accepts all three thresholds with sensible defaults. |
| US-02 | As a developer, launch count is tracked automatically when I call `trackLaunch()` so that launch-based conditions work. | `trackLaunch()` increments persisted counter. |
| US-03 | As a developer, I can track custom events (e.g., "level_complete") so that event-based conditions work. | `trackEvent(name)` increments persisted counter. |
| US-04 | As a developer, I can check if conditions are met before prompting so that I control when the dialog appears. | `isReady` returns bool synchronously (<1ms). |
| US-05 | As a developer, the in-app review dialog is shown when conditions are met. | `requestReview()` calls `in_app_review` when ready. |
| US-06 | As a developer, the library respects cooldown periods after prompting so users are not spammed. | `cooldownDays` config prevents re-prompt within the window. |
| US-07 | As a developer, state persists across app restarts via SharedPreferences. | All counters and dates survive app kill/restart. |
| US-12 | As a developer, I can use `FakeReviewManager` in tests without platform channels. | `FakeReviewManager` implements the same interface, controllable behavior. |

### SHOULD (P1)

| ID | Story | Acceptance Criteria |
|----|-------|-------------------|
| US-08 | As a developer, I can reset state for testing or debugging. | `reset()` clears all persisted state. |
| US-09 | As a developer, I can observe readiness changes as a Stream for reactive UI. | `readyStream` emits on every state change. |

### COULD (P2)

| ID | Story | Acceptance Criteria |
|----|-------|-------------------|
| US-10 | As a developer, I can trigger a prompt after "happy moments" (purchase, achievement). | `trackHappyMoment(name)` checks conditions and can auto-prompt. |
| US-11 | As a developer, I can enable debug mode to log condition checks and bypass cooldown. | `debug: true` in config enables logging and skips cooldown. |

## Non-Functional Requirements

| ID | Requirement |
|----|------------|
| NFR-01 | `isReady` check completes in <1ms (no I/O, cached state). |
| NFR-02 | SharedPreferences reads are cached after `initialize()`. |
| NFR-03 | 90%+ line test coverage. |
| NFR-04 | Zero analyzer warnings with flutter_lints. |
| NFR-05 | All public API documented with dartdoc. |
