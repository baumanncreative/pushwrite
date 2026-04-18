# Auftrag 003B: Echten macOS-TCC-Mikrofon-Flow nach 003A revalidieren

## Ziel

Revalidiere den bereits implementierten 003A-Mikrofon-Permission- und Blocked-Flow gegen echte macOS-TCC-Zustaende, damit der Mikrofonpfad nicht nur logisch und validator-seitig, sondern auch im realen Systemkontakt belastbar bestaetigt ist.

Der Auftrag dient nicht dazu, neue Produktlogik einzufuehren.  
Er dient dazu, den bereits implementierten 003A-Pfad unter echten TCC-Bedingungen sauber zu bestaetigen oder klar einzugrenzen, wo noch eine reale Luecke besteht.

---

## Ausgangslage

Der funktionale MVP-Kern von PushWrite ist produktnah vorhanden:

- globaler Hotkey
- Recording
- lokale Inferenz
- Insert am Cursor
- Gate fuer `empty|tooShort`
- minimale Rueckmeldung fuer Gate-Faelle

003 hat die Permission-Logik fachlich gesetzt:

- Accessibility ist fuer den bestehenden Insert-Pfad praktisch bereits gesetzt
- Mikrofon ist der naechste zwingende Permission-Schritt
- Mikrofon soll nicht beim Launch, sondern erst bei echter Aufnahmeabsicht behandelt werden
- Permission-, Device- und spaetere Accessibility-/Insert-Fehler muessen getrennt bleiben

003A wurde inzwischen implementiert.  
Die aktuelle offene Frage ist deshalb **nicht mehr die Logik des Flows**, sondern seine **echte TCC-Revalidierung** auf macOS.

Insbesondere reicht eine rein deterministische Runtime-Override-Pruefung nicht aus, wenn der echte System-Erstprompt auf `notDetermined` noch nicht sauber an einem frischen TCC-Zustand beobachtet wurde.

---

## Zweck

Dieser Auftrag soll:

- den bereits implementierten 003A-Pfad gegen echte macOS-Mikrofonzustände pruefen
- bestaetigen, dass der Systemprompt tatsaechlich nur bei echter Aufnahmeabsicht erscheint
- bestaetigen, dass `notDetermined`, `denied`, `allowed` und `allowed but no device / recorder failed` im echten Systemkontakt sauber getrennt bleiben
- bestaetigen, dass keine Regression in bestehende Accessibility-/Insert-Beobachtbarkeit entstanden ist
- eine belastbare Entscheidung liefern, ob 003A als voll verifiziert gelten kann

Dieser Auftrag soll **nicht**:

- neue Produktlogik einbauen
- neue UI-Flaechen einführen
- den Insert-Pfad aendern
- die Gate-Logik aendern
- neue Testarchitektur aufblasen
- allgemeine macOS-Permission-Theorie aufrollen

---

## Strenge Grenzen

1. Keine Code-Aenderungen am Produktpfad
2. Keine neue UI
3. Keine neue Insert-Methode
4. Keine neue Gate-Logik
5. Keine Ausweitung auf weitere Berechtigungen ausser dem bereits gebauten Mikrofonpfad
6. Keine Vermischung von:
   - Produktproblem
   - TCC-/Systemverhalten
   - Test-Harness-Problem

Wenn ein Test an TCC-Reset, Workstation-Zustand oder QA-Setup scheitert, muss genau das dokumentiert und vom Produktpfad getrennt werden.

---

## Kernfrage

Der Auftrag soll am Ende genau diese Frage beantworten:

**Ist 003A im realen macOS-TCC-Verhalten belastbar bestaetigt, oder ist bisher nur die interne Logik plausibel gruen?**

---

## Zu pruefende Echtfaelle

Es werden nur reale Mikrofon-TCC-Faelle des bereits implementierten 003A-Pfads geprueft.

### 1. mic_not_determined_allow_real
Ausgangslage:
- Mikrofonstatus ist fuer PushWrite real `notDetermined`

Zu pruefen:
- der Systemprompt erscheint erst bei echter Aufnahmeabsicht
- nicht bereits beim Launch
- Nutzer erlaubt den Zugriff
- der Lauf geht danach ehrlich und nachvollziehbar weiter
- kein unehrlicher Success ohne echte Aufnahme

### 2. mic_not_determined_deny_real
Ausgangslage:
- Mikrofonstatus ist fuer PushWrite real `notDetermined`

Zu pruefen:
- der Systemprompt erscheint erst bei echter Aufnahmeabsicht
- Nutzer verweigert den Zugriff
- kein Recording
- keine Inferenz
- kein Insert
- blocked-/error-Fall sauber sichtbar
- minimale lokale Rueckmeldung vorhanden, falls 003A dies so umgesetzt hat

### 3. mic_previously_denied_real
Ausgangslage:
- Mikrofonstatus ist fuer PushWrite real `denied`

Zu pruefen:
- kein erneuter unehrlicher Aufnahmeversuch
- kein nachgelagerter Recording-/Inferenz-/Insert-Pfad
- blocked-/error-Fall sauber sichtbar
- klare Trennung zu Device- oder Accessibility-Faellen

### 4. mic_allowed_real
Ausgangslage:
- Mikrofonstatus ist fuer PushWrite real `authorized`

Zu pruefen:
- bestehender Recording-Pfad laeuft ohne Regression
- keine ungewollte neue Friktion
- Recording -> Transcribing -> nachgelagerter Flow bleiben beobachtbar

### 5. mic_allowed_but_no_device_or_recorder_failed_real
Ausgangslage:
- Mikrofonpermission ist real erlaubt
- aber es gibt kein nutzbares Eingabegeraet oder der Recorder-Start scheitert real

Zu pruefen:
- der Fall wird nicht als Permission-Fall etikettiert
- der Fehler bleibt als eigener Produktzustand sichtbar
- kein unehrlicher Insert- oder Success-Pfad entsteht

### 6. no_regression_accessibility_insert_path_real
Zu pruefen:
- der bestehende Accessibility-/Insert-Pfad bleibt fachlich getrennt
- Mikrofon-TCC-Fehler werden nicht mit Accessibility-Blockern vermischt
- Insert-Regressionsindikatoren bleiben unveraendert beobachtbar

---

## Testdurchfuehrung

Die Revalidierung soll so real wie moeglich, aber so eng wie noetig bleiben.

### Pflichtprinzipien

1. **Echte TCC-Zustaende vor Overrides**
   - echte Systemzustaende haben Vorrang
   - Runtime-Overrides duerfen nur als Hilfsmittel dokumentiert werden, nicht als Ersatz fuer die reale Revalidierung

2. **Prompt nur bei echter Aufnahmeabsicht**
   - kein Launch-Test darf versehentlich den Mic-Prompt ausloesen
   - pruefen, dass der Systemprompt nur am realen Recording-Startpunkt erscheint

3. **Frischer TCC-Zustand sauber dokumentieren**
   - wie der `notDetermined`-Zustand hergestellt wurde
   - ob dies ueber frisches Bundle, TCC-Reset oder andere QA-Massnahme geschah
   - falls das lokal nicht belastbar moeglich ist, offen dokumentieren

4. **Keine Harness-Drift**
   - keine breite GUI-/AppleScript-/System-Events-Testbaustelle
   - wenn der QA-Aufbau selbst die eigentliche Blockade wird, klar als Harness-/Setup-Problem ausweisen

---

## Beobachtbarkeit

Die Revalidierung ist nur dann brauchbar, wenn pro Fall mindestens diese Punkte beantwortbar sind:

- welcher reale Mikrofonstatus lag vor
- ob ein echter macOS-Systemprompt erschien oder nicht
- an welchem Produktschritt der Lauf stand
- ob Recording startete oder nicht
- ob der Lauf blocked, error oder regulär weiterlief
- welcher lokale Rueckmeldungskanal benutzt wurde
- ob der nachgelagerte Inferenz-/Insert-Pfad korrekt ausblieb oder korrekt weiterlief
- ob der Befund dem Produktpfad, dem realen TCC-Verhalten oder dem Test-Setup zuzuordnen ist

---

## Bewertungslogik

Jeder getestete Fall muss genau einer dieser Kategorien zugeordnet werden:

### A. Produktpfad real bestaetigt
Der reale TCC-Fall wurde beobachtet und der 003A-Pfad verhaelt sich produktgerecht.

### B. Produktpfad plausibel, aber real nicht voll bestaetigt
Die Logik ist validator-seitig gruen, der echte Systemkontakt konnte fuer diesen Fall aber nicht vollstaendig hergestellt werden.

### C. Produktproblem plausibel
Der reale Lauf zeigt einen Befund, der eher fuer eine Produktluecke spricht, ohne schon voll bewiesen zu sein.

### D. Produktproblem nachgewiesen
Der reale Lauf zeigt belastbar, dass 003A im Produktpfad unzureichend ist.

### E. TCC-/QA-Setup-Problem
Die eigentliche Blockade liegt im Reset-, Bundle-, Workstation- oder Testaufbau, nicht belastbar im Produktpfad.

### F. Nicht belastbar beurteilbar
Weder echte Produktbestaetigung noch klare Problemzuordnung moeglich; Grund muss konkret benannt werden.

---

## Erwartetes Ergebnis

Am Ende soll **keine neue Produktimplementierung** stehen, sondern ein sauberer Revalidierungsbefund mit:

1. kurzer Zusammenfassung
2. geprueftem realen TCC-Setup
3. getesteten Echtfaellen
4. Beobachtungen pro Fall
5. sauberer Trennung von
   - Produktpfad
   - realem TCC-Verhalten
   - QA-/Harness-Problem
6. Gesamtbewertung:
   - 003A voll verifiziert
   - oder 003A nur teilweise real verifiziert
   - oder 003A fachlich nachzuschneiden
7. klare Empfehlung fuer den naechsten Schritt

---

## Abnahmekriterien

Der Auftrag ist abgeschlossen, wenn:

- mindestens ein echter `notDetermined`-Erstprompt-Fall dokumentiert ist
- klar belegt ist, dass der Prompt nicht beim Launch, sondern erst bei echter Aufnahmeabsicht erscheint
- `allow`, `deny`, `previously denied` und `allowed but no device / recorder failed` fachlich getrennt bewertet sind
- keine neue Produktlogik eingefuehrt wurde
- Accessibility-/Insert-Beobachtbarkeit nicht mit Mikrofon-TCC-Befunden vermischt wurde
- das Ergebnis klar sagt, ob 003A jetzt als voll verifiziert gelten kann oder nicht

---

## Erwartete Ergebnisdateien

Nach Ausfuehrung dieses Auftrags sollen die Resultate in folgenden Dateien festgehalten werden:

- `docs/execution/003B-results-revalidate-real-macos-tcc-microphone-flow-after-003A.md`
- `docs/execution/003B-results-revalidate-real-macos-tcc-microphone-flow-after-003A.json`

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- Umbau des 003A-Produktpfads
- neue Settings- oder Onboarding-UI
- breitere Launch-Readiness-Neuarchitektur
- weitere Berechtigungen ausser dem realen Mikrofon-TCC-Pfad
- breiter App-Kompatibilitaetstest
- neue Insert- oder Audioarchitektur
- Optimierung fuer spaetere Releases

---

## Kurzform fuer Codex

Revalidiere den bereits implementierten 003A-Mikrofon-Permission- und Blocked-Flow gegen echte macOS-TCC-Zustaende. Prioritaet hat ein real beobachteter `notDetermined`-Erstprompt bei echter Aufnahmeabsicht. Trenne sauber zwischen Produktpfad, realem TCC-Verhalten und QA-/Harness-Problem. Fuehre keine neuen Code-Aenderungen ein und entscheide am Ende klar, ob 003A jetzt voll verifiziert ist oder nur logisch plausibel gruen bleibt.