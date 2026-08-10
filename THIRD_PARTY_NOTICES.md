# Third-party notices

## whisper.cpp 1.8.1

- Source: `third_party/whisper.cpp`
- Upstream: <https://github.com/ggml-org/whisper.cpp>
- License: MIT
- License text: `third_party/whisper.cpp/LICENSE`
- Integration: statically compiled `whisper-cli`; no repository-local dynamic libraries in the app

## OpenAI Whisper Large-v3 multilingual Q5_0 model

- Release file: `PushWrite.app/Contents/Resources/whisper/models/ggml-large-v3-q5_0.bin`
- Upstream model family: <https://github.com/openai/whisper>
- Pinned converted distribution: <https://huggingface.co/ggerganov/whisper.cpp/blob/5359861c739e955e79d9a303bcbc70fb988958b1/ggml-large-v3-q5_0.bin>
- Size: 1,081,140,203 bytes
- SHA-256: `d75795ecff3f83b5faa89d1900604ad8c780abd5739fae406de19f23ecd98ad1`
- License: MIT
- License text in release: `PushWrite.app/Contents/Resources/whisper/licenses/OpenAI-Whisper-LICENSE.txt`

## PushWrite icons

All SVG, PNG and ICNS icon assets under `app/macos/PushWrite/Assets` were created for PushWrite in this repository. No proprietary third-party icon was copied.

## llama.cpp b10227

- Source: `third_party/llama.cpp`
- Upstream: <https://github.com/ggml-org/llama.cpp>
- Pin: tag `b10227`, commit `f5919bf458ef190468b5c329bb293f8a54a1e69c`
- License: MIT
- License text: `third_party/llama.cpp/LICENSE`
- Integration: statically compiled `llama-completion`; OpenSSL, server, RPC and subprocess features are disabled

## Qwen2.5 1.5B Instruct Q4_K_M

- Runtime file: `qwen2.5-1.5b-instruct-q4_k_m.gguf`
- Upstream: <https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF>
- Pinned distribution manifest: <https://registry.ollama.ai/v2/library/qwen2.5/manifests/1.5b>
- Size: 986,048,512 bytes
- SHA-256: `183715c435899236895da3869489cc30ac241476b4971a20285b1a462818a5b4`
- License: Apache-2.0
- License text in release: `PushWrite.app/Contents/Resources/local-text/licenses/Qwen2.5-LICENSE.txt`

## Historical translation spike dependencies — not shipped

Argos Translate, CTranslate2, SentencePiece and the Argos German/English model packages were evaluated in an isolated `/tmp` spike. They are not included, linked or executed by the application artifact. Their presence in the evaluation does not add a runtime dependency to PushWrite.
