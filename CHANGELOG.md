# Changelog

All notable changes are documented here.

## [Unreleased]

No unreleased changes.

## [0.2.0-alpha.1] - 2026-08-01

### Added

- native macOS menu-bar application with ready, recording, processing and attention states
- settings for transcription language and permission status
- original PushWrite template icon, three design concepts and complete app icon set
- platform-independent workflow, privacy-log and insertion-policy tests
- static `whisper.cpp` release build and self-contained model packaging
- model size and SHA-256 verification before every inference launch
- Accessibility selected-text insertion with Unicode keyboard-event fallback
- password-field, non-editable-target and foreground-app change guards
- bounded recording and inference watchdogs
- ad-hoc Alpha ZIP/DMG packaging plus Developer ID/notary hooks
- CI, build, install, test, privacy, security and release documentation

### Changed

- release version aligned to `0.2.0-alpha.1` and minimum macOS to 13.0
- runtime directories are private (`0700`)
- file-based QA control interface is disabled unless explicitly enabled for tests
- ordinary logs and JSON state redact user content
- completed or aborted flows delete audio and transcript work files
- text insertion no longer uses the general pasteboard

### Removed

- corrupt 162-byte `ggml-model-whisper-tiny.bin` download placeholder
- dynamic repository-local `whisper.cpp` library dependency from the app bundle

### Known limitations

- ARM64 only
- Developer ID signing and notarization require external credentials
- local clipboard translation remains visibly disabled; no cloud substitute exists
- final compatibility testing on a clean macOS 13 account and a physical Intel Mac was unavailable

## [0.1.0] - Unreleased prototype

Historical execution notes describe the prototype increments; no `0.1.0` release tag was created.
