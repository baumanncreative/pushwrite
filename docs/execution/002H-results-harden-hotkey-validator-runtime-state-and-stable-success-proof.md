# 002H Ergebnisse: Hotkey-Validator-Ausloesung, Runtime-State und echter Stable-Success-Nachweis

## Kurzfassung

- Der Stable-Hotkey-Validator erzeugt wieder reproduzierbar neue Hotkey-Responses.
- `product-state.json` wird ueber den kontrollierten Start-/Stop-/Status-Pfad konsistent auf `running=false` normalisiert, wenn der Produktprozess beendet ist.
- Ein echter Stable-Run in TextEdit ist mit `status=succeeded` und `observedTargetValueMatches=true` belegt.
- Ein echter Stable-Run in Safari ist mit `status=succeeded` und `observedTargetValueMatches=true` belegt.

## Geaenderte Artefakte

- `scripts/run_pushwrite_hotkey_validation.swift`
- `scripts/control_pushwrite_product.swift`
- `tests/integration/browser-textarea-fixture.html`
- `docs/execution/002H-results-harden-hotkey-validator-runtime-state-and-stable-success-proof.md`
- `docs/execution/002H-results-harden-hotkey-validator-runtime-state-and-stable-success-proof.json`

## 1. Hotkey-Validator-Haertung

### Beobachtung

Die Stable-Re-Runs aus 002G scheiterten nicht primaer am Produktflow, sondern am Validierungspfad:

- der Validator loeste den Hotkey ueber `System Events` aus
- in Re-Runs entstanden dadurch teils keine neuen `last-hotkey-response.json`-Eintraege
- bei fruehen `exit(1)`-Pfaden liess der Validator gestartete `PushWrite.app`-Instanzen stehen
- stehengebliebene Produktinstanzen verfaelschten spaetere Re-Runs

### Umsetzung

Der Validatorpfad wurde in drei kleinen Schritten gehaertet:

1. Hotkey-Ausloesung von `System Events` auf direkte HID-Keyboard-Events umgestellt
2. Validator auf `main() -> Int32` umgestellt, damit `defer { stopProduct(...) }` auch in Fehlerpfaden greift
3. Safari-Testvorbereitung gehaertet, damit die lokale Fixture den Fokus robust in der Textarea haelt

### Nachweis

Der reale Blocked-Stable-Run erzeugte wieder eine neue Hotkey-Response:

- Runtime: `build/pushwrite-product/runtime-002h-blocked-recheck`
- Response-ID: `D09F27FD-C1A0-4489-9108-9D806BC3563B`
- Flow: `triggered -> inserting -> blocked`
- `frontmostBundleAfterTrigger = com.apple.TextEdit`
- keine stehende `PushWrite.app`-Instanz nach Run-Ende

Damit ist die Restoffenheit aus 002G fuer die reine Hotkey-Validator-Ausloesung geschlossen.

## 2. Runtime-/State-Haertung

### Beobachtung

Vor der Haertung konnten Runtime-Artefakte nach beendetem Lauf in inkonsistentem Zustand verbleiben:

- `product-state.json` enthielt teils `running=true`
- `lastResponseStatus` stand bereits auf `stopped`
- der zugehoerige PID war nicht mehr aktiv

### Umsetzung

Die Runtime-Konsistenz wurde ohne Scope-Erweiterung im bestehenden Kontrollpfad gehaertet:

- `scripts/control_pushwrite_product.swift status` normalisiert stale States, wenn `running=true`, aber der PID tot ist
- `stop` wartet auf das Prozessende und liest den State anschliessend erneut ein
- dadurch wird `product-state.json` im regulaeren Bedienpfad auf einen koharenten Endzustand gebracht

### Nachweis

Finale Status-Abfragen nach den 002H-Laeufen:

- `runtime-002h-blocked-recheck/product-state.json`:
  - `running=false`
  - `lastResponseStatus=stopped`
- `runtime-002h-stable-success-rerun/product-state.json`:
  - `running=false`
  - `lastResponseStatus=stopped`
- `runtime-002h-safari-final/product-state.json`:
  - `running=false`
  - `lastResponseStatus=stopped`

Zusatzbeobachtung:

- nach dem finalen 002H-Lauf blieb keine `PushWrite.app`-Instanz mehr aktiv

## 3. Echter Stable-Success-Nachweis in TextEdit

### Lauf

- Runtime: `build/pushwrite-product/runtime-002h-stable-success-rerun`
- Summary: `build/pushwrite-product/runtime-002h-stable-success-rerun/summary.json`
- erwarteter Text: `PushWrite 002H observed stable success.`

### Ergebnis

- Produktflow: `status=succeeded`
- Flow-Events: `triggered -> inserting -> done`
- Fokus bei Receipt/Before/After blieb auf `com.apple.TextEdit`
- `productFrontmost*` blieb in allen drei Feldern `false`
- `observedTargetValueMatches=true`

### Schluesselfeld

`targetValue = "PushWrite 002H observed stable success."`

Damit ist der TextEdit-Nachweis fuer den Stable-Bundle-Pfad echt gruen im strikten Success-Kriterium.

## 4. Echter Stable-Success-Nachweis in Safari

### Lauf

- Runtime: `build/pushwrite-product/runtime-002h-safari-final`
- Summary: `build/pushwrite-product/runtime-002h-safari-final/summary.json`
- erwarteter Text: `PushWrite 002H observed stable success.`

### Ergebnis

- Produktflow: `status=succeeded`
- Flow-Events: `triggered -> inserting -> done`
- Fokus bei Receipt/Before/After blieb auf `com.apple.Safari`
- der fokussierte AX-Rollenpfad lag im Erfolgsrun auf `AXTextArea`
- `productFrontmost*` blieb in allen drei Feldern `false`
- `observedTargetValueMatches=true`

### Schluesselfeld

`targetValue = "PushWrite 002H observed stable success."`

Damit ist auch der Safari-Stable-Nachweis im strikten Success-Kriterium erbracht.

## 5. Offene Punkte und Randfaelle

- Die State-Normalisierung liegt aktuell im Control-Pfad. Wenn andere Werkzeuge das rohe `product-state.json` direkt lesen, ohne ueber `status` oder `stop` zu gehen, kann ein stale Zustand bis zur naechsten Normalisierung sichtbar bleiben.
- Die Safari-Haertung betrifft bewusst nur die lokale Testfixture. Sie beweist den MVP-Zielkontext `Safari textarea`, nicht beliebige Webanwendungen.
- Mikrofonaufnahme, Audio-Pufferung und `whisper.cpp` bleiben weiterhin unvalidiert.

## 6. MVP-Einordnung

### Bewertung

**Stabil genug fuer die Mikrofonstufe**

### Begruendung

- der reale Stable-Hotkey-Pfad erzeugt wieder neue Responses
- der kontrollierte Runtime-State endet konsistent
- TextEdit und Safari sind mit beobachtetem Zielwert-Match nachgewiesen
- false-success bleibt ausgeschlossen

Die verbleibenden Restpunkte sind klein und liegen nicht mehr im Kernpfad `Hotkey -> Flow -> Insert -> Beobachtung`.

## 7. Konkreter Folgeauftrag

**002I: Mikrofon-Start/Stop auf den gehaerteten Stable-Hotkey-Kern schneiden**

Kleiner Folgeauftrag:

- echte Mikrofonaufnahme zwischen Hotkey-Down und Hotkey-Up in denselben Stable-Produktpfad integrieren
- Runtime-State um klaren Aufnahmezustand erweitern (`idle`, `recording`, `transcribing`, `done` oder eng aequivalent)
- blocked/no-mic/no-permission-Faelle im selben Validatorstil dokumentieren
- noch ohne `whisper.cpp` oder Modellintegration, nur Aufnahme-Start/Stop und Artefaktfluss
