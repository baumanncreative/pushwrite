# 002N Ergebnisse: Robustheit der bestehenden Textinjektion in typischen macOS-App-Kontexten

## 1. Kurze Zusammenfassung

Der bestehende PushWrite-Insert-Pfad wurde fuer die Pflichtkontexte `TextEdit` und `Safari textarea` erneut in der realen lokalen macOS-Umgebung beobachtet. In beiden Pflichtkontexten ist der Produktpfad als funktional nachgewiesen. Ein zusaetzlich beobachtetes Problem lag nicht im Insert-Pfad selbst, sondern im aktuellen Launch-/Validator-Harness: der Hotkey-Validator konnte das Produktbundle am 2026-04-18 ueber seinen `NSWorkspace.openApplication(...)`-Startpfad nicht belastbar starten.

Fuer die Frage von 002N bedeutet das:

- der bestehende Insert-Pfad braucht auf Basis dieser Beobachtungen keinen technischen Nachschnitt
- die relevante Restoffenheit liegt aktuell in der Test-/Launch-Methode, nicht in der Textinjektion selbst
- eine Drittanbieter-App wurde bewusst nicht hinzugefuegt, um diesen Harness-Befund nicht mit einer zusaetzlichen GUI-Automationsquelle zu vermischen

## 2. Gepruefte Zielkontexte

### Pflichtkontexte

1. `TextEdit`
2. `Safari textarea` auf der lokalen Fixture `tests/integration/browser-textarea-fixture.html`

### Nicht aufgenommen

- keine Drittanbieter-App

Begruendung:

- der bestehende Befund aus TextEdit und Safari reicht fuer die Entscheidungsfrage bereits aus
- zusaetzlich wurde waehrend 002N ein aktuelles Launch-/Validator-Harness-Problem beobachtet
- ein dritter GUI-Kontext haette deshalb das Risiko erhoeht, Produktpfad und Harness-Drift zu vermischen

## 3. Durchgefuehrte Beobachtungen

### 3.1 Separater Harness-Befund vor den Pflichtlaeufen

Am 2026-04-18 wurde zuerst ein enger Re-Run ueber den bestehenden Hotkey-Validator gestartet:

```bash
./scripts/run_pushwrite_hotkey_validation.sh \
  --textedit-runs 3 \
  --safari-runs 3 \
  --product-output-dir build/pushwrite-product \
  --success-runtime-dir build/pushwrite-product/runtime-002n-success \
  --blocked-runtime-dir build/pushwrite-product/runtime-002n-blocked \
  --results-file build/pushwrite-product/runtime-002n-summary.json
```

Beobachtung:

- Abbruch vor den Kontextlaeufen mit
  `Product launch failed: Timed out: Condition not met within 20.0 seconds.`

Gegenprobe:

- direkter Produktstart ueber
  `./scripts/control_pushwrite_product.sh launch`
  funktionierte sofort
- Artefakt:
  `build/pushwrite-product/runtime-002n-launch-check/product-state.json`

Einordnung:

- Kategorie: `E. Test-Harness-/Automation-Problem`
- der Blocker liegt im Validator-Launchpfad, nicht in einer beobachteten Fehlfunktion der Textinjektion
- fuer die eigentliche 002N-Insertbewertung wurde deshalb bewusst auf den produktnahen Insert-Validator mit vorab direkt gestarteter App gewechselt

### 3.2 Produktnaher Pflichtlauf fuer Insert-Beobachtung

Produktstart:

```bash
./scripts/control_pushwrite_product.sh launch \
  --product-app build/pushwrite-product/PushWrite.app \
  --runtime-dir build/pushwrite-product/runtime-002n-product-validation \
  --timeout-ms 30000
```

Insert-Validierung:

```bash
./scripts/run_pushwrite_product_validation.sh \
  --skip-build \
  --skip-launch \
  --product-app-path build/pushwrite-product/PushWrite.app \
  --product-runtime-dir build/pushwrite-product/runtime-002n-product-validation \
  --textedit-runs 3 \
  --safari-runs 3 \
  --payload 'PushWrite 002N insert robustness check.' \
  --results-file build/pushwrite-product/runtime-002n-product-validation-summary.json
```

Wichtige Hauptbeobachtung:

- `Safari`: `3/3` erfolgreich
- `TextEdit`: zuerst `2/3` erfolgreich
- der einzelne `TextEdit`-Ausreisser hatte:
  - `status=succeeded`
  - `syntheticPastePosted=true`
  - `focusAtReceipt = com.openai.codex`
  - `focusBeforePaste = com.openai.codex`
  - `focusAfterPaste = com.openai.codex`
  - beobachteter Zielwert blieb leer

Diese Kombination spricht gegen ein isoliertes Produktproblem im Insert-Kern und fuer Fokusverlust im Testkanal unmittelbar vor bzw. waehrend des Requests.

### 3.3 Enger TextEdit-Nachlauf zur Trennung Produktpfad vs. Harness

Direkt danach wurde ein enger TextEdit-Nachlauf ohne Safari ausgefuehrt:

```bash
./scripts/control_pushwrite_product.sh launch \
  --product-app build/pushwrite-product/PushWrite.app \
  --runtime-dir build/pushwrite-product/runtime-002n-textedit-rerun \
  --timeout-ms 30000
```

```bash
./scripts/run_pushwrite_product_validation.sh \
  --skip-build \
  --skip-launch \
  --product-app-path build/pushwrite-product/PushWrite.app \
  --product-runtime-dir build/pushwrite-product/runtime-002n-textedit-rerun \
  --textedit-runs 5 \
  --safari-runs 0 \
  --payload 'PushWrite 002N textedit rerun.' \
  --results-file build/pushwrite-product/runtime-002n-textedit-rerun-summary.json
```

Beobachtung:

- `TextEdit`: `5/5` erfolgreich
- `productStatusSucceeded=5/5`
- `observedTargetMatch=5/5`
- Fokus bei Receipt/Before/After in allen 5 Runs auf `com.apple.TextEdit`
- `productFrontmost* = 0` in allen 5 Runs

Dieser Nachlauf stuetzt die Zuordnung des ersten Ausreissers als Harness-/Fokusproblem statt Produktfehler.

## 4. Beobachtungen pro Zielkontext

### 4.1 TextEdit

#### Frage 1: Laesst sich der bestehende Insert-Pfad sinnvoll pruefen?

Ja.

- TextEdit ist mit der bestehenden lokalen Vorbereitung und Ruecklese belastbar pruefbar.
- Die Ruecklese ueber den Dokumentinhalt ist fuer diesen Kontext aussagekraeftig.

#### Frage 2: Funktioniert der bestehende Insert-Pfad dort beobachtbar?

Ja.

Belastbare Beobachtung:

- enger Nachlauf `5/5` erfolgreich
- Clipboard-Restore-Proben `plain` und `rich` ebenfalls erfolgreich
- Produkt blieb nicht frontmost

#### Frage 3: Falls nicht: Produktpfad oder Harness?

Ein einzelner frueher Ausreisser im ersten Mischlauf war plausibel ein Harness-/Fokusproblem.

Indizien:

- Fokus bei Receipt/Before/After lag komplett auf `Codex`
- kein Symptom nur innerhalb von TextEdit
- unmittelbar anschliessender TextEdit-Nachlauf war `5/5` gruen

#### Bewertung

- Primaere Kategorie: `A. Produktpfad funktioniert`
- Zusatzbeobachtung: ein separater Ausreisser im Mischlauf war `E. Test-Harness-/Automation-Problem`

#### Bedeutung fuer 002N

- Fuer TextEdit reicht Dokumentation.
- Kein technischer Nachschnitt am Insert-Pfad begruendbar.

### 4.2 Safari-Textarea

#### Frage 1: Laesst sich der bestehende Insert-Pfad sinnvoll pruefen?

Ja, innerhalb des eng definierten Kontexts `Safari textarea` auf der lokalen Fixture.

#### Frage 2: Funktioniert der bestehende Insert-Pfad dort beobachtbar?

Ja.

Belastbare Beobachtung:

- produktnaher Pflichtlauf `3/3` erfolgreich
- `observedTargetValueMatches=3/3`
- Fokus bei Receipt/Before/After durchgaengig auf `com.apple.Safari`
- `focusAfterPaste.role = AXTextArea`
- Produkt blieb in allen Runs fokusneutral

#### Frage 3: Falls nicht: Produktpfad oder Harness?

Im aktuellen 002N-Lauf wurde kein Safari-Fehlschlag beobachtet.

Wichtige Kontexteinschraenkung:

- die Aussage gilt fuer die lokale `Safari textarea`-Fixture
- daraus folgt bewusst keine Aussage fuer beliebige Web-Apps oder komplexe ContentEditable-Kontexte

#### Bewertung

- Kategorie: `A. Produktpfad funktioniert`

#### Bedeutung fuer 002N

- Fuer den expliziten Pflichtkontext `Safari textarea` reicht Dokumentation.
- Kein technischer Nachschnitt am Insert-Pfad begruendbar.

## 5. Klare Trennung Produktpfad vs. Harness-/Automation-Problem

### Produktpfad

Nachgewiesen funktional in:

- `TextEdit`
- `Safari textarea`

Beobachtbare Indizien:

- reale Einfuegung des Payloads im Zielkontext
- `insertRoute = pasteboardCommandV`
- `insertSource = transcription`
- `syntheticPastePosted = true`
- Produkt bleibt nicht frontmost

### Harness-/Automation-Probleme

Beobachtet in 002N:

1. Hotkey-Validator-Launch:
   - Start ueber den bestehenden Validator schlug vor dem eigentlichen Insert mit Timeout fehl
   - derselbe Produktstand liess sich direkt starten
   - damit keine belastbare Produktaussage aus diesem Fehlschlag

2. Einzelner TextEdit-Ausreisser im ersten Mischlauf:
   - Fokus lag komplett auf `Codex`
   - der Zielkontext war beim Request nicht stabil TextEdit
   - damit ebenfalls keine belastbare Produktaussage gegen den Insert-Pfad

## Gesamtbewertung

Im enger geschnittenen 002N-Baseline-Scope ist der bestehende PushWrite-Insert-Pfad fuer die Pflichtkontexte TextEdit und Safari-Textarea beobachtbar tragfaehig.

Der aktuell verbleibende rote Befund ist in diesem Lauf dem Launch-/Validator-/Automation-Harness zuzuordnen, nicht belastbar dem bestehenden Insert-Pfad.

Auf Basis dieses Baseline-Laufs ist deshalb derzeit **kein technischer Nachschnitt am bestehenden Insert-Pfad begruendbar**.

Wichtig:
Diese Aussage gilt fuer den bewusst engen 002N-Pruefumfang. Die breitere Frage der Insert-Robustheit ueber weitere Zielanwendungen hinweg ist damit **nicht vollstaendig erledigt**, sondern durch diesen Lauf nur enger eingegrenzt.

## 7. Naechster Schritt

Empfohlener naechster Schritt:

- 002N als Insert-Befund abschliessen
- die Produktdokumentation um die jetzt sauber getrennten Aussagen ergaenzen:
  - `TextEdit` ist als native Baseline funktional bestaetigt
  - `Safari textarea` ist als Web-Baseline funktional bestaetigt
  - der aktuelle Restpunkt liegt im Validator-/Launch-Harness und ist nicht als Insert-Defekt zu lesen

Kein naechster Schritt aus 002N:

- kein zweiter Insert-Weg
- keine Accessibility-Erweiterung
- keine neue GUI-Testarchitektur

## 8. Verwendete Artefakte

- `build/pushwrite-product/runtime-002n-launch-check/product-state.json`
- `build/pushwrite-product/runtime-002n-product-validation-summary.json`
- `build/pushwrite-product/runtime-002n-product-validation/logs/events.jsonl`
- `build/pushwrite-product/runtime-002n-textedit-rerun-summary.json`
