# 002F Results: Product Start Path and TCC Hardening Before Microphone

## Kurze Zusammenfassung

002F haertet den realen Start- und Berechtigungspfad von `PushWrite.app` fuer den macOS-MVP v0.1.0, ohne Audio oder `whisper.cpp` anzubinden.

Umgesetzt wurden:

- stabiler Bundle-Startpfad ueber das reale Produktbundle und einen kontrollierten Launch-Wrapper
- echte Trusted-Beobachtung auf dem Produktbundle ohne `--force-accessibility-trusted`
- bereinigte Hotkey-Blocked-Fokusbeobachtung
- Hotkey-Validator auf denselben Bundle-Startpfad umgestellt
- kleine produktnahe Revalidierung fuer TextEdit, Safari und Blocked
- Nachhaertung des Stop-Pfads fuer kohaerentere `product-state.json`

Nicht umgesetzt wurden Mikrofonaufnahme, Audio-Pufferung, `whisper.cpp` oder alternative Insert-Methoden.

## Geaenderte und erstellte Artefakte

- `app/macos/PushWrite/main.swift`
- `scripts/control_pushwrite_product.swift`
- `scripts/control_pushwrite_product.sh`
- `scripts/run_pushwrite_hotkey_validation.swift`
- `scripts/run_pushwrite_product_validation.swift`
- `docs/execution/002F-results-product-start-and-tcc-hardening.json`
- dieses Ergebnisdokument

## Gehaerteter Startpfad

### Festgelegter Produktpfad

Fester Bundle-Pfad fuer Entwicklung und Revalidierung:

`/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`

Festgelegter Startpfad fuer reale Bundle-Starts:

```bash
'/Users/michel/Code/pushwrite/scripts/control_pushwrite_product.sh' launch \
  --product-app '/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app' \
  --runtime-dir '/Users/michel/Code/pushwrite/build/pushwrite-product/runtime-hotkey-success' \
  --simulated-text 'PushWrite 002E simulated transcription.'
```

Wichtig:

- der Startpfad arbeitet mit dem echten Produktbundle
- intern startet der Wrapper das Bundle ueber `NSWorkspace.openApplication(at:configuration:)`
- pro Lauf bleibt das Bundle fix, nur der Runtime-Pfad wechselt
- der Hotkey-Validator verwendet jetzt genau diesen Pfad

### Warum andere Pfade nicht als Standard gesetzt wurden

Beobachtet:

- `open -a /abs/path/PushWrite.app --args ...` lieferte reproduzierbar `kLSNoExecutableErr`
- der rohe, kompilierte Control-Binary-Launch war in dieser Umgebung ebenfalls nicht belastbar genug
- der Bundle-Executable-Direktstart aus 002D bleibt technisch moeglich, ist aber nicht mehr der bevorzugte Validierungspfad fuer 002F

Ableitung:

- der produktnahe Dev-/Validierungspfad soll am Bundle haengen, nicht an einem nackten Executable
- der Wrapper kapselt genau den belastbaren Bundle-Start fuer wiederholte Validierung

## TCC- und Accessibility-Verhalten

### Gesicherte Beobachtungen

1. Trusted-Lauf auf dem realen Bundle:

- Validator-Preflight lief ohne `--force-accessibility-trusted`
- `preflight.accessibilityTrusted = true`
- Hotkey war registriert
- TextEdit `1/1` success
- Safari-Textarea `1/1` success

2. Reproduzierbarer Blocked-Lauf auf demselben Bundle:

- Blocked-Runtime wurde bewusst ueber `--force-accessibility-blocked` gefahren
- `accessibilityTrusted = false`
- `blockedReason = Accessibility access is required before PushWrite can insert text with synthetic Cmd+V.`
- `syntheticPastePosted = false`
- kein Text wurde in TextEdit eingefuegt

3. Rebuild-Verhalten des Bundles:

- nach erneutem Build derselben `PushWrite.app` meldete ein realer Produktstart:
  - `accessibilityTrusted = false`
  - derselbe Blocked-Reason wie oben
- `codesign -dv --verbose=4` fuer das Bundle zeigte:
  - `Identifier=ch.baumanncreative.pushwrite`
  - `Signature=adhoc`
  - `CDHash=6de2fef4665d1814f8e621828a425d92e49dd1ba`

### Plausible Ableitung

Stark plausible Ursache fuer den Trust-Verlust nach Rebuild:

- das Bundle ist ad-hoc signiert
- die Designated Requirement ist in dieser Repo-Stufe praktisch an den CDHash gebunden
- ein Rebuild aendert den CDHash
- fuer wiederholte Validierung sollte deshalb derselbe bereits freigegebene Build weiterverwendet und nicht implizit neu gebaut werden

### Grenzen der aktuellen Umgebung

- der echte Trusted-Zustand wurde fuer einen bereits freigegebenen Build beobachtet
- der echte Untrusted-Zustand nach Rebuild wurde ebenfalls beobachtet
- ein erneuter Success-Lauf auf dem final neu gebauten Binary wurde in dieser Sitzung nicht mehr gefahren, weil der Rebuild den Trusted-Zustand verloren hat und kein neuer manueller Accessibility-Grant vorgenommen wurde

## Bereinigte Blocked-Fokusbeobachtung

### Aenderung

Der Hotkey-Pfad erfasst den Receipt-Fokus jetzt sofort im Hotkey-Event auf dem Main-Thread und uebergibt ihn in den Worker-Flow.

Vor 002F:

- der Blocked-Pfad konnte in `focusAtReceipt` und den abgeleiteten Snapshots noch `com.openai.codex` zeigen
- Ursache war die zu spaete Beobachtung nach dem eigentlichen Hotkey-Receipt

Nach 002F:

- Blocked-Run `90499D80-A83C-4A79-8DD6-E9A50510FC97`
- `focusAtReceipt.app.bundleID = com.apple.TextEdit`
- `focusBeforePaste.app.bundleID = com.apple.TextEdit`
- `focusAfterPaste.app.bundleID = com.apple.TextEdit`
- `frontmostBundleAfterTrigger = com.apple.TextEdit`
- `failureReasons = []`

Bewertung:

- Blockadeursache und Fokusdiagnostik sind jetzt sauber getrennt
- der Blocked-Fall bleibt ehrlich blockiert
- die Fokuslogs sind fuer spaetere Fehlersuche wieder brauchbar

## Hotkey-Validator

Gehaertet wurden:

- Success-Pfad nutzt keinen Trusted-Override mehr
- vorhandenes Produktbundle wird bevorzugt wiederverwendet, statt implizit neu gebaut zu werden
- dokumentierter Launch-Command zeigt jetzt den realen Bundle-Wrapper-Pfad
- Blocked-Fall prueft weiterhin reproduzierbar ueber denselben Bundle-Pfad

Konsequenz:

- der Validator maskiert den echten TCC-Zustand nicht mehr
- Trusted und Blocked koennen entlang desselben Produktstartpfads beobachtet werden

## Produktnahe Revalidierung

### Lauf A: Trusted Build auf realem Bundle

Zeitfenster:

- `2026-04-06T18:06:18Z` bis `2026-04-06T18:06:24Z`

Ergebnis:

- TextEdit `1/1` success
- Safari-Textarea `1/1` success
- Blocked `1/1` success
- Hotkey registriert
- Success-Flow-Events:
  - `triggered`
  - `inserting`
  - `done`
- Blocked-Flow-Events:
  - `triggered`
  - `inserting`
  - `blocked`

Koharenz:

- Produkt wurde in Success und Blocked nicht frontmost
- `last-hotkey-response.json` und `flow-events.jsonl` passen zu den beobachteten Runs

### Lauf B: Post-Build-Recheck auf finalem 002F-Code

Zeitfenster:

- Launch: `2026-04-06T18:09:06Z`
- Stop-Recheck: `2026-04-06T18:10:08Z`

Ergebnis:

- stabiler Startpfad ueber den Wrapper funktionierte weiterhin
- derselbe Bundle-Pfad war nach Rebuild nicht mehr trusted
- der neue Stop-Pfad schrieb `running=false` in `product-state.json`

Bewertung:

- Startpfad ist stabil genug
- TCC-Verhalten des Bundles ist jetzt belastbar eingeordnet
- Rebuild und Accessibility-Trust sind in dieser Repo-Stufe bewusst als getrennte Fehlerklasse sichtbar

## Beobachtung, Ableitung, Offen

### Beobachtung

- realer Bundle-Start funktioniert ueber den Control-Wrapper
- Trusted-Success und simulierter Blocked wurden auf dem Produktbundle validiert
- Hotkey-Blocked-Fokus ist bereinigt
- Rebuild desselben Bundle-Pfads kann den Trusted-Zustand verlieren

### Ableitung

- fuer die naechste Integrationsstufe muss der Build-/Signaturpfad als eigener Stabilitaetsfaktor behandelt werden
- Mikrofon-Start/Stop sollte erst auf einen eingefrorenen, bereits trusted Bundle-Build gesetzt werden, damit Mic-Fehler nicht mit TCC-Rebuild-Effekten vermischt werden

### Offen

- ob fuer die Dev-Schiene ein stabilerer lokaler Signing-Pfad statt ad-hoc eingefuehrt werden soll
- ob der Safari-Harness fuer wiederholte kurze Re-Runs noch einen kleineren Reset-Hook braucht; ein zweiter erneuter 1x-Lauf lief spaeter in einen Timeout, obwohl der erste 1x-Lauf gruen war

## MVP-Einordnung

**Im Wesentlichen tragfaehig, aber mit kleiner verbleibender Resthaertung.**

Begruendung:

- der reale Bundle-Startpfad ist festgelegt und reproduzierbar
- der echte Trusted-Zustand und ein reproduzierbarer Blocked-Zustand sind verstanden
- die Blocked-Fokusdiagnostik ist bereinigt
- der Hotkey-/Flow-/Insert-Kern ist auf dem realen Bundle erfolgreich revalidiert
- die verbleibende Resthaertung liegt jetzt klar im Build-/Trust-Erhalt zwischen Rebuild und naechster Integrationsstufe

## Konkreter Folgeauftrag

### Folgeauftrag 002G

Schneide als naechsten Auftrag nur diesen Scope:

1. friere einen bereits trusted Produktbuild fuer die Mikrofonstufe ein oder fuehre einen stabileren lokalen Signing-Pfad ein
2. binde Mikrofon Start/Stop minimal an den bestehenden Hotkey-Flow an
3. halte Mic-Blocked, Accessibility-Blocked und Insert-Blocked in getrennten Flow-/Statusartefakten auseinander
4. revalidiere danach nur:
   - Hotkey -> Mic start
   - Mic stop -> simuliertes/echtes Transkript -> Insert
   - getrennte Blocked-Pfade fuer Mic und Accessibility
