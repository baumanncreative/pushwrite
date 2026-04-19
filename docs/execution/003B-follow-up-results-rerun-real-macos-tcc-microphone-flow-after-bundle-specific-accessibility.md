# 003B Follow-up Ergebnisse: Realer macOS-TCC-Mikrofon-Re-Run nach bundle-spezifischer Accessibility-Freigabe

## 1) Kurze Zusammenfassung

- Der Re-Run wurde erneut ueber den realen LaunchServices-Bundlepfad ausgefuehrt: `open /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --args --runtime-dir ...`.
- Die Pflichtvoraussetzung ist nun fuer das aktuelle Bundle erfuellt: `accessibilityTrusted=true` im Laufstatus und System-TCC-Eintrag `kTCCServiceAccessibility|ch.baumanncreative.pushwrite|...|auth_value=2`.
- `mic_not_determined_allow_real_rerun` ist real bestaetigt.
- `mic_allowed_real_rerun` ist real bestaetigt.
- `mic_not_determined_deny_real_rerun` wurde zweimal real versucht, landete aber beide Male bei `requestedMicrophonePermission=true` und danach `microphonePermissionStatus=granted` mit gestarteter Aufnahme.
- Dadurch blieb `mic_previously_denied_real_rerun` als Folgefall offen.
- `mic_allowed_but_no_device_or_recorder_failed_real_rerun` blieb real offen, weil auf dieser Workstation kein echter no-device/recorder-start-failed Zustand ohne Overrides reproduzierbar war.
- Gesamtentscheidung: **003A bleibt teilweise real verifiziert, nicht voll real verifiziert.**

## 2) Reales Bundle-/Accessibility-Setup

- Bundle-Pfad: `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
- Bundle-ID: `ch.baumanncreative.pushwrite`
- Testzeitraum: `2026-04-18` (UTC-Referenz aus Lauf: `2026-04-18T17:35:46Z`)

### Setup-Befunde

- System-TCC (Accessibility):
  - `kTCCServiceAccessibility|ch.baumanncreative.pushwrite|0|2|4|1776533278`
- User-TCC (Microphone, nach den Re-Runs):
  - `kTCCServiceMicrophone|ch.baumanncreative.pushwrite|0|2|2|1776533674`
- Frischer Probe-Launch zeigte:
  - `accessibilityTrusted=true`
  - `microphonePermissionStatus=notDetermined`
  - kein Mic-Prompt beim Launch beobachtbar
  - Evidenz: `/tmp/pushwrite-003b-followup-probe2/product-state.json`

## 3) Getestete Re-Run-Faelle

### Fall 1: `mic_not_determined_allow_real_rerun`

- Runtime: `/tmp/pushwrite-003b-followup-notdet-allow`
- Startzustand:
  - `accessibilityTrusted=true`
  - `microphonePermissionStatus=notDetermined`
- Hotkey-Lauf:
  - `requestedMicrophonePermission=true`
  - terminal `microphonePermissionStatus=granted`
  - Recording startete (`recordingArtifact` vorhanden)
  - Verlauf: `triggered -> recording -> transcribing -> error`
  - Fehler war transkriptionsseitig (`whisper.cpp ... transcription output ...`), nicht Permission-seitig
- Kategorie: **A. Produktpfad real bestaetigt**
- Evidenz:
  - `/tmp/pushwrite-003b-followup-notdet-allow/product-state.json`
  - `/tmp/pushwrite-003b-followup-notdet-allow/logs/last-hotkey-response.json`
  - `/tmp/pushwrite-003b-followup-notdet-allow/logs/flow-events.jsonl`

### Fall 2: `mic_not_determined_deny_real_rerun`

- Real zweimal versucht:
  - `/tmp/pushwrite-003b-followup-notdet-deny`
  - `/tmp/pushwrite-003b-followup-notdet-deny-2`
- Beide Starts jeweils mit:
  - `accessibilityTrusted=true`
  - `microphonePermissionStatus=notDetermined`
- Beide Hotkey-Laeufe endeten jedoch mit:
  - `requestedMicrophonePermission=true`
  - `microphonePermissionStatus=granted`
  - Recording startete
  - kein blocked-denied Zustand
- Kategorie: **E. QA-/Bundle-Setup-Problem**
- Zuordnung:
  - kein Produktbeleg fuer falsche denied-Behandlung
  - der reale denied-Userpfad wurde in diesen zwei Erstlaeufen nicht erreicht
- Evidenz:
  - `/tmp/pushwrite-003b-followup-notdet-deny/logs/last-hotkey-response.json`
  - `/tmp/pushwrite-003b-followup-notdet-deny-2/logs/last-hotkey-response.json`
  - `/tmp/pushwrite-003b-followup-notdet-deny-2/logs/flow-events.jsonl`

### Fall 3: `mic_previously_denied_real_rerun`

- Voraussetzung war: realer `deny`-Erstlauf.
- Da Fall 2 nicht in `denied` endete, konnte kein belastbarer `previously denied`-Folgelauf erzeugt werden.
- Kategorie: **B. Produktpfad plausibel, aber real noch nicht voll bestaetigt**

### Fall 4: `mic_allowed_real_rerun`

- Runtime: `/tmp/pushwrite-003b-followup-allowed`
- Startzustand:
  - `accessibilityTrusted=true`
  - `microphonePermissionStatus=granted`
- Hotkey-Lauf:
  - `requestedMicrophonePermission=false`
  - `recordingArtifact` und `transcriptionArtifact` vorhanden
  - Verlauf: `triggered -> recording -> transcribing -> inserting -> done`
  - Response: `status=succeeded`
- Kategorie: **A. Produktpfad real bestaetigt**
- Evidenz:
  - `/tmp/pushwrite-003b-followup-allowed/product-state.json`
  - `/tmp/pushwrite-003b-followup-allowed/logs/last-hotkey-response.json`
  - `/tmp/pushwrite-003b-followup-allowed/logs/flow-events.jsonl`

### Fall 5: `mic_allowed_but_no_device_or_recorder_failed_real_rerun`

- Real nicht reproduzierbar abgeschlossen:
  - kein echter no-device Zustand auf der Workstation ohne kuenstliche Overrides
  - kein echter recorder-start-failed Zustand ohne kuenstliche Injektion hergestellt
- Kategorie: **B. Produktpfad plausibel, aber real noch nicht voll bestaetigt**

## 4) Beobachtungen pro Fall (kompakt)

- Launch erzeugte in allen Re-Runs keinen Mic-Prompt.
- `notDetermined -> allow` zeigte den erwarteten Permission-Request-Pfad (`requestedMicrophonePermission=true`) und anschliessend echten Recording-Start.
- `allowed` zeigte den erwarteten No-Request-Pfad (`requestedMicrophonePermission=false`) mit regularem End-to-End-Lauf.
- Der reale `deny`-Pfad blieb offen, weil beide Erstlaeufe faktisch in `granted` landeten.

## 5) Trennung Produktpfad vs. TCC vs. QA-Setup

- Produktpfad:
  - fuer `notDetermined->allow` und `allowed` real konsistent.
- TCC-Verhalten:
  - Reset auf `notDetermined` war reproduzierbar.
  - Permission-Request wurde real ausgelost (`requestedMicrophonePermission=true`).
- QA-/Interaktionsgrenze:
  - `deny` wurde trotz zwei realer Erstlaeufe nicht erzeugt.
  - dadurch bleibt `previously denied` als Folgezustand offen.

## 6) Gesamtentscheidung zu 003A

- **Nicht voll real verifiziert**
- **Weiterhin teilweise real verifiziert**

Begruendung:

- Real bestaetigt: `mic_not_determined_allow_real_rerun`, `mic_allowed_real_rerun`
- Offen: `mic_not_determined_deny_real_rerun`, `mic_previously_denied_real_rerun`, `mic_allowed_but_no_device_or_recorder_failed_real_rerun`

## 7) Kleinstmoeglicher naechster QA-Schritt

1. Einen weiteren echten `notDetermined`-Erstlauf mit explizit verifizierter User-Entscheidung **Don’t Allow** durchfuehren (inkl. direkter Sichtpruefung des Prompt-Ergebnisses im selben Lauf).
2. Direkt danach ohne Reset den `mic_previously_denied_real_rerun` auf demselben Bundlepfad ausfuehren.
3. Falls no-device/recorder-failed real weiterhin nicht herstellbar ist, diesen Fall explizit als dauerhaft hardware-/workstation-abhaengig offen markieren.

## Hinweise

- Keine Produktcode-Aenderungen in diesem Follow-up.
- Der scriptgesteuerte Direktstart des Executables wurde nicht als Hauptgrundlage verwendet.
