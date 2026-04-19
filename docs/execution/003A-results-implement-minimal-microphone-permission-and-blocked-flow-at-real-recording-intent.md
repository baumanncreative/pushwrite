# 003A Ergebnisse: Minimaler Mikrofon-Permission- und Blocked-Flow bei echter Aufnahmeabsicht

## Kurzfassung

- Status:
  - `003A = implementiert`
  - `003A = produktnah tragfaehig`
  - `003A = teilweise real verifiziert`
  - `deny -> previously denied = bekannte QA-Restriktion`
- Der Mikrofon-Check bleibt strikt am realen Aufnahmezeitpunkt im Hotkey-Down-Pfad.
- `NSMicrophoneUsageDescription` ist im Produktbundle vorhanden und wurde im gebauten Bundle verifiziert.
- `notDetermined` fuehrt jetzt nur bei echter Aufnahmeabsicht in die Systemabfrage; der Lauf geht danach entweder direkt ehrlich in `recording` ueber oder endet sauber `blocked`.
- Mikrofon-Permission-, Device-/Recorder- und spaetere Accessibility-/Insert-Faelle bleiben in Response, Runtime-State und Flow-Events getrennt sichtbar.
- Fehlende Mikrofonfreigabe sowie Recorder-/Device-Fehler erhalten eine minimale lokale Rueckmeldung ueber denselben kleinen Panel-Kanal; Accessibility bleibt im bestehenden Launch-/Blocked-Kanal.
- Der bestehende Insert-/Gate-Pfad regressiert nicht; die 002K-Transcription-Insert-Validierung ist gegen das aktualisierte Bundle erneut gruen.

## Umgesetzte Aenderungen

### Produktcode

- `app/macos/PushWrite/main.swift`
  - erweitert `ProductFlowSnapshot`, `ProductFlowEvent`, `ProductState` und `ProductResponse` um:
    - `requestedMicrophonePermission`
    - `microphonePermissionStatus`
    - `localUserFeedback`
    - State-seitig zusaetzlich `lastRequestedMicrophonePermission` und `lastLocalUserFeedback`
  - haelt den Mikrofon-Authorisierungscheck weiter direkt vor `startRecordingSession`
  - fuehrt `notDetermined` bedarfsnah ueber `requestMicrophoneAccess` aus
  - stoppt denied/restricted faelle ehrlich vor Recording/Transkription/Insert
  - trennt `blocked` fuer Permission von `failed` fuer `no device` und Recorder-Startfehler
  - nutzt einen minimal generalisierten `ProductFeedbackWindowController` fuer:
    - Mikrofonzugriff verweigert oder eingeschraenkt
    - Recorder-/Device-Startfehler
  - laesst Accessibility im vorhandenen Blocked-Panel-Stil
  - fuehrt testbare Runtime-Overrides fuer Validatoren ein:
    - erzwungener `notDetermined`-Status
    - erzwungenes Permission-Request-Ergebnis
    - erzwungener Recorder-Startfehler

### Steuerung und Validierung

- `scripts/control_pushwrite_product.swift`
  - versteht die neuen Mic-Test-Flags und das erweiterte State-/Response-Modell.
- `scripts/run_pushwrite_recording_validation.swift`
  - validiert jetzt:
    - `mic_allowed`
    - `mic_not_determined_allow`
    - `mic_not_determined_deny`
    - `mic_previously_denied`
    - `mic_allowed_but_no_device`
    - `mic_allowed_but_recorder_failed`
    - `blocked_accessibility`
    - `inference_failure`
  - prueft zusaetzlich Bundle-Voraussetzung, `requestedMicrophonePermission`, `localUserFeedback` und Mic-Status in Response, State und terminalem Flow-Event.

## Validierung

### 003A Mikrofonvalidator

- Bundle-Voraussetzung:
  - `NSMicrophoneUsageDescription` im gebauten Bundle vorhanden
  - Wert: `PushWrite needs microphone access to record speech from the global push-to-talk hotkey.`
- Launch:
  - keine Recording-Artefakte
  - keine Hotkey-Response
  - kein pauschaler Mikrofon-Prompt beim Start
- Validierte Runtime-Verzeichnisse:
  - `mic_allowed`: `build/pushwrite-product/runtime-003a-mic-allowed`
  - `mic_not_determined_allow`: `build/pushwrite-product/runtime-003a-mic-prompt-allow`
  - `mic_not_determined_deny`: `build/pushwrite-product/runtime-003a-mic-prompt-deny`
  - `mic_previously_denied`: `build/pushwrite-product/runtime-003a-mic-previously-denied`
  - `mic_allowed_but_no_device`: `build/pushwrite-product/runtime-003a-mic-no-device`
  - `mic_allowed_but_recorder_failed`: `build/pushwrite-product/runtime-003a-mic-recorder-failed`
  - `blocked_accessibility`: `build/pushwrite-product/runtime-003a-accessibility-blocked`
  - `inference_failure`: `build/pushwrite-product/runtime-003a-inference-failure`
- Ergebnis:
  - Implementations- und Produktflussvalidierung aller 003A-Szenarien gruen
  - real bestaetigt:
    - kein Mic-Prompt beim Launch
    - realer `notDetermined -> allow`-Pfad
    - realer `allowed`-Pfad
  - offen:
    - reale Verifikation des terminalen `notDetermined -> denied`-Erstlaufs
    - reale Verifikation des davon abhaengigen `previously denied`-Folgelaufs
  - dieser Restpunkt wird als bekannte QA-/Interaktionsrestriktion gefuehrt und blockiert den aktuellen Produktfortschritt nicht

### 002K Regressionsvalidierung des Insert-Pfads

- Script: `scripts/run_pushwrite_transcription_insert_validation.sh`
- Gegen dasselbe aktualisierte Bundle erneut ausgefuehrt
- Ergebnis:
  - `success` gruen
  - `gated_empty` gruen
  - `gated_too_short` gruen
  - `blocked_accessibility` gruen
  - `inference_failure` gruen

## Beobachtete Produktwirkung

- Permission-relevante Laeufe schreiben jetzt explizit:
  - ob die Permission in diesem Lauf angefragt wurde
  - welcher Mikrofonstatus terminal galt
  - welche minimale lokale Rueckmeldung ausgeloest wurde
- `mic_not_determined_allow` bleibt ehrlich:
  - Launch-Status `notDetermined`
  - Hotkey-Lauf mit `requestedMicrophonePermission=true`
  - direkter Uebergang in `recording -> transcribing -> inserting -> done`
- `mic_not_determined_deny` und `mic_previously_denied` bleiben ehrlich:
  - kein Recording-Artefakt
  - kein Transkriptionsartefakt
  - kein Insert
  - `status=blocked`
  - `localUserFeedback=blockedPanel`
- `mic_allowed_but_no_device` und `mic_allowed_but_recorder_failed` bleiben getrennt von Permission:
  - `status=failed`
  - `microphonePermissionStatus=granted`
  - eigener `error`
  - `localUserFeedback=blockedPanel`

## Geaenderte Artefakte

- `app/macos/PushWrite/main.swift`
- `scripts/control_pushwrite_product.swift`
- `scripts/run_pushwrite_recording_validation.swift`
- `docs/execution/003A-results-implement-minimal-microphone-permission-and-blocked-flow-at-real-recording-intent.md`
- `docs/execution/003A-results-implement-minimal-microphone-permission-and-blocked-flow-at-real-recording-intent.json`

## Risiken und Grenzen

- Die reale Verifikation deckt derzeit `launch ohne Prompt`, `allowed` und `notDetermined -> allow` ab.
- Offen bleibt ausschliesslich die reale Verifikation des terminalen `notDetermined -> denied`-Erstlaufs und des daraus folgenden `previously denied`-Folgelaufs.
- Fuer diese beiden Faelle liegt aktuell kein nachgewiesener Produktfehler vor; sie werden als bekannte QA-/Interaktionsrestriktion gefuehrt.
- Deterministische Validator-Overrides bestehen weiterhin fuer die technische Produktflusspruefung von `notDetermined -> denied` und `previously denied`.
- Der bestehende unversionierte Auftragsrahmen `docs/execution/003A-implement-minimal-microphone-permission-and-blocked-flow-at-real-recording-intent.md` wurde nicht veraendert.
