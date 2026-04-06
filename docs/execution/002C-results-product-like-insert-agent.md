# 002C Results: Product-Like Paste Insert Agent

## Ziel und Scope

Dieser Schritt ueberfuehrt den in 002B validierten Paste-Pfad in eine kleine, produktnaehere Agentenform fuer PushWrite v0.1.0:

1. langlebiger `LSUIElement`-Hintergrund-Agent statt Einmal-Harness
2. expliziter Accessibility-Preflight vor jedem Insert
3. kontrollierter Trigger ueber Request/Response-Dateien im Runtime-Verzeichnis
4. derselbe Insert-Pfad wie in 002B:
   - Plain-Text ins General Pasteboard
   - synthetisches `Cmd+V`
   - optionales Clipboard-Restore

Nicht umgesetzt wurden Hotkey, Audio, Transkription, breite UI oder alternative Injektionspfade.

## Erstellte Artefakte

- `app/macos/PushWriteInsertAgent/Info.plist`
- `app/macos/PushWriteInsertAgent/main.swift`
- `scripts/build_pushwrite_insert_agent.sh`
- `scripts/control_pushwrite_insert_agent.swift`
- `scripts/control_pushwrite_insert_agent.sh`
- `scripts/run_pushwrite_insert_agent_validation.swift`
- `scripts/run_pushwrite_insert_agent_validation.sh`
- `docs/execution/002C-results-product-like-insert-agent.json`
- dieses Ergebnisdokument

## Agentenansatz

### Form

- native macOS-Agent-App mit `LSUIElement`
- keine sichtbare Haupt-UI
- Activation Policy `.prohibited`
- langlebiger Hintergrundprozess mit Runtime-Spool

### Trigger- und Ergebnisprotokoll

Der Agent verwendet ein kleines lokales Runtime-Verzeichnis:

- `agent-state.json`
- `requests/<id>.json`
- `responses/<id>.json`
- `logs/events.jsonl`

Der produktnahe Triggerpfad ist bewusst klein:

1. Agent starten
2. Request-Datei schreiben
3. Agent pollt den Request-Spool
4. Agent fuehrt Preflight oder Insert aus
5. Response-Datei und Event-Log werden geschrieben

### Praktischer Startpfad

Fuer die aktuelle Repo-Stufe war der direkte Start ueber `open -a ... --args ...` der reproduzierbare Pfad:

```bash
open -a /tmp/pushwrite-insert-agent-build/PushWriteInsertAgent.app --args --runtime-dir /tmp/pushwrite-insert-agent-validation
```

Danach koennen Requests ueber das Control-Skript geschickt werden:

```bash
bash scripts/control_pushwrite_insert_agent.sh preflight --runtime-dir /tmp/pushwrite-insert-agent-validation
bash scripts/control_pushwrite_insert_agent.sh insert --runtime-dir /tmp/pushwrite-insert-agent-validation --text "PushWrite test"
```

## Accessibility-Preflight

### Umsetzung

- der Agent prueft `AXIsProcessTrustedWithOptions` explizit
- Preflight kann ohne Prompt oder mit Prompt ausgefuehrt werden
- Insert laeuft nur weiter, wenn `accessibilityTrusted=true`
- bei fehlender Freigabe wird kein Pasteboard-Write und kein synthetisches `Cmd+V` ausgefuehrt

### Beobachtet

- der neue Bundle-Pfad `ch.baumanncreative.pushwrite.InsertAgent` war in dieser Umgebung nicht fuer Accessibility freigegeben
- Preflight ohne Prompt lieferte konsistent:
  - `status=blocked`
  - `accessibilityTrusted=false`
  - `syntheticPastePosted=false`
- Preflight mit Prompt blieb ebenfalls `blocked`, solange die Freigabe nicht manuell gesetzt wurde

### Produktnahe Wirkung

- fehlende Accessibility blockiert den Insert-Pfad sauber vor dem ersten Paste
- der Blockadezustand ist ueber `agent-state.json` und die jeweilige Response-Datei nachvollziehbar

## Insert-Verhalten

### Implementiert

- Plain-Text ins General Pasteboard
- konfigurierbares `Cmd+V`
- optionales Restore des urspruenglichen Clipboards
- Fokus-Snapshots bei Request-Eingang, direkt vor Paste und direkt nach Paste
- Minimal-Haertung gegen fruehes Lesen von Request-Dateien:
  - mehrfache Retry-Leseversuche bei JSON-Decode-Fehlern

### Beobachtet

#### 1. Blocked Insert auf neuer App-Identitaet

- ein Insert-Request mit fehlender Accessibility lieferte:
  - `status=blocked`
  - `syntheticPastePosted=false`
  - `clipboardRestored=false`
- der Agent wurde dabei nicht frontmost:
  - `agentFrontmostAtReceipt=false`
  - `agentFrontmostBeforePaste=false`
  - `agentFrontmostAfterPaste=false`

#### 2. Erfolgreicher Insert auf neuer Agentenform

Nicht beobachtet in dieser Sitzung.

Begruendung:

- die neue Agent-App war noch nicht fuer Accessibility freigegeben
- deshalb wurde der erfolgreiche TextEdit-/Safari-Insert auf genau diesem neuen Bundle nicht erneut durchlaufen

### Saubere Trennung zwischen Beobachtung und Ableitung

Beobachtet:

- langlebiger Agent-Start
- expliziter Blocked-Preflight
- Blocked-Insert ohne Fokusuebernahme
- Runtime-Request/Response funktioniert

Ableitung aus 002B plus identischer Insert-Logik:

- nach gesetzter Accessibility-Freigabe ist derselbe Pasteboard-plus-`Cmd+V`-Pfad erwartbar weiter tragfaehig
- diese Ableitung ist stark, aber fuer das neue Bundle in 002C noch nicht erneut erfolgreich gemessen

## Vergleich zum 002B-Harness

### Gegenueber 002B neu

- nicht mehr pro Run eine neue Agent-App-Instanz fuer einen Einzeltest
- stattdessen langlebiger Hintergrund-Agent mit Runtime-Spool
- eigener produktnaher Blockade- und Ergebnispfad
- expliziter Zustand `blocked` statt bloss Harness-Fehler

### Gegenueber 002B unveraendert

- Insert-Kernpfad bleibt gleich
- Fokusneutralitaet bleibt ein harter Anspruch
- Clipboard-Restore bleibt Teil des Pfads

## Fokusbeobachtungen

- im beobachteten Blocked-Pfad wurde der Agent nicht frontmost
- der Agent aktiviert sich nicht selbst
- das spricht dafuer, dass die produktnahe Agentenform den Fokus auch im Fehlerfall nicht unnoetig uebernimmt

Der erfolgreiche Fokusverlauf im Insert-Success-Fall ist fuer die neue Bundle-Identitaet noch offen, bis Accessibility gesetzt und die Regression erneut ausgefuehrt wurde.

## Minimale Resthaertung

Fuer v0.1.0 fehlt noch die kleinste noetige Haertung in drei Punkten:

1. stabiler Startpfad fuer die konkrete App-Datei
2. klarer First-Run-/Blocked-Flow fuer Accessibility
3. erneute Success-Regression auf derselben neuen App-Datei in:
   - TextEdit
   - Safari-Textarea
   - Clipboard-Restore

Sekundaer sichtbar geworden:

- file-basierter Request-Spool braucht Retry beim Einlesen, damit Requests nicht zu frueh konsumiert werden

## MVP-Einordnung

**Tragfaehig, aber mit klarer Resthaertung.**

Begruendung:

- der validierte Insert-Pfad ist jetzt in eine produktnaehere, langlebige Agentenform ueberfuehrt
- Accessibility-Blockaden werden explizit und reproduzierbar behandelt
- der Agent bleibt im beobachteten Blocked-Fall fokusneutral
- es gibt einen kleinen kontrollierten Trigger- und Ergebnisweg

Noch nicht ausreichend fuer "produktnah tragfaehig" ohne Zusatz:

- die neue Agent-App-Identitaet wurde in dieser Sitzung noch nicht erfolgreich fuer Accessibility freigegeben
- damit fehlt noch der erneute Success-Nachweis des neuen Bundles in den Pflichtkontexten

## Konkrete Folgeempfehlung

### Folgeauftrag 002D

Schneide einen kleinen Integrationsauftrag fuer den echten PushWrite-Produktfluss mit genau diesem Scope:

1. stabilen Agent-Start fuer die konkrete Produkt-App-Datei festlegen
2. minimalen Accessibility-Blocked-Flow fuer First Run implementieren
3. einen internen Produkt-Trigger `insertTranscription(text:)` an den Agenten anbinden
4. danach dieselbe Success-Regression fuer TextEdit, Safari-Textarea und Clipboard-Restore auf genau dieser Produkt-App erneut ausfuehren

## Offene Punkte

- der erfolgreiche Insert-Success-Lauf fuer das neue Agent-Bundle steht noch aus
- unklar bleibt noch, wie stabil die Accessibility-Freigabe ueber Rebuilds derselben Produkt-App-Datei hinweg bleibt
- nicht validiert wurden weiterhin Terminale, geschuetzte Felder, Canvas-Editoren oder Remote-Sessions
