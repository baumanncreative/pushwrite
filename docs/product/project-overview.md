# Project overview

## Product

PushWrite is a local macOS menu-bar utility for system-wide push-to-talk dictation. The user holds a global hotkey, speaks, releases the keys, and receives locally transcribed text at the focused cursor position.

## Current release

`0.2.0-alpha.2` is the current installable ARM64 Alpha. It targets macOS 13 or newer, packages its native application, static `whisper.cpp` CLI and multilingual tiny model together, and refreshes the live microphone permission state in the menu and settings.

## Product promise

- local audio capture and inference
- no Cloud transcription or telemetry
- direct insertion without placing transcript text on the general clipboard
- narrow, visible permission use
- content-free routine logs and short-lived work files

## Included

- native menu-bar status and settings
- global `Control + Option + Command + P` press-and-hold interaction
- German, English and automatic language modes
- Accessibility insertion with Unicode-event fallback
- local error recovery and permission guidance

## Explicitly excluded

- Cloud processing
- file import and batch transcription
- history or transcript storage
- rewriting, summarisation and prompt workflows
- Windows, Linux, mobile and Intel artifacts
- active clipboard translation in this Alpha

The translation surface is present but disabled because the native runtime, exact model redistribution evidence and complete offline in-app validation have not all passed the release gate. There is no Cloud substitute.

## Technical basis

The AppKit layer owns hotkey, recording, permissions, UI and insertion. `whisper.cpp` 1.8.1 owns local inference. `PushWriteCore.swift` contains deterministic state and policy logic. See the [current runtime architecture](../architecture/runtime-0.2.0-alpha.1.md).
