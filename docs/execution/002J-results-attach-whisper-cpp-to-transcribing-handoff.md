# 002J Ergebnisse: `whisper.cpp` am bestehenden `transcribing`-Uebergabepunkt

## Kurzfassung

- `PushWrite.app` ersetzt den bisherigen `transcribing`-Platzhalter jetzt durch echten lokalen `whisper.cpp`-Lauf gegen das bereits vorhandene WAV-Artefakt unter `runtime/.../recordings/<flow-id>.wav`.
- Das bestehende Artefaktformat `wav-lpcm-16khz-mono` funktioniert direkt mit `whisper-cli`; es war keine zusaetzliche Vor-Konvertierung im Produktpfad noetig.
- Erfolgreiche Laeufe schreiben jetzt neben dem Recording-Artefakt ein echtes Transkriptionsartefakt inklusive erkanntem Text, Roh-JSON und Metadaten.
- Fehlschlaege im Inferenzschnitt bleiben im selben Artefaktstil sichtbar: `last-hotkey-response.json`, `product-state.json` und das neue Transkriptionsartefakt tragen denselben Fehler.
- Die kleine 002J-Revalidierung auf dem Stable-Bundle ist fuer Success, Inferenzfehler, Accessibility-Blocked, Microphone-Denied und No-Mic gruen.

## Geaenderte oder erstellte Artefakte

- `app/macos/PushWrite/main.swift`
- `scripts/control_pushwrite_product.swift`
- `scripts/run_pushwrite_recording_validation.swift`
- `scripts/build_whispercpp_minimal.sh`
- `third_party/whisper.cpp`
- `models/ggml-tiny.bin`
- `build/whispercpp/build/bin/whisper-cli`
- `build/whispercpp/micro-machines-16k-mono.wav`
- `build/pushwrite-product/runtime-002j-transcription-summary.json`
- `docs/execution/002J-results-attach-whisper-cpp-to-transcribing-handoff.md`
- `docs/execution/002J-results-attach-whisper-cpp-to-transcribing-handoff.json`

## 1. `whisper.cpp`-Anbindung am bestehenden WAV-Pfad

### Umsetzung

- Der Hotkey-Pfad schreibt weiterhin zuerst das bestehende Recording-Artefakt nach `runtime/.../recordings/<flow-id>.wav`.
- `finishRecordingSession(...)` liest genau dieses WAV-Artefakt und fuehrt danach `whisper-cli` auf demselben Pfad aus.
- Der minimale Aufruf ist:
  - `whisper-cli -m <model> -f <recording.wav> -nt -ng -otxt -oj -of runtime/.../recordings/<flow-id>.transcription`
- `-ng` bleibt fuer 002J gesetzt, damit die erste lokale Produktvalidierung ohne weitere GPU-Annahmen stabil laeuft.

### WAV-Kompatibilitaet

- Verifiziertes Produktformat: `wav-lpcm-16khz-mono`
- Verifizierte Referenzdatei: `build/whispercpp/micro-machines-16k-mono.wav`
- Beobachtung:
  - `afinfo` meldet `1 ch, 16000 Hz, Int16`
  - `whisper-cli` akzeptiert dieses Format direkt
- Ergebnis:
  - keine zusaetzliche Audio-Konvertierung im Produktpfad noetig

## 2. Echter `transcribing`-Schritt

### Ablauf

- Hotkey-Up stoppt wie bisher die Aufnahme und setzt sofort `flow.state=transcribing`.
- Auf der bestehenden Worker-Queue passiert danach:
  - optionaler validator-only Fixture-Ersatz des gerade geschriebenen WAV-Artefakts
  - Persistenz des Recording-Artefakts
  - echter `whisper.cpp`-Lauf
  - Persistenz des Transkriptionsartefakts
  - terminaler Uebergang nach `done` oder `error`

### Zustandsuebergaenge

- Success:
  - `triggered -> recording -> transcribing -> done`
- Inferenzfehler:
  - `triggered -> recording -> transcribing -> error`
- Accessibility-Blocked bleibt:
  - `triggered -> blocked`
- Microphone-Denied bleibt:
  - `triggered -> blocked`
- No-Mic bleibt:
  - `triggered -> error`

## 3. Persistenz von Ergebnis und Fehlern

### Neue produktnahe Artefakte

- `recordings/<flow-id>.transcription.artifact.json`
- `recordings/<flow-id>.transcription.txt`
- `recordings/<flow-id>.transcription.json`

### Inhalt

- `last-hotkey-response.json`
  - `textLength`
  - `recordingArtifact`
  - `transcriptionArtifact`
  - `error` bei Inferenzfehler
- `product-state.json`
  - `lastRecording`
  - `lastTranscription`
  - `flow.textLength`
  - `flow.error` bei Inferenzfehler
- `transcription.artifact.json`
  - CLI- und Modellpfad
  - Sprache
  - erkannter Text
  - Textlaenge
  - Start-/Endzeit
  - Laufzeit
  - Fehlertext bei Fehlschlag

## 4. Modellwahl fuer 002J

- Gewaehltes Modell: `models/ggml-tiny.bin`
- Groesse: `77,691,713` Bytes, ca. `74.1 MiB`
- SHA-256: `be07e048e1e599ad46341c8d2a135645097a538221678b7acdd1b1919c6e1b21`

### Warum genau dieses Modell fuer den ersten Schritt

- klein genug fuer einen schnellen ersten lokalen Produktdurchstich
- ausreichend fuer 002J, weil hier der Integrationsschnitt wichtiger ist als Qualitaetsvergleich zwischen Modellen
- minimiert Download-, Build- und Laufzeit fuer die erste End-to-End-Stufe

## 5. Kleine produktnahe Revalidierung

### Laufbasis

- Stable-Bundle: `build/pushwrite-product/PushWrite.app`
- Validator-Summary: `build/pushwrite-product/runtime-002j-transcription-summary.json`
- Success-Fixture fuer deterministische Automation: `build/whispercpp/micro-machines-16k-mono.wav`

### Success

- Runtime: `build/pushwrite-product/runtime-002j-transcription-success`
- Flow: `triggered -> recording -> transcribing -> done`
- `status=succeeded`
- Recording-Artefakt:
  - Format: `wav-lpcm-16khz-mono`
  - Dauer: `29888 ms`
- Transkriptionsartefakt:
  - `status=succeeded`
  - `language=en`
  - `textLength=933`
  - Inferenzdauer im Produktlauf: `1351 ms`
- Ergebnis:
  - echtes Textresultat im Produktpfad vorhanden

### Inferenzfehler

- Runtime: `build/pushwrite-product/runtime-002j-transcription-inference-failure`
- Validierung ueber absichtlich fehlenden Modellpfad auf demselben Stable-Bundle
- Flow: `triggered -> recording -> transcribing -> error`
- `status=failed`
- Recording-Artefakt bleibt erhalten
- `transcriptionArtifact.status=failed`
- Fehlertext erscheint konsistent in:
  - `last-hotkey-response.json.error`
  - `last-hotkey-response.json.transcriptionArtifact.error`
  - `product-state.json.lastError`
  - `product-state.json.lastTranscription.error`
  - `product-state.json.flow.error`

### Bestehende Fehlerpfade

- Accessibility-Blocked:
  - `triggered -> blocked`
  - kein Recording-Artefakt
  - kein Transkriptionsartefakt
- Microphone-Denied:
  - `triggered -> blocked`
  - kein Recording-Artefakt
  - kein Transkriptionsartefakt
- No-Mic:
  - `triggered -> error`
  - kein Recording-Artefakt
  - kein Transkriptionsartefakt

## 6. Beobachtung, Interpretation, Empfehlung

### Beobachtung

- `whisper.cpp` funktioniert direkt am bestehenden Recording-WAV.
- Der Produktfluss erzeugt jetzt ein echtes Textresultat ohne neue Audioabstraktion.
- Inferenzfehler bleiben im Runtime-State und in den Response-Artefakten konsistent sichtbar.

### Interpretation

- Der erste echte Pfad `Hotkey -> Recording -> lokale Inferenz -> Textresultat` ist vorhanden.
- Die technische Unsicherheit liegt nicht mehr am `transcribing`-Uebergabepunkt, sondern vor allem an der letzten Produktstufe der Texteinsetzung.

### Empfehlung

- Die naechste Stufe sollte den bestehenden `done`-Pfad mit `transcriptionArtifact.text` an den vorhandenen Insert-Schnitt anschliessen.
- Vor diesem Schnitt bleibt nur kleine Resthaertung noetig; eine neue Inferenz- oder Audioarchitektur ist dafuer nicht erforderlich.

## 7. Technische Risiken und offene Punkte

- Die automatisierte Success-Revalidierung nutzt bewusst einen validator-only Fixture-Ersatz des gerade geschriebenen WAV-Artefakts, damit der Produktpfad deterministisch bleibt. Der Endnutzerpfad nimmt weiterhin echtes Mikrofon-Audio auf.
- Fuer 002J wurde genau ein kleines Modell lokal abgelegt. Es gibt noch keine Packaging-, Update- oder Modellverwaltungslogik.
- Das verwendete Modell wurde wegen nicht verfuegbarer offizieller Mirror-URLs ueber einen alternativen Downloadpfad beschafft; fuer spaetere Haertung sollte der Bezugsweg enger kontrolliert oder intern gespiegelt werden.
- Sehr kurze oder stille Aufnahmen haben noch keine eigene Produktpolitik. Der Pfad transkribiert derzeit auch solche Artefakte und kann dabei ein leeres Erfolgsresultat liefern.

## 8. MVP-Einordnung

**Im Wesentlichen tragfaehig, aber mit kleiner Resthaertung.**

Begruendung:

- das bestehende WAV-Artefakt reicht direkt fuer `whisper.cpp`
- `transcribing` ist jetzt ein echter lokaler Inferenzschritt
- Erfolg und Inferenzfehler landen konsistent in denselben Runtime-/Response-Artefakten
- die verbleibende Arbeit vor der Textinjektions-Anbindung ist klein und klar begrenzt

## 9. Konkreter Folgeauftrag

### Folgeauftrag 002K

Textinjektions-Anbindung an den jetzt echten `done`-Pfad.

Kleiner Scope:

1. nutze `transcriptionArtifact.text` aus dem Hotkey-Flow als Quelle fuer den bestehenden Insert-Pfad
2. fuehre fuer leere oder zu kurze Transkripte eine kleine Gating-Regel ein
3. halte `done`, `blocked` und `error` im Runtime-State unveraendert beobachtbar
4. validiere danach nur:
   - Success: `Hotkey -> Recording -> Transcription -> Insert`
   - leeres/zu kurzes Ergebnis ohne unerwuenschten Paste
   - Accessibility-Blocked ohne Regression
