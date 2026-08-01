# Local translation evaluation — 0.2.0-alpha.1

## Release decision

Clipboard translation is **disabled** in this Alpha. No Cloud API, Apple translation service or partial-online fallback was added. The menu and settings explain the disabled state; no clipboard watcher starts.

## Evaluated direction

The implementation spike used Argos Translate 1.9.6 with CTranslate2 4.8.1 and SentencePiece 0.2.0 on ARM64. The official Argos package index exposed model packages `translate-en_de-1_3` and `translate-de_en-1_3`. Argos documents local CTranslate2 packages and approximately 100 MB per language pair: [Argos packages](https://argos-translate.readthedocs.io/en/stable/source/argostranslate.html) and [GUI/model package guidance](https://argos-translate.readthedocs.io/en/latest/source/gui.html).

The model downloads were materially larger than the documentation's rough average (150,512,831 bytes for DE→EN; the EN→DE transfer produced a transport-corrupted outer ZIP but yielded a complete 162,737,071-byte model for the isolated spike). The supported high-level runtime pulls a Python/Stanza/PyTorch dependency chain; that cannot be shipped in the present native, no-Python app without a separate integration and license review. Direct CTranslate2 inference succeeded, but sentence segmentation, long-input behaviour, model metadata/license evidence and a stable Swift/C++ ownership boundary are not release-ready.

OPUS-MT/Marian and Core ML/ONNX conversion were reviewed as alternatives. They do not remove the need to establish exact converted-model provenance, redistribution terms, checksums, quality baselines and reproducible native packaging. Apple system translation was not selected because this release requires independently demonstrable local model and processing provenance.

## Gate results

| Criterion | Result |
|---|---|
| German ↔ English model availability | Available in the Argos index |
| Local CTranslate2 inference capability | Real ARM64 inference passed in both directions under `sandbox-exec` network denial |
| Native app integration | Not complete; Python reference stack is not a release dependency |
| Model size | About 143 MB per downloaded pair during the spike |
| Long-text segmentation | Requires an additional SBD component; not validated in-app |
| Exact model training-data/license evidence | Insufficient in the downloaded package index metadata for redistribution approval |
| Offline spike proof | EN→DE: 0.149 s load, 0.318 s inference, 263,077,888-byte max RSS; DE→EN: 0.069 s load, 0.174 s inference, 250,576,896-byte max RSS |
| Offline app proof | Not available because no release-grade engine/model bundle was integrated |
| Intel | Not tested |

## Required next work

1. Select exact immutable model artifacts with explicit redistribution licenses.
2. Add a native C/C++ integration or an independently signed helper without Python/PyTorch.
3. Define sentence segmentation and hard input limits.
4. Verify package checksums before install and at runtime.
5. Benchmark representative German/English text, long inputs, RAM, cold/warm latency and offline operation.
6. Add unit, corruption, missing-model, UI and network-denied integration tests.

Until every gate passes, the feature remains disabled and the dictation release is unaffected.

## Reproduced sample results

- EN→DE input: `PushWrite processes speech entirely on this Mac and never sends the transcript to a server.`
- EN→DE output: `PushWrite verarbeitet die Sprache vollständig auf diesem Mac und sendet das Transkript niemals an einen Server.`
- DE→EN input: `PushWrite verarbeitet Sprache vollständig auf diesem Mac und sendet das Transkript niemals an einen Server.`
- DE→EN output: `PushWrite processes language entirely on this Mac and never sends the transcript to a server.`

Both processes ran locally with `(deny network*)`. The isolated model binaries measured:

- EN→DE `model.bin`: 162,737,071 bytes, SHA-256 `c29ca0fe955386c79197d0fce05b9cec0fa68953e41254a27ca654ee0dfb175a`
- DE→EN `model.bin`: 162,736,973 bytes, SHA-256 `8035a90049ecfb74c61ee8c84189a848b39f91023084e9eeadfd51d01b978c3f`

These are evaluation identifiers only. The model packages are not committed or shipped because their package metadata contains no explicit model redistribution license.
