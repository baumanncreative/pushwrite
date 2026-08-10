# Local language processing — 0.3.0

## Guarantee

PushWrite performs capture, recognition, normalization and translation on the Mac running the application. The installed application needs no API key and makes no Cloud request. There is no online fallback.

Every text-model invocation uses all three controls below:

1. a fixed model file inside `PushWrite.app`;
2. the runtime's `--offline` switch;
3. `/usr/bin/sandbox-exec` with `(deny network*)` around the child process.

Production audio is captured as an in-memory 16 kHz mono WAV buffer. PushWrite streams that buffer to Whisper over standard input, reads Whisper JSON from standard output and streams local-model prompts over standard input. Production therefore does not create audio, transcript, JSON or prompt intermediates on disk. Startup also removes stale recording artifacts left by older versions. QA builds may persist fixture artifacts only when their compile-time control interface and explicit sensitive-test flag are both enabled. Routine logs contain text lengths, state and error metadata, not user content.

## Pipeline

1. `whisper.cpp` 1.8.1 and the bundled multilingual Whisper Large-v3 Q5_0 model convert the in-memory WAV stream to a raw transcript.
2. The selected spoken-language setting constrains Whisper where possible. The three German variants map to Whisper's `de` code; automatic passes the explicit `-l auto` flag so Whisper performs multilingual detection instead of using its command-line default.
3. `llama-completion` from `llama.cpp` b10227 receives a bounded local prompt and the raw transcript.
4. Same-language output uses Whisper's normalized transcript directly. Translation uses Qwen2.5 1.5B Instruct Q4_K_M; non-English-to-non-English fallback routes use an English pivot. A small deterministic French correction step fixes known contraction and article errors without another generative pass.
5. The transformed text passes the existing non-empty and minimum-length gate and is inserted without the general pasteboard.

The source modes are automatic, German (Germany), German (Austria), German (Switzerland/Swiss German), English, Spanish and French. The output modes are System, German, English, Spanish and French. `System` selects the first supported entry in `Locale.preferredLanguages`; if none is supported, German is the deterministic fallback.

Automatic mode leaves multilingual detection to Whisper Large-v3. Swiss German is detected as German and emitted in normalized written form. Selecting Swiss German explicitly constrains recognition to German. For German output, this standard written transcript bypasses the smaller translation model to avoid omissions or hallucinated dialect normalization.

## Model and runtime provenance

| Component | Pin | Integrity | License |
|---|---|---|---|
| Whisper Large-v3 Q5_0 | `ggml-large-v3-q5_0.bin` from pinned `ggerganov/whisper.cpp` revision `5359861c739e955e79d9a303bcbc70fb988958b1` | SHA-1 `e6e2ed78495d403bef4b7cff42ef4aaadcfea8de`, SHA-256 `d75795ecff3f83b5faa89d1900604ad8c780abd5739fae406de19f23ecd98ad1`, 1081140203 bytes | MIT |
| `llama.cpp` | tag `b10227`, commit `f5919bf458ef190468b5c329bb293f8a54a1e69c` | source archive SHA-256 in `third_party/llama.cpp/UPSTREAM.md` | MIT |
| Qwen2.5 1.5B Instruct Q4_K_M | Ollama registry manifest `qwen2.5:1.5b`, upstream `Qwen/Qwen2.5-1.5B-Instruct-GGUF` | `183715c435899236895da3869489cc30ac241476b4971a20285b1a462818a5b4`, 986048512 bytes | Apache-2.0 |

The build verifies both exact models before copying them. The installed app verifies model size and SHA-256 again before each production invocation. Both the Qwen license and `llama.cpp` license are bundled under `Contents/Resources/local-text/licenses`.

## Bounds and failure behavior

- input is rejected above 20,000 characters rather than truncated;
- inference has a 180-second watchdog;
- generated output is rejected when empty, non-UTF-8 or more than four times the input length (minimum allowance 1,024 characters);
- model/runtime absence, checksum mismatch, sandbox absence or non-zero inference exit fails the flow without inserting the raw transcript;
- no fallback sends the transcript elsewhere.

The 1.5B quantized model trades model size and latency for local operation. It is suitable for short push-to-talk dictation but does not guarantee professional human-translation quality. Named entities and specialized terminology remain a residual quality risk and are covered by explicit release notes rather than a Cloud fallback.
