# 002E Results: Minimal Hotkey Flow and In-Memory Transcription Wiring

## Ziel und Scope

002E schliesst den ersten kleinen produktnahen End-to-End-Kern in `PushWrite.app` fuer den macOS-MVP von v0.1.0:

1. globaler Hotkey
2. kleiner Flow
3. simuliertes In-Memory-Transkript
4. Uebergabe an `insertTranscription(text:)`
5. bestehender paste-basierter Insert-Pfad

Nicht umgesetzt wurden Mikrofonaufnahme, Audio-Pufferung, Whisper-/`whisper.cpp`-Inferenz, Hotkey-Settings oder eine breitere Produkt-UI.

## Geaenderte und erstellte Artefakte

- `app/macos/PushWrite/main.swift`
- `scripts/build_pushwrite_product.sh`
- `scripts/control_pushwrite_product.sh`
- `scripts/run_pushwrite_hotkey_validation.swift`
- `scripts/run_pushwrite_hotkey_validation.sh`
- `docs/execution/002E-results-minimal-hotkey-flow-and-in-memory-transcription-wiring.json`
- dieses Ergebnisdokument

## Hotkey-Ansatz

### Implementierung

Der minimale globale Hotkey wird im Produktbundle ueber Carbon registriert:

- API: `RegisterEventHotKey`
- Trigger: `Control+Option+Command+P`
- KeyCode: `35`
- Carbon-Modifikatoren: `6400`

Die Hotkey-Registrierung wird in `product-state.json` sichtbar gemacht:

- `hotKey.descriptor`
- `hotKey.keyCode`
- `hotKey.carbonModifiers`
- `hotKey.registered`
- `hotKey.registrationError`

Fuer 002E gibt es bewusst:

- genau einen festen Entwicklungs-Hotkey
- kein Preferences-System
- keine frei konfigurierbare Belegung

### Minimaler Umgang mit Kollisionen und Parallelitaet

Fuer diese Stufe wird nur minimal gehaertet:

- wenn die Registrierung scheitert, bleibt der Fehler im Produktzustand sichtbar
- wenn bereits ein Flow laeuft, wird kein zweiter paralleler Insert-Flow gestartet
- der Hotkey laeuft auf denselben seriellen Worker-Pfad wie der bestehende Produktablauf

## Minimaler Flow

### Zustandsmodell

Der Flow wurde klein und explizit gehalten:

- `idle`
- `triggered`
- `inserting`
- `done`
- `blocked`
- `error`

### Beobachtbarkeit

Der Zustand wird an zwei Stellen sichtbar:

- `product-state.json`
- `logs/flow-events.jsonl`

Jeder Hotkey-Lauf erhaelt eine eigene Flow-ID. Dadurch ist nachvollziehbar, ob der Ablauf wirklich den erwarteten Pfad genommen hat.

### Beobachtete Uebergaenge

Success-Run:

- `triggered`
- `inserting`
- `done`

Blocked-Run:

- `triggered`
- `inserting`
- `blocked`

## In-Memory-Transcription-Wiring

### Simulierter Text

Der Produktprozess kann einen simulierten Transkriptions-Text uebergeben bekommen:

- Launch-Argument: `--simulated-transcription-text`
- alternativ per Environment fuer Dev-/Validierungskontexte

Verwendeter Validierungstext:

`PushWrite 002E simulated transcription.`

### Interner Uebergabepunkt

Der Hotkey baut keinen zweiten Insert-Mechanismus. Stattdessen:

1. Hotkey loest den Flow aus
2. der Flow nimmt den simulierten In-Memory-Text
3. der Text laeuft in `insertTranscription(text:)`
4. `insertTranscription(text:)` verwendet denselben bestehenden Insert-Kern

Damit bleibt fuer spaetere Audio-/Whisper-Anbindung nur ein produktinterner Anschluss offen:

`Transkriptionsresultat -> insertTranscription(text:) -> performInsert(...)`

## Produktnahe Kurzvalidierung

### Startpfad

Der belastbare Entwicklungsstart fuer diese Stufe war:

```bash
open -a /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --args \
  --runtime-dir /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002e-success-manual \
  --simulated-transcription-text 'PushWrite 002E simulated transcription.' \
  --force-accessibility-trusted
```

Fuer den Blocked-Run:

```bash
open -a /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --args \
  --runtime-dir /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002e-blocked-manual \
  --simulated-transcription-text 'PushWrite 002E simulated transcription.' \
  --force-accessibility-blocked
```

Wichtig:

- der neue Validator fuer 002E wurde angelegt
- die finale belastbare Beobachtung stammt in dieser Sitzung aber aus dem manuellen Produktlauf
- Grund: der verschachtelte Launch ueber den Validator war in dieser Umgebung noch nicht stabil genug und lieferte sporadisch `kLSNoExecutableErr`

### TextEdit

Dokumentierter produktnaher Success-Run:

- Runtime: `/Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002e-success-manual`
- Hotkey-Response-ID: `80FD0ED8-E077-40FA-BAF8-991D24802FE0`
- Status: `succeeded`
- `kind=insertTranscription`
- `insertRoute=pasteboardCommandV`
- `insertSource=transcription`
- `syntheticPastePosted=true`

Beobachtet:

- `focusAtReceipt.app.bundleID = com.apple.TextEdit`
- `focusBeforePaste.app.bundleID = com.apple.TextEdit`
- `focusAfterPaste.app.bundleID = com.apple.TextEdit`
- `focusAfterPaste.role = AXTextArea`
- `focusAfterPaste.value = PushWrite 002E simulated transcription.`
- Produkt war weder bei Receipt noch vor oder nach Paste frontmost

Flow-Ereignisse fuer diese Response-ID:

- `triggered`
- `inserting`
- `done`

### Safari-Textarea

Dokumentierter produktnaher Success-Run:

- Runtime: `/Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002e-success-manual`
- Hotkey-Response-ID: `B363A41F-E235-4E83-9B5D-93B7108B101E`
- Status: `succeeded`
- `kind=insertTranscription`
- `insertRoute=pasteboardCommandV`
- `insertSource=transcription`
- `syntheticPastePosted=true`

Beobachtet:

- `focusAtReceipt.app.bundleID = com.apple.Safari`
- `focusBeforePaste.app.bundleID = com.apple.Safari`
- `focusAfterPaste.app.bundleID = com.apple.Safari`
- `focusAfterPaste.role = AXTextArea`
- `focusAfterPaste.value = PushWrite 002E simulated transcription.`
- Produkt war weder bei Receipt noch vor oder nach Paste frontmost

Flow-Ereignisse fuer diese Response-ID:

- `triggered`
- `inserting`
- `done`

Zusaetzliche Beobachtung aus der manuellen Serie:

- die verwendete Browser-Textarea-Fixture nahm den Text korrekt an
- waehrend des manuellen Laufs spiegelte die Fixture-URL den eingefuegten Text im Hash wider

### Accessibility Blocked

Dokumentierter Blocked-Run:

- Runtime: `/Users/michel/Code/pushwrite/build/pushwrite-product/runtime-002e-blocked-manual`
- Hotkey-Response-ID: `57CA68B2-BEE2-4A87-9EC8-DC6FD8B6968A`
- Status: `blocked`
- `accessibilityTrusted=false`
- `syntheticPastePosted=false`
- `clipboardRestored=false`
- `blockedReason=Accessibility access is required before PushWrite can insert text with synthetic Cmd+V.`

Flow-Ereignisse fuer diese Response-ID:

- `triggered`
- `inserting`
- `blocked`

Beobachtet:

- kein falscher Success-Zustand
- kein Insert in das Zieltextfeld
- Produkt war weder bei Receipt noch vor oder nach dem Blocked-Lauf frontmost
- der Hotkey-Pfad hat im Blocked-Fall keine zusaetzliche Blocked-Window-Fokusuebernahme erzwungen
- stattdessen blieb der Ablauf bei ehrlicher Blockade plus minimaler Rueckmeldung

Wichtige offene Beobachtung:

- die Focus-Snapshots im Blocked-Response zeigten `com.openai.codex`
- das ist fuer den produktnahen Blocked-Pfad noch nicht sauber genug
- der Flow selbst blockiert korrekt, aber die Fokusbeobachtung ist in diesem Fall noch uneinheitlich

## Beobachtungen und Bewertung

### Beobachtet

- der Hotkey laesst sich reproduzierbar registrieren und ausloesen, sobald das Bundle sauber gestartet ist
- der kleine Flow bleibt nachvollziehbar und durchgaengig beobachtbar
- der simulierte Text laeuft ueber denselben Produktpfad wie spaeter echte Transkription
- der bestehende Insert-Pfad funktioniert auf Produktpfad-Ebene weiter in TextEdit und Safari
- der Blocked-Pfad meldet ehrlich `blocked` und erzeugt keinen falschen Success

### Neu sichtbar gewordene Probleme

- der reale Start-/TCC-Pfad ist fuer diese Stufe noch nicht sauber genug gehaertet
- der erfolgreiche Success-Run musste in dieser Sitzung ueber `--force-accessibility-trusted` abgesichert werden
- der Blocked-Run wurde ueber `--force-accessibility-blocked` reproduziert
- damit ist das Hotkey-/Flow-/Insert-Wiring validiert, aber nicht vollstaendig als frischer Real-TCC-Lauf eines neuen Rebuilds
- der verschachtelte Validator-Start ist noch nicht belastbar genug
- die Fokusbeobachtung im Blocked-Fall ist noch nicht stabil

## MVP-Einordnung

**Tragfaehig mit kleiner, aber zwingender Resthaertung im Start-/TCC-Pfad.**

Begruendung:

- der erste produktnahe Kernablauf existiert jetzt real im Produktbundle
- Hotkey, Flow, Textuebergabe und Insert-Pfad sind verbunden
- Success- und Blocked-Verhalten sind auf Produktpfad-Ebene beobachtet
- vor echter Audiointegration fehlt aber noch eine kleine, klare Haertung des realen Start- und Permissions-Pfads

## Konkreter Folgeauftrag

### Folgeauftrag 002F

Vor Mikrofon- und Whisper-Integration einen kleinen Haertungsauftrag schneiden mit genau diesem Scope:

1. realen Bundle-Startpfad fuer `PushWrite.app` vereinheitlichen und stabilisieren
2. echten Accessibility-Trust-Zustand nach Rebuilds belastbar erkennen, ohne Success-Validierung auf Dev-Overrides stuetzen zu muessen
3. Fokusbeobachtung im Blocked-Hotkey-Pfad bereinigen
4. den 002E-Hotkey-Validator auf genau diesen stabilen Startpfad umstellen
5. danach erst den naechsten Integrationsschnitt fuer Mikrofon-Start/Stop auf denselben Hotkey-Flow legen

## Offene Punkte

- wie stabil Launch Services und TCC das ad-hoc gebaute Bundle ueber wiederholte Rebuilds behandeln
- ob der Produktstart fuer Dev/Validation kuenftig bewusst ueber genau einen festen `open`-Pfad oder einen festen Bundle-Executable-Pfad erfolgen soll
- warum die Fokus-Snapshots im Blocked-Hotkey-Lauf aktuell nicht konsistent zum eigentlichen Zielkontext sind
