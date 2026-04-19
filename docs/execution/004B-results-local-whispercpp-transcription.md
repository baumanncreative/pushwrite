# 004B Results: Lokale whisper.cpp-Transkription am 004A-Handoff

## Status
- umgesetzt

## Kurzfassung
- Der bestehende 004A-Handoff (`RecordingArtifact -> AudioProcessingHandoff`) ist jetzt direkt an lokale `whisper.cpp`-Transkription angebunden.
- Der Hotkey-Hauptfluss bleibt unveraendert im Muster `idle -> recording -> processing -> idle`.
- Fuer `usable` wird lokal transkribiert; fuer `empty` und `tooShort` wird bewusst geskippt (ohne Inferenz).
- Es gibt jetzt persistierte 004B-Result-Artefakte fuer den letzten Lauf und fuer Historie.
- Cursor-Insert wurde nicht angebunden.

## Geaenderte Dateien
- `app/macos/PushWrite/main.swift`
- `docs/execution/004B-results-local-whispercpp-transcription.md`

## Technische Umsetzung
- Einstieg bleibt identisch:
  - `finishRecordingSession(...)` erzeugt weiterhin `RecordingArtifact`.
  - `handoffAudioForProcessing(recordingArtifact:)` erzeugt weiterhin `AudioProcessingHandoff` mit `usability`.
- Neuer 004B-Schritt direkt nach Handoff:
  - `processAudioProcessingHandoff(session:handoff:)`
  - Verhalten:
    - `empty` -> kein Whisper-Lauf, `transcription-skipped`
    - `tooShort` -> kein Whisper-Lauf, `transcription-skipped`
    - `usable` -> lokaler Whisper-Lauf via bestehende `transcribeRecording(...)`-Integration
- Persistiertes 004B-Result:
  - neues minimales Objekt `TranscriptionResult` mit:
    - `id`, `recordingID`, `recordingFilePath`
    - `recordingUsability`
    - `transcriptionAttempted`
    - `succeeded`
    - `status` (`succeeded` | `failed` | `skipped`)
    - `text`/`textLength`
    - `skipReason` oder `error`
    - `startedAt`, `completedAt`, `durationMs`
- Persistenz:
  - `logs/last-transcription-result.json`
  - `logs/transcription-results.jsonl`
- Fehlerbehandlung:
  - Inferenzfehler bleiben kontrolliert (`status=failed`) und laufen sauber auf `idle` zurueck.
  - Neuer Fehlerfall fuer brauchbares Audio ohne Text: `emptyTranscriptionOutput`.

## Verwendeter Modellpfad / Modellannahme
- Verwendetes Modell in den ausgefuehrten 004B-Laeufen:
  - `/Users/michel/Code/pushwrite/models/ggml-tiny.bin`
- Pfadaufloesung:
  - explizit via `--whisper-model-path` oder `PUSHWRITE_WHISPER_MODEL_PATH`
  - fallback auf `defaultWhisperModelPath()` (`<repo>/models/ggml-tiny.bin`)
- CLI-Pfad:
  - explizit via `--whisper-cli-path` oder `PUSHWRITE_WHISPER_CLI_PATH`
  - fallback auf `defaultWhisperCLIPath()` (`<repo>/build/whispercpp/build/bin/whisper-cli`)
- Keine Downloader-/Modellmanagement-Logik hinzugefuegt.

## Beobachtbarkeit
- Bestehende Handoff-Artefakte bleiben:
  - `logs/last-audio-processing-handoff.json`
  - `logs/audio-processing-handoffs.jsonl`
- Neue 004B-Result-Artefakte:
  - `logs/last-transcription-result.json`
  - `logs/transcription-results.jsonl`
- Erweiterte Event-Namen in `logs/hotkey-recording-prototype.jsonl`:
  - `transcription-handoff-received`
  - `transcription-started`
  - `transcription-succeeded`
  - `transcription-failed`
  - `transcription-skipped`
  - `processing-flow-completed`
- Rueckkehr in Abschluss bleibt sichtbar:
  - `flow-completed-succeeded` oder `flow-completed-failed`
  - `flow-returned-idle`

## Nicht umgesetzt
- Kein Cursor-Insert / keine Accessibility-Insert-Mechanik im 004B-Hotkey-Pfad.
- Kein Toggle-, VAD- oder Continuous-Dictation-Modus.
- Keine Datei-Transkription als separater Produktpfad.
- Kein Modell-Download-Manager oder Mehrmodell-Management.
- Kein UI-Polish ausser bestehender Runtime-Beobachtbarkeit.

## Bekannte Risiken / Annahmen
- `TranscriptionResult.succeeded=false` bei `status=skipped` ist absichtlich technisch eng (keine Inferenz ausgefuehrt, daher keine erfolgreiche Transkription).
- `transcribeRecording(...)` persistiert weiterhin das bestehende `TranscriptionArtifact`; 004B ergaenzt zusaetzlich das neue Result-Log.
- Die Qualitaet des Transcript-Textes haengt weiterhin am lokalen `ggml-tiny`-Modell und Audioqualitaet; 004B optimiert hier bewusst nicht.

## Testhinweise
- Build:
  - `./scripts/build_pushwrite_product.sh build/pushwrite-product-candidate-004B`

- Erfolgsfall (`usable`, lokale Inferenz):
  1. Launch:
     - `./scripts/control_pushwrite_product.sh launch --product-app /Users/michel/Code/pushwrite/build/pushwrite-product-candidate-004B/PushWrite.app --runtime-dir /tmp/pushwrite-004B-runtime-success --whisper-cli-path /Users/michel/Code/pushwrite/build/whispercpp/build/bin/whisper-cli --whisper-model-path /Users/michel/Code/pushwrite/models/ggml-tiny.bin --whisper-language en --transcription-fixture-wav /Users/michel/Code/pushwrite/build/whispercpp/micro-machines-16k-mono.wav --force-accessibility-trusted --force-microphone-permission-status granted`
  2. Hotkey triggern (press-and-hold).
  3. Erwartete Artefakte:
     - `/tmp/pushwrite-004B-runtime-success/logs/last-audio-processing-handoff.json`
     - `/tmp/pushwrite-004B-runtime-success/logs/last-transcription-result.json`
     - `/tmp/pushwrite-004B-runtime-success/logs/transcription-results.jsonl`
     - `/tmp/pushwrite-004B-runtime-success/recordings/<flow-id>.transcription.txt`
  4. Erwartung:
     - `last-transcription-result.json`: `status=succeeded`, `transcriptionAttempted=true`, `textLength>0`

- Skip-Fall (`tooShort`):
  1. Launch ohne Fixture:
     - `./scripts/control_pushwrite_product.sh launch --product-app /Users/michel/Code/pushwrite/build/pushwrite-product-candidate-004B/PushWrite.app --runtime-dir /tmp/pushwrite-004B-runtime-short --whisper-cli-path /Users/michel/Code/pushwrite/build/whispercpp/build/bin/whisper-cli --whisper-model-path /Users/michel/Code/pushwrite/models/ggml-tiny.bin --whisper-language en --force-accessibility-trusted --force-microphone-permission-status granted`
  2. Sehr kurzer Hotkey-Hold.
  3. Erwartung:
     - `last-transcription-result.json`: `status=skipped`, `recordingUsability=tooShort`, `transcriptionAttempted=false`, `skipReason=tooShortRecording`
     - Kein Haengenbleiben in `processing`, Flow endet wieder in `idle`.

- Fehlerfall (fehlender Modellpfad):
  1. Launch mit absichtlich fehlendem Modell:
     - `./scripts/control_pushwrite_product.sh launch --product-app /Users/michel/Code/pushwrite/build/pushwrite-product-candidate-004B/PushWrite.app --runtime-dir /tmp/pushwrite-004B-runtime-failure --whisper-cli-path /Users/michel/Code/pushwrite/build/whispercpp/build/bin/whisper-cli --whisper-model-path /Users/michel/Code/pushwrite/models/ggml-tiny-missing-004B.bin --whisper-language en --transcription-fixture-wav /Users/michel/Code/pushwrite/build/whispercpp/micro-machines-16k-mono.wav --force-accessibility-trusted --force-microphone-permission-status granted`
  2. Hotkey triggern.
  3. Erwartung:
     - `last-transcription-result.json`: `status=failed`, `transcriptionAttempted=true`, `error` enthaelt `whisper.cpp model is missing`
     - `last-hotkey-response.json`: `status=failed`
     - Flow kehrt kontrolliert nach `idle` zurueck.

## Rollback
- Code rueckgaengig:
  - `git restore /Users/michel/Code/pushwrite/app/macos/PushWrite/main.swift`
- 004B-Dokumentation rueckgaengig:
  - `git restore /Users/michel/Code/pushwrite/docs/execution/004B-results-local-whispercpp-transcription.md`

