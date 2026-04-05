# PushWrite

**Local voice input for macOS**  
*Powered by Whisper*

PushWrite is a local, offline-capable voice input tool for macOS.

Its purpose is narrow and practical: hold a global push-to-talk hotkey, speak into the microphone, transcribe speech locally, and insert the resulting text directly at the current cursor position.

## Status

PushWrite is in early development.

This repository currently defines the product scope, technical direction, architecture decisions, and execution briefs for the MVP. The full macOS application is not implemented yet.

## Product Focus

PushWrite is intentionally built around one primary workflow:

1. Press and hold a global hotkey
2. Speak into the microphone
3. Release the hotkey to stop recording
4. Transcribe the audio locally
5. Insert the recognized text directly at the active cursor position

The project is deliberately narrow in scope.

Current product focus:

- Single product: PushWrite
- Active platform: macOS only
- Core interaction: push-to-talk voice input
- Local transcription as the default path
- Direct text insertion as part of the product core
- No cloud-dependent MVP path
- No premature expansion into broader transcription workflows

## MVP Scope (v0.1.0)

Version `0.1.0` is the first deliberately constrained product increment.

Included in scope:

- global push-to-talk hotkey
- microphone recording on macOS
- local speech-to-text transcription
- direct insertion at the active cursor position
- only the minimal settings required for the core workflow

Explicitly out of scope:

- file transcription
- MP3, MP4, audio, or video import
- cloud transcription
- Windows support
- Linux support
- iOS or Android versions
- advanced editing features
- prompt-based rewriting features
- multi-engine transcription architecture
- premature platform abstraction for hypothetical future releases

## Platform Decision

PushWrite currently targets **macOS only**.

This is a deliberate product and architecture decision. The MVP is not being optimized for Windows, Linux, iOS, or Android. Future expansion is possible, but it is not a driver for the current implementation scope.  [oai_citation:3‡ROADMAP.md](sediment://file_000000005278720abe94b393f65f7bfa)

## Whisper Basis

PushWrite is based on the **OpenAI Whisper** model family.

For the macOS MVP, the preferred inference runtime is **`whisper.cpp`**. This direction is based on the project’s current technical decision that a local, offline-capable, embeddable runtime is a better fit for a native macOS product than using the Python-first `openai/whisper` repository as the primary product runtime.  [oai_citation:4‡ANALYSE-whisper-vs-whisper-cpp-macos-mvp.md](sediment://file_00000000c37872469f9f2f33a0827004)

Practical implication:

- OpenAI Whisper remains the upstream model foundation
- `whisper.cpp` is the preferred inference runtime for the MVP
- the macOS application layer still has to solve product-specific behavior separately

That macOS application layer includes, at minimum:

- global hotkey handling
- microphone control
- permissions handling
- app state and error flow
- direct text insertion at the current cursor position

These parts are not solved by Whisper itself.  [oai_citation:5‡ANALYSE-whisper-vs-whisper-cpp-macos-mvp.md](sediment://file_00000000c37872469f9f2f33a0827004)

## Design Principles

PushWrite follows these principles:

- local first
- offline-capable by default
- product clarity over feature volume
- stability over feature breadth
- simple architecture over speculative abstraction
- strict separation between inference concerns and macOS application concerns
- MVP discipline over future-facing complexity

## Repository Structure

The repository is organized around product definition, architecture decisions, and execution briefs.

```text
pushwrite/
├─ README.md
├─ LICENSE
├─ CHANGELOG.md
├─ CODE_OF_CONDUCT.md
├─ CONTRIBUTING.md
├─ ROADMAP.md
└─ docs/
   ├─ product/
   │  ├─ project-overview.md
   │  └─ mvp-definition.md
   ├─ architecture/
   │  ├─ technical-decisions.md
   │  ├─ risks-open-questions.md
   │  └─ system-components.md
   └─ execution/
      ├─ README.md
      ├─ 001-architecture-validation-plan.md
      ├─ 002-text-insertion-macos.md
      ├─ 003-permissions-start-flow-macos.md
      └─ 004-hotkey-recording-flow.md