# 007 Results: Bundle Whisper Runtime and Minimal Model into App

## Status
- completed

## Kurzfassung
- Der Product-Build bundelt jetzt `whisper-cli` und genau ein MVP-Minimalmodell (`ggml-tiny.bin`) reproduzierbar in `PushWrite.app/Contents/Resources/whisper/...`.
- Die Runtime-Aufloesung priorisiert jetzt:
  1. gebundelte Produktressourcen
  2. explizite Dev-/Debug-Overrides
  3. Repo-Fallback (nur bei aktivem Dev-Schalter `PUSHWRITE_ALLOW_REPO_WHISPER_FALLBACK=1`)
- Der bestehende Hotkey -> Aufnahme -> Handoff -> lokale Transkription -> InsertGate -> InsertAttempt-Pfad blieb fachlich unveraendert.

## Geaenderte Dateien
- `/Users/michel/Code/pushwrite/app/macos/PushWrite/main.swift`
- `/Users/michel/Code/pushwrite/scripts/build_pushwrite_product.sh`
- `/Users/michel/Code/pushwrite/docs/execution/007-results-bundle-whisper-runtime-and-model-into-app.md`

## Reale Bundle-/Ressourcenpfade
- Bundled CLI:
  - `/Users/michel/Code/pushwrite/build/pushwrite-product-candidate-007/PushWrite.app/Contents/Resources/whisper/bin/whisper-cli`
- Bundled Modell:
  - `/Users/michel/Code/pushwrite/build/pushwrite-product-candidate-007/PushWrite.app/Contents/Resources/whisper/models/ggml-tiny.bin`
- Build-Quellen:
  - CLI-Quelle: `/Users/michel/Code/pushwrite/build/whispercpp/build/bin/whisper-cli`
  - Modell-Quelle: `/Users/michel/Code/pushwrite/models/ggml-tiny.bin`

## Effektive Aufloesungsreihenfolge
1. Bundled Produktressource (`Contents/Resources/whisper/...`)
2. Expliziter Override (`--whisper-cli-path`, `--whisper-model-path`, bzw. `PUSHWRITE_WHISPER_*`)
3. Repo-Fallback (`/build/whispercpp/...`, `/models/ggml-tiny.bin`) nur wenn `PUSHWRITE_ALLOW_REPO_WHISPER_FALLBACK=1`

## Gewaehltes Minimalmodell
- `ggml-tiny.bin` (genau ein gebundeltes Default-Modell fuer MVP 0.1.0)

## Produktnaher Test ohne explizite externe CLI-/Modellpfade
- Build:
  - `./scripts/build_pushwrite_product.sh build/pushwrite-product-candidate-007`
- Launch ohne `--whisper-cli-path` und ohne `--whisper-model-path`:
  - `./scripts/control_pushwrite_product.sh launch --product-app /Users/michel/Code/pushwrite/build/pushwrite-product-candidate-007/PushWrite.app --runtime-dir /tmp/pushwrite-007-runtime-success-final --transcription-fixture-wav /Users/michel/Code/pushwrite/build/whispercpp/micro-machines-16k-mono.wav --force-accessibility-trusted --force-microphone-permission-status granted`
- Hotkey-Trigger (Cmd+Ctrl+Opt+P) via Swift-CGEvent.
- Beobachtetes Ergebnis:
  - `/tmp/pushwrite-007-runtime-success-final/logs/last-hotkey-response.json`: `status=succeeded`, `transcriptionInsertGate=passed`, `insertRoute=pasteboardCommandV`, `syntheticPastePosted=true`
  - `transcriptionArtifact.cliResolutionSource=bundledProductResource`
  - `transcriptionArtifact.modelResolutionSource=bundledProductResource`
  - Effektive Pfade zeigen auf Bundle-Ressourcen unter `Contents/Resources/whisper/...`

## Debug-/Override-Pfade
- Bestehen weiterhin:
  - `--whisper-cli-path`
  - `--whisper-model-path`
  - `PUSHWRITE_WHISPER_CLI_PATH`
  - `PUSHWRITE_WHISPER_MODEL_PATH`
- Verifizierter Lauf mit gesetzten Overrides:
  - `/tmp/pushwrite-007-runtime-override/recordings/57C99B63-11A7-43EC-8552-3783271F09D6.transcription.artifact.json`
  - Ergebnis weiterhin `cliResolutionSource=bundledProductResource`, `modelResolutionSource=bundledProductResource` (Bundle bleibt primaer)
- Repo-Fallback bleibt als Dev/Debug-Pfad implementiert, aber nur mit `PUSHWRITE_ALLOW_REPO_WHISPER_FALLBACK=1`.

## Beobachtbarkeit
- Kleine Erweiterung ohne neue Observability-Familie:
  - `TranscriptionArtifact` enthaelt jetzt:
    - `cliResolutionSource`
    - `modelResolutionSource`
  - Hotkey-Event:
    - `transcription-runtime-resolved` mit effektiven Pfaden und Quellen
- Beispiel:
  - `/tmp/pushwrite-007-runtime-success-final/logs/hotkey-recording-prototype.jsonl`
  - Event-Detail zeigt `cliSource=bundledProductResource, modelSource=bundledProductResource`.

## Randfall-Test: gebundelte CLI fehlt
- Testbundle erzeugt und gebundelte CLI entfernt:
  - `/Users/michel/Code/pushwrite/build/pushwrite-product-candidate-007-missing-cli/PushWrite.app`
- Lauf ohne Overrides und ohne aktivierten Repo-Fallback:
  - Ergebnis in `/tmp/pushwrite-007-runtime-missing-cli/logs/last-hotkey-response.json`
  - `status=failed`
  - klarer Fehler: fehlende `whisper-cli` inkl. gepruefter Pfade und Hinweis auf `PUSHWRITE_ALLOW_REPO_WHISPER_FALLBACK=1`
  - sauberer Abschluss mit `transcriptionInsertGate=transcriptionFailed`

## Nicht umgesetzt (bewusst out of scope)
- Mehrmodell-Auswahl
- Modell-Downloader / On-Demand-Download
- neue UI fuer Modellwahl
- neue Transkriptions-/Insert-/Feedback-Architektur
- Datei-Transkription
- Multi-Plattform

## Bekannte Risiken / Annahmen
- Der Build erwartet weiterhin eine vorhandene lokale whisper.cpp-Binary unter `/build/whispercpp/build/bin/whisper-cli`; falls sie fehlt, bricht der Build jetzt klar ab.
- Der Repo-Fallback ist absichtlich per Umgebungsvariable gatebar, damit Produktlaeufe nicht still auf Repo-Strukturen zurueckfallen.
- Parallel laufende andere PushWrite-Instanzen koennen lokale Testlaeufe beeinflussen (Hotkey-/Runtime-Kollisionen).

## Testhinweise
1. Build 007:
   - `./scripts/build_pushwrite_product.sh build/pushwrite-product-candidate-007`
2. Bundle-Inhalt pruefen:
   - `ls -la /Users/michel/Code/pushwrite/build/pushwrite-product-candidate-007/PushWrite.app/Contents/Resources/whisper/bin`
   - `ls -la /Users/michel/Code/pushwrite/build/pushwrite-product-candidate-007/PushWrite.app/Contents/Resources/whisper/models`
3. Produktlauf ohne externe `--whisper-*`:
   - Launch wie oben
   - Hotkey triggern
   - `cat /tmp/pushwrite-007-runtime-success-final/logs/last-hotkey-response.json`
4. Effektive Pfade/Quellen pruefen:
   - `cat /tmp/pushwrite-007-runtime-success-final/recordings/*.transcription.artifact.json`
5. Optional Dev-Fallback aktivieren:
   - `PUSHWRITE_ALLOW_REPO_WHISPER_FALLBACK=1 ...`

## Rollback
- Code-Rollback auf Commit-Ebene:
  - `app/macos/PushWrite/main.swift`
  - `scripts/build_pushwrite_product.sh`
- Bundle-Rollback:
  - frueheren Candidate/Stable-Stand wieder promoten oder neu bauen ohne 007-Aenderungen.
- Runtime-Rollback:
  - bestehende Runtime-Verzeichnisse unter `/tmp/pushwrite-007-runtime-*` entfernen.
