# 002L Ergebnisse: Minimale lokale Rueckmeldung fuer gegatete `done`-Laeufe

## Kurzfassung

- Gegatete erfolgreiche Hotkey-Laeufe mit `transcriptionInsertGate=empty|tooShort` loesen jetzt einen kleinen lokalen Systemton ueber `NSSound.beep()` aus.
- Der bestehende Insert-Pfad bleibt unveraendert: nur `passed` geht weiter in `insertTranscription(...) -> performInsert(...) -> postSyntheticPaste()`.
- Gate-Faelle bleiben terminal `done`, fuehren weiter keinen Paste aus und sind jetzt zusaetzlich ueber `gatedTranscriptionFeedback=systemBeep` in Response, State und Flow-Log beobachtbar.
- Die produktnahe Revalidierung ist gruen fuer:
  - `success`
  - `gated_empty`
  - `gated_too_short`
  - zusaetzlich `blocked_accessibility` ohne Regression

## Geaenderte oder erstellte Artefakte

- `app/macos/PushWrite/main.swift`
- `scripts/control_pushwrite_product.swift`
- `scripts/run_pushwrite_transcription_insert_validation.swift`
- `docs/execution/002L-results-add-minimal-user-feedback-for-gated-done-runs.md`
- `docs/execution/002L-results-add-minimal-user-feedback-for-gated-done-runs.json`
- `build/pushwrite-product/runtime-002l-success/summary.json`
- `build/pushwrite-product/runtime-002l-gated-empty/summary.json`
- `build/pushwrite-product/runtime-002l-gated-too-short/summary.json`
- `build/pushwrite-product/runtime-002l-blocked/summary.json`

## 1. Minimale lokale Rueckmeldung

### Gewaehlte Form

- Rueckmeldung: `NSSound.beep()`
- Trigger: nur im Hotkey-`done`-Pfad fuer `transcriptionInsertGate=empty|tooShort`
- Persistierte Beobachtbarkeit: `gatedTranscriptionFeedback=systemBeep`

### Warum das fuer den MVP klein genug ist

- Es wird kein neues Fenster, kein Panel, keine Preferences-Flaeche und kein neuer menuebasierter Zustand eingefuehrt.
- Die Rueckmeldung benutzt nur einen vorhandenen lokalen AppKit-Systemmechanismus.
- Die bestehende Gate-Regel bleibt inhaltlich unveraendert; erweitert wurde nur ein kleiner Produktsignal-Schritt direkt am Gate-Abschluss.

### Warum das keine neue UI-Flaeche ist

- Es gibt keine neue sichtbare Produktflaeche im engeren Sinn.
- Der Ton ist ein lokales Systemsignal, kein neues Produkt-Panel.
- `blocked` behaelt seine bestehende Accessibility-UI; 002L fuegt dort nichts hinzu.

## 2. Insert-Pfad unveraendert

- Der bestehende Insert-Pfad bleibt unveraendert:
  - `insertTranscription(text: transcriptionArtifact.text, requestID: session.flowID, presentsBlockedUI: false, receiptObservation: ...)`
  - `performInsert(...)`
  - `writePlainTextToPasteboard(...)`
  - `postSyntheticPaste()`
- Bei `empty|tooShort` wird weiter kein Paste ausgeloest:
  - `insertRoute=nil`
  - `syntheticPastePosted=false`
  - kein `inserting`-State
- `success` verwendet weiter denselben Produktpfad wie in 002K.

## 3. Beobachtbarkeit im Runtime-State

### Neue Beobachtungsfelder

- `last-hotkey-response.json.gatedTranscriptionFeedback`
- `product-state.json.lastGatedTranscriptionFeedback`
- `product-state.json.flow.gatedTranscriptionFeedback`
- terminale `done`-Events in `logs/flow-events.jsonl`

### Trennung der Zustaende bleibt erhalten

- `gated_empty`
  - `status=succeeded`
  - `state=done`
  - `transcriptionInsertGate=empty`
  - `gatedTranscriptionFeedback=systemBeep`
- `gated_too_short`
  - `status=succeeded`
  - `state=done`
  - `transcriptionInsertGate=tooShort`
  - `gatedTranscriptionFeedback=systemBeep`
- `success`
  - `status=succeeded`
  - `state=done`
  - `transcriptionInsertGate=passed`
  - `gatedTranscriptionFeedback=nil`
- `blocked` und `error`
  - bleiben getrennt
  - erhalten keine neue Gate-Rueckmeldung

## 4. Enge produktnahe Revalidierung

### Stable-Bundle

- `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`

### Validator

- `./scripts/run_pushwrite_transcription_insert_validation.sh --scenario success --skip-build --product-app-path /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --success-runtime-dir /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002l-success --results-file /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002l-success/summary.json`
- `./scripts/run_pushwrite_transcription_insert_validation.sh --scenario gated_empty --skip-build --product-app-path /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --gated-empty-runtime-dir /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002l-gated-empty --results-file /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002l-gated-empty/summary.json`
- `./scripts/run_pushwrite_transcription_insert_validation.sh --scenario gated_too_short --skip-build --product-app-path /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --gated-too-short-runtime-dir /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002l-gated-too-short --results-file /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002l-gated-too-short/summary.json`
- Optionaler Regressionscheck:
  - `./scripts/run_pushwrite_transcription_insert_validation.sh --scenario blocked_accessibility --skip-build --product-app-path /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --blocked-runtime-dir /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002l-blocked --results-file /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002l-blocked/summary.json`

### Ergebnis `success`

- Summary: `build/pushwrite-product/runtime-002l-success/summary.json`
- Beobachtet:
  - `flowStates=["triggered","recording","transcribing","inserting","done"]`
  - `transcriptionInsertGate=passed`
  - `gatedTranscriptionFeedback=nil`
  - `syntheticPastePosted=true`
  - `insertRoute=pasteboardCommandV`
  - `observedText == transcriptionArtifact.text`

### Ergebnis `gated_empty`

- Summary: `build/pushwrite-product/runtime-002l-gated-empty/summary.json`
- Beobachtet:
  - `flowStates=["triggered","recording","transcribing","done"]`
  - `transcriptionInsertGate=empty`
  - `gatedTranscriptionFeedback=systemBeep`
  - `syntheticPastePosted=false`
  - `insertRoute=nil`
  - `observedText=""`

### Ergebnis `gated_too_short`

- Summary: `build/pushwrite-product/runtime-002l-gated-too-short/summary.json`
- Beobachtet:
  - `flowStates=["triggered","recording","transcribing","done"]`
  - `transcriptionInsertGate=tooShort`
  - `gatedTranscriptionFeedback=systemBeep`
  - `syntheticPastePosted=false`
  - `insertRoute=nil`
  - `transcriptionArtifact.text="x"`
  - `observedText=""`

### Optionaler Regressionscheck `blocked_accessibility`

- Summary: `build/pushwrite-product/runtime-002l-blocked/summary.json`
- Beobachtet:
  - `flowStates=["triggered","blocked"]`
  - `status=blocked`
  - `gatedTranscriptionFeedback=nil`
  - `observedText=""`

## 5. Dokumentierte Beobachtungen

- Die konkrete Rueckmeldung ist ein einzelner lokaler Systemton.
- Die Rueckmeldung wird nur in Gate-Faellen gesetzt und beobachtet:
  - `hotKeyResponse.gatedTranscriptionFeedback=systemBeep`
  - `product-state.json.flow.gatedTranscriptionFeedback=systemBeep`
  - `product-state.json.lastGatedTranscriptionFeedback=systemBeep`
  - terminales `done`-Event in `logs/flow-events.jsonl` enthaelt dasselbe Feld
- `success` funktioniert produktnah unveraendert weiter ueber den bestehenden Insert-Pfad.
- Gate-Faelle bleiben sauber von `blocked` und `error` getrennt, weil sie weiter `done` + `status=succeeded` bleiben.

## 6. Technische Risiken und offene Punkte

- Die neue Rueckmeldung ist rein auditiv. Wenn Systemton, Audioausgabe oder Lautstaerke lokal nicht verfuegbar sind, bleibt der Gate-Fall fuer den Nutzer weiter still, obwohl er intern sauber beobachtbar ist.
- `empty` und `tooShort` teilen bewusst dasselbe minimalistische Signal. Das ist fuer den MVP schmal, trennt die beiden Gate-Gruende aber nicht nutzerseitig.
- Einzelzeichen-Diktate bleiben weiterhin absichtlich als `tooShort` gegatet. 002L aendert diese Regel nicht.

## 7. MVP-Einordnung

**Im Wesentlichen tragfaehig, aber mit kleiner Resthaertung.**

Begruendung:

- Die verbleibende UX-Luecke fuer stille Gate-Faelle ist im normalen Audiofall geschlossen.
- Der Produktkern bleibt schmal: kein neuer Insert-Weg, keine neue Gate-Regel, keine neue UI-Flaeche.
- Die Resthaertung liegt jetzt nicht mehr im Insert-Pfad, sondern nur noch in der Audioabhaengigkeit des minimalen Signals.

## 8. Konkreter Folgeauftrag

### Folgeauftrag 002M

Audioabhaengigkeit der Gate-Rueckmeldung klein haerten.

Kleiner Scope:

1. produktnah pruefen, wie verlaesslich `NSSound.beep()` bei stummem oder umgeleitetem macOS-Audio wahrnehmbar ist
2. nur falls noetig eine ebenso schmale nicht-auditive Fallback-Rueckmeldung definieren
3. den bestehenden Insert-Pfad, die bestehende Gate-Regel und den `done`-Status unveraendert lassen
