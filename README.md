# PushWrite

**Local voice input for macOS — Powered by Whisper**

PushWrite `0.2.0-alpha.2` is a native menu-bar app for local push-to-talk dictation on Apple-Silicon Macs. Hold `Control + Option + Command + P`, speak, then release: PushWrite records locally, transcribes with the bundled `whisper.cpp` runtime and inserts the text into the focused editable field without placing transcript text on the general pasteboard.

## Alpha status

Implemented:

- global press-and-hold hotkey
- local microphone recording and local `whisper.cpp` transcription
- multilingual `ggml-tiny` model with runtime SHA-256 verification
- direct Accessibility insertion with Unicode keyboard-event fallback
- protected-field, missing-focus and target-change guards
- native menu-bar states, settings, permission guidance and app icon
- automatic cleanup of audio and transcript work files
- offline-capable self-contained ARM64 app bundle

The optional clipboard translation UI is intentionally disabled. A fully local German↔English engine was evaluated, but its current runtime/model packaging and model-license evidence do not yet meet this release's integration gate. PushWrite does not monitor the clipboard and contains no cloud fallback.

## Requirements

- Apple Silicon (`arm64`)
- macOS 13.0 or newer
- microphone permission
- Accessibility permission for insertion into other apps

Intel Macs are not part of this Alpha because no `x86_64` runtime artifact was built or tested.

## Privacy

The production path contains no network client or telemetry. Audio, model inference and insertion remain local. The transcript is never staged on `NSPasteboard.general`; Apple documents that the general pasteboard automatically participates in Universal Clipboard, so avoiding it is required for PushWrite's local-only guarantee. Normal logs redact text values. Temporary audio and transcript artifacts are deleted when a flow completes or the app exits.

See [runtime architecture](docs/architecture/runtime-0.2.0-alpha.1.md), [permission model](docs/architecture/permission-model.md), [translation evaluation](docs/architecture/local-translation.md) and [security review](docs/security/0.2.0-alpha.2-security-review.md).

## Build and test

```sh
PUSHWRITE_SDK_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  ./scripts/build_whispercpp_minimal.sh

PUSHWRITE_SDK_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  ./scripts/build_pushwrite_product.sh /tmp/pushwrite-product

PUSHWRITE_SDK_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  ./scripts/run_pushwrite_unit_tests.sh

PUSHWRITE_SDK_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  ./scripts/run_pushwrite_ui_tests.sh
```

The SDK override is only needed on machines whose active Command Line Tools SDK does not match the installed Swift compiler. Full instructions are in [docs/building.md](docs/building.md).

## Install

Open the DMG, drag `PushWrite.app` to `/Applications`, start it, then grant the requested permissions. The published Alpha artifact is ad-hoc signed until a baumanncreative Developer ID Application certificate and notary profile are supplied. See [docs/installing.md](docs/installing.md).

## Repository layout

```text
app/macos/PushWrite/       Native AppKit application and assets
core/workflow/             Platform-independent workflow rules
models/                    Bundled multilingual Whisper model
scripts/                   Reproducible build, QA and release tools
tests/unit/                Swift unit tests
third_party/whisper.cpp/   Vendored whisper.cpp 1.8.1 source
docs/                      Product, architecture, test and release evidence
```

## License

PushWrite is licensed under MIT. Bundled third-party notices are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
