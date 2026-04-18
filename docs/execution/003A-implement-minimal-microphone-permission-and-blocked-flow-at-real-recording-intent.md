# Auftrag 003A: Minimalen Mikrofon-Permission- und Blocked-Flow bei echter Aufnahmeabsicht implementieren

## Ziel

Implementiere fuer PushWrite den kleinstmoeglichen ehrlichen Mikrofon-Permission- und Blocked-Flow direkt am realen Aufnahmezeitpunkt, ohne den bestehenden Insert-Pfad, die Gate-Logik oder den allgemeinen Produktscope auszuweiten.

Der Auftrag soll eine konkrete MVP-Luecke schliessen:

- Der Produktkern `Hotkey -> Recording -> lokale Inferenz -> Insert` existiert bereits.
- Mikrofon ist im Produktfluss der naechste zwingende Permission-Schritt.
- Der Mikrofon-Prompt soll nicht beim Launch erscheinen, sondern erst bei echter Aufnahmeabsicht.
- Permission-, Device- und spaetere Accessibility-/Insert-Fehler duerfen nicht vermischt werden.

---

## Ausgangslage

Der funktionale MVP-Kern von PushWrite ist bereits produktnah vorhanden:

- globaler Hotkey
- Recording
- lokale Inferenz
- Insert am Cursor
- Gate fuer `empty|tooShort`
- minimale Rueckmeldung fuer Gate-Faelle

Aus 003 ist fachlich bereits geklaert:

- Accessibility ist fuer den bestehenden Insert-Pfad praktisch bereits gesetzt
- Mikrofon ist der naechste zwingende Permission-Schritt
- Mikrofon soll erst bei echter Aufnahmeabsicht behandelt werden, nicht pauschal beim Start
- Device-Fehler und Permission-Fehler muessen getrennt behandelt werden
- `NSMicrophoneUsageDescription` muss fuer den ersten echten Mikrofon-Build im Bundle vorhanden sein

Dieser Entscheid liegt bereits vor. Was noch fehlt, ist die enge Produktintegration in den bestehenden Recording-Pfad.

---

## Zweck

Dieser Auftrag soll:

- den Mikrofonzugriff im realen Nutzungszeitpunkt sauber behandeln
- den ersten echten Aufnahmeversuch ehrlich machen
- einen klaren blocked-/error-Pfad fuer fehlende Mikrofonberechtigung schaffen
- Permission-, Device- und spaetere Insert-Blockaden sauber trennen
- die Beobachtbarkeit im bestehenden Produktfluss erhalten

Dieser Auftrag soll **nicht**:

- neue UI-Flaechen einführen
- einen allgemeinen Permission-Assistenten bauen
- den Launch-/Accessibility-Flow neu aufrollen
- den Insert-Pfad umbauen
- die Gate-Logik erweitern
- ein breites Recovery- oder Settings-System bauen
- die Audio-Engine grundsaetzlich neu schneiden

---

## Produktregel

Wenn der Nutzer den globalen Hotkey betaetigt und damit eine echte Aufnahmeabsicht ausloest, dann gilt:

1. **Mikrofonzugriff bereits erlaubt**
   - der bestehende Recording-Pfad laeuft unveraendert weiter

2. **Mikrofonzugriff noch nicht entschieden**
   - der System-Prompt darf in genau diesem Moment erscheinen
   - danach muss der Lauf ehrlich weitergefuehrt werden:
     - bevorzugt: direkter Uebergang in den Recording-Pfad, wenn das im bestehenden Flow technisch sauber moeglich ist
     - alternativ: ehrlicher Abbruch mit klar beobachtbarem Zustand, wenn fuer den aktuellen Hotkey-Lauf kein sauberer Sofort-Uebergang moeglich ist

3. **Mikrofonzugriff verweigert oder eingeschraenkt**
   - es darf kein scheinbar erfolgreicher Recording-Lauf starten
   - es darf kein nachgelagerter Inferenz- oder Insert-Pfad anlaufen
   - der Lauf muss ehrlich als blocked oder error beobachtbar sein
   - der Nutzer braucht eine minimale, lokale und ehrliche Rueckmeldung

4. **Mikrofon formal erlaubt, aber kein nutzbares Geraet oder Recorder-Start scheitert**
   - dieser Fall darf nicht als Permission-Problem gelabelt werden
   - der Lauf muss als eigener Fehler-/Blocked-Fall sichtbar bleiben

---

## Strenge Grenzen

1. Keine neue Insert-Methode
2. Keine neue Gate-Regel
3. Keine neue dauerhafte Produkt-UI
4. Kein mehrstufiges Onboarding
5. Kein Mikrofon-Prompt beim Launch
6. Keine Scope-Ausweitung auf weitere Berechtigungen
7. Keine Vermischung mit Packaging, Modellwahl, Hotkey-Optimierung oder breiter Recovery-Architektur
8. Keine erneute Grundsatzdiskussion ueber Accessibility; bestehender Launch-/Blocked-Pfad bleibt gesetzt

---

## Konkrete Umsetzungserwartung

Implementiere nur den kleinstmoeglichen Produktpfad fuer Mikrofonberechtigung im Moment echter Aufnahmeabsicht.

Dazu gehoert mindestens:

1. **Bundle-Voraussetzung**
   - stelle sicher, dass der notwendige statische `NSMicrophoneUsageDescription`-Eintrag im Produktbundle vorhanden ist

2. **Permission-Check direkt vor Recording-Start**
   - pruefe den aktuellen Mikrofon-Authorisierungsstatus unmittelbar vor dem Start der Aufnahme
   - keine pauschale Vorab-Abfrage beim App-Start

3. **Bedarfsnahe Systemabfrage**
   - wenn der Status `notDetermined` ist, darf die Systemabfrage genau in diesem Moment ausgeloest werden

4. **Ehrlicher Permission-Blocked-Fall**
   - wenn Zugriff verweigert ist, darf kein unehrlicher Recording-, Transcribing- oder Insert-Lauf starten
   - der Fall muss klein, aber klar rueckgemeldet und beobachtbar sein

5. **Getrennter Device-/Recorder-Fall**
   - wenn Zugriff erlaubt ist, aber kein nutzbares Eingabegeraet vorhanden ist oder der Recorder nicht startet, muss dieser Fall getrennt von Permission behandelt werden

6. **Beobachtbarkeit fortfuehren**
   - Response
   - Runtime-State
   - Flow-/Event-Persistenz
   - Validator-Erwartungen

Wenn neue Felder noetig sind, dann nur klein, eindeutig und anschlussfaehig an bestehende Zustands- und Reason-Muster.

---

## Beobachtbarkeit

Folgende Fragen muessen danach eindeutig beantwortbar sein:

- warum kein Recording gestartet wurde
- ob der Lauf blocked, error oder regulär weitergelaufen ist
- ob der Mikrofon-Prompt im aktuellen Lauf relevant war
- ob eine minimale Nutzer-Rueckmeldung ausgeloest wurde
- dass kein nachgelagerter Inferenz- oder Insert-Pfad faelschlich gestartet wurde
- ob das Problem in der Permission liegt oder im Recorder-/Device-Start

Falls neue Reason-Klassen notwendig sind, sollen sie den Unterschied mindestens zwischen diesen Faellen sauber tragen:

- Mikrofon-Permission fehlt oder wurde verweigert
- Mikrofon-Permission wurde gerade angefragt
- Mikrofon formal erlaubt, aber kein Geraet / Recorder-Start fehlgeschlagen

Die Benennung darf an den bestehenden Produktstil angepasst werden, aber die fachliche Trennung ist Pflicht.

---

## Nutzerfuehrung

Der MVP braucht hier keine neue Oberflaeche, aber er darf auch nicht still oder irrefuehrend sein.

Deshalb gilt:

- bestehende Blocked-/Setup-Kanaele nur minimal wiederverwenden oder erweitern
- keine neue Haupt-UI
- keine allgemeine Settings-Seite
- die Rueckmeldung muss fuer den Nutzer erkennbar machen, warum der aktuelle Aufnahmeversuch nicht normal weiterlief
- ein reines technisches Nebenprotokoll reicht nicht

Wenn fuer einen denied-Fall ein bestehender Blocked-Kanal wiederverwendet werden kann, ist das dem Bau einer neuen UI klar vorzuziehen.

---

## Pflichtfaelle fuer Validierung

Mindestens diese Faelle pruefen und dokumentieren:

1. **mic_allowed**
   - Mikrofon ist bereits erlaubt
   - Hotkey startet den bestehenden Recording-Pfad ohne Regression

2. **mic_not_determined_allow**
   - Hotkey loest erstmals die Systemabfrage aus
   - Nutzer erlaubt den Zugriff
   - danach entweder:
     - sauberer Uebergang in den Recording-Pfad
     - oder ehrlicher, sauber dokumentierter Abbruch des aktuellen Laufs mit klarer Folge fuer den naechsten Versuch
   - kein unehrlicher Success ohne echte Aufnahme

3. **mic_not_determined_deny**
   - Hotkey loest die Systemabfrage aus
   - Nutzer verweigert den Zugriff
   - kein Recording
   - keine Inferenz
   - kein Insert
   - blocked-/error-Fall sauber sichtbar

4. **mic_previously_denied**
   - keine erneute unehrliche Aufnahme
   - kein nachgelagerter Flow
   - blocked-/error-Fall sauber sichtbar
   - minimale ehrliche Rueckmeldung vorhanden

5. **mic_allowed_but_no_device_or_recorder_failed**
   - Mikrofonpermission ist erlaubt
   - Aufnahme kann trotzdem nicht starten
   - dieser Fall wird getrennt von Permission dokumentiert
   - keine falsche Zuordnung als denied

6. **no_regression_accessibility_insert_path**
   - bestehender Accessibility-/Insert-Pfad wird durch den neuen Mic-Flow nicht unklar oder regressiv
   - Permission-, Device- und spaetere Insert-Blocker bleiben getrennt beobachtbar

---

## Abnahmekriterien

Der Auftrag ist abgeschlossen, wenn:

- `NSMicrophoneUsageDescription` im Produktbundle vorhanden ist
- der Mikrofon-Prompt nicht pauschal beim Launch erscheint
- der Prompt nur bei echter Aufnahmeabsicht auftritt
- bei erlaubtem Zugriff der bestehende Recording-Pfad nicht regressiert
- bei verweigertem Zugriff kein unehrlicher Recording-/Transcribing-/Insert-Lauf startet
- Permission- und Device-/Recorder-Fehler fachlich getrennt sichtbar sind
- der blocked-/error-Fall sauber beobachtbar ist
- keine neue UI-Flaeche eingefuehrt wurde
- keine neue Insert- oder Gate-Logik eingefuehrt wurde
- Resultate dokumentiert und revalidiert sind

---

## Erwartete Ergebnisdateien

Nach Ausfuehrung dieses Auftrags sollen die Resultate in folgenden Dateien festgehalten werden:

- `docs/execution/003A-results-implement-minimal-microphone-permission-and-blocked-flow-at-real-recording-intent.md`
- `docs/execution/003A-results-implement-minimal-microphone-permission-and-blocked-flow-at-real-recording-intent.json`

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- Umbau des Launch-Readiness-Systems
- neue allgemeine Permission-Architektur
- neue Insert-Strategien
- Erweiterung des Gate-Verhaltens
- neue Preferences- oder Settings-Oberflaechen
- Audio-Device-Management jenseits des minimal noetigen Fehlerpfads
- breites UX-Polishing fuer spaetere Releases
- Multiplattform-Betrachtung
- Datei-Transkription

---

## Kurzform fuer Codex

Integriere den kleinstmoeglichen Mikrofon-Permission- und Blocked-Flow direkt in den bestehenden Hotkey-zu-Recording-Pfad. Kein Mikrofon-Prompt beim Launch. Bei erlaubtem Zugriff bleibt der bestehende Recording-Pfad unveraendert. Bei nicht entschiedener Freigabe darf der Systemprompt nur bei echter Aufnahmeabsicht erscheinen. Bei verweigertem Zugriff oder Recorder-/Device-Fehlern darf kein unehrlicher Recording-, Inferenz- oder Insert-Lauf starten; stattdessen muss ein klar beobachtbarer, minimal rueckgemeldeter und fachlich sauber getrennter Blocked-/Error-Fall entstehen.