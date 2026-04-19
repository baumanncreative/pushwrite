# 003B Ergebnisse: Revalidierung des realen macOS-TCC-Mikrofon-Flows nach 003A

## Kurzfassung

- Ein echter `notDetermined`-Ausgangszustand fuer das aktuelle Produktbundle wurde auf dieser Workstation hergestellt und beobachtet.
- Der echte Bundle-Launch ueber LaunchServices erzeugte **keinen** Mikrofonprompt beim Start.
- Der erste echte Hotkey-Lauf vom aktuellen `.app`-Bundle erreichte den Mikrofonpfad **nicht**, weil derselbe reale Lauf bereits an fehlender Accessibility-Freigabe fuer genau dieses Bundle blockierte.
- Damit ist fuer 003B real bestaetigt: kein Mic-Prompt beim Launch und keine Vermischung von Accessibility-Blocker mit Mikrofon-TCC.
- Damit ist **nicht** real bestaetigt: ein echter macOS-Mikrofon-Erstprompt bei realer Aufnahmeabsicht sowie die realen `allow`-/`deny`-/`previously denied`-/`allowed but recorder failed`-Faelle fuer das aktuelle Bundle.
- Gesamturteil: **003A ist weiterhin logisch plausibel gruen, aber nicht voll real verifiziert.**

## Geprueftes reales TCC-Setup

- Produktbundle: `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
- Bundle ID: `ch.baumanncreative.pushwrite`
- Testdatum: `2026-04-18`
- Relevante reale QA-Schritte:
  - `tccutil reset Microphone ch.baumanncreative.pushwrite`
  - direkter TCC-DB-Read fuer `kTCCServiceMicrophone` und `kTCCServiceAccessibility`
  - echter App-Bundle-Launch ueber `open /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --args --runtime-dir /tmp/pushwrite-003b-open2`
  - echter globaler Hotkey-Trigger ueber synthetischen `Control+Option+Command+P`-Keydown/-keyup

### Reale Beobachtungen zum Setup

- Nach `tccutil reset Microphone ch.baumanncreative.pushwrite` existierte kein Mikrofon-TCC-Eintrag fuer `ch.baumanncreative.pushwrite` in `~/Library/Application Support/com.apple.TCC/TCC.db`.
- Der echte LaunchServices-Start des `.app`-Bundles schrieb `product-state.json` mit:
  - `running=true`
  - `microphonePermissionStatus=notDetermined`
  - `accessibilityTrusted=false`
- Beim Launch selbst entstand kein Hotkey-Response-Artefakt und kein beobachtbarer Mic-Prompt.
- Wichtiger Harness-Befund:
  - der direkte Shell-Start des Executables bzw. der bestehende Script-Launch ist **nicht** belastbar fuer echten Mikrofon-TCC-Nachweis
  - dieser Pfad meldete `microphonePermissionStatus=granted`, obwohl fuer `ch.baumanncreative.pushwrite` kein Mikrofon-TCC-Eintrag vorlag
  - die wahrscheinlichste Ursache ist Client-/Responsible-Process-Zurechnung an den aufrufenden Host statt an das Produktbundle
  - fuer echte TCC-Revalidierung ist deshalb der LaunchServices-Start des `.app`-Bundles der relevante Pfad

## Getestete Echtfaelle

### 1. `mic_not_determined_allow_real`

- Kategorie: `E. TCC-/QA-Setup-Problem`
- Ergebnis:
  - `notDetermined` vor dem ersten Aufnahmeversuch real bestaetigt
  - kein Mic-Prompt beim Launch real bestaetigt
  - echter `allow`-Erstprompt **nicht** erreichbar
- Beobachtung:
  - der erste echte Hotkey-Lauf blockierte vor dem Mikrofonpfad an `Accessibility`
  - `requestedMicrophonePermission=false`
  - `microphonePermissionStatus=notDetermined`
  - `status=blocked`
  - `blockedReason=Accessibility access is required before PushWrite can insert text with synthetic Cmd+V.`
- Schluss:
  - der echte `allow`-Pfad ist fuer das aktuelle Bundle auf dieser Workstation nicht beurteilbar, weil die vorgelagerte Accessibility-Freigabe fehlt

### 2. `mic_not_determined_deny_real`

- Kategorie: `E. TCC-/QA-Setup-Problem`
- Ergebnis:
  - `notDetermined` vor Hotkey real bestaetigt
  - echter Mic-Erstprompt fuer einen realen `deny`-Lauf **nicht** erreicht
- Beobachtung:
  - derselbe reale Bundle-Zustand blockiert schon vor dem Mikrofonpfad an `Accessibility`
- Schluss:
  - kein belastbarer `deny`-Systemkontakt fuer das aktuelle Produktbundle

### 3. `mic_previously_denied_real`

- Kategorie: `E. TCC-/QA-Setup-Problem`
- Ergebnis:
  - kein realer `previously denied`-Bundle-Zustand hergestellt oder beobachtet
- Beobachtung:
  - ohne zuvor erreichbaren echten Mic-Erstprompt liess sich kein bundle-spezifischer `denied`-Folgezustand ueber den echten Produktpfad herstellen
- Schluss:
  - nur validator-seitig bekannt, real fuer dieses Bundle nicht bestaetigt

### 4. `mic_allowed_real`

- Kategorie: `B. Produktpfad plausibel, aber real nicht voll bestaetigt`
- Ergebnis:
  - es gibt weiterhin starke Indizien aus 003A fuer den funktionierenden Aufnahmepfad
  - fuer 003B wurde der echte `authorized`-Pfad des aktuellen, ueber LaunchServices gestarteten Bundles **nicht** voll bestaetigt
- Beobachtung:
  - der fuer echte Bundle-TCC relevante Startpfad (`open ...PushWrite.app`) stand real auf `notDetermined` und blieb accessibility-blocked
  - der scriptgesteuerte Direktstart ist fuer Mic-TCC nicht belastbar, weil er `granted` ohne bundle-spezifischen Mic-TCC-Eintrag melden kann
- Schluss:
  - realer `authorized`-Bundle-Lauf bleibt offen

### 5. `mic_allowed_but_no_device_or_recorder_failed_real`

- Kategorie: `B. Produktpfad plausibel, aber real nicht voll bestaetigt`
- Ergebnis:
  - die Trennung dieses Falls ist aus 003A validator-seitig vorhanden
  - ein echter Bundle-Lauf mit real erlaubtem Mikrofon und anschliessendem Recorder-/Device-Fehler wurde in 003B nicht erreicht
- Schluss:
  - nicht real bestaetigt

### 6. `no_regression_accessibility_insert_path_real`

- Kategorie: `A. Produktpfad real bestaetigt`
- Ergebnis:
  - real bestaetigt fuer das aktuelle `.app`-Bundle
- Beobachtung:
  - LaunchServices-Start: `microphonePermissionStatus=notDetermined`, kein Mic-Prompt
  - echter Hotkey-Lauf: `triggered -> blocked`
  - `requestedMicrophonePermission=false`
  - `blockedReason` bleibt ein reiner Accessibility-Befund
  - kein Recording-Artefakt
  - kein Transkriptionsartefakt
  - kein Insert
- Schluss:
  - Mikrofon-TCC wurde in diesem realen Blockerfall **nicht** mit Accessibility vermischt

## Saubere Trennung der Befunde

### Produktpfad

- Keine neue Produktlogik wurde fuer 003B eingebaut.
- Der reale Bundle-Lauf zeigt weiterhin saubere Sichtbarkeit von `blocked`, `requestedMicrophonePermission` und `microphonePermissionStatus`.
- Im real beobachteten Accessibility-Blockerfall wurde kein unehrlicher Mikrofon- oder Success-Pfad ausgelost.

### Reales TCC-Verhalten

- `tccutil reset Microphone ch.baumanncreative.pushwrite` war wirksam genug, um fuer den echten Bundle-Launch wieder `notDetermined` sichtbar zu machen.
- Der Mic-Prompt erschien nicht beim Launch.
- Ein echter Mic-Erstprompt bei Aufnahmeabsicht konnte nicht beobachtet werden, weil der reale Hotkey-Lauf vorher an fehlender Accessibility-Freigabe fuer das aktuelle Bundle endete.

### QA-/Harness-Problem

- Der bestehende scriptgesteuerte Direktstart des Executables ist fuer echten Mikrofon-TCC-Nachweis nicht belastbar.
- Nur der LaunchServices-Start des `.app`-Bundles lieferte den plausiblen bundle-spezifischen `notDetermined`-Befund.
- Fuer das aktuelle Bundle fehlt auf dieser Workstation eine reale Accessibility-Freigabe; dadurch ist die Mic-Erstprompt-Revalidierung blockiert.

## Gesamtbewertung

- **003A nicht voll verifiziert**
- **003A teilweise real verifiziert**

Begruendung:

- Real bestaetigt:
  - Mic-Prompt erscheint nicht beim Launch
  - echter Bundle-Zustand `notDetermined` ist herstellbar
  - Accessibility-/Insert-Blocker bleiben real getrennt von Mikrofon-TCC
- Nicht real bestaetigt:
  - echter Mic-Erstprompt bei Aufnahmeabsicht
  - realer `allow`-Lauf
  - realer `deny`-Lauf
  - realer `previously denied`-Lauf
  - realer `allowed but no device / recorder failed`-Lauf

## Empfehlung fuer den naechsten Schritt

1. Accessibility fuer **genau dieses aktuelle** Produktbundle `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app` auf der Workstation real freigeben oder einen stabil signierten/stabilen Bundle-Pfad verwenden, dessen Accessibility-Zustand erhalten bleibt.
2. Danach denselben echten LaunchServices-Pfad erneut verwenden:
   - `tccutil reset Microphone ch.baumanncreative.pushwrite`
   - `open .../PushWrite.app --args --runtime-dir ...`
   - echter Hotkey-Trigger
3. Erst dann `mic_not_determined_allow_real` und `mic_not_determined_deny_real` erneut ausfuehren.
4. Erst nach erfolgreichem realen Erstprompt auch `previously_denied_real` und `allowed_but_no_device_or_recorder_failed_real` real abschliessen.

## Relevante Artefakte und Evidenz

- Reale Bundle-Launch-Evidenz:
  - `/tmp/pushwrite-003b-open2/product-state.json`
- Reale Hotkey-/Blocked-Evidenz:
  - `/tmp/pushwrite-003b-open2/logs/last-hotkey-response.json`
  - `/tmp/pushwrite-003b-open2/logs/flow-events.jsonl`
- Vorliegende 003A-Referenz:
  - `/Users/michel/Code/pushwrite/docs/execution/003A-results-implement-minimal-microphone-permission-and-blocked-flow-at-real-recording-intent.md`
  - `/Users/michel/Code/pushwrite/docs/execution/003A-results-implement-minimal-microphone-permission-and-blocked-flow-at-real-recording-intent.json`

## Geaenderte Artefakte

- `/Users/michel/Code/pushwrite/docs/execution/003B-results-revalidate-real-macos-tcc-microphone-flow-after-003A.md`
- `/Users/michel/Code/pushwrite/docs/execution/003B-results-revalidate-real-macos-tcc-microphone-flow-after-003A.json`
