# 004A Results: Minimaler Hotkey-/Aufnahme-Prototyp

## Status
- umgesetzt

## Kurzfassung
- Der minimale Hotkey-/Aufnahme-Flow fuer macOS wurde als press-and-hold umgesetzt.
- Aktiv ist das Interaktionsmodell `pressAndHold` mit globalem Hotkey `Control+Option+Command+P` (`GlobalHotKeyConfiguration.default` in `app/macos/PushWrite/main.swift`).
- Der aktive Hauptfluss im Hotkey-Pfad ist jetzt `idle -> recording -> processing -> idle`.

## Geaenderte Dateien
- `app/macos/PushWrite/main.swift`: Minimaler Hotkey-/Aufnahme-Prototyp mit `processing`-Zwischenschritt, Audio-Handoff-Hook, Aufnahmeklassifikation und zusaetzlicher Prototyp-Beobachtbarkeit.
- `docs/execution/004A-results-hotkey-recording-prototype.md`: Persistierte Ergebnisdokumentation fuer 004A.

## Technische Umsetzung
- Hotkey down/up Behandlung:
- Hotkey down (`kEventHotKeyPressed`) wird in `handleGlobalHotKeyPressed()` verarbeitet.
- Start erfolgt nur, wenn `hotKeyState.registered == true` und `isProcessing == false`.
- Zusaetzliche Down-Trigger waehrend laufender Verarbeitung werden kontrolliert ignoriert (`hotkey-down-ignored`).
- Hotkey up (`kEventHotKeyReleased`) wird in `handleGlobalHotKeyReleased()` verarbeitet.
- Stop erfolgt nur fuer eine aktive Session mit passender `flowID` in `stopActiveRecordingSession(_)`.
- Up ohne aktive Aufnahme wird ignoriert und protokolliert (`hotkey-up-ignored`).
- Zustandswechsel:
- Aufnahme-Start setzt Zustand auf `recording` ueber `transitionFlow(to: .recording, ...)`.
- Aufnahme-Stop setzt Zustand auf `processing` ueber `transitionFlow(to: .processing, ...)`.
- Abschluss (Erfolg/Fehler/Blockierung) kehrt im Hotkey-Flow immer auf `idle` zurueck (`completeGlobalHotKeyFlow` mit `transitionFlow(to: .idle, ...)`).
- Audio-Handoff:
- Nach Stop wird das fertige `RecordingArtifact` in `finishRecordingSession(...)` an genau einen Verarbeitungs-Hook uebergeben: `handoffAudioForProcessing(recordingArtifact:)`.
- Der Handoff persistiert:
- letzte Uebergabe: `logs/last-audio-processing-handoff.json`
- historisierte Uebergaben: `logs/audio-processing-handoffs.jsonl`
- Schnittstelle ist `AudioProcessingHandoff` mit `id`, `recordingArtifact`, `usability`, `heuristic`, `startedAt`.
- Leere/zu kurze Aufnahmen:
- Klassifikation erfolgt ueber `classifyRecordingUsability(durationMs:fileSizeBytes:minimumUsableDurationMs:)`.
- Heuristik:
- `empty`: `durationMs <= 0` oder `fileSizeBytes <= 44` (WAV-Header-only/leer)
- `tooShort`: `durationMs < 300` ms
- `usable`: sonst
- Die Klassifikation wird im Handoff-Artefakt persistiert und blockiert den Zustandsabschluss nicht.

## Beobachtbarkeit
- Vorhandene Laufzeitartefakte im Runtime-Verzeichnis (`runtimeDir`):
- `product-state.json`: aktueller Snapshot inkl. Flow-State und letzter Artefakte.
- `logs/flow-events.jsonl`: strukturierte State-Transitions pro Flow-ID.
- `logs/hotkey-recording-prototype.jsonl`: schlanke Prototyp-Events fuer Down/Up/Start/Stop/Processing/Handoff/Idle.
- `logs/hotkey-responses.jsonl` und `logs/last-hotkey-response.json`: letzte und historische Hotkey-Responses.
- `logs/audio-processing-handoffs.jsonl` und `logs/last-audio-processing-handoff.json`: Audio-Uebergabepunkt fuer spaetere Whisper-Anbindung.
- `recordings/<flow-id>.wav` und `recordings/<flow-id>.json`: Audioartefakt und Metadaten.
- Relevante Prototyp-Eventnamen in `hotkey-recording-prototype.jsonl`:
- `hotkey-down-detected`, `recording-start-attempt`, `recording-state-entered`
- `hotkey-up-detected`, `recording-stopped`, `processing-state-entered`
- `audio-handoff-started`, `audio-handoff-succeeded` oder `audio-handoff-failed`
- `flow-returned-idle`
- Standard-Runtime-Ordner ohne `--runtime-dir`:
- `~/Library/Application Support/PushWrite/runtime`

## Nicht umgesetzt
- Keine finale Whisper-Inferenz im Hotkey-Pfad.
- Keine finale Textinjektion am Cursor im Hotkey-Pfad.
- Kein Toggle-Modus, keine VAD-Logik, kein kontinuierlicher Diktiermodus.
- Kein UI-Polish und keine breite Architektur-Erweiterung fuer weitere Plattformen.

## Bekannte Risiken / Annahmen
- Der Hotkey-Prototyp ist bewusst eng geschnitten; fruehere Flows mit `transcribing`/`inserting`/`done` sind im Hotkey-Pfad nicht mehr der aktive Hauptpfad.
- Die Usability-Heuristik ist eine MVP-Prototyp-Regel und noch keine finale Produktpolitik.
- Bewertung basiert auf Dauer und Dateigroesse; keine semantische Audioqualitaetspruefung.
- Runtime-Beobachtbarkeit ist lokal dateibasiert (JSON/JSONL), keine externe Telemetrie.

## Testhinweise
- Build:
- `./scripts/build_pushwrite_product.sh build/pushwrite-product-candidate-004A`
- Start mit explizitem Runtime-Ordner:
- `./scripts/control_pushwrite_product.sh launch --product-app /Users/michel/Code/pushwrite/build/pushwrite-product-candidate-004A/PushWrite.app --runtime-dir /tmp/pushwrite-004A-runtime`
- Im laufenden App-Kontext Hotkey halten (`Control+Option+Command+P`), sprechen, loslassen.
- Danach pruefen:
- `/tmp/pushwrite-004A-runtime/logs/flow-events.jsonl` enthaelt Reihenfolge mit `recording`, `processing`, `idle`.
- `/tmp/pushwrite-004A-runtime/logs/hotkey-recording-prototype.jsonl` zeigt Down/Up/Start/Stop/Handoff/Idle.
- `/tmp/pushwrite-004A-runtime/logs/last-audio-processing-handoff.json` existiert mit `usability` und `heuristic`.
- `/tmp/pushwrite-004A-runtime/recordings/` enthaelt WAV + Metadaten.

## Rollback
- Diese Dokumentationsaenderung rueckgaengig machen:
- `git restore /Users/michel/Code/pushwrite/docs/execution/004A-results-hotkey-recording-prototype.md`
- Falls 004A-Code ebenfalls zurueckgesetzt werden soll:
- `git restore /Users/michel/Code/pushwrite/app/macos/PushWrite/main.swift`
