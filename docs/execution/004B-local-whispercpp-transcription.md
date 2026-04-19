# Auftrag für Codex 004B: Lokale whisper.cpp-Transkription an den 004A-Handoff anbinden

## Ziel

Erweitere den bereits umgesetzten 004A-Prototypen so, dass der bestehende Audio-Handoff im macOS-Hotkey-Pfad an eine **lokale Transkription mit whisper.cpp** angebunden wird.

Der Auftrag dient dazu, den naechsten engen Produktschritt fuer PushWrite zu validieren:

- press-and-hold Aufnahme bleibt wie in 004A bestehen
- das aufgenommene Audio wird nach dem bestehenden Handoff lokal transkribiert
- das Transkript wird als beobachtbares Ergebnis persistiert
- es erfolgt **noch keine** Cursor-Textinjektion

Dieser Auftrag dient **nicht** dazu, bereits den finalen Insert-Pfad, UI-Polish, umfangreiche Modellverwaltung oder spaetere Komfortmodi zu bauen.

---

## Ausgangslage

Der Stand aus 004A ist:

- globaler Hotkey im Modell **press-and-hold**
- Hauptfluss **idle -> recording -> processing -> idle**
- Audio wird nach Stop an einen klaren Handoff-Punkt uebergeben
- Handoff-Artefakte und Runtime-Beobachtbarkeit existieren bereits
- leere / zu kurze / brauchbare Aufnahmen werden bereits technisch klassifiziert
- finale Whisper-Inferenz im Hotkey-Pfad ist noch nicht eingebaut
- finale Cursor-Textinjektion ist noch nicht eingebaut

Genau diese Luecke soll 004B schliessen.

---

## Verbindliche Produktentscheidung fuer diesen Auftrag

Fuer 004B gilt verbindlich:

- Zielplattform bleibt **nur macOS**
- Fokus bleibt **nur MVP 0.1.0**
- Inferenzbasis bleibt **whisper.cpp**
- 004A-Hotkey-Modell bleibt unveraendert
- 004A-Hauptfluss bleibt grundsaetzlich unveraendert
- gebaut wird **lokale Transkription nach dem bestehenden Handoff**
- **kein** Cursor-Insert in diesem Auftrag
- **keine** Datei-Transkription als eigener Produktpfad
- **keine** Toggle-, VAD- oder Continuous-Dictation-Erweiterung

---

## Problemrahmen

Nach 004A endet der Hotkey-Pfad technisch am Audio-Handoff.
Damit ist der Aufnahmefluss validiert, aber der Produktkern ist noch nicht bis zur lokalen Spracherkennung geschlossen.

Der jetzt zu validierende Abschnitt ist:

1. Audio-Handoff liegt vor
2. brauchbare Aufnahme wird lokal an whisper.cpp uebergeben
3. Transkription wird lokal ausgefuehrt
4. Resultat wird als beobachtbares Artefakt persistiert
5. Fehler oder Skip-Faelle bleiben kontrollierbar
6. der Hotkey-Flow endet weiterhin sauber

004B soll damit den produktnahen Zwischenschritt schaffen:
**Audio vorhanden -> lokales Transkript vorhanden**
ohne bereits den finalen Insert-Mechanismus zu beruehren.

---

## Umsetzungsziel

Implementiere einen kleinen, kontrollierbaren Transkriptionsschritt hinter dem bestehenden Audio-Handoff.

Am Ende dieses Auftrags soll fuer brauchbare Aufnahmen ein lokal erzeugtes Transkript vorliegen, das zur Laufzeit sauber persistiert und nachvollzogen werden kann.

Dabei gilt:

- die Transkription muss lokal erfolgen
- die Transkription muss auf whisper.cpp basieren
- das Ergebnis muss technisch beobachtbar sein
- der Ablauf darf bei Fehlern oder unbrauchbarem Audio nicht haengen bleiben

---

## Verbindlicher Scope

### In Scope

- bestehenden 004A-Handoff konsumieren
- brauchbare Aufnahmen lokal mit whisper.cpp transkribieren
- ein minimales Transkriptions-Resultatobjekt einfuehren oder nutzen
- Resultat und Fehler-/Skip-Befunde zur Laufzeit persistieren
- bestehende Beobachtbarkeit sinnvoll erweitern
- kontrollierter Rueckweg nach Abschluss oder Fehler
- persistierte Results-Datei im Repo anlegen oder aktualisieren

### Nicht in Scope

- Cursor-Textinjektion
- Accessibility-Insert-Mechanik
- Toggle-Modus
- VAD
- kontinuierlicher Diktiermodus
- Datei-Transkription als separates Feature
- Modell-Download-Manager
- umfangreiche UI-Erweiterung
- Multiplattform-Unterstuetzung
- breite Architektur fuer spaetere Ausbaustufen
- Performance-Optimierung ueber den minimal noetigen Grad hinaus

---

## Verbindliche Schnittstelle

Der bestehende Audio-Handoff aus 004A ist der Startpunkt.

Bitte verwende den bereits vorhandenen Handoff-Punkt als fachliche Eingangsgrenze.
Falls eine kleine technische Umformung noetig ist, darf sie vorgenommen werden, aber:

- kein neuer Parallelpfad
- kein zweites konkurrierendes Handoff-Modell
- keine unnötige Vorab-Abstraktion

Ziel ist ein klarer Ablauf:

`recordingArtifact -> handoff -> lokale whisper.cpp-Transkription -> persistiertes Transkriptionsresultat`

---

## Umgang mit Usability-Klassifikation

Die bestehende 004A-Klassifikation fuer Aufnahmen bleibt fuer 004B verbindlich wirksam.

Das bedeutet:

- `empty` -> keine Inferenz starten
- `tooShort` -> keine Inferenz starten
- `usable` -> lokale Inferenz starten

Fuer `empty` und `tooShort` soll **kein stilles Verschwinden** passieren.
Stattdessen muss ein beobachtbares Resultat oder Skip-Artefakt entstehen, das klar zeigt:

- warum keine Transkription ausgefuehrt wurde
- auf welche Aufnahme sich der Fall bezieht
- dass der Ablauf kontrolliert abgeschlossen wurde

---

## Transkriptionslogik

### Fuer brauchbare Aufnahmen

Fuer Aufnahmen mit Status `usable` gilt:

- lokale whisper.cpp-Transkription ausfuehren
- Transkript als String oder sauber strukturiertes Resultat persistieren
- Erfolgs-/Fehlerstatus festhalten
- den Hotkey-Flow danach kontrolliert abschliessen

### Fuer nicht brauchbare Aufnahmen

Fuer `empty` oder `tooShort` gilt:

- keine whisper.cpp-Inferenz ausfuehren
- Skip-/Blockierungsbefund persistieren
- kein haengender Processing-Zustand
- kontrollierte Rueckkehr in den Abschluss

---

## Modell- und Runtime-Regeln

Bitte halte die Modellanbindung fuer 004B bewusst eng.

Anforderungen:

- verwende die bestehende oder naheliegendste Integrationsmoeglichkeit fuer whisper.cpp im Projekt
- falls ein Modellpfad erforderlich ist, waehle den einfachsten kontrollierbaren Weg
- kein Downloader
- kein komplexes Modellmanagement
- kein Overengineering fuer spaetere Mehrmodell-Szenarien

Falls im Projekt bereits eine Konfiguration oder ein vorbereiteter Ort fuer das Modell existiert, nutze diesen bevorzugt.
Falls nicht, fuehre nur die minimal noetige, lokal nachvollziehbare Konfiguration ein.

Bitte dokumentiere klar:

- welches Modell fuer 004B verwendet wird
- wie der Pfad bestimmt wird
- welche Annahmen dafuer gelten

---

## Ergebnisartefakte

Bitte fuehre eine klare, kleine Persistierung fuer Transkriptionsresultate ein.

Mindestens erwartet:

- ein Artefakt fuer das **letzte** Transkriptionsresultat
- ein Artefakt fuer die **historisierten** Transkriptionsresultate

Empfohlene Form:
- `logs/last-transcription-result.json`
- `logs/transcription-results.jsonl`

Wenn im Projekt bereits ein konsistenteres Namensschema existiert, darf dieses verwendet werden.
Wichtig ist:

- der Pfad ist klar
- der Inhalt ist maschinenlesbar
- Erfolg, Fehler und Skip sind unterscheidbar
- Bezug zur Aufnahme bzw. Flow-ID ist enthalten

---

## Mindestinhalt eines Transkriptionsresultats

Das Resultat soll mindestens diese Informationen tragen:

- eindeutige ID oder Flow-ID
- Bezug auf die zugrunde liegende Aufnahme
- usability-Status der Aufnahme
- ob Transkription versucht wurde
- ob Transkription erfolgreich war
- falls erfolgreich: resultierender Text
- falls nicht erfolgreich: Fehler- oder Skip-Grund
- Zeitangaben fuer Start/Abschluss soweit im bestehenden Stil sinnvoll

Bitte klein halten.
Keine breite Telemetriestruktur bauen.

---

## Beobachtbarkeit

Erweitere die bestehende 004A-Beobachtbarkeit nur so weit, wie fuer 004B noetig.

Mindestens nachvollziehbar sein sollen:

- Audio-Handoff empfangen
- Transkription gestartet
- Transkription erfolgreich
- Transkription fehlgeschlagen
- Transkription bewusst uebersprungen
- Rueckkehr in den Abschluss

Wenn neue Eventnamen eingefuehrt werden, bitte klar und knapp halten.

---

## Fehler- und Randfaelle

Mindestens diese Faelle muessen behandelt werden:

### 1. Handoff liegt vor, aber Aufnahme ist `empty`
Erwartung:
- keine Inferenz
- Skip-Befund persistieren
- kein Haengenbleiben

### 2. Handoff liegt vor, aber Aufnahme ist `tooShort`
Erwartung:
- keine Inferenz
- Skip-Befund persistieren
- kein Haengenbleiben

### 3. Aufnahme ist `usable`, aber whisper.cpp kann nicht initialisiert werden
Erwartung:
- Fehlerbefund persistieren
- kein Haengenbleiben
- sauberer Abschluss

### 4. Modellpfad oder Modellressource fehlt
Erwartung:
- klarer Fehlerbefund
- keine stille Null-Antwort
- sauberer Abschluss

### 5. Inferenz startet, liefert aber kein brauchbares Resultat
Erwartung:
- Fehler oder leeres Resultat klar unterscheiden
- Befund persistieren
- sauberer Abschluss

### 6. Während Fehlern bleibt der Flow in `processing`
Erwartung:
- aktiv verhindern
- lieber enger schneiden als Recovery-Komplexitaet aufbauen

---

## Technische Leitplanken

- bestehende Projektstruktur respektieren
- keine breite Neustrukturierung
- keine hypothetische Zukunftsarchitektur
- nur minimal noetige neue Typen, Helper und Dateien
- vorhandene 004A-Schnittstellen bevorzugt weiterverwenden
- keine zweite konkurrierende Transkriptionspipeline einbauen

---

## Akzeptanzkriterien

Der Auftrag ist erfuellt, wenn Folgendes belegbar ist:

1. Der bestehende 004A-Handoff kann fuer `usable`-Aufnahmen eine lokale whisper.cpp-Transkription ausloesen.
2. Fuer `empty`- und `tooShort`-Aufnahmen wird keine Inferenz ausgefuehrt.
3. Es gibt ein persistiertes Artefakt fuer das letzte Transkriptionsresultat.
4. Es gibt ein historisiertes Artefakt fuer Transkriptionsresultate.
5. Erfolgs-, Fehler- und Skip-Faelle sind unterscheidbar.
6. Der resultierende Text ist fuer Erfolgsfaelle lokal nachvollziehbar gespeichert.
7. Der Ablauf bleibt kontrolliert und haengt nicht im Processing-Pfad.
8. Cursor-Insert ist weiterhin nicht Teil des Hotkey-Pfads.
9. Die Umsetzung bleibt eng und fuehrt keine unnötige Zusatzkomplexitaet ein.

---

## Testhinweise, die Codex liefern soll

Bitte liefere am Ende:

1. wie 004B gebaut und gestartet wird
2. wie eine brauchbare Testaufnahme ausgefuehrt wird
3. welche Runtime-Artefakte danach vorhanden sein muessen
4. wie ein erfolgreicher Transkriptionsfall aussieht
5. wie ein Skip-Fall (`empty` oder `tooShort`) aussieht
6. wie ein Fehlerfall aussieht

---

## Persistierte Repo-Dokumentation ist Pflicht

Lege oder aktualisiere zusaetzlich eine Results-Datei im Repo unter genau diesem Pfad:

`docs/execution/004B-results-local-whispercpp-transcription.md`

Diese Datei muss den **tatsaechlich umgesetzten Stand** dokumentieren, nicht nur den Auftrag wiederholen.

Mindestens enthalten:

- Status
- Kurzfassung
- geaenderte Dateien
- technische Umsetzung
- verwendeter Modellpfad / Modellannahme
- Beobachtbarkeit
- nicht umgesetzt
- bekannte Risiken / Annahmen
- Testhinweise
- Rollback

---

## Ausgabe von Codex

Bitte liefere am Ende:

1. den exakten Pfad der Auftragsumsetzung
2. den exakten Pfad der Results-Datei
3. die Liste aller real geaenderten Dateien
4. eine kurze Beschreibung, wie der bestehende 004A-Handoff an whisper.cpp angebunden wurde
5. eine kurze Beschreibung, was bewusst noch nicht gebaut wurde

---

## Prioritaet bei Zielkonflikten

Wenn waehrend der Umsetzung Zielkonflikte auftreten, gilt diese Prioritaet:

1. enger, kontrollierter Produktfluss
2. lokale beobachtbare Transkription
3. sauberer Abschluss ohne Haenger
4. kleine Eingriffsflaeche im Code
5. erst danach Komfort oder Ausbaufaehigkeit