# Auftrag 001: Architektur- und Validierungsplan für PushWrite v0.1.0 auf macOS

## Ziel

Erstelle einen präzisen Architektur- und Validierungsplan für das MVP von PushWrite auf macOS.

Der Auftrag dient nicht dazu, die App bereits vollständig zu implementieren.  
Er dient dazu, die vorhandenen Produkt- und Architekturentscheidungen in eine sinnvolle, risikoorientierte technische Reihenfolge zu überführen.

Das Ergebnis soll so konkret sein, dass daraus direkt die nächsten kleinen Implementierungsaufträge abgeleitet werden können.

---

## Projektkontext

PushWrite ist ein lokal laufendes Open-Source-Werkzeug für macOS.

Der Kernworkflow des MVP ist:

1. Nutzer drückt einen globalen Hotkey
2. PushWrite startet eine Mikrofonaufnahme
3. Nutzer spricht
4. PushWrite beendet die Aufnahme
5. Die Sprache wird lokal transkribiert
6. Der erkannte Text wird direkt an der aktuellen Cursor-Position eingefügt

Der MVP ist absichtlich eng geschnitten.

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- Standardpfad ist lokaler, offline-fähiger Betrieb
- `whisper.cpp` ist die bevorzugte Inferenz-Basis
- Inferenz-Layer und macOS-App-Layer sind getrennt zu betrachten
- keine Datei-Transkription
- keine Multi-Engine-Architektur
- keine Windows-, Linux- oder Mobile-Vorbereitung
- keine vorzeitige Zukunftsabstraktion

---

## Zweck dieses Auftrags

Dieser Auftrag soll nicht „möglichst viel bauen“, sondern klären:

- in welcher Reihenfolge der MVP technisch sinnvoll umgesetzt werden soll
- welche Risiken zuerst validiert werden müssen
- welche Arbeitspakete klein und sinnvoll geschnitten sind
- welche Teile bewusst noch nicht gebaut werden sollen

---

## Konkreter Auftrag

Analysiere den beschriebenen MVP von PushWrite und liefere einen strukturierten Architektur- und Validierungsplan für die Umsetzung auf macOS.

Das Ergebnis soll den Weg von den bestehenden Entscheidungen hin zu einer kontrollierten Implementierungsreihenfolge beschreiben.

---

## Erwartetes Ergebnis

Liefere ein strukturiertes Dokument mit den folgenden Abschnitten:

### 1. Technische Ausgangslage
Kurze Einordnung der vorhandenen Produkt- und Architekturannahmen.

### 2. MVP-kritische Risiken
Welche technischen Risiken bedrohen den MVP direkt?

Besonders zu prüfen sind:
- Textinjektion an der Cursor-Position
- globale Hotkey-Steuerung
- macOS-Berechtigungen
- Zusammenspiel von Aufnahme, Transkription und Einfügen

### 3. Frühe Validierungspunkte
Welche Punkte müssen möglichst früh verifiziert werden, bevor grössere Implementierung sinnvoll ist?

### 4. Empfohlene Umsetzungsreihenfolge
Welche technische Reihenfolge ist sinnvoll?

Nicht nach Schönheitsprinzip, sondern nach:
- Risiko
- Blockadepotenzial
- MVP-Relevanz
- Abhängigkeitslogik

### 5. Empfohlene erste Arbeitspakete
Schneide die ersten Arbeitspakete so, dass sie:
- klein genug sind
- klar überprüfbar sind
- nicht mehrere Problemarten gleichzeitig mischen

### 6. Architekturgrenzen
Benenne ausdrücklich, was im MVP **nicht** gebaut oder abstrahiert werden soll.

### 7. Vorschlag für die nächsten 3 bis 5 Folgeaufträge
Formuliere daraus direkt kleine, konkrete Folgeaufträge für die Umsetzung.

---

## Anforderungen

Das Ergebnis muss:

- den engen MVP-Scope respektieren
- nur macOS betrachten
- `whisper.cpp` als gesetzte Inferenz-Richtung respektieren
- die Trennung zwischen Inferenz-Layer und macOS-App-Layer einhalten
- Risiken pragmatisch statt akademisch behandeln
- Abhängigkeiten sichtbar machen
- kleine, anschlussfähige Arbeitspakete vorschlagen
- so formuliert sein, dass daraus unmittelbar weitere Codex-Aufträge entstehen können

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- die vollständige Implementierung der App
- umfangreicher Produktcode
- UI-Design im Detail
- Multiplattform-Architektur
- Datei-Transkription
- Multi-Engine-Schnittstellen
- allgemeine Zukunftsarchitektur
- grosse Refaktorierungs- oder Framework-Vorschläge ohne MVP-Zwang

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Was kann den MVP direkt scheitern lassen?
2. Was muss vor grösserer Implementierung validiert werden?
3. Welche Pakete sind klein genug, um sauber umgesetzt und geprüft zu werden?
4. Welche technischen Ideen sind für später denkbar, aber jetzt bewusst auszuschliessen?

---

## Form der Antwort

Die Antwort soll:

- klar gegliedert sein
- mit kurzen Überschriften arbeiten
- keine unnötige Theorie enthalten
- keine vage Zukunftssprache verwenden
- konkrete, überprüfbare Vorschläge machen

Wenn Annahmen nötig sind, sollen sie als Annahmen markiert werden.

Wenn Unsicherheiten bleiben, sollen sie als offene Punkte benannt werden.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- eine klare technische Reihenfolge vorgeschlagen wird
- die grössten MVP-Risiken explizit benannt werden
- frühe Validierungspunkte klar priorisiert sind
- die ersten Arbeitspakete klein und logisch geschnitten sind
- klar gesagt wird, was vorerst nicht gebaut werden soll
- das Ergebnis direkt als Grundlage für Folgeaufträge verwendbar ist