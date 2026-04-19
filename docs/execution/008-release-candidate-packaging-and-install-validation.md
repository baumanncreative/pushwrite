# Auftrag für Codex 008: Release-Candidate-Packaging und Installationsvalidierung fuer PushWrite

## Ziel

Mache aus dem aktuellen produktnahen PushWrite-Stand einen **reproduzierbaren, extern testbaren Release Candidate** fuer macOS.

Der Auftrag dient dazu, die Luecke zwischen:

- funktionierendem Produktbundle
- und sauber weitergebbarem Teststand

zu schliessen.

008 dient **nicht** dazu, neue Kernfunktionen zu bauen.
008 dient dazu, den bestehenden Produktstand fuer externe Tests, spaetere Releases und klare Installationsvalidierung zu haerten.

---

## Ausgangslage

Der Stand vor 008 ist:

- der MVP-Kern ist fachlich geschlossen:
  - Hotkey
  - Aufnahme
  - lokale Transkription
  - Insert-Gate
  - Insert-Versuch
  - minimale Rueckmeldung
- der Stable-Bundle-/LaunchServices-Pfad ist fuer den Produktnachweis gueltig revalidiert
- die lokale whisper.cpp-Runtime und genau ein Minimalmodell sind im Produktbundle enthalten
- der Produktlauf kann ohne explizite externe `--whisper-cli-path`- und `--whisper-model-path`-Angaben erfolgen

Was noch fehlt, ist ein sauberer externer Teststand mit klaren Release-Artefakten, reproduzierbarer Build-Form und nachvollziehbarer Installationsvalidierung.

---

## Verbindliche Produktentscheidung fuer diesen Auftrag

Fuer 008 gilt verbindlich:

- Zielplattform bleibt **nur macOS**
- Fokus bleibt **nur MVP 0.1.0**
- bestehender Produktfluss bleibt fachlich unveraendert
- 008 baut **keine** neue Transkriptionslogik
- 008 baut **keine** neue Insert-Logik
- 008 baut **keine** neue Feedback-Logik
- 008 baut **kein** Mehrmodell-Management
- 008 baut **keine** Datei-Transkription
- 008 baut **keine** Multiplattform-Erweiterung
- 008 baut **keine** Notarisierungs-/App-Store-/Vertriebsarchitektur
- Fokus ist:
  - reproduzierbarer Product-Build
  - installierbares Release-Artefakt
  - klare externe Testanleitung
  - klare Release-Validierung

---

## Problemrahmen

Nach 007 ist PushWrite zwar produktnah lauffaehig, aber noch nicht sauber als externer Teststand organisiert.

Der aktuelle Rest ist nicht mehr Produktlogik, sondern Produktisierung:

- Wie wird aus dem Build ein klar benannter Release Candidate?
- Wie wird daraus ein weitergebbares Artefakt?
- Wie wird Installation und erster Start nachvollziehbar validiert?
- Welche minimalen Release-Metadaten muessen dokumentiert sein?
- Wie wird verhindert, dass externe Tests still auf Dev-Annahmen beruhen?

008 soll diesen Release-/Installationsschnitt schliessen.

---

## Umsetzungsziel

Implementiere einen kleinen, kontrollierten Release-Candidate-Prozess fuer PushWrite.

Am Ende dieses Auftrags soll es geben:

1. einen reproduzierbaren Product-Build fuer einen klar benannten Release Candidate
2. ein klar weitergebbares Release-Artefakt
3. eine kleine Installations- und Testanleitung fuer externe Tester
4. eine minimale technische Release-Validierung
5. eine Results-Datei, die den realen Stand dokumentiert

---

## Verbindlicher Scope

### In Scope

- Product-Build fuer einen klaren Release-Candidate-Stand schneiden
- ein installierbares bzw. weitergebbares Artefakt erzeugen
- Bundle-Inhalt auf Minimalvollstaendigkeit pruefen
- zentrale Release-Metadaten dokumentieren
- Installationsanleitung fuer externe Tester anlegen
- eine kleine Release-Validierung durchfuehren
- persistierte Results-Datei im Repo anlegen oder aktualisieren

### Nicht in Scope

- neue Features
- neue Hotkey-Modelle
- neue Accessibility-Architektur
- neue Insert-Strategie
- neue UI-Flaechen
- DMG-Design
- Notarisierung
- Auto-Update
- Sparkle-/Updater-Integration
- GitHub-Release-Automatisierung
- Installer-Paket (`.pkg`) falls nicht zwingend noetig
- Mehrmodell-/Downloader-Logik

---

## Verbindliche Kernfrage

Die zentrale Frage von 008 lautet:

**Kann PushWrite als klar benannter Release Candidate reproduzierbar gebaut, als Artefakt weitergegeben und mit dokumentierten Schritten installiert und getestet werden, ohne auf versteckte Dev-Annahmen angewiesen zu sein?**

---

## Erwartete Release-Artefakte

Bitte erzeuge mindestens diese zwei Ebenen:

### 1. Product-Bundle
- das reale `.app`-Bundle fuer den Release Candidate

### 2. Weitergebbares Artefakt
- bevorzugt ein einfaches Release-Archiv wie `.zip`, sofern das im aktuellen Setup der kleinste saubere Weg ist

Wichtig:
- der Name soll klar release-candidate-tauglich sein
- die Benennung soll reproduzierbar und konsistent sein
- die Results-Datei muss den realen Namen und Pfad dokumentieren

Falls ein anderes kleines Format sinnvoller ist, kurz begruenden.
Bitte **kein** Scope-Ausbau in Richtung komplexer Installer.

---

## Verbindliche Benennungsregel

Bitte verwende fuer den Release Candidate ein klares, konsistentes Schema.

Mindestens dokumentieren:

- Produktname
- Versionskennung
- Candidate-Charakter

Beispielhafte Richtung:
- `PushWrite-v0.1.0-rc1.app`
- `PushWrite-v0.1.0-rc1-macos.zip`

Wenn das bestehende Projekt bereits ein anderes konsistentes Schema hat, nutze dieses.
Wichtig ist:
- eindeutig
- reproduzierbar
- spaeter releasefaehig anschlussbar

---

## Verbindliche Bundle-Pruefung

Bitte pruefe und dokumentiere vor dem Packaging mindestens:

- Bundle-Identifier
- Bundle-Executable
- vorhandene whisper-Ressourcen im Bundle
- vorhandenes Minimalmodell im Bundle
- Codesign-/CDHash-Befund
- ob der Product-Build erfolgreich ist

Bitte **keine** neue grossflaechige Preflight-Architektur bauen.
Ein kleiner Build-/Validate-Schritt oder schlankes Script ist ausreichend.

---

## Verbindliche Installationsvalidierung

Bitte fuehre eine kleine, kontrollierte Installationsvalidierung durch.

Ziel ist **nicht** vollumfaengliches Distribution-Testing, sondern eine minimale belastbare Produktpruefung.

Mindestens pruefen:

1. Release-Artefakt laesst sich entpacken oder bereitstellen
2. `.app` ist am erwarteten Ort vorhanden
3. Bundle enthaelt die benoetigten Ressourcen
4. Produkt kann im gueltigen QA-Pfad gestartet werden
5. mindestens ein Erfolgsfall ist nachvollziehbar
6. mindestens ein negativer Fall ist nachvollziehbar

Wenn der `open`-CLI-Pfad weiterhin separat auffaellig ist, soll 008 das **nicht** breit loesen.
Bitte dann den gueltigen LS-API-Pfad weiter als primaeren Testpfad dokumentieren.

---

## Verbindliche Trennung von primaerem und sekundaerem Startpfad

Bitte dokumentiere weiter sauber:

### Primaer (gueltig)
- Stable-/Release-Candidate-Bundle
- LaunchServices-Start ueber gueltigen Produktpfad
- dokumentierter CDHash
- produktnaher Testbefund

### Sekundaer (Debug)
- Direktstarts
- Dev-Overrides
- Repo-Fallback
- kein Ersatz fuer den primaeren Release-/Installationsnachweis

---

## Externe Testanleitung

Bitte lege eine kleine, klare Datei fuer externe Tester an.

Empfohlener Pfad:
`docs/testing/008-external-test-instructions.md`

Die Datei soll mindestens enthalten:

- was der Tester erhaelt
- wie das Artefakt entpackt wird
- wie die App gestartet wird
- welche Berechtigungen erwartet werden
- wie ein kurzer Erfolgsfall getestet wird
- wie ein kurzer negativer Fall getestet wird
- welche Artefakte oder Beobachtungen bei Problemen wichtig sind

Bitte klein und praktisch halten.
Keine Entwickler-Abhandlung.

---

## Release-Metadaten

Bitte dokumentiere in Results und falls sinnvoll in einer kleinen Release-Info-Datei mindestens:

- exakter Pfad des Release-Candidate-Bundles
- exakter Pfad des Release-Artefakts
- Bundle-Identifier
- Version / Candidate-Name
- CDHash
- gebundeltes Modell
- gebundelter whisper-CLI-Pfad
- gueltiger Startpfad fuer Produktpruefung

Optional, wenn klein machbar:
- Dateigroesse des Artefakts
- SHA256 des Release-Artefakts

Nicht noetig:
- neue Release-Datenbank
- changelog-Automation
- GitHub-Release-Automation

---

## Beobachtbarkeit

Bitte fuehre keine neue grosse Observability-Familie ein.

Nur soweit noetig dokumentieren oder klein erweitern, damit nachvollziehbar bleibt:

- Release Candidate wurde mit gebundelten Ressourcen gebaut
- welcher Startpfad fuer die Validierung verwendet wurde
- welcher Erfolgsfall validiert wurde
- welcher negative Fall validiert wurde

Bevorzugt bestehende Artefakte weiterverwenden.

---

## Fehler- und Randfaelle

Mindestens diese Faelle muessen sauber behandelt werden:

### 1. Product-Build gelingt, aber Release-Artefakt fehlt
Erwartung:
- klarer Fehlerbefund
- kein unscharfer „fast fertig“-Stand

### 2. Release-Artefakt existiert, aber Bundle ist unvollstaendig
Erwartung:
- klarer Validierungsfehler
- keine stillschweigende Freigabe

### 3. Release Candidate startet nur noch mit Dev-Overrides
Erwartung:
- das waere fuer 008 ein Fehlschlag
- Release-Stand muss ohne explizite externe Whisper-Pfade pruefbar sein

### 4. Primaerer Startpfad bleibt von `open`-CLI irritiert
Erwartung:
- nicht breit loesen
- gueltigen LS-API-Pfad fuer 008 klar dokumentieren
- Debug-Befund getrennt halten

### 5. Externe Testanleitung setzt verstecktes Dev-Wissen voraus
Erwartung:
- nachschaerfen
- Anleitung muss fuer einen externen Tester lesbar sein

---

## Akzeptanzkriterien

Der Auftrag ist erfuellt, wenn Folgendes belegbar ist:

1. Es gibt einen klar benannten Release Candidate als `.app`-Bundle.
2. Es gibt ein weitergebbares Release-Artefakt.
3. Das Bundle enthaelt die fuer den MVP benoetigten Whisper-Ressourcen.
4. Der Release Candidate ist ohne explizite externe `--whisper-*`-Pfade pruefbar.
5. Ein primaerer gueltiger Produktstartpfad ist dokumentiert.
6. Mindestens ein Erfolgsfall und ein negativer Fall wurden fuer den Release Candidate validiert.
7. Es gibt eine kleine externe Testanleitung.
8. Es wurde keine unnoetige neue Produktlogik eingefuehrt.
9. Die Results-Datei dokumentiert reale Pfade, reale Artefakte und reale Testbefunde.

---

## Testhinweise, die Codex liefern soll

Bitte liefere am Ende:

1. exakten Pfad des Release-Candidate-Bundles
2. exakten Pfad des weitergebbaren Artefakts
3. exakten Bundle-Identifier
4. dokumentierten CDHash
5. exakten Pfad des gebundelten CLI
6. exakten Pfad des gebundelten Modells
7. wie der Release Candidate gebaut wird
8. wie der Release Candidate installiert bzw. entpackt wird
9. welcher primaere Startpfad fuer die Validierung verwendet wurde
10. welcher Erfolgsfall validiert wurde
11. welcher negative Fall validiert wurde
12. welche Dateien real geaendert wurden

---

## Persistierte Repo-Dokumentation ist Pflicht

Lege oder aktualisiere zusaetzlich eine Results-Datei im Repo unter genau diesem Pfad:

`docs/execution/008-results-release-candidate-packaging-and-install-validation.md`

Diese Datei muss den **tatsaechlich umgesetzten Stand** dokumentieren, nicht nur den Auftrag wiederholen.

Mindestens enthalten:

- Status
- Kurzfassung
- geaenderte Dateien
- exakter Release-Candidate-Pfad
- exakter Artefaktpfad
- Bundle-/Ressourcenpruefung
- CDHash
- primaerer Startpfad
- validierter Erfolgsfall
- validierter negativer Fall
- externe Testanleitung
- nicht umgesetzt
- bekannte Risiken / Annahmen
- Testhinweise
- Rollback

---

## Zusaetzliche Repo-Datei fuer externe Tester

Lege oder aktualisiere zusaetzlich:

`docs/testing/008-external-test-instructions.md`

Diese Datei soll bewusst knapp, praktisch und nicht entwicklerlastig sein.

---

## Ausgabe von Codex

Bitte liefere am Ende:

1. den exakten Pfad der Auftragsumsetzung
2. den exakten Pfad der Results-Datei
3. den exakten Pfad der externen Testanleitung
4. die Liste aller real geaenderten Dateien
5. eine kurze Beschreibung, wie der Release Candidate jetzt gebaut und verpackt wird
6. eine kurze Beschreibung, welcher primaere Startpfad fuer die Validierung verwendet wurde
7. eine kurze Beschreibung, was bewusst noch nicht gebaut wurde

---

## Prioritaet bei Zielkonflikten

Wenn waehrend der Umsetzung Zielkonflikte auftreten, gilt diese Prioritaet:

1. klarer extern testbarer Release Candidate
2. Bundle mit gebundelten MVP-Ressourcen
3. primaerer gueltiger Produktstartpfad sauber dokumentiert
4. kleine Eingriffsflaeche im Code und Build
5. kein Scope-Ausbau in Notarisierung/Installer/Feature-Richtung