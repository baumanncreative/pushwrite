# Auftrag für Codex 005: Lokales Transkript kontrolliert an den Insert-Pfad anbinden

## Ziel

Erweitere den bereits umgesetzten 004B-Stand so, dass ein **erfolgreiches lokales Transkriptionsresultat** kontrolliert an den bestehenden Textinsertions-Pfad angebunden wird.

Der Auftrag dient dazu, den MVP-Kern fuer PushWrite weiter zu schliessen:

- press-and-hold Aufnahme bleibt wie bisher bestehen
- lokale whisper.cpp-Transkription bleibt wie bisher bestehen
- nur ein erfolgreiches, brauchbares Transkript darf einen Insert-Versuch ausloesen
- Insert-Erfolg, Insert-Gate und Insert-Fehler muessen beobachtbar sein

Dieser Auftrag dient **nicht** dazu, neue UI-Flaechen, neue Diktiermodi, neue Accessibility-Strategien oder breite Editierlogik einzufuehren.

---

## Ausgangslage

Der Stand aus 004A und 004B ist:

- globaler Hotkey im Modell press-and-hold
- Hauptfluss im Hotkey-Pfad: `idle -> recording -> processing -> idle`
- Audio-Handoff nach Abschluss der Aufnahme ist vorhanden
- Aufnahmen werden als `empty`, `tooShort` oder `usable` klassifiziert
- fuer `usable` erfolgt lokale whisper.cpp-Transkription
- es gibt persistierte Transkriptionsresultate
- Cursor-Insert ist im 004B-Hotkey-Pfad noch nicht angebunden

Genau diese letzte Luecke soll 005 kontrolliert schliessen.

---

## Verbindliche Produktentscheidung fuer diesen Auftrag

Fuer 005 gilt verbindlich:

- Zielplattform bleibt **nur macOS**
- Fokus bleibt **nur MVP 0.1.0**
- Hotkey-Modell bleibt **press-and-hold**
- Inferenzbasis bleibt **whisper.cpp**
- 004A- und 004B-Pfade bleiben grundsaetzlich erhalten
- Insert darf nur aus einem **erfolgreichen** Transkriptionsresultat heraus versucht werden
- es wird **kein** zweiter konkurrierender Insert-Pfad gebaut
- Robustheit und Beobachtbarkeit sind wichtiger als Komfort

---

## Problemrahmen

Nach 004B liegt fuer brauchbare Aufnahmen lokal ein Transkriptionsresultat vor.

Der jetzt zu validierende Abschnitt ist:

1. Aufnahme abgeschlossen
2. Audio-Handoff erfolgt
3. lokale Transkription erfolgreich
4. Insert-Gate prueft, ob ein Insert-Versuch ueberhaupt zulaessig ist
5. falls zulaessig: kontrollierter Insert-Versuch
6. Resultat wird sauber persistiert
7. der Flow endet kontrolliert

005 soll damit den produktnahen Schritt schaffen:

**lokales Transkript vorhanden -> kontrollierter Insert-Versuch vorhanden**

---

## Umsetzungsziel

Implementiere einen kleinen, kontrollierbaren Insert-Schritt hinter dem bestehenden 004B-Transkriptionsresultat.

Am Ende dieses Auftrags soll fuer erfolgreiche und brauchbare Transkriptionsresultate ein Insert-Versuch erfolgen koennen, ohne den Scope unnoetig zu verbreitern.

Wichtig:

- nicht jedes Transkript fuehrt automatisch zu einem Insert
- es braucht einen klaren, engen Gate-Schritt
- Erfolg, Gate und Fehler muessen klar unterscheidbar sein
- der Ablauf darf nicht in `processing` haengen bleiben

---

## Verbindlicher Scope

### In Scope

- bestehenden 004B-Transkriptionspfad weiterverwenden
- nur fuer geeignete Resultate einen Insert-Versuch ausloesen
- bestehenden oder naheliegendsten vorhandenen Insert-Mechanismus im Projekt wiederverwenden
- minimale Insert-Result- oder Attempt-Persistenz einfuehren
- Beobachtbarkeit fuer Insert-Erfolg, Gate und Fehler erweitern
- kontrollierte Rueckkehr in den Abschluss
- persistierte Results-Datei im Repo anlegen oder aktualisieren

### Nicht in Scope

- neuer alternativer Insert-Stack
- neue Accessibility-Architektur
- neue Rechte-Dialog-Strategie
- Toggle-Modus
- VAD
- kontinuierlicher Diktiermodus
- Datei-Transkription
- UI-Polish
- Editier- oder Nachbearbeitungsfunktionen
- Multiplattform-Unterstuetzung
- breite Refactors fuer spaetere Zukunftsszenarien

---

## Verbindliche Kernregel fuer den Insert-Versuch

Ein Insert-Versuch darf nur erfolgen, wenn **alle** folgenden Bedingungen erfuellt sind:

1. das Transkriptionsresultat hat `status = succeeded`
2. `transcriptionAttempted = true`
3. der resultierende Text ist nicht leer
4. der resultierende Text ist nach einer minimalen Normalisierung nicht nur Leerraum

Wenn eine dieser Bedingungen nicht erfuellt ist, darf **kein** Insert-Versuch gestartet werden.
Stattdessen muss ein beobachtbarer Gate-Befund persistiert werden.

---

## Erwartete Insert-Gates

Bitte fuehre mindestens diese minimalen Gate-Faelle ein:

- `transcriptionSkipped`
- `transcriptionFailed`
- `emptyTranscriptionText`
- `whitespaceOnlyTranscriptionText`

Falls im bestehenden Code bereits passendere oder konsistentere Gate-Namen existieren, duerfen diese verwendet werden.
Wichtig ist:

- Gate-Faelle muessen klar von echten Insert-Fehlern getrennt sein
- Gate-Faelle muessen beobachtbar persistiert werden
- Gate-Faelle duerfen den Flow nicht haengen lassen

---

## Wiederverwendung bestehender Insert-Logik

Bitte baue **keinen neuen konkurrierenden Insert-Pfad**, wenn im Projekt bereits ein geeigneter Produkt-Insert-Mechanismus oder produktnaher Insert-Helfer existiert.

Anforderung:

- zuerst den vorhandenen Codepfad pruefen
- wenn sinnvoll moeglich: bestehenden Insert-Mechanismus eng wiederverwenden
- nur wenn technisch wirklich noetig: minimalen Adapter oder kleinen Glue-Code bauen

Nicht gewuenscht:

- parallele Insert-Implementierungen
- zweiter Insert-Mechanismus nur fuer den Hotkey-Pfad
- breite Insert-Abstraktionen fuer spaetere Plattformen

Bitte in der Results-Datei klar dokumentieren, **welcher** Insert-Pfad konkret verwendet oder angebunden wurde.

---

## Technische Ablaufregel

Der fachliche Ablauf fuer 005 soll so geschnitten sein:

`TranscriptionResult -> InsertGate -> InsertAttempt -> InsertResult -> Flow-Abschluss`

Dabei gilt:

- Gate vor Insert
- genau ein Insert-Versuch pro geeignetem Transkriptionsresultat
- keine mehrfachen automatischen Retries in diesem Auftrag
- Abschluss immer kontrolliert

---

## Minimale Normalisierung vor Insert

Vor dem Insert-Versuch darf eine **kleine, enge** Textnormalisierung erfolgen, aber nur soweit noetig, um offensichtliche Leerfaelle zu erkennen.

Erlaubt fuer 005:

- trimmen von fuehrenden und nachgestellten Leerzeichen
- Erkennung von nur-Whitespace-Text

Nicht gewuenscht in 005:

- aggressive Textumformung
- automatische Interpunktions- oder Formatierungslogik
- inhaltliche Nachbearbeitung
- Sprach- oder Stilkorrektur
- komplexe Prompting- oder Postprocessing-Stufen

---

## Persistierte Ergebnisartefakte

Bitte fuehre eine klare, kleine Persistierung fuer Insert-Ergebnisse ein.

Mindestens erwartet:

- ein Artefakt fuer das **letzte** Insert-Ergebnis
- ein Artefakt fuer die **historisierten** Insert-Ergebnisse

Empfohlene Form:
- `logs/last-insert-result.json`
- `logs/insert-results.jsonl`

Falls im Projekt bereits ein konsistenteres Namensschema existiert, darf dieses verwendet werden.
Wichtig ist:

- maschinenlesbar
- Erfolg, Gate und Fehler unterscheidbar
- Bezug auf `flowID` und Transkriptionsresultat vorhanden

---

## Mindestinhalt eines Insert-Ergebnisses

Das Insert-Ergebnis soll mindestens diese Informationen tragen:

- eindeutige ID oder Flow-ID
- Bezug auf das zugrunde liegende Transkriptionsresultat
- ob ein Insert-Versuch gestartet wurde
- ob der Fall `gated`, `succeeded` oder `failed` ist
- Gate-Grund oder Fehlergrund
- bei Erfolg: eingefuegte Textlaenge
- sinnvolle Zeitangaben fuer Start/Abschluss

Bitte klein halten.
Keine breite Telemetriestruktur bauen.

---

## Beobachtbarkeit

Erweitere die bestehende Beobachtbarkeit nur so weit, wie fuer 005 noetig.

Mindestens nachvollziehbar sein sollen:

- insert-gate-evaluated
- insert-gated
- insert-started
- insert-succeeded
- insert-failed
- processing-flow-completed

Wenn im bestehenden Event-Schema andere Namen besser passen, duerfen diese verwendet werden.
Wichtig ist nur, dass Gate, Erfolg und Fehler sauber getrennt sichtbar sind.

---

## Fehler- und Randfaelle

Mindestens diese Faelle muessen behandelt werden:

### 1. Transkriptionsresultat ist `skipped`
Erwartung:
- kein Insert-Versuch
- beobachtbarer Gate-Befund
- kontrollierter Abschluss

### 2. Transkriptionsresultat ist `failed`
Erwartung:
- kein Insert-Versuch
- beobachtbarer Gate-Befund
- kontrollierter Abschluss

### 3. Transkriptionsresultat ist `succeeded`, aber Text ist leer
Erwartung:
- kein Insert-Versuch
- Gate-Befund `emptyTranscriptionText`
- kontrollierter Abschluss

### 4. Transkriptionsresultat ist `succeeded`, aber Text ist nur Whitespace
Erwartung:
- kein Insert-Versuch
- Gate-Befund `whitespaceOnlyTranscriptionText`
- kontrollierter Abschluss

### 5. Insert-Versuch startet, aber der bestehende Insert-Mechanismus liefert Fehler
Erwartung:
- Fehlerbefund persistieren
- kein Haengenbleiben
- kontrollierte Rueckkehr in den Abschluss

### 6. Insert gelingt, aber der Ablauf bleibt in `processing`
Erwartung:
- aktiv verhindern
- sauberer Abschluss und Rueckkehr nach `idle`

---

## QA- und Scope-Abgrenzung

Dieser Auftrag soll **nicht** gleichzeitig die bekannte Accessibility-Trust-Drift loesen.

Falls fuer den Test Insert-/Accessibility-Bedingungen relevant sind:

- nur den bestehenden Produktpfad nutzen
- keinen neuen Berechtigungs-Workaround bauen
- keine neue Diagnose- oder Reparaturlogik fuer Rechte-Themen einfuehren

Dokumentiere stattdessen sauber, unter welchen Bedingungen der Insert-Test als gueltig bewertet wurde.

---

## Technische Leitplanken

- bestehende Projektstruktur respektieren
- keine breite Neustrukturierung
- vorhandene 004A- und 004B-Schnittstellen bevorzugt weiterverwenden
- Insert nur minimal anbinden
- keine hypothetische Zukunftsarchitektur
- keine neue Parallel-Implementierung
- kleine Eingriffsflaeche im Code bevorzugen

---

## Akzeptanzkriterien

Der Auftrag ist erfuellt, wenn Folgendes belegbar ist:

1. Ein erfolgreiches 004B-Transkriptionsresultat kann einen Insert-Versuch ausloesen.
2. `skipped`- und `failed`-Transkriptionsresultate fuehren zu keinem Insert-Versuch.
3. Leere oder nur-Whitespace-Transkripte fuehren zu einem Gate statt zu einem Insert-Versuch.
4. Es gibt ein persistiertes Artefakt fuer das letzte Insert-Ergebnis.
5. Es gibt ein historisiertes Artefakt fuer Insert-Ergebnisse.
6. Gate-, Erfolgs- und Fehlerfaelle sind unterscheidbar.
7. Der Ablauf bleibt kontrolliert und haengt nicht im `processing`-Pfad.
8. Es wird kein zweiter konkurrierender Insert-Pfad gebaut.
9. Die Umsetzung bleibt eng und fuehrt keine unnoetige Zusatzkomplexitaet ein.

---

## Testhinweise, die Codex liefern soll

Bitte liefere am Ende:

1. wie 005 gebaut und gestartet wird
2. wie ein erfolgreicher Insert-Fall lokal geprueft wird
3. wie ein Gate-Fall lokal geprueft wird
4. wie ein Insert-Fehlerfall lokal geprueft wird
5. welche Runtime-Artefakte danach vorhanden sein muessen
6. welcher konkrete Insert-Pfad oder Insert-Helfer verwendet wurde

---

## Persistierte Repo-Dokumentation ist Pflicht

Lege oder aktualisiere zusaetzlich eine Results-Datei im Repo unter genau diesem Pfad:

`docs/execution/005-results-controlled-transcript-insert-path.md`

Diese Datei muss den **tatsaechlich umgesetzten Stand** dokumentieren, nicht nur den Auftrag wiederholen.

Mindestens enthalten:

- Status
- Kurzfassung
- geaenderte Dateien
- technische Umsetzung
- verwendeter Insert-Pfad / Insert-Helfer
- Insert-Gates
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
4. eine kurze Beschreibung, wie das 004B-Transkriptionsresultat an den Insert-Pfad angebunden wurde
5. eine kurze Beschreibung, welche Gate-Regeln konkret umgesetzt wurden
6. eine kurze Beschreibung, was bewusst noch nicht gebaut wurde

---

## Prioritaet bei Zielkonflikten

Wenn waehrend der Umsetzung Zielkonflikte auftreten, gilt diese Prioritaet:

1. enger, kontrollierter Produktfluss
2. klare Gate-Regeln vor Insert
3. beobachtbarer Insert-Erfolg / Gate / Fehler
4. kleine Eingriffsflaeche im Code
5. erst danach Komfort oder Ausbaufaehigkeit