# Beta 9: iPad Support + iCloud Real-time Sync Plan

Date: 2026-04-22
Owner: Copilot session

## Goal

Enable iPad support without changing existing macOS UI/UX behavior, and ensure SwiftData + CloudKit synchronization is active between macOS and iPad builds.

## Scope

1. Project-level platform support
2. Cross-platform compile compatibility fixes (no visual redesign)
3. iCloud/CloudKit entitlements and signing configuration
4. Build verification for macOS and iOS Simulator
5. Git branch workflow and merge to main after verification

## Implementation Steps

### 1) Baseline verification

- Confirm current macOS build status.
- Check current platform settings and CloudKit configuration in app bootstrap.

### 2) Enable iPad target support

- Update app target build settings in `project.pbxproj`:
  - `SUPPORTED_PLATFORMS` -> include `iphoneos iphonesimulator macosx`
  - Keep existing macOS support intact.
  - Keep `TARGETED_DEVICE_FAMILY` iPad-focused.

### 3) Keep UI/UX unchanged while making shared code cross-platform

- Add a small compatibility utility for `NSColor` usage on iOS.
- Guard cursor-specific code (`NSCursor`) behind macOS compile checks.
- Keep all current layouts and interaction patterns unchanged for macOS.

### 4) Enable CloudKit capabilities for runtime sync

- Add app entitlements file with CloudKit/iCloud keys.
- Set target `CODE_SIGN_ENTITLEMENTS` for Debug/Release.
- Keep existing SwiftData `cloudKitDatabase: .automatic` model configuration.

### 5) Verification

- Build macOS destination.
- Build iOS Simulator destination.
- Inspect destination list to confirm iOS/iPad destinations are available for app scheme.

### 6) Git workflow

- Work on feature branch: `beta9/ipad-support-icloud-sync`.
- Commit only task-related changes.
- Merge into `main` only after all checks pass.
