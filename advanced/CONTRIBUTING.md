# Contributing

Thanks for considering contributing to Glances Client.

## Project scope

This is a deliberately **minimal, read-only** monitoring client. v1 has no
drill-down detail screens and no write operations by design — before adding a
feature, check whether it fits the minimal-monitoring mission or belongs on the
roadmap for the next release.

## Getting started

1. Fork and clone the repository.
2. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable channel).
3. Run `flutter pub get`.
4. Run `flutter analyze` and `flutter test` — both must pass before submitting.

## Development setup

You need a reachable Glances server (v4 API) to exercise the UI:

```bash
glances -w
```

Then run the app with `flutter run` and enter your server address on the
first-run screen.

## Code style

- Follow `flutter analyze` (the repo's default lint set) — zero warnings.
- Keep screens pure widgets: state lives in Riverpod providers, not in
  `State` where it can be avoided.
- Use the existing theme (`lib/ui/theme/`) — pure-black AMOLED background with
  the teal accent. Do not introduce new color schemes.

## Tests

Changes must keep the test suite green. Tests live in `test/`:

- `server_config_test.dart` — URL normalize/validate logic
- `first_run_flow_test.dart` — first-run gate widget tests

Add tests for any new logic or behavior you introduce.

## Pull requests

- Fill in the PR template.
- Reference the issue your PR fixes, if any.
- Keep PRs focused — one logical change per PR.

## Releasing

Maintainers: tagging `v*` triggers the release workflow, which builds the
signed APK and attaches it to a GitHub Release. Bump `versionCode` /
`versionName` in `android/app/build.gradle.kts` before tagging.
