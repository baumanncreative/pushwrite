# PushWrite

Local voice input for macOS<br>
Powered by Whisper

PushWrite is a macOS product focused on one primary workflow: hold a global hotkey, speak into the microphone, transcribe locally with Whisper, and insert the resulting text directly at the current cursor position.

> Status: early development. This repository currently defines the project structure, baseline documentation, and technical boundaries for the MVP. It does not yet contain an implemented application.

## Product Focus

- Single product: PushWrite
- Active platform: macOS only
- Fixed transcription engine: Whisper
- No multi-engine abstraction
- No mobile structure

## MVP Scope

- Global hotkey to start and stop voice capture
- Microphone recording on macOS
- Local transcription using Whisper
- Direct text insertion at the active cursor position
- Minimal settings required to support the core workflow

## Out of Scope

- Windows support
- Linux support
- Mobile apps
- File transcription
- Cloud transcription
- Multi-engine support
- Premature platform or architecture expansion

## High-Level Architecture

```text
pushwrite/
├─ app/macos              macOS-specific application layer
├─ core/audio             microphone capture and audio handling
├─ core/transcription     Whisper-oriented transcription flow
├─ core/text_insertion    text delivery to the active cursor
├─ core/hotkey            global hotkey registration and handling
├─ core/settings          configuration required by the MVP
├─ docs/architecture      technical structure and system notes
├─ docs/product           product scope and product-facing references
├─ docs/decisions         architectural and product decisions
├─ scripts                local development and maintenance scripts
└─ tests                  unit and integration test structure
```

## Repository Boundaries

- `app/macos` is reserved for macOS-specific application code.
- `core/*` contains shared product logic for the active macOS scope.
- `docs/*` stores architecture notes, product references, and decisions.
- `tests/*` is reserved for automated verification of core flows.

## Whisper Notice

PushWrite uses Whisper as a local transcription engine.<br>
Whisper itself is not included in this repository.
