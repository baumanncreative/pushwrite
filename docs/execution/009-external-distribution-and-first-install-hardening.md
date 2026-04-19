# Auftrag für Codex 009: Externe Distribution und Erstinstallationshaertung fuer PushWrite

## Ziel

Haerte den bestehenden Release-Candidate-Stand von PushWrite fuer **externe Tester auf einem fremden Mac**.

Der Auftrag dient dazu, die aktuelle Luecke zwischen:

- intern validiertem Release Candidate
- und realistisch weitergebbarem externem Teststand

zu schliessen.

009 dient **nicht** dazu, neue Produktfunktionen zu bauen.
009 dient dazu, Distribution, Erstinstallation, Erststart und Testfuehrung fuer externe Tester sauber zu schneiden und nachvollziehbar zu dokumentieren.

---

## Ausgangslage

Der Stand vor 009 ist:

- es gibt einen reproduzierbaren Release Candidate:
  - `PushWrite-v0.1.0-rc1`
- es gibt ein weitergebbares ZIP-Artefakt
- das Produktbundle enthaelt die benoetigten Whisper-Ressourcen
- der primaere gueltige Produktstartpfad ist dokumentiert:
  - LaunchServices-API (`NSWorkspace.openApplication`)
- ein Erfolgsfall und ein negativer Fall wurden fuer den RC validiert
- eine erste externe Testanleitung existiert bereits

Was noch fehlt, ist eine saubere Haertung fuer die reale Aussenperspektive:

- Was bekommt ein externer Tester genau?
- Wie installiert und startet er die App erstmalig?
- Welche Hinweise gelten fuer einen nicht voll distributionsgehaerteten Stand?
- Welche Schritte sind Pflicht, welche nur Debug?
- Wie meldet ein externer Tester Probleme, ohne Dev-Kontext zu brauchen?

Genau diese Luecke soll 009 schliessen.

---

## Verbindliche Produktentscheidung fuer diesen Auftrag

Fuer 009 gilt verbindlich:

- Zielplattform bleibt **nur macOS**
- Fokus bleibt **nur MVP 0.1.0**
- der bestehende Produktfluss bleibt fachlich unveraendert
- 009 baut **keine** neue Transkriptionslogik
- 009 baut **keine** neue Insert-Logik
- 009 baut **keine** neue Feedback-Logik
- 009 baut **keine** neue Accessibility-Architektur
- 009 baut **keine** Notarisierung
- 009 baut **keinen** `.pkg`-Installer
- 009 baut **kein** DMG-Design
- 009 baut **keine** GitHub-Release-Automatisierung
- Fokus ist:
  - externe Verteilbarkeit
  - Erstinstallationsklarheit
  - Erststartklarheit
  - saubere Testerfuehrung
  - saubere Problemrueckmeldung

---

## Problemrahmen

Nach 008 ist PushWrite intern gut release-candidate-faehig.
Aber fuer echte externe Tester bleiben typische Reibungspunkte offen:

- ZIP erhalten und entpacken
- App an einen sinnvollen Ort bewegen
- erster Start auf einem fremden Mac
- Umgang mit Berechtigungen
- Trennung zwischen gueltigem Produktpfad und Debug-Hilfen
- Rückmeldung, welche Logs oder Dateien bei Problemen gebraucht werden
- Dokumentation der aktuellen Distributionsrealitaet ohne falsche Versprechen

Die zentrale Frage von 009 lautet:

**Kann ein externer Tester ohne Repo-Kontext den RC erhalten, installieren, starten, einen Minimaltest durchfuehren und bei Problemen brauchbare Rueckmeldung geben?**

---

## Umsetzungsziel

Implementiere einen kleinen, kontrollierten Distributions- und Erstinstallationsschritt fuer externe Tester.

Am Ende dieses Auftrags soll es geben:

1. eine klare externe Erstinstallations-Checkliste
2. eine kleine Release-/Distributions-Info fuer den konkreten RC
3. eine schlanke technische Erstinstallationsvalidierung
4. eine saubere Trennung zwischen primaerem Produktpfad und sekundaeren Debug-Pfaden
5. klare Hinweise, welche Problemdaten externe Tester liefern sollen

---

## Verbindlicher Scope

### In Scope

- bestehenden RC-Stand fuer externe Tester dokumentarisch und prozessual schaerfen
- eine klare Erstinstallations-Checkliste fuer externe Tester anlegen oder verbessern
- eine kleine distributionsnahe Release-Info erzeugen
- eine technische Erstinstallationsvalidierung durchfuehren oder erweitern
- dokumentieren, welcher primaere Produktstartpfad fuer externe Tester gueltig ist
- dokumentieren, welche Artefakte oder Logs bei Problemen gebraucht werden
- persistierte Results-Datei im Repo anlegen oder aktualisieren

### Nicht in Scope

- neue Produktfeatures
- neue Hotkey-Modelle
- neue Accessibility-Architektur
- neue Insert-Strategie
- Notarisierung
- `.pkg`-Installer
- DMG-Design
- Auto-Update
- GitHub-Release-Automatisierung
- neue UI-Flaechen
- Mehrmodell-Management
- Datei-Transkription
- Multiplattform-Unterstuetzung

---

## Verbindliche Kernfrage

Die zentrale Frage von 009 lautet:

**Ist der aktuelle RC fuer einen externen Tester praktisch genug vorbereitet, dass Erstinstallation und Ersttest ohne verstecktes Dev-Wissen moeglich sind?**

Nicht gesucht ist:
- neue Produktfunktion
- neue Build-Architektur
- neue Vertriebsplattform

Gesucht ist:
- klare externe Testfaehigkeit

---

## Erwartete Artefakte von 009

Bitte erzeuge oder aktualisiere mindestens diese drei Ebenen:

### 1. Externe Erstinstallations-Checkliste
Pfad:
`docs/testing/009-external-first-install-checklist.md`

Diese Datei soll fuer einen externen Tester lesbar sein und mindestens enthalten:

- was er erhaelt
- wie er das ZIP entpackt
- wo die App sinnvoll abgelegt wird
- wie der erste Start erfolgt
- welche Berechtigungen relevant sind
- wie ein kurzer Erfolgsfall getestet wird
- wie ein kurzer negativer Fall getestet wird
- was bei Problemen zurueckgemeldet werden soll

### 2. Kleine distributionsnahe Release-Info
Entweder als eigene kleine Datei oder als klar dokumentierter Teil des RC-Outputs.

Mindestens dokumentieren:

- RC-Name
- Artefaktname
- Bundle-Identifier
- Version / RC-Kennung
- CDHash
- SHA256 des ZIP-Artefakts, falls bereits vorhanden oder klein erzeugbar
- gebundeltes Modell
- gebundelter whisper-CLI-Pfad
- primaerer gueltiger Produktstartpfad
- bekannte Distributionsgrenzen dieses Standes

### 3. Technische Erstinstallationsvalidierung
Ein schlanker, reproduzierbarer Validierungsschritt fuer:

- entpacktes ZIP
- vorhandenes `.app`
- Bundle-/Ressourcenvollstaendigkeit
- produktnahen Erststart
- einen Erfolgspfad
- einen negativen Pfad

Falls bestehende Skripte dafuer schon geeignet sind, bitte bevorzugt weiterverwenden und nur klein erweitern.

---

## Verbindliche Trennung von primaer und sekundaer

Bitte halte fuer 009 weiterhin strikt getrennt:

### Primaer (gueltig)
- Release-Candidate-Bundle
- produktnaher Startpfad
- LaunchServices-Start ueber den gueltigen Produktpfad
- dokumentierter CDHash
- produktnaher Erfolgs- und Negativtest

### Sekundaer (Debug)
- Direct-/Control-Starts
- Repo-Fallbacks
- Dev-Overrides
- manuelle Diagnosepfade
- kein Ersatz fuer den primaeren externen Testnachweis

Wenn fuer die technische Validierung Hilfsskripte genutzt werden, muss klar bleiben:
- was davon nur Teststeuerung ist
- und was als gueltiger Produktbefund zaehlt

---

## Verbindliche Inhalte der externen Checkliste

Die externe Checkliste soll bewusst klein, praktisch und nicht entwicklerlastig sein.

Sie muss mindestens diese Fragen beantworten:

1. **Was erhalte ich?**
2. **Wie entpacke ich die App?**
3. **Wo lege ich die App ab?**
4. **Wie starte ich sie beim ersten Mal?**
5. **Welche Berechtigungen sind fuer den Test relevant?**
6. **Wie pruefe ich in 1-2 Minuten, dass der Erfolgsfall funktioniert?**
7. **Wie pruefe ich in 1-2 Minuten einen negativen Fall?**
8. **Welche Informationen soll ich bei einem Fehler zurueckmelden?**
9. **Was ist bekannte Grenze dieses RC-Stands?**

Bitte keine Entwicklerabhandlung schreiben.
Die Datei soll direkt an einen externen Tester gegeben werden koennen.

---

## Verbindliche Problemrueckmeldung fuer externe Tester

Bitte definiere fuer 009 klar, welche Rueckmeldung ein externer Tester bei Problemen liefern soll.

Mindestens sinnvoll:

- macOS-Version
- verwendeter RC-Name
- ob App entpackt und gestartet werden konnte
- ob Mikrofonberechtigung erteilt wurde
- ob Accessibility benoetigt und erteilt wurde
- beobachteter Erfolgs- oder Fehlerfall
- relevante Log-/Response-Datei oder deren Pfad, falls vorhanden
- Screenshot nur wenn er den Befund wirklich erklaert

Bitte klein und praktikabel halten.

---

## Release-/Distributionsgrenzen ehrlich dokumentieren

Bitte dokumentiere ehrlich, was dieser RC **noch nicht** ist.

Zum Beispiel in sinngemaesser Form:

- kein notarisiertes Distributionsprodukt
- kein finaler Installer
- kein Auto-Update
- RC fuer kontrollierte externe Tests, nicht fuer breite Endnutzerverteilung

Wichtig:
- keine falschen Release-Versprechen
- keine irrefuehrende „fertig fuer alles“-Sprache

---

## Beobachtbarkeit

Bitte fuehre keine neue grosse Observability-Familie ein.

Wenn moeglich:

- bestehende Response-/State-/Validation-Artefakte weiterverwenden
- nur klein ergaenzen, wo externe Testbarkeit sonst unscharf bleibt

Wichtig ist:
- ein externer Tester muss nicht alle Logs verstehen
- aber wir muessen intern wissen, welche Artefakte wir im Problemfall brauchen

---

## Fehler- und Randfaelle

Mindestens diese Faelle muessen sauber behandelt oder dokumentiert werden:

### 1. ZIP laesst sich verteilen, aber Erststart ist fuer externe Tester unklar
Erwartung:
- Checkliste nachschaerfen
- kein stilles Dev-Wissen voraussetzen

### 2. RC funktioniert nur mit Dev-Overrides
Erwartung:
- das waere fuer 009 ein Fehlschlag
- externer Testpfad muss ohne explizite externe Whisper-Pfade erklaerbar sein

### 3. Primaerer Produktstartpfad ist dokumentiert, aber externe Anleitung verweist implizit auf Debug-Pfade
Erwartung:
- korrigieren
- primaer und sekundaer klar trennen

### 4. Negative Faelle sind intern testbar, fuer externe Tester aber nicht klar pruefbar
Erwartung:
- minimalen Negativfall so beschreiben, dass er ohne Dev-Kontext nachvollziehbar bleibt

### 5. Checkliste wird zu technisch
Erwartung:
- reduzieren
- auf externen Tester zuschneiden

---

## Akzeptanzkriterien

Der Auftrag ist erfuellt, wenn Folgendes belegbar ist:

1. Es gibt eine klare externe Erstinstallations-Checkliste.
2. Der RC ist fuer externe Tester als konkretes Artefakt beschrieben.
3. Der primaere gueltige Produktstartpfad ist klar dokumentiert.
4. Ein externer Tester braucht fuer den Basis-Test keinen Repo-Kontext.
5. Ein Erfolgsfall ist fuer externe Tester knapp beschreibbar.
6. Ein negativer Fall ist fuer externe Tester knapp beschreibbar.
7. Problemrueckmeldung ist klar definiert.
8. Es wurde keine neue Produktlogik eingefuehrt.
9. Die Results-Datei dokumentiert reale Artefakte, reale Pfade und reale Erstinstallationsvalidierung.

---

## Testhinweise, die Codex liefern soll

Bitte liefere am Ende:

1. exakten Pfad des RC-Bundles
2. exakten Pfad des ZIP-Artefakts
3. exakten Pfad der externen Erstinstallations-Checkliste
4. exakten primaeren Produktstartpfad fuer den RC
5. welche Datei oder welcher Abschnitt die Distributionsgrenzen dokumentiert
6. welcher Erfolgsfall fuer externe Tester beschrieben ist
7. welcher negative Fall fuer externe Tester beschrieben ist
8. welche Dateien real geaendert wurden

---

## Persistierte Repo-Dokumentation ist Pflicht

Lege oder aktualisiere zusaetzlich eine Results-Datei im Repo unter genau diesem Pfad:

`docs/execution/009-results-external-distribution-and-first-install-hardening.md`

Diese Datei muss den **tatsaechlich umgesetzten Stand** dokumentieren, nicht nur den Auftrag wiederholen.

Mindestens enthalten:

- Status
- Kurzfassung
- geaenderte Dateien
- RC-Pfad
- ZIP-Pfad
- primaerer Produktstartpfad
- externe Erstinstallations-Checkliste
- definierte Problemrueckmeldung
- validierter Erfolgsfall
- validierter negativer Fall
- dokumentierte Distributionsgrenzen
- nicht umgesetzt
- bekannte Risiken / Annahmen
- Testhinweise
- Rollback

---

## Zusaetzliche Repo-Datei fuer externe Tester

Lege oder aktualisiere zusaetzlich:

`docs/testing/009-external-first-install-checklist.md`

Diese Datei soll:
- kurz
- praktisch
- nicht entwicklerlastig
- direkt weitergebbar

sein.

---

## Ausgabe von Codex

Bitte liefere am Ende:

1. den exakten Pfad der Auftragsumsetzung
2. den exakten Pfad der Results-Datei
3. den exakten Pfad der externen Erstinstallations-Checkliste
4. die Liste aller real geaenderten Dateien
5. eine kurze Beschreibung, wie externe Tester jetzt durch Erstinstallation und Ersttest gefuehrt werden
6. eine kurze Beschreibung, welcher primaere Produktstartpfad fuer den RC gilt
7. eine kurze Beschreibung, was bewusst noch nicht gebaut wurde

---

## Prioritaet bei Zielkonflikten

Wenn waehrend der Umsetzung Zielkonflikte auftreten, gilt diese Prioritaet:

1. externer Tester kann den RC ohne Repo-Kontext praktisch pruefen
2. primaerer gueltiger Produktstartpfad bleibt klar dokumentiert
3. Distributionsgrenzen werden ehrlich benannt
4. kleine Eingriffsflaeche in Build, Doku und Validierung
5. kein Scope-Ausbau in Notarisierung/Installer/Feature-Richtung