# 002G Results: Stable Product Build, Signing, Trust Path, and Observed Success Criterion

## Kurze Zusammenfassung

002G schliesst zwei Teilziele fuer den macOS-MVP v0.1.0:

- der lokale Produktbuild ist jetzt als `candidate -> promote -> stable` Pfad festgelegt
- ein Validator-Run gilt jetzt nur noch dann als Success, wenn die Texteinfuegung im Zielkontext wirklich beobachtet wurde

Der Standardpfad fuer Validierung ist jetzt das stabile Bundle unter:

`/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`

Neue Builds gehen standardmaessig zuerst nach:

`/Users/michel/Code/pushwrite/build/pushwrite-product-candidate/PushWrite.app`

Die Validatoren sind auf `stable first` umgestellt und schreiben jetzt explizit aus:

- welches Success-Kriterium gilt
- wie oft der Produkt-Response `status=succeeded` meldete
- wie oft der Zielwert wirklich dem erwarteten Text entsprach

Damit ist false success auf JSON-Ebene nicht mehr verdeckt.

## Geaenderte und erstellte Artefakte

- `scripts/build_pushwrite_product.sh`
- `scripts/inspect_pushwrite_product_identity.sh`
- `scripts/promote_pushwrite_product_candidate.sh`
- `scripts/control_pushwrite_product.sh`
- `scripts/run_pushwrite_hotkey_validation.swift`
- `scripts/run_pushwrite_product_validation.swift`
- `docs/execution/002G-results-trusted-product-build-and-local-signing-path.json`
- dieses Ergebnisdokument

## Stabiler lokaler Build- und Bundle-Pfad

### Festgelegte Rollen

Candidate-Bundle:

`/Users/michel/Code/pushwrite/build/pushwrite-product-candidate/PushWrite.app`

Stable-Bundle:

`/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`

### Standardablaeufe

Candidate bauen:

```bash
'/Users/michel/Code/pushwrite/scripts/build_pushwrite_product.sh'
```

Stable explizit aus Candidate befuellen:

```bash
'/Users/michel/Code/pushwrite/scripts/promote_pushwrite_product_candidate.sh'
```

Stable starten:

```bash
'/Users/michel/Code/pushwrite/scripts/control_pushwrite_product.sh' launch \
  --product-app '/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app' \
  --runtime-dir '/Users/michel/Code/pushwrite/build/pushwrite-product/runtime-XYZ'
```

### Fixierte Regeln

- `build_pushwrite_product.sh` baut standardmaessig nicht mehr direkt in den Stable-Pfad
- ein direkter Build nach `build/pushwrite-product` wird bewusst mit Exit 64 abgelehnt
- Stable soll nur durch explizite Promotion ersetzt werden
- Validatoren bevorzugen das Stable-Bundle und bauen nur dann Candidate, wenn Stable fehlt oder ein expliziter Pfad uebergeben wird

### Zweck der Trennung

- TCC/Accessibility soll nicht bei jedem Entwicklungsbuild implizit am validierten Stable-Bundle haengen
- das fuer Validierung relevante Bundle bleibt ueber einen festen Pfad eindeutig
- neue Kandidaten koennen gebaut und inspiziert werden, ohne den Stable-Pfad sofort zu ueberschreiben

## Signing- und Bundle-Identitaetsanalyse

### Gesichert beobachtet

Stable und Candidate zeigen aktuell dieselbe Bundle-Identitaet:

- Bundle Identifier: `ch.baumanncreative.pushwrite`
- Signature: `adhoc`
- CDHash: `461a4ebceba89aa627aa82430d24695cae4f0def`
- Designated Requirement: `cdhash H"461a4ebceba89aa627aa82430d24695cae4f0def"`

Quellen:

- `build/pushwrite-product/bundle-identity.txt`
- `build/pushwrite-product-candidate/build-identity.txt`

Die beiden Mach-O-Executables sind aktuell byte-identisch:

- `shasum build/pushwrite-product/PushWrite.app/Contents/MacOS/PushWrite`
- `shasum build/pushwrite-product-candidate/PushWrite.app/Contents/MacOS/PushWrite`
- beide Hashes: `2764cd2a69f80ec7a2d97cdc5a78fc746dc2843f`

### Plausible Schlussfolgerung

- in der aktuellen Repo-Stufe ist die lokale Signatur ad-hoc
- die effektive Designated Requirement ist hier an den CDHash gebunden
- sobald ein Rebuild den CDHash aendert, ist Trust-Verlust fuer Accessibility stark plausibel

### Noch offen

- ob fuer die lokale Dev-Schiene eine stabilere Signing-Identitaet als ad-hoc eingefuehrt werden soll
- ob TCC in dieser konkreten Umgebung ausschliesslich ueber CDHash bindet oder weitere Identitaetsmerkmale mit auswertet

## Signing-, Rebuild- und Trust-Verhalten

## Gesichert beobachtet

1. Reales Stable-Bundle startet produktnah ueber den Control-Wrapper.

Beleg:

- `2026-04-11T10:05:41Z`
- `runtime-002g-real-blocked-rerun/product-state.json`
- `accessibilityTrusted = false`
- `hotKey.registered = true`
- `blockedReason = Accessibility access is required before PushWrite can insert text with synthetic Cmd+V.`

2. Reale Blocked-Hotkey-Events sind fuer das Stable-Bundle in den Runtime-Logs nachweisbar.

Beleg:

- `build/pushwrite-product/runtime-002g-real-blocked/logs/hotkey-responses.jsonl`
- `build/pushwrite-product/runtime-002g-real-blocked/logs/flow-events.jsonl`
- mehrfach beobachtet:
  - `status = blocked`
  - `syntheticPastePosted = false`
  - Flow: `triggered -> inserting -> blocked`

3. Ein Produkt-Response `status=succeeded` ist kein hinreichender Success-Beleg.

Beleg aus Session-Beobachtung vom `2026-04-07`:

- forced-trusted TextEdit-Lauf:
  - Produkt meldete `status = succeeded`
  - `syntheticPastePosted = true`
  - Flow: `triggered -> inserting -> done`
  - Validator-Beobachtung: `targetValue = ""`
  - Validator-Failure: `target-value-mismatch`
- forced-trusted Safari-Lauf:
  - Produkt meldete `status = succeeded`
  - `syntheticPastePosted = true`
  - Flow: `triggered -> inserting -> done`
  - Validator-Beobachtung: `targetValue = ""`
  - Validator-Failure: `target-value-mismatch`

Die zugehoerigen Runtime-Logs sind noch vorhanden:

- `build/pushwrite-product/runtime-002g-forced-trusted-textedit/logs/last-hotkey-response.json`
- `build/pushwrite-product/runtime-002g-forced-trusted-textedit/logs/flow-events.jsonl`
- `build/pushwrite-product/runtime-002g-forced-trusted-safari/logs/last-hotkey-response.json`
- `build/pushwrite-product/runtime-002g-forced-trusted-safari/logs/flow-events.jsonl`

Die damaligen temp-JSONs mit dem gemessenen `targetValue` sind in `/tmp` nicht mehr vorhanden. Die Session-Beobachtung selbst war aber eindeutig: Produktflow gruen, Zielkontext leer.

4. Ein Statusartefakt ist noch inkonsistent.

Beleg:

- `build/pushwrite-product/runtime-002g-product-preflight/product-state.json`
- dort steht weiterhin `running = true`
- gleichzeitig ist der zugehoerige Prozess nicht mehr aktiv und `lastResponseStatus = stopped`

5. Die heutigen Hotkey-Reruns vom `2026-04-11` zaehlen nicht als Success-Nachweis.

Beleg:

- Blocked-Rerun: `Blocked hotkey observation failed: Timed out: Condition not met within 10.0 seconds.`
- TextEdit-Rerun: `TextEdit hotkey series failed: Timed out: Condition not met within 10.0 seconds.`
- Safari-Rerun: `Safari hotkey series failed: Timed out: Condition not met within 20.0 seconds.`

Diese Runs wurden verworfen.

## Plausible Schlussfolgerung

- Stable darf fuer Trust-relevante Validierung nur ueber explizite Promotion ersetzt werden
- Candidate-Builds koennen lokal beliebig neu entstehen; Stable ist der Trust-Kandidat
- wenn Stable durch einen abweichenden Candidate ersetzt wird, muss Accessibility-Trust als potentiell neu zu vergebender Schritt behandelt werden
- die heutigen Hotkey-Timeouts sprechen eher fuer Drift im Validator-Ausloesungspfad als fuer einen gesicherten Produktregress, weil Produktstart, Bundle-Pfad und historische Hotkey-Logs weiterhin konsistent sind

## Noch offen

- warum der Hotkey-Validator am `2026-04-11` trotz laufender Einzelinstanz keinen neuen `last-hotkey-response.json` Eintrag erzeugte
- ob `System Events`-basierte Hotkey-Ausloesung aktuell selbst der fragile Teil ist
- ob die inkonsistente `product-state.json` nach Stop dieselbe Ursachenklasse betrifft oder getrennt ist

## Empfohlene lokale Strategie

Ab jetzt gilt fuer die lokale MVP-Schiene:

1. Neue Produktbuilds immer zuerst als Candidate bauen.
2. Candidate ueber `inspect_pushwrite_product_identity.sh` inspizieren.
3. Nur bewusst freigegebene Candidates nach Stable promoten.
4. Accessibility-Trust nur fuer das Stable-Bundle vergeben und daran validieren.
5. Nach jeder Promotion Trust-Status neu pruefen; bei geaenderter Bundle-Identitaet Re-Grant nicht als Fehler, sondern als kontrollierten Schritt behandeln.

Pragmatische Folge:

- Trust-Erhalt ist nur fuer unveraendertes Stable-Bundle erwartbar
- Trust-Verlust nach Promotion/Rebuild wird nicht mehr mit Produktlogik verwechselt

## Umstellung der Validatoren

### Stable-vs-Candidate

Beide Validatoren arbeiten jetzt mit derselben Regel:

- expliziter `--product-app-path` gewinnt
- sonst wird Stable bevorzugt
- nur wenn Stable fehlt und kein `--skip-build` gesetzt ist, wird Candidate gebaut bzw. verwendet

### Gehaertetes Success-Kriterium

Beide Validatoren schreiben jetzt explizit:

- `ValidationSummary.successCriteria`
- `ContextSummary.strictSuccessRule`
- `ContextSummary.productResponseSucceededCount`
- `ContextSummary.observedTargetValueMatchesCount`
- `ContextRunRecord.productResponseSucceeded`
- `ContextRunRecord.observedTargetValueMatches`

Damit gilt technisch:

- `successCount` ist jetzt strikt
- `status=succeeded` alleine reicht nicht
- eine fehlende beobachtete Texteinfuegung bleibt rot, auch wenn Produktflow und Runtime-Logs `done` zeigen

## Kleine produktnahe Revalidierung

### Gesichert verwertbar

1. Produktstart auf Stable-Bundle:

- Stable-Bundle startet ueber den fixierten Wrapper
- Hotkey wird registriert
- Blocked-Reason ist auf dem realen Bundle lesbar

2. Reale Blocked-Hotkey-Observation:

- Runtime-Logs unter `runtime-002g-real-blocked` zeigen echte Hotkey-Blocked-Ereignisse
- `syntheticPastePosted = false`
- kein verdeckter Success im Blocked-Fall

3. Historisch gesicherte false-success-Beobachtung:

- TextEdit und Safari konnten bereits belegen:
  - Produktflow `done`
  - Produktresponse `succeeded`
  - aber beobachteter Zielwert leer

### Nicht als Success gewertet

Die erneuten Hotkey-Runs vom `2026-04-11` wurden nicht gewertet, weil sie in Timeouts endeten und damit keinen belastbaren Nachweis fuer einen gruenden oder blockierten Lauf liefern.

## Verbleibende Resthaertung vor Mikrofonintegration

1. Hotkey-Validator-Ausloesung wieder deterministisch machen.

Ziel:

- ein einzelner Stable-Bundle-Run fuer TextEdit und Safari muss wieder reproduzierbar neue Hotkey-Responses erzeugen

2. `product-state.json` nach Stop haerten.

Ziel:

- `running=false` muss nach jedem Stop konsistent im Statusartefakt landen

3. Optional: lokales Dev-Signing stabilisieren.

Nur falls der Stable-Pfad laenger gehalten werden soll:

- ad-hoc durch eine bewusst feste lokale Signatur ersetzen
- andernfalls Re-Grant nach Promotion als normaler Maintenance-Schritt dokumentieren

## MVP-Einordnung

**Im Wesentlichen tragfaehig, aber mit kleiner Resthaertung.**

Begruendung:

- Stable-vs-Candidate ist sauber gesetzt
- Signing-/Trust-Verhalten ist fuer den MVP hinreichend eingegrenzt
- false success ist auf Validator-Ebene jetzt explizit ausgeschlossen
- offen ist noch die deterministische Hotkey-Ausloesung der heutigen Revalidierung, nicht die Build-/Trust-Strategie selbst

## Konkreter Folgeauftrag

**002H: Hotkey-Validator-Ausloesung und Statusartefakt final haerten**

Scope:

- deterministische Hotkey-Ausloesung fuer den Stable-Bundle-Validator wiederherstellen
- `product-state.json` nach Stop konsistent abschliessen
- genau einen realen Stable-Bundle-Lauf fuer TextEdit und einen fuer Safari erneut fahren
- die jetzt eingefuehrten `observedTargetValueMatches*` Felder dabei mit echten Gruen-Runs belegen
