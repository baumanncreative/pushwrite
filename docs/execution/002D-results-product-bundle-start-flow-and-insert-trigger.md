# 002D Results: Product Bundle Start Flow, Accessibility Blocked Flow, and `insertTranscription(text:)`

## Ziel und Scope

002D bindet den validierten paste-basierten Insert-Pfad erstmals an ein echtes `PushWrite.app`-Bundle fuer den macOS-MVP von v0.1.0.

Umgesetzt wurden nur die fuer diesen Schnitt noetigen Produktteile:

1. fixes Produktbundle `PushWrite.app`
2. reproduzierbarer Entwicklungs- und Validierungsstart auf genau diesem Bundle
3. minimaler First-Run-/Blocked-Flow fuer fehlende Accessibility
4. interner Produkt-Trigger `insertTranscription(text:)`
5. erneute Bundle-Regression fuer TextEdit, Safari-Textarea und Clipboard-Restore

Nicht umgesetzt wurden Hotkey, Audio, Transkription selbst, breite UI oder alternative Injektionspfade.

## Geaenderte und erstellte Artefakte

- `app/macos/PushWrite/Info.plist`
- `app/macos/PushWrite/main.swift`
- `scripts/build_pushwrite_product.sh`
- `scripts/control_pushwrite_product.swift`
- `scripts/control_pushwrite_product.sh`
- `scripts/run_pushwrite_product_validation.swift`
- `scripts/run_pushwrite_product_validation.sh`
- `docs/execution/002D-results-product-bundle-start-flow-and-insert-trigger.json`
- dieses Ergebnisdokument

## Stabiler Produkt-Startpfad

### Festgelegter Bundle-Pfad

Fester Build-Ausgabepfad fuer Entwicklung und Revalidierung:

`/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`

Wichtige Stabilitaetsentscheidung:

- Bundle Identifier: `ch.baumanncreative.pushwrite`
- fixer absoluter Bundle-Pfad im Repo
- fixer Runtime-Pfad pro Validierungslauf

Damit wandern fuer denselben Entwicklungsschritt weder Bundle-ID noch Bundle-Datei.

### Beobachteter Startpfad

Der Launch-Services-Pfad ueber `open ... PushWrite.app` war in dieser Umgebung fuer das ad-hoc gebaute Bundle nicht tragfaehig:

- beobachtet: `kLSNoExecutableErr`

Deshalb wurde fuer 002D der stabile Entwicklungsstart auf den Bundle-internen Executable festgelegt:

```bash
/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app/Contents/MacOS/PushWrite \
  --runtime-dir /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-final6
```

Einordnung:

- das Bundle selbst bleibt fix und produktnah
- gestartet wird bewusst der Executable innerhalb genau dieses Bundles
- fuer wiederholte lokale Validierung ist das in dieser Repo-Stufe stabiler als `open`

### TCC-/Freigabe-Folgerung

Beobachtet:

- das Produktbundle `ch.baumanncreative.pushwrite` war in dieser Umgebung bereits fuer Accessibility freigegeben
- die State-Datei des Produktbundles meldete `accessibilityTrusted=true`

Ableitung:

- fixer Bundle-Pfad plus fixe Bundle-ID reduzieren unnötige Freigabewechsel fuer denselben Entwicklungsschnitt
- offen bleibt weiterhin, wie stabil ad-hoc-Rebuilds derselben `.app` ueber laengere Zeit von macOS-TCC behandelt werden

## Minimaler First-Run-/Blocked-Flow

### Implementiert

Im Produktbundle wurde ein kleiner, nicht-blockierender Blocked-Flow eingebaut:

- Accessibility-Check beim Produktstart
- Accessibility-Check vor `preflight`, `insert` und `insertTranscription`
- klarer Produktzustand in `product-state.json`
- kleine Blocked-Window mit:
  - Titel fuer den Blockadegrund
  - kurzer Erklaerung, was fehlt
  - `Open System Settings`
  - `Not Now`
- kein falscher Success:
  - `status=blocked`
  - `syntheticPastePosted=false`
  - `clipboardRestored=false`

### Beobachteter Blocked-Run

Da das echte Bundle auf diesem Rechner bereits trusted war, wurde der Blocked-Pfad auf **demselben Bundle** ueber eine interne Debug-Override reproduziert:

`PUSHWRITE_FORCE_ACCESSIBILITY_BLOCKED=1`

Diese Override wurde nur fuer die 002D-Validierung benutzt, um **kein** TCC-Reset auf Systemebene ausloesen zu muessen.

Beobachtet im Blocked-Run:

- `preflight` lieferte `status=blocked`
- `insertTranscription` lieferte `status=blocked`
- `blockedReason` war konsistent:
  - `Accessibility access is required before PushWrite can insert text with synthetic Cmd+V.`
- `syntheticPastePosted=false`
- `productFrontmostAtReceipt=false`
- `productFrontmostBeforePaste=false`
- `productFrontmostAfterPaste=false`

Bewertung:

- der Blocked-Flow ist minimal, ehrlich und technisch sauber
- der Produktzustand wird als Blockade markiert
- der Produktprozess taeuscht keinen Erfolg vor

## `insertTranscription(text:)`

### Produktanbindung

Im Produktbundle gibt es jetzt zwei kleine Insert-Einstiege:

- direkter Request-Pfad `insert`
- interner Produktpfad `insertTranscription`

Beide laufen absichtlich in denselben Insert-Kern:

- Plain-Text ins General Pasteboard
- synthetisches `Cmd+V`
- optionales Clipboard-Restore

### Technische Form

`insertTranscription(text:)` ruft intern denselben `performInsert(...)`-Pfad auf wie der direkte Insert-Request.

Die Response macht diese Anbindung sichtbar:

- `kind=insertTranscription`
- `insertSource=transcription`
- `insertRoute=pasteboardCommandV`

Damit ist der spaetere Hotkey-/Audio-/Transkriptionsschnitt klar:

- Transkriptionsresultat an `insertTranscription(text:)`
- kein zweiter Insert-Mechanismus noetig

## Success-Regression auf dem Produktbundle

### Gruener dokumentierter Bundle-Lauf

Dokumentierter Green-Run aus
`docs/execution/002D-results-product-bundle-start-flow-and-insert-trigger.json`:

- Produktbundle: `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
- Runtime: `/Users/michel/Code/pushwrite/build/pushwrite-product/runtime-final6`
- Triggerpfad: `insertTranscription`

Ergebnisse:

- TextEdit: `5/5` erfolgreich
- Safari-Textarea: `5/5` erfolgreich
- Clipboard-Restore Plain Text: erfolgreich
- Clipboard-Restore Rich Clipboard: erfolgreich

Fokusbeobachtung im Green-Run:

- Produkt nie frontmost in TextEdit
- Produkt nie frontmost in Safari
- Ziel-App blieb bei Receipt, Before-Paste und After-Paste korrekt

### Zusaetzlich beobachtete Serienlast

Es wurde zusaetzlich ein laengerer `20/20`-Regressionslauf versucht.

Beobachtet:

- TextEdit-Inserts liefen im Produktbundle weiter sauber
- der Safari-Validierungspfad brach im Testharness wegen Fixture-Re-Navigation mit Timeout ab

Wichtig:

- das ist aktuell ein Harness-/Revalidierungsproblem
- kein beobachteter Produktfokusfehler im Insert-Kern
- fuer 002D bleibt das als Resthaertung sichtbar

## Beobachtungen und Bewertung

### Beobachtet

- das neue Produktbundle `ch.baumanncreative.pushwrite` startet und schreibt seinen Produktzustand
- der minimale Accessibility-Blocked-Flow ist im Bundle implementiert
- `insertTranscription(text:)` haengt sauber am paste-basierten Insert-Pfad
- der Green-Run auf dem echten Produktbundle ist fuer TextEdit, Safari und Clipboard-Restore bestaetigt
- der Produktprozess blieb in den erfolgreichen Runs fokusneutral

### Nicht vollstaendig gehaertet

- der lokale Launch-Services-Start via `open PushWrite.app` war fuer das ad-hoc Bundle nicht stabil
- der Safari-Harness ist fuer laengere Serienlast (`20/20`) noch nicht robust genug
- der echte untrusted-Zustand des Bundles wurde in dieser Sitzung nicht ueber TCC selbst, sondern ueber die interne Debug-Override reproduziert

## MVP-Einordnung

**Tragfaehig mit kleiner verbleibender Resthaertung.**

Begruendung:

- der Insert-Pfad ist jetzt an ein echtes `PushWrite.app`-Bundle gebunden
- der Produkt-Blocked-Flow ist minimal und ehrlich
- `insertTranscription(text:)` ist als spaeterer Produktanschluss sauber vorbereitet
- der Green-Run auf dem Produktbundle ist fuer die Pflichtkontexte vorhanden

Noch nicht ganz auf "produktnah tragfaehig" ohne Zusatz:

- der finale lokale Startpfad ist in dieser Stufe der Bundle-Executable, nicht Launch Services
- die lange Safari-Serienrevalidierung braucht noch eine kleine Harness-Haertung

## Konkreter Folgeauftrag

### Folgeauftrag 002E

Schneide als naechsten echten Integrationsschritt einen kleinen Auftrag mit genau diesem Scope:

1. `PushWrite.app` um einen minimalen Hotkey-/Flow-Coordinator erweitern
2. ein erstes in-memory `transcription text -> insertTranscription(text:)`-Wiring ohne echtes Audio implementieren
3. den Entwicklungsstart weiter haerten:
   - klären, ob `open PushWrite.app` fuer das Bundle repariert werden kann
   - oder den direkten Executable-Start bewusst als Dev-Startpfad festschreiben
4. die Safari-Serienrevalidierung fuer laengere Laeufe stabilisieren

## Offene Punkte

- wie Launch Services fuer das ad-hoc Bundle stabil eingebunden werden kann
- ob fuer echte Produkt-Blocked-Tests spaeter ein dedizierter Testmodus beibehalten werden soll oder ein kontrollierter TCC-Reset-Schritt benoetigt wird
- ob die Safari-Fixture fuer laengere Serienlaeufe besser ueber einen noch stabileren Resetpfad vorbereitet werden sollte
