# Auftrag 003B Final Mini-Follow-up: Realen macOS-Deny- und Previously-Denied-Mikrofonpfad verifizieren

## Ziel

Fuehre den kleinstmoeglichen abschliessenden QA-Follow-up fuer den bereits implementierten 003A-Mikrofon-Flow durch, um die noch offenen realen Mikrofon-TCC-Faelle `deny` und direkt danach `previously denied` auf demselben echten Bundle-Pfad zu verifizieren.

Der Auftrag dient nicht dazu, neue Produktlogik zu bauen.  
Er dient dazu, den letzten noch offenen Permission-Pfad fuer 003A unter realen Bedingungen nachzuziehen.

---

## Ausgangslage

003A ist implementiert.

003B und das anschliessende 003B-Follow-up haben bereits real bestaetigt:

- kein Mic-Prompt beim Launch des echten LaunchServices-Bundle-Pfads
- bundle-spezifische Accessibility ist fuer das aktuelle Produktbundle vorhanden
- `mic_not_determined_allow_real_rerun` ist real bestaetigt
- `mic_allowed_real_rerun` ist real bestaetigt

Offen geblieben sind nur noch:

- `mic_not_determined_deny_real_rerun`
- der daraus folgende `mic_previously_denied_real_rerun`
- optional weiterhin `mic_allowed_but_no_device_or_recorder_failed_real_rerun`, falls real herstellbar

Das aktuelle Ergebnis lautet deshalb weiterhin:

- 003A ist **teilweise real verifiziert**
- 003A ist **nicht voll real verifiziert**

---

## Zweck

Dieser Auftrag soll ausschliesslich die noch offene reale Deny-Kette schliessen:

1. echter `notDetermined -> Don’t Allow`
2. direkt danach ohne Reset der echte `previously denied`-Folgelauf

Optional darf am Ende noch kurz festgehalten werden, ob der Fall `allowed but no device / recorder failed` real weiter offen bleibt und deshalb als workstation-/hardwareabhaengig offen markiert wird.

Dieser Auftrag soll **nicht**:

- neue Produktlogik einbauen
- UI erweitern
- Insert- oder Gate-Logik aendern
- allgemeine TCC- oder Accessibility-Architektur neu aufrollen
- breite neue Re-Runs fuer bereits bestaetigte Gruenfaelle durchfuehren

---

## Strenge Grenzen

1. Keine Code-Aenderungen am Produkt
2. Keine neue UI
3. Keine neue Insert-Methode
4. Keine neue Gate-Logik
5. Keine Wiederholung bereits real bestaetigter `allow`- und `allowed`-Faelle als Hauptziel
6. Nur der echte LaunchServices-Bundle-Pfad zaehlt als Hauptgrundlage
7. Scriptgesteuerter Direktstart des Executables darf nicht als Pass/Fail-Hauptbeleg verwendet werden

---

## Verbindlicher Testpfad

Der Lauf muss ueber denselben realen Bundle-Pfad erfolgen, der im 003B-Follow-up bereits belastbar war:

1. sicherstellen, dass fuer das aktuelle Bundle weiterhin bundle-spezifische Accessibility aktiv ist:
   - `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
2. fuer den Deny-Erstlauf einen echten `notDetermined`-Mikrofonzustand fuer `ch.baumanncreative.pushwrite` herstellen
3. Launch ueber LaunchServices:
   - `open /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --args --runtime-dir <...>`
4. echter globaler Hotkey-Trigger
5. User-Entscheidung am echten Mic-Prompt explizit sichtbar als **Don’t Allow**
6. danach ohne Mikrofon-Reset denselben Bundle-Pfad erneut starten
7. denselben Hotkey erneut ausloesen, um den echten `previously denied`-Folgelauf zu beobachten

Wichtig:
Wenn der Deny-Erstlauf nicht wirklich in `denied` endet, darf der Folgefall `previously denied` nicht kuenstlich behauptet werden.

---

## Pflichtfaelle

### 1. mic_not_determined_deny_real_final

Ausgangslage:
- `accessibilityTrusted=true`
- Mikrofonstatus fuer das reale Bundle ist `notDetermined`

Zu pruefen:
- kein Mic-Prompt beim Launch
- Mic-Prompt erscheint erst bei echter Aufnahmeabsicht
- User klickt real sichtbar **Don’t Allow**
- kein Recording
- keine Inferenz
- kein Insert
- blocked-/error-Fall sauber sichtbar
- keine Vermischung mit Accessibility

### 2. mic_previously_denied_real_final

Voraussetzung:
- der vorherige reale Erstlauf endete tatsaechlich in `denied`

Zu pruefen:
- beim naechsten Lauf kein unehrlicher Aufnahmeversuch
- kein Recording
- keine Inferenz
- kein Insert
- klarer blocked-/error-Fall fuer denied
- keine Vermischung mit Device-/Recorder-Fehlern

---

## Optionaler Restpunkt

### 3. mic_allowed_but_no_device_or_recorder_failed_real_status

Nur falls ohne kuenstliche Overrides real beobachtbar oder kurz sauber einordbar:

- Ist dieser Fall auf der aktuellen Workstation real herstellbar?
- Falls nein:
  - explizit als hardware-/workstation-abhaengig offen markieren
  - keinen neuen Testaufbau dafuer aufblasen

Dieser Punkt ist nicht der Hauptzweck des Auftrags.

---

## Beobachtbarkeit

Pro Pflichtlauf muss mindestens dokumentiert werden:

- verwendeter Bundle-Pfad
- Accessibility-Zustand fuer genau dieses Bundle
- Mikrofonstatus vor dem Versuch
- ob ein echter macOS-Mikrofonprompt erschien
- welche User-Entscheidung real getroffen wurde
- ob `requestedMicrophonePermission` gesetzt wurde
- ob Recording startete oder nicht
- ob Inferenz startete oder nicht
- ob Insert startete oder nicht
- finaler Produktstatus
- blockedReason oder errorReason
- relevante Evidenzdateien aus dem Runtime-Verzeichnis

---

## Bewertungslogik

Jeder Pflichtfall muss genau einer dieser Kategorien zugeordnet werden:

### A. Produktpfad real bestaetigt
Der reale Bundle-Lauf zeigt den erwarteten Deny-/Previously-Denied-Pfad sauber.

### B. Produktpfad plausibel, aber real noch nicht voll bestaetigt
Der Fall bleibt trotz korrektem Setup offen.

### C. Produktproblem plausibel
Der reale Lauf deutet auf eine Produktluecke.

### D. Produktproblem nachgewiesen
Der reale Lauf belegt eine Produktluecke belastbar.

### E. QA-/Interaktionsproblem
Die eigentliche Blockade liegt in der realen Prompt-Interaktion oder im Setup, nicht belastbar im Produktpfad.

### F. Nicht belastbar beurteilbar
Keine saubere Zuordnung moeglich; Grund muss konkret benannt werden.

---

## Abnahmekriterien

Der Auftrag ist abgeschlossen, wenn:

- ein echter `notDetermined -> Don’t Allow`-Lauf auf dem realen Bundle-Pfad ausgefuehrt und dokumentiert wurde
- danach ohne Reset ein echter `previously denied`-Folgelauf ausgefuehrt und dokumentiert wurde, falls der Erstlauf real in `denied` endete
- beide Faelle sauber von Accessibility und Device-/Recorder-Fehlern getrennt sind
- keine Produktcode-Aenderungen erfolgt sind
- am Ende klar entschieden ist:
  - 003A jetzt voll real verifiziert
  - oder 003A bleibt teilweise real verifiziert
- falls `allowed but no device / recorder failed` weiterhin nicht real herstellbar ist, wurde dieser Punkt explizit als workstation-/hardwareabhaengig offen markiert statt kuenstlich weiter aufgeblasen

---

## Erwartetes Ergebnis

Am Ende soll ein sehr enger QA-Befund stehen mit:

1. kurzer Zusammenfassung
2. Bundle-/TCC-Setup des Final-Mini-Follow-ups
3. realem `deny`-Erstlauf
4. realem `previously denied`-Folgelauf
5. optional kurzem Status zu `allowed but no device / recorder failed`
6. klarer Gesamtentscheidung zu 003A
7. falls weiter offen: exakt einem verbleibenden Grund

---

## Erwartete Ergebnisdateien

Nach Ausfuehrung dieses Auftrags sollen die Resultate in folgenden Dateien festgehalten werden:

- `docs/execution/003B-final-mini-follow-up-results-verify-real-macos-deny-and-previously-denied-microphone-flow.md`
- `docs/execution/003B-final-mini-follow-up-results-verify-real-macos-deny-and-previously-denied-microphone-flow.json`

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- Produktcode aendern
- neue Permission-Architektur
- neue Accessibility-UI
- neue Insert-Logik
- breiter App-Kompatibilitaetstest
- neuer allgemeiner Mikrofontest
- weiterer Ausbau ueber den Deny-/Previously-Denied-Re-Run hinaus

---

## Kurzform fuer Codex

Fuehre keinen neuen Entwicklungsauftrag aus, sondern den letzten kleinen realen QA-Nachzug fuer 003A. Verifiziere auf dem echten LaunchServices-Bundle-Pfad zuerst einen realen `notDetermined -> Don’t Allow`-Lauf und direkt danach ohne Reset den echten `previously denied`-Folgelauf. Trenne sauber zwischen Produktpfad, TCC-Verhalten und Interaktions-/Setup-Problem. Fuehre keine Code-Aenderungen ein.