# Tech Stack — flutter_review_kit

## Runtime

| Component | Version | Role |
|-----------|---------|------|
| Dart SDK | >= 3.4.0 | Language |
| Flutter SDK | >= 3.22.0 | Framework |
| `in_app_review` | >= 2.0.0 | Platform review dialog (peer dependency) |
| `shared_preferences` | >= 2.2.0 | Persistent state storage |

## Development

| Component | Role |
|-----------|------|
| `flutter_test` | Unit & widget testing |
| `flutter_lints` | Static analysis |

## CI/CD

| Component | Role |
|-----------|------|
| GitHub Actions | Lint, test, coverage on push/PR |

## Architecture

- **No state management dependency** — exposes Stream + getters
- **Instance-based** — no singletons, no service locator
- **Interface-based persistence** — `ReviewStore` abstraction allows custom backends
- **Dependency injection** — `InAppReview` injectable for testing
