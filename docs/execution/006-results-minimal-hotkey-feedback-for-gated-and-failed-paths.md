# 006 Results: Minimal Hotkey Feedback fuer Gate- und Fehlerpfade

## Status
- umgesetzt

## Kurzfassung
- Der bestehende 005-Pfad bleibt erhalten: `Hotkey -> Aufnahme -> Handoff -> lokale Transkription -> InsertGate -> InsertAttempt`.
- Fuer no-insert- und insert-failed-Endlagen wird jetzt am Flow-Ende genau einmal eine kleine lokale Rueckmeldung ueber den bestehenden Panel-Pfad ausgeloest.
- Erfolgreiche Inserts bleiben stumm (`localUserFeedback=nil`, kein `local-feedback-triggered`).
- Die Beobachtbarkeit wurde klein erweitert: `local-feedback-evaluated` und `local-feedback-triggered` in `hotkey-recording-prototype.jsonl`.

## Geaenderte Dateien
- `/Users/michel/Code/pushwrite/app/macos/PushWrite/main.swift`
- `/Users/michel/Code/pushwrite/docs/execution/006-results-minimal-hotkey-feedback-for-gated-and-failed-paths.md`

## Verwendeter Feedback-/Response-Pfad
- Wiederverwendeter lokaler Pfad:
  - `presentFeedbackPanel(...)` (bestehender Produkt-Dialogpfad)
  - `ProductFeedbackWindowController` (bestehender Controller)
- Keine neue Feedback-Architektur wurde eingefuehrt.
- Persistenz weiter ueber bestehende Artefakte:
  - `logs/last-hotkey-response.json`
  - `logs/hotkey-responses.jsonl`
  - `logs/flow-events.jsonl`
  - `logs/hotkey-recording-prototype.jsonl`

## Abgedeckte Rueckmeldungsfaelle
- `transcriptionSkipped` -> semantisch `tooShortRecording` -> Message: `Kein Text eingefuegt. Aufnahme zu kurz.`
- `transcriptionFailed` -> semantisch `transcriptionFailed` -> Message: `Kein Text eingefuegt. Transkription fehlgeschlagen.`
- `emptyTranscriptionText` -> semantisch `noUsableText` -> Message: `Kein Text eingefuegt. Kein brauchbarer Text erkannt.`
- `whitespaceOnlyTranscriptionText` -> semantisch `noUsableText` -> Message: `Kein Text eingefuegt. Kein brauchbarer Text erkannt.`
- `insertFailed` (nach `passed`) -> semantisch `insertFailed` -> Message: `Text konnte nicht eingefuegt werden.`
- `status=succeeded` mit `transcriptionInsertGate=passed` bleibt stumm.

## Genau-einmal-Logik pro Flow
- Rueckmeldung wird nur im Endpunkt `completeGlobalHotKeyFlow(...)` bewertet und getriggert.
- Keine Trigger im Gate-Zweig und kein Trigger im Insert-Zweig selbst.
- Nachweis je letztem Flow pro Runtime:
  - `runtime-006-gate-skipped`: `local-feedback-triggered` fuer Flow-ID exakt `1x`
  - `runtime-006-gate-transcription-failed`: exakt `1x`
  - `runtime-006-gate-empty`: exakt `1x`
  - `runtime-006-gate-whitespace`: exakt `1x`
  - `runtime-006-insert-failed`: fuer die letzte Flow-ID exakt `1x`
  - `runtime-006-success-silent`: `0x`

## Beobachtbarkeit
- Neue Events in `logs/hotkey-recording-prototype.jsonl`:
  - `local-feedback-evaluated`
  - `local-feedback-triggered`
- Event-Detail enthaelt:
  - `feedbackCase` (`tooShortRecording|transcriptionFailed|noUsableText|insertFailed|none`)
  - `insertStatus`
  - `insertGate`
- Bestehende Response-/State-Felder weitergenutzt:
  - `transcriptionInsertGate`
  - `status`
  - `localUserFeedback` (`blockedPanel` fuer ausgeloeste Rueckmeldung)

## QA-Abgrenzung: Stable-Bundle vs. Debug-Start

### Primaer (gueltig): Stable-Bundle + LaunchServices
- Stable-Bundle-Pfad:
  - `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
- Dokumentierter CDHash:
  - `00b1aaa0b4a2017a9bb9892df95a2a1417956f20`
- LaunchServices-Startversuch (dokumentiert):
  - `open -n /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --args ...`
- Beobachtung in dieser Session:
  - LaunchServices gab `kLSNoExecutableErr` (`Code=-10827`) zurueck.
- Konsequenz:
  - Fuer diese konkrete Session liegt kein neuer gueltiger Laufbefund ueber LaunchServices vor.

### Sekundaer (Debug): Direct-/Control-Starts
- Fuer Funktionsnachweis 006 wurden sekundaere Direktstarts genutzt:
  - `scripts/control_pushwrite_product.sh launch ...`
- Diese Nachweise sind fuer 006-Implementierung nuetzlich, gelten aber nicht als Ersatz fuer den primaeren LaunchServices-Trust-Befund.

## Konkrete Runtime-Evidenz (sekundaer, direkt gestartet)
- `runtime-006-gate-skipped`
  - `last-hotkey-response.json`: `status=succeeded`, `transcriptionInsertGate=transcriptionSkipped`, `localUserFeedback=blockedPanel`
  - `hotkey-recording-prototype.jsonl`: `feedbackCase=tooShortRecording`, `local-feedback-triggered`
- `runtime-006-gate-transcription-failed`
  - `last-hotkey-response.json`: `status=failed`, `transcriptionInsertGate=transcriptionFailed`, `localUserFeedback=blockedPanel`
  - Event: `feedbackCase=transcriptionFailed`
- `runtime-006-gate-empty`
  - `last-hotkey-response.json`: `transcriptionInsertGate=emptyTranscriptionText`, `localUserFeedback=blockedPanel`
  - Event: `feedbackCase=noUsableText`
- `runtime-006-gate-whitespace`
  - `last-hotkey-response.json`: `transcriptionInsertGate=whitespaceOnlyTranscriptionText`, `localUserFeedback=blockedPanel`
  - Event: `feedbackCase=noUsableText`
- `runtime-006-insert-failed`
  - `last-hotkey-response.json`: `status=failed`, `transcriptionInsertGate=passed`, `localUserFeedback=blockedPanel`
  - `last-insert-result.json`: `status=failed`, `insertAttempted=true`, `gate=passed`
  - Event: `feedbackCase=insertFailed`
- `runtime-006-success-silent`
  - `last-hotkey-response.json`: `status=succeeded`, `transcriptionInsertGate=passed`, `localUserFeedback=null`
  - nur `local-feedback-evaluated` mit `feedbackCase=none`
  - kein `local-feedback-triggered`

## Nicht umgesetzt (bewusst)
- Keine neue Haupt-UI, Menubar-UI oder Notification-Architektur.
- Keine neue Accessibility-Strategie.
- Kein neuer Insert-Stack.
- Keine Retry-/Diktiermodus-/Editier-Logik.

## Bekannte Risiken / Annahmen
- Die neue Rueckmeldung ist ein kurzer lokaler Dialogpfad; keine dauerhafte Notification-Historie.
- `transcriptionSkipped` wird produktseitig als `tooShortRecording` rueckgemeldet.
- LaunchServices-Lauf war in dieser Session mit `kLSNoExecutableErr` blockiert; deshalb nur sekundare Direktstart-Evidenz fuer die funktionale 006-Logik.

## Testhinweise

1) Build und Start
- Build Candidate:
  - `./scripts/build_pushwrite_product.sh build/pushwrite-product-candidate-006`
- Direct Launch (sekundaer):
  - `./scripts/control_pushwrite_product.sh launch --product-app /Users/michel/Code/pushwrite/build/pushwrite-product-candidate-006/PushWrite.app --runtime-dir <runtime-dir> --force-accessibility-trusted --force-microphone-permission-status granted --force-microphone-request-result granted [weitere whisper flags je Szenario]`

2) Gate-Fall lokal pruefen
- `transcriptionSkipped`:
  - kurzer Hold (z. B. 120ms)
  - erwartet: `transcriptionInsertGate=transcriptionSkipped`, `localUserFeedback=blockedPanel`, Event `feedbackCase=tooShortRecording`
- `emptyTranscriptionText`/`whitespaceOnlyTranscriptionText`:
  - Fake-CLI verwenden, die leeren bzw. whitespace-only Text schreibt
  - erwartet: jeweiliger Gate-Wert + Event `feedbackCase=noUsableText`

3) Insert-Fehlerfall lokal pruefen
- Launch mit `--force-synthetic-paste-failure`
- langer Hold
- erwartet:
  - `last-hotkey-response.json`: `status=failed`, `transcriptionInsertGate=passed`, `localUserFeedback=blockedPanel`
  - `last-insert-result.json`: `status=failed`, `insertAttempted=true`, `gate=passed`
  - Event `feedbackCase=insertFailed`

4) Nachweis, dass Erfolgsfall stumm bleibt
- Erfolgsszenario mit realer whisper-cli + Modell + Fixture
- erwartet:
  - `last-hotkey-response.json`: `status=succeeded`, `transcriptionInsertGate=passed`, `localUserFeedback=null`
  - `hotkey-recording-prototype.jsonl`: `local-feedback-evaluated` mit `feedbackCase=none`
  - kein `local-feedback-triggered`

5) Relevante Runtime-Artefakte
- `/Users/michel/Code/pushwrite/build/pushwrite-product/<runtime>/logs/last-hotkey-response.json`
- `/Users/michel/Code/pushwrite/build/pushwrite-product/<runtime>/logs/hotkey-recording-prototype.jsonl`
- `/Users/michel/Code/pushwrite/build/pushwrite-product/<runtime>/logs/flow-events.jsonl`
- `/Users/michel/Code/pushwrite/build/pushwrite-product/<runtime>/logs/last-insert-result.json` (bei Insert-Versuch)

6) Gueltiger Stable-Bundle-/LaunchServices-Pfad dokumentieren
- Stable-Bundle:
  - `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
- LaunchServices:
  - `open -n /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --args ...`
- Laufresultat dieser Session dokumentieren (inkl. ggf. LS-Fehlercode).

7) Dokumentierter CDHash fuer gueltigen Bundle-Test
- `00b1aaa0b4a2017a9bb9892df95a2a1417956f20`
- Ermittelt via:
  - `codesign -dv --verbose=4 /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`

## Rollback
- Code:
  - `git restore /Users/michel/Code/pushwrite/app/macos/PushWrite/main.swift`
- Dokumentation:
  - `git restore /Users/michel/Code/pushwrite/docs/execution/006-results-minimal-hotkey-feedback-for-gated-and-failed-paths.md`
