# Project overview

## Product

PushWrite is a local macOS menu-bar utility for system-wide push-to-talk dictation. The user holds a global hotkey, speaks, releases the keys, and receives locally transcribed text at the focused cursor position.

## Current release

`0.3.2` is the current ARM64 release candidate. It targets macOS 13 or newer and packages the native application, `whisper.cpp`, `llama.cpp`, a multilingual Whisper model and a multilingual local text model together. It supports live permission refresh, a visible status popover, single-instance protection and verified Accessibility insertion without using the general pasteboard. Unverifiable opaque fields fail closed.

## Product promise

- local audio capture and inference
- no Cloud transcription, translation or telemetry
- direct insertion without placing transcript text on the general clipboard
- narrow, visible permission use
- content-free routine logs and short-lived work files

## Included

- native menu-bar status and settings
- global `Control + Option + Command + P` press-and-hold interaction
- automatic/fixed spoken-language modes for German (Germany, Austria and Switzerland), English (USA), Spanish and French
- system/fixed output-language modes for German, English (USA), Spanish and French
- Swiss German to Hochdeutsch normalization
- Accessibility insertion with Unicode-event fallback
- local error recovery and permission guidance

## Explicitly excluded

- Cloud processing
- file import and batch transcription
- history or transcript storage
- general rewriting, summarisation and prompt workflows
- Windows, Linux, mobile and Intel artifacts
- clipboard monitoring or clipboard translation

## Technical basis

The AppKit layer owns hotkey, recording, permissions, UI and insertion. `whisper.cpp` 1.8.1 owns local speech recognition. `llama.cpp` b10227 and Qwen2.5 1.5B Instruct own local transcript normalization and translation. `PushWriteCore.swift` contains deterministic state, language and policy logic. See the [0.3.0 local language architecture](../architecture/local-language-processing-0.3.0.md).
