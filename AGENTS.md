# AGENTS.md

## Project

Mac Patro is a macOS 13+ SwiftUI menu-bar application built with Swift Package Manager.

- Root package: `Package.swift`
- Library target: `MacPatroKit`
- Executable target: `MacPatroNativeApp`
- Tests: `MacPatroNative/Tests/MacPatroNativeTests`
- App entry point: `MacPatroNative/Sources/App/MacPatroNativeApp.swift`

## Working Rules

- Make the smallest change that satisfies the request.
- Do not commit changes until the user has approved the commit message.
- Match the existing Swift style; do not introduce architecture or dependencies speculatively.
- Prefer Swift, SwiftUI, Foundation, AppKit, and ServiceManagement APIs already available on macOS 13+.
- Do not commit secrets or a private calendar-data URL. `MacPatroNative/Sources/RemoteURL.swift` is local configuration.
- Keep app bundle versions numeric. `build.sh` exposes local builds as `<version>--build-<timestamp>` through `CFBundleGetInfoString`.

## Nepali Calendar Safety

Calendar conversion is correctness-critical.

- Active month-length data is encoded in `MacPatroNative/Sources/DateConverter.swift`.
- `MacPatroNative/Sources/NepaliDateData.swift` is intentionally retained as reference data. It currently differs from the active encoded data for BS 2083–2086.
- Do not delete, regenerate, or reconcile either table without an authoritative source and explicit conversion fixtures for affected years.
- Do not change epochs, time zones, month lengths, supported ranges, or conversion arithmetic as part of unrelated refactors.
- After any calendar-related change, run the full supported-range test and the complete suite.

## Validation

Run before considering a change complete:

```bash
swift test
swift build -c release
```

For calendar changes, also run:

```bash
swift test --filter DateConverterTests
```

The build currently emits a known warning for the unused `sambat-widget/Assets.xcassets`; do not expand scope merely to silence it.

## Local App Build

Build and package a universal app:

```bash
./build.sh             # defaults to version 1.0.12
./build.sh 1.0.13      # explicit numeric version
```

The output is `dist/Mac Patro.app`. The script copies the SwiftPM resource bundle, keeps `CFBundleShortVersionString` numeric, uses `YYYYMMDDHHMMSS` for `CFBundleVersion`, and displays `<version>--build-<timestamp>` in the About window. Override the timestamp only for reproducible builds with `BUILD_TIMESTAMP=YYYY-MM-DD-HHMMSS`.

## Releases and Homebrew

Releases are explicit and tag-driven. Merging to `main` does not release.

When asked to release:

1. Ensure the release commit is on `main`, the working tree is clean, and validation passes.
2. Require an explicit `vMAJOR.MINOR.PATCH` version from the user; never guess or auto-increment it.
3. Create the tag from updated `main` and push only that tag.
4. Wait for the `Release MacPatro Native` GitHub Actions run to finish; do not report success immediately after pushing.
5. Verify the GitHub release contains both DMGs.
6. Verify the workflow's follow-up `chore(homebrew): update cask to v<version>` commit reached `main` and that `Casks/mac-patro.rb` contains the release version and SHA256.

The workflow creates the release before committing the cask update, so a failed release cannot publish a cask pointing at a missing asset. Repository settings and branch protection must allow GitHub Actions to write that cask commit to `main`.
