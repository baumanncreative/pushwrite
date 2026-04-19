# 005 Results: Controlled Transcript Insert Path

## Status
- umgesetzt

## Kurzfassung
- Der 004B-Transkriptionspfad ist jetzt kontrolliert an den bestehenden Produkt-Insert-Pfad angebunden.
- Ein Insert-Versuch wird nur nach einem erfolgreichen und brauchbaren `TranscriptionResult` ausgefuehrt.
- Gate-, Erfolgs- und Fehlerfaelle werden getrennt beobachtet und als Insert-Result persistiert.
- Der Hotkey-Flow bleibt kontrolliert und kehrt weiterhin sauber nach `idle` zurueck.

## Geaenderte Dateien
- `/Users/michel/Code/pushwrite/app/macos/PushWrite/main.swift`
- `/Users/michel/Code/pushwrite/scripts/control_pushwrite_product.swift`
- `/Users/michel/Code/pushwrite/scripts/run_pushwrite_transcription_insert_validation.swift`
- `/Users/michel/Code/pushwrite/docs/execution/005-results-controlled-transcript-insert-path.md`

## Technische Umsetzung
- Neuer fachlicher Schritt hinter 004B:
  - `TranscriptionResult -> InsertGate -> InsertAttempt -> InsertResult -> Flow-Abschluss`
- Gate-Auswertung basiert auf `TranscriptionResult`:
  - nur bei `status=succeeded` und `transcriptionAttempted=true` und nicht-leerem, nicht-nur-Whitespace Text wird `passed`.
- Bei `passed` wird genau ein Insert-Versuch ueber den bestehenden Pfad ausgefuehrt:
  - `insertTranscription(...) -> performInsert(...) -> postSyntheticPaste()`
- Kein zweiter Insert-Stack wurde eingefuehrt.
- `whisper`-Text wird jetzt nur noch von trailing line breaks bereinigt (keine aggressive Umformung), damit `empty` und `whitespace-only` sauber unterscheidbar bleiben.

## Verwendeter Insert-Pfad / Insert-Helfer
- Verwendet wird der bestehende Produktpfad in:
  - `/Users/michel/Code/pushwrite/app/macos/PushWrite/main.swift`
  - konkrete Kette: `insertTranscription(...) -> performInsert(...)`
- Insert-Route bleibt unveraendert:
  - `insertRoute = pasteboardCommandV`

## Insert-Gates
Umgesetzt und persistiert:
- `transcriptionSkipped`
- `transcriptionFailed`
- `emptyTranscriptionText`
- `whitespaceOnlyTranscriptionText`
- `passed`

Gate-Regel (verbindlich umgesetzt):
1. `TranscriptionResult.status == succeeded`
2. `transcriptionAttempted == true`
3. Text nicht leer (`""`)
4. Text nach Trim nicht nur Whitespace

Wenn eine Bedingung nicht erfuellt ist:
- kein Insert-Versuch
- persistierter Gate-Befund (`status=gated`)
- kontrollierter Flow-Abschluss

## Persistierte Insert-Artefakte
Neu im Runtime-Log:
- `logs/last-insert-result.json`
- `logs/insert-results.jsonl`

Mindestinhalt pro Insert-Result:
- `flowID` / `transcriptionResultID`
- `transcriptionResultStatus`
- `transcriptionAttempted`
- `insertAttempted`
- `status` (`gated|succeeded|failed`)
- `gate` / `gateReason` bzw. `error`
- `insertedTextLength`
- `startedAt`, `completedAt`, `durationMs`

## Beobachtbarkeit
Erweitert in `logs/hotkey-recording-prototype.jsonl`:
- `insert-gate-evaluated`
- `insert-gated`
- `insert-started`
- `insert-succeeded`
- `insert-failed`
- `processing-flow-completed`

Zusatz:
- `processing-flow-completed` enthaelt jetzt `transcriptionStatus`, `insertStatus`, `insertGate`.

## Lokal verifizierte Faelle
Verifiziert auf macOS mit Produktbundle:
- `/Users/michel/Code/pushwrite/build/pushwrite-product-candidate-005/PushWrite.app`

1. success
- `transcriptionInsertGate=passed`
- `insertAttempted=true`
- `insert-result.status=succeeded`

2. transcriptionSkipped (zu kurzer Hold)
- `transcriptionInsertGate=transcriptionSkipped`
- `insertAttempted=false`
- `insert-result.status=gated`

3. transcriptionFailed (fehlendes Modell)
- `transcriptionInsertGate=transcriptionFailed`
- `insertAttempted=false`
- `insert-result.status=gated`

4. emptyTranscriptionText (Fake-CLI mit leerem Text)
- `transcriptionInsertGate=emptyTranscriptionText`
- `insertAttempted=false`
- `insert-result.status=gated`

5. whitespaceOnlyTranscriptionText (Fake-CLI mit nur Leerzeichen)
- `transcriptionInsertGate=whitespaceOnlyTranscriptionText`
- `insertAttempted=false`
- `insert-result.status=gated`

6. insert-failed (erzwungener Paste-Fehler)
- `transcriptionInsertGate=passed`
- `insertAttempted=true`
- `insert-result.status=failed`
- Flow endet kontrolliert und geht zurueck nach `idle`

## Build- und Start-Hinweise
Build:
- `./scripts/build_pushwrite_product.sh build/pushwrite-product-candidate-005`

Start (allgemein):
- `./scripts/control_pushwrite_product.sh launch --product-app /Users/michel/Code/pushwrite/build/pushwrite-product-candidate-005/PushWrite.app --runtime-dir <runtime-dir> --whisper-cli-path /Users/michel/Code/pushwrite/build/whispercpp/build/bin/whisper-cli --whisper-model-path /Users/michel/Code/pushwrite/models/ggml-tiny.bin --force-accessibility-trusted --force-microphone-permission-status granted`

Hotkey triggern (press-and-hold, lokal):
- `swift -e 'import ApplicationServices; import Foundation; let flags: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand]; guard let source = CGEventSource(stateID: .combinedSessionState) else { fatalError("no source") }; let keyCode: CGKeyCode = 35; guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true), let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else { fatalError("no events") }; down.flags = flags; up.flags = flags; down.post(tap: .cghidEventTap); usleep(900000); up.post(tap: .cghidEventTap); usleep(1000000)'`

## Testhinweise
1) Erfolgreicher Insert-Fall lokal pruefen
- Launch mit realer whisper-cli + realem Modell + Fixture WAV.
- Hotkey long hold.
- Erwartet:
  - `logs/last-hotkey-response.json`: `status=succeeded`, `kind=insertTranscription`, `transcriptionInsertGate=passed`, `syntheticPastePosted=true`
  - `logs/last-insert-result.json`: `status=succeeded`, `insertAttempted=true`, `gate=passed`

2) Gate-Fall lokal pruefen
- Skip-Gate: sehr kurzer Hold ohne Fixture.
  - Erwartet: `transcriptionInsertGate=transcriptionSkipped`, `insertAttempted=false`, `status=gated`
- Empty-Gate: Fake-CLI mit leerer Ausgabe (`""`).
  - Erwartet: `transcriptionInsertGate=emptyTranscriptionText`, `insertAttempted=false`
- Whitespace-Gate: Fake-CLI mit nur Leerzeichen.
  - Erwartet: `transcriptionInsertGate=whitespaceOnlyTranscriptionText`, `insertAttempted=false`

3) Insert-Fehlerfall lokal pruefen
- Launch zusaetzlich mit `--force-synthetic-paste-failure`.
- Hotkey long hold.
- Erwartet:
  - `transcriptionInsertGate=passed`
  - `insertAttempted=true`
  - `logs/last-insert-result.json`: `status=failed`, `error` gesetzt
  - kein Haengenbleiben im `processing`-Pfad

4) Runtime-Artefakte danach
- `logs/last-transcription-result.json`
- `logs/transcription-results.jsonl`
- `logs/last-insert-result.json`
- `logs/insert-results.jsonl`
- `logs/last-hotkey-response.json`
- `logs/hotkey-recording-prototype.jsonl`

## Nicht umgesetzt (bewusst)
- kein neuer konkurrierender Insert-Pfad
- keine neue Accessibility-Architektur
- keine neue Rechte-Dialog-Strategie
- kein Toggle-/VAD-/Continuous-Modus
- keine Editier- oder Nachbearbeitungslogik
- keine Multiplattform-Erweiterung

## Bekannte Risiken / Annahmen
- Fuer reproduzierbare Insert-Fehlertests wurde ein enger Test-Override ergaenzt:
  - `--force-synthetic-paste-failure` / `PUSHWRITE_FORCE_SYNTHETIC_PASTE_FAILURE=1`
  - nur fuer kontrollierte Validierung gedacht.
- Bei Gate-Faellen wird aktuell kein zusaetzliches UX-Feedback erzwungen; der Fokus liegt in 005 auf kontrolliertem Ablauf und Persistenz.

## Rollback
Code:
- `git restore /Users/michel/Code/pushwrite/app/macos/PushWrite/main.swift`
- `git restore /Users/michel/Code/pushwrite/scripts/control_pushwrite_product.swift`
- `git restore /Users/michel/Code/pushwrite/scripts/run_pushwrite_transcription_insert_validation.swift`

Dokumentation:
- `git restore /Users/michel/Code/pushwrite/docs/execution/005-results-controlled-transcript-insert-path.md`
