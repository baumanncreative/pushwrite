# Third-party notices

## whisper.cpp 1.8.1

- Source: `third_party/whisper.cpp`
- Upstream: <https://github.com/ggml-org/whisper.cpp>
- License: MIT
- License text: `third_party/whisper.cpp/LICENSE`
- Integration: statically compiled `whisper-cli`; no repository-local dynamic libraries in the app

## Whisper multilingual tiny model

- File: `models/ggml-tiny.bin`
- Upstream model family: OpenAI Whisper
- Distribution format/source tooling: whisper.cpp model tooling
- Size: 77,691,713 bytes
- SHA-256: `be07e048e1e599ad46341c8d2a135645097a538221678b7acdd1b1919c6e1b21`
- License: MIT model/code release terms referenced by the upstream Whisper and whisper.cpp projects

## PushWrite icons

All SVG, PNG and ICNS icon assets under `app/macos/PushWrite/Assets` were created for PushWrite in this repository. No proprietary third-party icon was copied.

## Translation spike dependencies — not shipped

Argos Translate, CTranslate2, SentencePiece and the Argos German/English model packages were evaluated in an isolated `/tmp` spike. They are not included, linked or executed by the application artifact. Their presence in the evaluation does not add a runtime dependency to PushWrite.
