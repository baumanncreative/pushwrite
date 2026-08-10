# PushWrite

**Local voice input for macOS — fully offline**

PushWrite `0.3.1` is a native menu-bar app for local push-to-talk dictation on Apple-Silicon Macs. Hold `Control + Option + Command + P`, speak, then release: PushWrite records locally, transcribes with bundled `whisper.cpp`, normalizes or translates the transcript with bundled `llama.cpp` and inserts the result into the focused editable field without placing text on the general pasteboard.

## Release status

Implemented:

- global press-and-hold hotkey
- local microphone recording and local `whisper.cpp` transcription
- multilingual Whisper Large-v3 Q5_0 model with runtime size and SHA-256 verification
- separate spoken-language and output-language settings
- automatic input detection plus German (Germany, Austria and Switzerland/Swiss German), English, Spanish and French input modes
- system-language output plus German, English, Spanish and French output modes
- stronger Swiss German recognition with Whisper Large-v3 and local multilingual translation using Qwen2.5 1.5B Instruct
- checksum-verified, Apache-2.0-licensed local text model and MIT-licensed `llama.cpp` runtime
- OS-enforced network denial around every local text-model process
- direct Accessibility insertion with process-directed, value-verified Unicode keyboard-event fallback; unverifiable opaque fields fail closed
- protected-field, missing-focus and target-change guards
- native menu-bar states, settings, permission guidance and app icon
- in-memory production audio, transcript and prompt processing without work files
- offline-capable self-contained ARM64 app bundle

PushWrite does not monitor the clipboard and contains no cloud fallback. Recognition, normalization and translation work after installation without a network connection.

## Requirements

- Apple Silicon (`arm64`)
- macOS 13.0 or newer
- microphone permission
- Accessibility permission for insertion into other apps

Intel Macs are not part of this release because no `x86_64` runtime artifact was built or tested.

## Privacy

The production workflow contains no telemetry, API request or cloud fallback. Audio, model inference and insertion remain local. Audio is recorded in memory; Whisper receives WAV bytes over standard input and returns JSON over standard output; the text model receives its prompt over standard input. No production audio, prompt or transcript work files are created. The text runtime is invoked with `--offline`, a fixed bundled model path and a macOS sandbox profile that denies all network access. The transcript is never staged on `NSPasteboard.general`; Apple documents that the general pasteboard automatically participates in Universal Clipboard, so avoiding it is required for PushWrite's local-only guarantee. Normal logs redact text values, and startup removes stale recording artifacts from older versions.

See [0.3.0 local language architecture](docs/architecture/local-language-processing-0.3.0.md), [permission model](docs/architecture/permission-model.md), [test matrix](docs/testing/0.3.0-test-matrix.md) and [security review](docs/security/0.3.0-security-review.md).

## Build and test

```sh
PUSHWRITE_SDK_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  ./scripts/build_whispercpp_minimal.sh

./scripts/fetch_whisper_model.sh

./scripts/fetch_local_text_model.sh

PUSHWRITE_SDK_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  ./scripts/build_llamacpp_minimal.sh

PUSHWRITE_SDK_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  ./scripts/build_pushwrite_product.sh /tmp/pushwrite-product

PUSHWRITE_SDK_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  ./scripts/run_pushwrite_unit_tests.sh

PUSHWRITE_SDK_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  ./scripts/run_pushwrite_ui_tests.sh
```

The SDK override is only needed on machines whose active Command Line Tools SDK does not match the installed Swift compiler. Full instructions are in [docs/building.md](docs/building.md).

## Install

Open the DMG, drag `PushWrite.app` to `/Applications`, start it once and choose **Done** in the initial Gatekeeper warning. Then use **Open Anyway** under System Settings → Privacy & Security and grant the requested permissions. The GitHub direct-download build is explicitly marked `-unsigned` and is not Apple-notarized. It is built on GitHub Actions with Sigstore-backed provenance and published as an immutable release. A separate authenticated builder remains available for Developer-ID-signed and notarized artifacts. See [docs/installing.md](docs/installing.md).

## Repository layout

```text
app/macos/PushWrite/       Native AppKit application and assets
core/workflow/             Platform-independent workflow rules
models/                    Local build-time model cache (release models are fetched and verified)
scripts/                   Reproducible build, QA and release tools
tests/unit/                Swift unit tests
third_party/whisper.cpp/   Vendored whisper.cpp 1.8.1 source
third_party/llama.cpp/     Vendored llama.cpp b10227 source
docs/                      Product, architecture, test and release evidence
```

## License

PushWrite is licensed under MIT. Bundled third-party notices are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
