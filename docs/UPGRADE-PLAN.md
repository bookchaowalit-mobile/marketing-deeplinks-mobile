# Upgrade Plan — Deeplinks Mobile

## Current state

Score: 7.5/10 — inspector/builder with edge-case-tested logic (ports, opaque schemes, bad escapes), copy action, a11y guideline tests and fail-closed signing; no history, icon or E2E flow yet.

## Backlog

### P0
- None open. (Release signing now fails closed without `android/key.properties`.)

### P1
- Share sheet for the built link and a short history of inspected links (shared_preferences). (Copy is done.)
- Replace the template launcher icon with a real app icon (the application ID `com.bookchaowalit.*` is already set).
- Add a Maestro smoke flow for the main journey.
- Add a CI job that builds a signed release bundle from repository secrets (keystore decoded at runtime, never committed).

### P2
- Tablet layout (NavigationRail).
- Localisation (Thai/English) for UI strings.

## Done in this pass (pass 3)

- Bug fix: the "invalid percent-encoding" warnings were dead code — Dart's `Uri` keeps `%zz` literally instead of throwing — so malformed escapes were never flagged. The raw path and query are now checked explicitly.
- Bug fix: building a link with `host:port` (e.g. `example.com:8080`) failed with a misleading "Illegal IPv6 address"; ports are now supported (1–65535) and hosts with spaces or `/` get a clear error instead of being silently percent-encoded.
- Bug fix: `mailto`/`tel`/`sms`/`geo` links were built as `mailto:///a@b.com`; they are now `mailto:a@b.com` (with `+` in the query still encoded).
- Copy button for the built link (disabled while the builder shows an error); built link is a live region; warning icons have a semantic label.
- Edge-case unit tests: malformed escapes, empty/whitespace/unparsable input, host:port and bad hosts, opaque schemes, Thai/emoji round trip. Widget tests: copy to clipboard, disabled copy with host error, empty-link state, a11y guidelines, 200% text scale.

## Done in pass 2

- Release builds no longer sign with the debug key: `android/app/build.gradle.kts` reads the ignored `android/key.properties` and a Gradle guard fails any release assemble/bundle without it (pattern from `bookchaowalit-goal-tracker-mobile`). Root `.gitignore` also ignores `key.properties`, `*.jks`, `*.keystore`; README documents the setup. Not build-verified here (no Android SDK/Gradle in this environment).


## Done in pass 1

- Replaced the Expo/npm CI (which could never fail) with fail-closed Flutter CI: `dart format` check, `flutter analyze`, `flutter test`, debug APK on `main`.
- Implemented the core feature (inspect and build deep links: scheme, host, path and query parameters) with pure-Dart logic in `lib/logic/`.
- Replaced placeholder Explore/Profile tabs with an About screen describing features and privacy.
- Added unit tests for the logic and widget tests for the main journey.
- Removed unused `go_router` / `flutter_riverpod` dependencies; README now matches the code.
