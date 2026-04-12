# 002I Ergebnisse: Mikrofon-Start/Stop im gehaerteten Stable-Hotkey-Flow

## Kurzfassung

- `PushWrite.app` steuert den Stable-Hotkey jetzt als echtes `press-and-hold`-Recording.
- Hotkey-Down fuehrt nicht mehr direkt in den simulierten Insert-Pfad, sondern in `triggered -> recording`.
- Hotkey-Up stoppt die Aufnahme, schreibt ein wiederverwendbares Runtime-Artefakt (`.wav` plus Metadaten-JSON) und wechselt ueber `transcribing` in den terminalen Zustand.
- `product-state.json`, `flow-events.jsonl` und `last-hotkey-response.json` unterscheiden jetzt sauber zwischen `recording`, `transcribing`, Accessibility-Blocked, Microphone-Denied und No-Mic.
- Die kleine Produktvalidierung auf dem Stable-Bundle ist fuer Success, Accessibility-Blocked, Microphone-Denied und No-Mic grün.

## Geaenderte Artefakte

- `app/macos/PushWrite/main.swift`
- `app/macos/PushWrite/Info.plist`
- `scripts/build_pushwrite_product.sh`
- `scripts/control_pushwrite_product.swift`
- `scripts/run_pushwrite_recording_validation.swift`
- `scripts/run_pushwrite_recording_validation.sh`
- `docs/execution/002I-results-microphone-start-stop-into-stable-hotkey-flow.md`
- `docs/execution/002I-results-microphone-start-stop-into-stable-hotkey-flow.json`

## 1. Mikrofonanbindung

### Umsetzung

- `PushWrite.app` bindet echte Mikrofonaufnahme ueber `AVAudioRecorder` an den vorhandenen Stable-Hotkey-Kern an.
- Jeder erfolgreiche Hotkey-Lauf schreibt ein Runtime-Artefakt nach `runtime-.../recordings/<flow-id>.wav`.
- Zusaetzlich wird `runtime-.../recordings/<flow-id>.json` mit Format-, Dauer- und Dateimetadaten geschrieben.
- Das Artefaktformat ist bewusst eng gehalten: `wav-lpcm-16khz-mono`.

### Produktwirkung

- Der Hotkey erzeugt keinen simulierten Textfluss mehr.
- Der bestehende direkte Insert-Pfad bleibt fuer explizite Request-Dateien erhalten.
- Der Hotkey-Pfad endet in dieser Stufe nach dem Platzhalterzustand `transcribing`, ohne bereits `whisper.cpp` anzubinden.

## 2. Hotkey-Start/Stop-Modell

### Festgelegtes Interaktionsmodell

- Modell: `press-and-hold`
- Hotkey-Down:
  - setzt `isProcessing=true`
  - schreibt `flow.state=triggered`
  - prueft Accessibility und Mikrofonstatus
  - startet bei Erfolg die Aufnahme und wechselt nach `recording`
- Hotkey-Up:
  - stoppt die aktive Aufnahme
  - schreibt die Artefakte
  - wechselt nach `transcribing`
  - schliesst den Lauf mit `status=succeeded` und `flow.state=done`

### Ungueltige oder doppelte Trigger

- weiterer Hotkey-Down waehrend `recording` oder `transcribing` wird nicht in einen zweiten Lauf uebersetzt
- stattdessen entsteht ein eigener `blocked`-Lauf mit klarer Busy-Reason
- Hotkey-Up ohne aktive Session bleibt folgenlos
- Hotkey-Up waehrend eines noch laufenden Mic-Permission-Checks wird als `pendingStopAfterRecordingStart` gepuffert

## 3. Permission-Verhalten

### Accessibility

- Accessibility bleibt fuer den bestehenden Produktpfad die vorgelagerte Blockerklasse.
- Ist Accessibility nicht vertraut, endet der Hotkey-Lauf sofort mit:
  - `status=blocked`
  - `blockedReason=Accessibility access is required before PushWrite can insert text with synthetic Cmd+V.`
- In diesem Fall wird keine Mikrofonaufnahme gestartet.

### Mikrofon

- `NSMicrophoneUsageDescription` ist jetzt im Produktbundle gesetzt.
- Mikrofonfreigabe wird nicht beim Launch angefragt.
- Die Abfrage liegt ausschliesslich im Hotkey-Down-Pfad.
- Bei bereits erteilter Freigabe startet die Aufnahme direkt.
- Bei verweigerter Freigabe endet der Lauf mit:
  - `status=blocked`
  - `blockedReason=Microphone access is required before PushWrite can start recording.`
- Bei fehlendem Eingabegeraet endet der Lauf mit:
  - `status=failed`
  - `error=No audio input device is available for PushWrite recording.`

### Beobachtete Grenze

- Auf dieser Workstation war Mikrofon fuer `PushWrite` bereits vor 002I freigegeben.
- Deshalb konnte der echte OS-Erstprompt nicht erneut beobachtet werden, ohne den TCC-Eintrag zurueckzusetzen.
- Verifiziert wurde stattdessen:
  - Launch erzeugt keine Recording-Artefakte
  - Launch erzeugt keine Hotkey-Response
  - der Mic-Check liegt damit nicht pauschal im Startpfad

## 4. Erweiterter Runtime-State

### Neue Flow-Zustaende

- `recording`
- `transcribing`

### Semantik

- `recording`: aktive Mikrofonaufnahme laeuft
- `transcribing`: Platzhalterzustand zwischen Stop und spaeterer lokaler Inferenz

`transcribing` ist in 002I bewusst noch kein echter Inferenzschritt. Der Zustand markiert nur den Uebergabepunkt fuer die naechste Stufe.

### Neue beobachtbare Runtime-Felder

- `product-state.json`
  - `microphonePermissionStatus`
  - `hotKeyInteractionModel`
  - `activeRecordingID`
  - `lastRecording`
  - `lastError`
- `last-hotkey-response.json`
  - `kind=recordAudio`
  - `requestedMicrophonePermission`
  - `recordingStartedAt`
  - `recordingStoppedAt`
  - `recordingArtifact`
  - `transcribingPlaceholder`
- `flow-events.jsonl`
  - Success-Sequenz: `triggered -> recording -> transcribing -> done`
  - Accessibility-Blocked: `triggered -> blocked`
  - Microphone-Denied: `triggered -> blocked`
  - No-Mic: `triggered -> error`

## 5. Produktnahe Validierung

### Laufbasis

- Stable-Bundle: `build/pushwrite-product/PushWrite.app`
- Validator-Summary: `build/pushwrite-product/runtime-002i-recording-summary.json`
- Hotkey-Haltedauer im Success-Run: `900ms`

### Success-Run

- Runtime: `build/pushwrite-product/runtime-002i-recording-success`
- Flow: `triggered -> recording -> transcribing -> done`
- `status=succeeded`
- `kind=recordAudio`
- Artefakt:
  - WAV: `recordings/B8D073C9-715B-43E7-972E-994D64F888DA.wav`
  - Metadaten: `recordings/B8D073C9-715B-43E7-972E-994D64F888DA.json`
  - `durationMs=496`
  - `fileSizeBytes=19688`
- `frontmostBundleAfterTrigger = com.apple.TextEdit`
- `syntheticPastePosted=false`

### Accessibility-Blocked

- Runtime: `build/pushwrite-product/runtime-002i-recording-blocked`
- Flow: `triggered -> blocked`
- `status=blocked`
- `requestedMicrophonePermission=false`
- kein Recording-Artefakt

### Microphone-Denied

- Runtime: `build/pushwrite-product/runtime-002i-recording-denied`
- Validierung ueber erzwungenen Denied-Pfad auf demselben Stable-Bundle
- Flow: `triggered -> blocked`
- `status=blocked`
- `microphonePermissionStatus=denied`
- `blockedReason=Microphone access is required before PushWrite can start recording.`
- kein Recording-Artefakt

### No-Mic

- Runtime: `build/pushwrite-product/runtime-002i-recording-no-mic`
- Validierung ueber erzwungenen No-Mic-Pfad auf demselben Stable-Bundle
- Flow: `triggered -> error`
- `status=failed`
- `error=No audio input device is available for PushWrite recording.`
- kein Recording-Artefakt

## 6. Beobachtung, Interpretation, Empfehlung

### Beobachtung

- der Hotkey steuert Aufnahme-Start und Aufnahme-Stop konsistent
- `recording` und `transcribing` landen reproduzierbar im Runtime-State
- Success, Accessibility-Blocked, Microphone-Denied und No-Mic sind in denselben Artefakten getrennt beobachtbar
- das Success-Artefakt ist bereits in einer Form abgelegt, die fuer lokale Transkription weiterverwendbar ist

### Interpretation

- der Produktkern ist fuer den naechsten Schnitt nicht mehr am Audio-Start/Stop blockiert
- die verbleibende Unsicherheit liegt jetzt nicht mehr im Hotkey oder Recorder-Start, sondern im Uebergang von `transcribing` zu echter lokaler Inferenz
- der echte OS-Erstprompt bleibt wegen des bereits gesetzten lokalen Mic-TCC-Zustands in dieser Sitzung unbeobachtet

### Empfehlung

- `whisper.cpp` sollte direkt an das bestehende WAV-Artefakt und den Platzhalterzustand `transcribing` angeschlossen werden
- die naechste Stufe sollte keine neue Audioaufnahme-Abstraktion erfinden, sondern den jetzigen Artefaktfluss wiederverwenden

## 7. Technische Risiken und offene Punkte

- Der echte OS-Erstprompt fuer Mikrofon wurde in 002I nicht erneut beobachtet, weil die Workstation `microphonePermissionStatus=granted` lieferte und kein TCC-Reset vorgenommen wurde.
- Success-, Denied- und No-Mic-Laeufe wurden auf dem frisch promoted Stable-Bundle mit `--force-accessibility-trusted` isoliert validiert, damit der neue Mic-Schnitt nicht mit einem erneuten Accessibility-Regrant vermischt wird.
- `AVAudioRecorder` schreibt in 002I bewusst direkt PCM-WAV. Die naechste Stufe sollte vor Inferenz nur noch klein pruefen, ob `whisper.cpp` genau dieses Artefaktformat ohne Vor-Konvertierung akzeptiert.
- Es gibt noch keinen expliziten Cancel-/Too-short-Pfad. Sehr kurze Aufnahmen ergeben derzeit trotzdem ein Artefakt und laufen in den Platzhalterzustand `transcribing`.

## 8. MVP-Einordnung

**Im Wesentlichen tragfaehig, aber mit kleiner Resthaertung vor `whisper.cpp`.**

Begruendung:

- Hotkey-Down/Up ist als Aufnahme-Start/Stop stabil genug
- Recording-, Denied-, No-Mic- und Accessibility-Blocked sind beobachtbar getrennt
- das Runtime-Artefakt fuer die Transkriptionsstufe ist vorhanden
- die verbleibende Resthaertung ist klein und klar begrenzt

## 9. Konkreter Folgeauftrag

### Folgeauftrag 002J

`whisper.cpp` an den bestehenden `transcribing`-Uebergabepunkt anschliessen.

Kleiner Scope:

1. lese das in 002I erzeugte WAV-Artefakt direkt aus `runtime/.../recordings/<flow-id>.wav`
2. ersetze den Platzhalterzustand `transcribing` durch echten lokalen Inferenzaufruf
3. schreibe erkannte Textresultate und Inferenzfehler in dieselben Response-/State-Artefakte
4. fuehre danach nur diese kleine Revalidierung aus:
   - recording success -> transcribing -> text result available
   - no-permission
   - no-mic
   - transcription failure without inkonsistentem Runtime-State
