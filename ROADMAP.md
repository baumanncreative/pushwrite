# Roadmap

## 0.2.0-alpha.1 — current

- ARM64 macOS 13+ menu-bar Alpha
- local push-to-talk recording and multilingual Whisper transcription
- direct pasteboard-free text insertion
- explicit permission and error recovery flows
- reproducible ad-hoc DMG/ZIP packaging
- disabled, technically prepared local-translation settings surface

## Next Alpha

- obtain Developer ID Application credentials, notarize and staple the release
- validate first installation on a clean macOS 13 user account
- expand the real app matrix and repeated-use soak coverage
- decide whether to bundle a native local translation runtime only after model licensing, binary packaging, latency and quality gates pass
- avoid per-request Whisper process/model startup if measured latency requires an in-process runtime

## Later, not scheduled

- Intel macOS artifact after explicit build and hardware validation
- configurable global hotkey
- Windows, Linux and mobile platforms
- file transcription, history, cloud sync, rewriting and cloud inference
