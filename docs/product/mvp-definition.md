# Alpha definition — 0.2.0-alpha.1

## Required core outcome

On an Apple-Silicon Mac running macOS 13 or newer, a user can install PushWrite, grant microphone and Accessibility permission, hold the global hotkey, speak German or English, release, and receive a local Whisper transcript in the focused editable field while the original clipboard remains unchanged.

## Definition of done

### Function

- hotkey down starts one recording
- hotkey up stops that recording
- bundled `whisper.cpp` performs real local inference
- direct insertion succeeds in supported editable fields
- password/protected fields, absent focus and changed targets are rejected
- errors and watchdog expiry return to idle
- repeated use does not duplicate one transcript

### Application

- menu-bar states communicate ready, recording, processing and attention
- settings expose hotkey, permissions and transcription language
- first-use permission guidance is actionable
- original template and app icons are bundled
- VoiceOver labels exist for custom controls

### Privacy and distribution

- no production network path or telemetry
- transcript insertion does not use the general pasteboard
- routine artifacts and logs do not retain content
- static runtime/model bundle requires no development tools after install
- DMG and ZIP plus SHA-256 checksums are produced
- signing/notarization is executed when credentials exist and exactly blocked otherwise

## Optional translation gate

Clipboard translation is additive and cannot block the dictation core. It may be enabled only after a native, fully local German↔English engine has passed model provenance/license, integrity, offline, quality, latency, long-input, missing/corrupt-model and packaging tests. `0.2.0-alpha.1` does not meet that gate, therefore the checkbox is disabled and no clipboard observer runs.

## Non-goals

- Cloud fallback of any kind
- general transcription file workflows
- persistence/history
- dynamic plug-ins or downloadable executable code
- automatic update service
- architectures and OS versions not represented by a tested artifact
