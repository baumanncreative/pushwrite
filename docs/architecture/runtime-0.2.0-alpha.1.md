# Runtime architecture — 0.2.0-alpha.1

## Supported target

PushWrite is an AppKit menu-bar app with bundle ID `ch.baumanncreative.pushwrite`, deployment target macOS 13.0 and ARM64 architecture. It is built directly with `swiftc`; no Python, Homebrew or development checkout is required by the packaged app.

## Core flow

```text
Carbon global hotkey down
  → permission and focus checks
  → AVAudioRecorder starts 16 kHz mono WAV capture
Carbon global hotkey up
  → recorder stops
  → bundled static whisper-cli processes bundled ggml-tiny.bin
  → transcript is validated
  → AXSelectedText writes into the focused element
  → Unicode CGEvents are the fallback
  → temporary content artifacts are deleted
  → idle
```

The state machine permits only explicit transitions between idle, recording, transcribing, inserting, done and error states. Recording and inference have 120-second watchdogs. Errors return the app to idle after local feedback.

## Components

- `core/workflow/PushWriteCore.swift`: state rules, deduplication, privacy-safe log text and insertion-target policy.
- `app/macos/PushWrite/main.swift`: lifecycle, hotkey, capture, local inference, permissions, focus snapshots, insertion and cleanup.
- `app/macos/PushWrite/ProductUI.swift`: menu bar and settings window.
- `third_party/whisper.cpp`: vendored upstream runtime source, version 1.8.1.
- `models/ggml-tiny.bin`: multilingual Whisper model included in the app.

## Public macOS APIs

- Carbon `RegisterEventHotKey` for the global press-and-hold interaction
- AVFoundation `AVAudioRecorder` and microphone authorization APIs
- ApplicationServices Accessibility APIs for trust, focus inspection and `AXSelectedText`
- CoreGraphics keyboard events for a pasteboard-free Unicode fallback
- AppKit `NSStatusItem`, `NSMenu` and `NSWindow`

## Data lifetime

Runtime data lives under `~/Library/Application Support/PushWrite/runtime` in `0700` directories. Audio and transcript working files exist only during a flow and are removed on success, failure or normal termination. State and logs retain timestamps, lengths, statuses and non-content diagnostics; text/value fields are blank unless an explicit QA-only environment switch is set.

## QA-only interface

The file-based request/response controller exists to drive deterministic integration tests. Production launches do not create or poll its request directories. The controller sets `PUSHWRITE_ENABLE_CONTROL_INTERFACE=1` only for the child test app process.

## Dependency boundary

The bundled `whisper-cli` is statically linked to whisper/ggml components. `otool -L` must show system libraries/frameworks only. Model integrity is verified against the compiled expected byte count and SHA-256 before `Process` launches the CLI.

## Deliberate separation

Translation types and settings are independent from dictation. No translation engine is linked to this release, so failure or absence of translation can never block dictation.
