# Auftrag 003B Follow-up: Realen macOS-TCC-Mikrofon-Flow nach bundle-spezifischer Accessibility-Freigabe erneut pruefen

## Ziel

Fuehre einen engen realen Re-Run des bereits implementierten und teilweise real verifizierten 003A-Mikrofon-Flows durch, nachdem fuer **genau das aktuell verwendete PushWrite.app-Bundle** reale Accessibility-Freigabe vorliegt oder ein stabiler signierter Bundle-Pfad verwendet wird.

Der Auftrag dient nicht dazu, neue Produktlogik zu bauen.  
Er dient dazu, die in 003B offen gebliebenen echten Mikrofon-TCC-Faelle endlich auf demselben realen Bundle-Pfad sauber nachzupruefen.

---

## Ausgangslage

003A ist implementiert.  
003B hat bereits real bestaetigt:

- echter `notDetermined`-Zustand fuer das aktuelle Bundle war herstellbar
- kein Mikrofonprompt beim Launch
- keine Vermischung von Accessibility-Blocker und Mikrofon-TCC

003B hat zugleich gezeigt:

- der echte Hotkey-Lauf des aktuellen `.app`-Bundles erreichte den Mikrofonpfad nicht
- Grund war fehlende reale Accessibility-Freigabe fuer genau dieses Bundle
- der scriptgesteuerte Direktstart des Executables ist fuer echten bundle-spezifischen Mikrofon-TCC-Nachweis auf dieser Workstation nicht belastbar
- der relevante Realpfad ist der LaunchServices-Start des `.app`-Bundles

Deshalb ist 003A aktuell nur **teilweise real verifiziert**, aber nicht voll verifiziert.

---

## Zweck

Dieser Folgeauftrag soll ausschliesslich die noch offenen Realfaelle auf demselben belastbaren Bundle-Pfad nachziehen.

Er soll:

- den echten Mic-Erstprompt bei realer Aufnahmeabsicht pruefen
- reale `allow`- und `deny`-Faelle bestaetigen
- danach den realen `previously denied`-Folgezustand pruefen
- wenn real erreichbar, auch `allowed but no device / recorder failed` sauber nachziehen
- am Ende klar entscheiden, ob 003A nun voll real verifiziert ist

Dieser Auftrag soll **nicht**:

- neue Produktlogik einfuehren
- UI erweitern
- Insert- oder Gate-Logik aendern
- neue Testarchitektur bauen
- den bestehenden Accessibility- oder Insert-Pfad neu verhandeln

---

## Strenge Grenzen

1. Keine Code-Aenderungen am Produkt
2. Keine neue UI
3. Keine neue Insert-Methode
4. Keine neue Gate-Logik
5. Keine Vermischung von Produktproblem, TCC-Verhalten und QA-Setup
6. Nur der reale `.app`-Bundle-Pfad zaehlt als Pass/Fail-Grundlage
7. Scriptgesteuerter Direktstart des Executables darf hoechstens als Nebenbefund dokumentiert werden, nicht als Hauptnachweis

---

## Pflichtvoraussetzung vor dem Re-Run

Vor den eigentlichen Mikrofonfaellen muss **eine** dieser Bedingungen erfuellt sein:

### Option A – bevorzugt
Fuer **genau dieses aktuelle** Produktbundle liegt reale Accessibility-Freigabe vor:

- `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`

### Option B – nur falls A unzuverlaessig ist
Es wird ein stabiler signierter bzw. stabiler Bundle-Pfad verwendet, dessen Accessibility-Zustand fuer den Re-Run erhalten bleibt.

Wichtig:
Wenn diese Voraussetzung nicht sauber erfuellt ist, darf der Auftrag nicht kuenstlich als fehlgeschlagener Mikrofontest gewertet werden. Dann ist der Befund weiterhin ein QA-/Bundle-Setup-Problem.

---

## Verbindlicher Testpfad

Der Re-Run muss ueber denselben realen Bundle-Pfad erfolgen, der in 003B als belastbar identifiziert wurde:

1. optional oder gezielt:
   - `tccutil reset Microphone ch.baumanncreative.pushwrite`
2. Launch des `.app`-Bundles ueber LaunchServices:
   - `open /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --args --runtime-dir <...>`
3. echter globaler Hotkey-Trigger
4. Beobachtung ueber reale Produktartefakte und Logs des gestarteten Bundle-Laufs

Nicht ausreichend als Hauptgrundlage:
- direkter Executable-Start
- alte Validator-Pfade, die nicht denselben realen Bundle-TCC-Kontext benutzen

---

## Zu pruefende Echtfaelle

### 1. mic_not_determined_allow_real_rerun

Ausgangslage:
- Mikrofonstatus fuer das reale Bundle ist `notDetermined`
- bundle-spezifische Accessibility ist vorhanden

Zu pruefen:
- kein Mic-Prompt beim Launch
- Mic-Prompt erscheint erst bei echter Aufnahmeabsicht
- Nutzer erlaubt
- der Lauf geht danach ehrlich weiter
- kein unehrlicher Success ohne echte Aufnahme

### 2. mic_not_determined_deny_real_rerun

Ausgangslage:
- Mikrofonstatus fuer das reale Bundle ist `notDetermined`
- bundle-spezifische Accessibility ist vorhanden

Zu pruefen:
- kein Mic-Prompt beim Launch
- Mic-Prompt erscheint erst bei echter Aufnahmeabsicht
- Nutzer verweigert
- kein Recording
- keine Inferenz
- kein Insert
- blocked-/error-Fall sauber sichtbar

### 3. mic_previously_denied_real_rerun

Voraussetzung:
- echter `deny`-Erstlauf wurde real erreicht

Zu pruefen:
- kein erneuter unehrlicher Aufnahmeversuch
- kein nachgelagerter Recording-/Inferenz-/Insert-Pfad
- blocked-/error-Fall sauber sichtbar
- klare Trennung zu Device- oder Accessibility-Faellen

### 4. mic_allowed_real_rerun

Voraussetzung:
- reales Bundle mit erlaubter Accessibility und erlaubtem Mikrofonstatus

Zu pruefen:
- bestehender Recording-Pfad laeuft ohne Regression
- keine neue Friktion
- Recording -> Transcribing -> nachgelagerter Flow bleiben beobachtbar

### 5. mic_allowed_but_no_device_or_recorder_failed_real_rerun

Voraussetzung:
- reales Bundle mit erlaubtem Mikrofonstatus
- Device-/Recorder-Fehler real herstellbar oder kontrolliert beobachtbar

Zu pruefen:
- Fall wird nicht als Permission-Problem etikettiert
- eigener Fehlerzustand bleibt sichtbar
- kein unehrlicher Success-/Insert-Pfad entsteht

---

## Bewertungslogik

Jeder Fall muss genau einer dieser Kategorien zugeordnet werden:

### A. Produktpfad real bestaetigt
Der reale Bundle-Lauf zeigt den erwarteten 003A-Produktpfad sauber.

### B. Produktpfad plausibel, aber real noch nicht voll bestaetigt
Der Fall bleibt wegen Setup oder fehlender Herstellbarkeit offen.

### C. Produktproblem plausibel
Der reale Lauf deutet auf eine Produktluecke.

### D. Produktproblem nachgewiesen
Der reale Lauf belegt eine Produktluecke belastbar.

### E. QA-/Bundle-Setup-Problem
Die eigentliche Blockade liegt weiterhin in Bundle-, Trust- oder Workstation-Setup.

### F. Nicht belastbar beurteilbar
Keine saubere Zuordnung moeglich; Grund muss konkret benannt werden.

---

## Beobachtbarkeit

Pro Lauf muss mindestens klar dokumentiert werden:

- verwendeter reale Bundle-Pfad
- ob fuer genau dieses Bundle Accessibility real vorhanden war
- realer Mikrofonstatus vor dem Versuch
- ob ein echter macOS-Systemprompt erschien
- ob Recording startete oder nicht
- ob der Lauf blocked, error oder regulär weiterlief
- ob Inferenz und Insert korrekt ausblieben oder korrekt folgten
- welche Artefakte als Evidenz verwendet wurden
- ob ein Befund Produktpfad, TCC oder QA-Setup zuzuordnen ist

---

## Abnahmekriterien

Der Auftrag ist abgeschlossen, wenn:

- der Re-Run ueber den realen LaunchServices-Bundle-Pfad erfolgt ist
- bundle-spezifische Accessibility vor dem Mikrofontest sauber geklaert wurde
- mindestens `mic_not_determined_allow_real_rerun` und `mic_not_determined_deny_real_rerun` real bewertet wurden
- danach `mic_previously_denied_real_rerun` nachgezogen wurde, falls real erreichbar
- `mic_allowed_real_rerun` real bewertet wurde
- `mic_allowed_but_no_device_or_recorder_failed_real_rerun` real bewertet oder sauber als weiterhin offen eingegrenzt wurde
- am Ende klar entschieden ist:
  - 003A jetzt voll real verifiziert
  - oder weiterhin nur teilweise real verifiziert
- keine Produktcode-Aenderungen erfolgt sind

---

## Erwartetes Ergebnis

Am Ende soll ein enger Revalidierungsbefund stehen mit:

1. kurzer Zusammenfassung
2. realem Bundle-/Accessibility-Setup
3. getesteten Re-Run-Faellen
4. Beobachtungen pro Fall
5. sauberer Trennung von Produktpfad, TCC und QA-Setup
6. Gesamtentscheidung zu 003A
7. falls weiter offen: kleinstmoeglicher naechster QA-Schritt

---

## Erwartete Ergebnisdateien

Nach Ausfuehrung dieses Auftrags sollen die Resultate in folgenden Dateien festgehalten werden:

- `docs/execution/003B-follow-up-results-rerun-real-macos-tcc-microphone-flow-after-bundle-specific-accessibility.md`
- `docs/execution/003B-follow-up-results-rerun-real-macos-tcc-microphone-flow-after-bundle-specific-accessibility.json`

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- Produktcode aendern
- neue Permission-Architektur
- neue Accessibility-UI
- neue Insert-Logik
- breiter App-Kompatibilitaetstest
- neue Audio- oder Recorder-Architektur
- weiterer Ausbau ueber den realen TCC-Re-Run hinaus

---

## Kurzform fuer Codex

Fuehre keinen neuen Produktauftrag aus, sondern einen engen realen QA-Re-Run von 003B. Sorge zuerst dafuer, dass fuer genau das aktuelle PushWrite.app-Bundle reale Accessibility-Freigabe vorliegt oder ein stabiler signierter Bundle-Pfad verwendet wird. Wiederhole dann den echten LaunchServices-Bundle-Start und pruefe die offenen realen Mikrofon-TCC-Faelle `notDetermined -> allow`, `notDetermined -> deny`, danach `previously denied` sowie den realen `allowed`-Pfad. Werte nur den echten Bundle-Pfad als Hauptgrundlage und fuehre keine Code-Aenderungen ein.