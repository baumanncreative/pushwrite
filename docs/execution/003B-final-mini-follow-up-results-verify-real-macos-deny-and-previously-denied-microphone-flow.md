# 003B Final Mini-Follow-up Ergebnisse: Reale Verifikation von Deny und Previously-Denied im macOS-Mikrofonpfad

## 1. Kurze Zusammenfassung

- Der Final-Mini-Follow-up wurde auf dem echten LaunchServices-Bundle-Pfad ausgefuehrt.
- Bundle-spezifische Accessibility war aktiv (`accessibilityTrusted=true`, System-TCC `auth_value=2`).
- Der Pflichtfall `mic_not_determined_deny_real_final` wurde real zweimal versucht, endete aber beide Male nicht in `denied`, sondern in `granted` mit gestarteter Aufnahme.
- Dadurch war `mic_previously_denied_real_final` als direkter Folgefall ohne Reset fachlich nicht ausloesbar.
- Gesamtentscheidung: **003A bleibt teilweise real verifiziert, nicht voll real verifiziert.**

## 2. Bundle-/TCC-Setup des Final-Mini-Follow-ups

- Bundle-Pfad: `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
- Bundle-ID: `ch.baumanncreative.pushwrite`
- Launch-Pfad: `open /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --args --runtime-dir <...>`

### Setup-Befunde

- Accessibility (System-TCC):
  - `kTCCServiceAccessibility|ch.baumanncreative.pushwrite|0|2|4|1776533278`
- Mikrofon (User-TCC nach den Final-Versuchen):
  - `kTCCServiceMicrophone|ch.baumanncreative.pushwrite|0|2|2|1776574195`

## 3. Realer `mic_not_determined_deny_real_final`-Erstlauf

### Versuch 1

- Runtime: `/tmp/pushwrite-003b-final-notdet-deny`
- Startzustand vor Hotkey:
  - `accessibilityTrusted=true`
  - `microphonePermissionStatus=notDetermined`
- Laufbefund:
  - `requestedMicrophonePermission=true`
  - terminal `microphonePermissionStatus=granted`
  - Recording startete (`recordingArtifact` vorhanden)
  - Flow: `triggered -> recording -> transcribing -> error`
  - kein blocked-denied Zustand

### Versuch 2 (kontrollierter Wiederholungsversuch)

- Runtime: `/tmp/pushwrite-003b-final-notdet-deny-attempt2`
- Startzustand vor Hotkey:
  - `accessibilityTrusted=true`
  - `microphonePermissionStatus=notDetermined`
- Laufbefund:
  - `requestedMicrophonePermission=true`
  - terminal `microphonePermissionStatus=granted`
  - Recording startete (`recordingArtifact` vorhanden)
  - Flow: `triggered -> recording -> transcribing -> error`
  - kein blocked-denied Zustand

### Einordnung

- Kategorie: **E. QA-/Interaktionsproblem**
- Grund:
  - Der reale Erstpromptpfad wurde zwar erreicht (`requestedMicrophonePermission=true`), aber ein tatsaechlicher Endzustand `denied` wurde in beiden realen Versuchen nicht erreicht.
  - Damit ist der offene Punkt aktuell nicht belastbar als Produktfehler klassifizierbar.

## 4. Realer `mic_previously_denied_real_final`-Folgelauf

- Voraussetzung fuer diesen Pflichtfall war ein realer Erstlauf mit terminalem `denied`.
- Diese Voraussetzung wurde im Final-Mini-Follow-up nicht erreicht.
- Deshalb wurde kein kuenstlicher `previously denied`-Pass/Fail behauptet.

### Einordnung

- Kategorie: **B. Produktpfad plausibel, aber real noch nicht voll bestaetigt**
- Grund:
  - Folgefall fachlich korrekt blockiert durch fehlenden realen `denied`-Erstzustand.

## 5. Optionaler Restpunkt: `allowed but no device / recorder failed`

- Status: weiter offen, workstation-/hardwareabhaengig.
- Im Final-Mini-Follow-up wurde dafuer kein neuer kuenstlicher Testaufbau eingefuehrt.

## 6. Klare Gesamtentscheidung zu 003A

- **Nicht voll real verifiziert**
- **Weiterhin teilweise real verifiziert**

## 7. Exakt ein verbleibender Grund

- Ein realer `notDetermined -> denied`-Erstlauf wurde trotz erreichter Prompt-Anfrage im Final-Mini-Follow-up nicht terminal als `denied` erreicht; dadurch bleibt der `previously denied`-Folgelauf offen.

## 8. Relevante Evidenzdateien

- Versuch 1:
  - `/tmp/pushwrite-003b-final-notdet-deny/product-state.json`
  - `/tmp/pushwrite-003b-final-notdet-deny/logs/last-hotkey-response.json`
  - `/tmp/pushwrite-003b-final-notdet-deny/logs/flow-events.jsonl`
- Versuch 2:
  - `/tmp/pushwrite-003b-final-notdet-deny-attempt2/product-state.json`
  - `/tmp/pushwrite-003b-final-notdet-deny-attempt2/logs/last-hotkey-response.json`
  - `/tmp/pushwrite-003b-final-notdet-deny-attempt2/logs/flow-events.jsonl`
