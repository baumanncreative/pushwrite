# Changelog

All notable changes are documented here.

## [Unreleased]

No unreleased changes.

## [0.3.1] - 2026-08-10

### Changed

- labeled English as `Englisch (USA)` in both spoken-language and output-language settings
- pinned the approved white waveform app icon in product and install validation
- added the exact Gatekeeper override sequence directly to the unsigned DMG

## [0.3.0] - 2026-08-10

### Added

- separate spoken-language and output-language settings
- automatic input detection and fixed modes for German (Germany, Austria and Switzerland/Swiss German), English, Spanish and French
- System, German, English, Spanish and French output modes
- stronger Swiss German recognition with bundled Whisper Large-v3 Q5_0
- fully local multilingual translation with bundled Qwen2.5 1.5B Instruct and `llama.cpp`
- pinned model/runtime provenance, runtime model checksum verification and bundled license notices
- an OS-level network-denial sandbox around each text-model invocation
- deterministic local-language quality validation for Swiss German, German, English, Spanish and French

### Changed

- removed the Alpha suffix and promoted the application version to `0.3.0`
- migrated the previous `Automatisch` output choice to `System`
- extended release packaging and install validation to the local text runtime and model
- replaced Whisper tiny with the checksum-verified multilingual Large-v3 Q5_0 model
- moved production audio, Whisper JSON and local-model prompts to in-memory child-process pipes
- authenticated PATH-selected CMake with the Kitware Developer ID and bounded every Swiss ASR download
- retired the unauthenticated developer-only Accessibility insert agent
- made QA validators refuse pre-existing runtime directories instead of deleting them
- added startup cleanup for stale recording artifacts left by older builds
- bound Unicode fallback events to the validated target process and removed the unverified opaque insertion route
- pinned both signed inference executables inside the app and sandboxed both against network access and filesystem creation or deletion
- required Developer ID signing, exact Team-ID verification, notarization, stapling and Gatekeeper assessment for stable artifacts

### Fixed

- routed local text prompts through the supported `/dev/stdin` file descriptor so Swiss German normalization and translation execute without writing transcripts to disk
- rejected protected-content Accessibility metadata and multiline or control-character insertion into terminal applications
- redacted Accessibility titles and prevented runtime symlinks or pre-existing validator scratch roots from redirecting writes or deletion

## [0.2.0-alpha.3] - 2026-08-02

### Fixed

- Codex/ChatGPT compose fields that expose no focused Accessibility element now receive dictation through a bundle-scoped, focus-stable Unicode compatibility route
- Electron-style targets are asked to expose their Accessibility tree before the compatibility route is considered
- the compatibility route preserves the general pasteboard and remains unavailable to unknown applications, known non-editable targets and protected fields

## [0.2.0-alpha.2] - 2026-08-02

### Fixed

- microphone permission status now refreshes whenever the menu opens or the app becomes active
- clicking the microphone status requests access when macOS has not decided yet, and opens System Settings only after denial or restriction
- real TCC status is no longer frozen in a process-local QA override after the permission callback
- release signing now embeds the Hardened Runtime audio-input entitlement and install validation verifies it

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
