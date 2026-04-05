# Technical Decisions

## Zweck dieses Dokuments

Dieses Dokument hält die aktuell verbindlichen technischen Grundsatzentscheide für PushWrite fest.

Es dokumentiert:

- getroffene technische Entscheidungen
- Begründungen auf Produktebene
- bewusste Abgrenzungen
- daraus folgende Architekturkonsequenzen

Dieses Dokument ist **keine** vollständige Systemarchitektur und **kein** Implementierungsplan.  
Es beschreibt nur jene technischen Leitplanken, die für alle nachgelagerten Architektur- und Umsetzungsdokumente verbindlich sind.

---

## Decision 001: macOS als einzige Zielplattform für v0.1.0

### Status
**Entschieden**

### Entscheidung
Für Version `0.1.0` wird PushWrite ausschliesslich für **macOS** entwickelt.

### Begründung
Der MVP soll einen stabilen Kernworkflow liefern und nicht gleichzeitig mehrere Plattformen bedienen.  
Die technische Komplexität von globalem Hotkey, Mikrofonaufnahme, Berechtigungen und Texteinfügung ist bereits auf einer einzelnen Plattform hoch genug.

### Konsequenz
- Architektur und Implementierung werden auf macOS optimiert
- keine Multiplattform-Abstraktion im MVP
- keine technische Vorwegnahme von Windows, Linux oder Mobile
- plattformspezifische Entscheidungen dürfen bewusst macOS-nah sein

### Explizit nicht entschieden
- keine Festlegung für spätere Windows- oder Linux-Architektur
- keine Vorentscheidung für mobile Plattformen

---

## Decision 002: Lokale Inferenz statt Cloud-basierter Standardverarbeitung

### Status
**Entschieden**

### Entscheidung
Die Sprach-zu-Text-Verarbeitung im MVP soll lokal auf dem Gerät stattfinden.

### Begründung
Lokale Verarbeitung ist Teil des Produktversprechens. PushWrite soll als offline-fähiges, systemnahes Spracheingabe-Werkzeug funktionieren und nicht von einer externen Online-Transkriptionsinfrastruktur abhängen.  [oai_citation:3‡ANALYSE-whisper-vs-whisper-cpp-macos-mvp.md](sediment://file_00000000c37872469f9f2f33a0827004)

### Konsequenz
- der Standardpfad des Produkts ist offline-fähig
- Modellhandling und Runtime müssen lokal kontrollierbar sein
- die Architektur darf keine Pflichtabhängigkeit zu einem Cloud-Service enthalten

### Explizit nicht entschieden
- keine Aussage über mögliche spätere optionale Online-Funktionen
- keine Aussage über Telemetrie, sofern sie den Kernworkflow nicht betrifft

---

## Decision 003: `whisper.cpp` als bevorzugte Inferenz-Basis für das macOS-MVP

### Status
**Entschieden**

### Entscheidung
Für PushWrite v0.1.0 wird **`whisper.cpp`** als bevorzugte technische Basis für die lokale Sprach-zu-Text-Inferenz verwendet.  [oai_citation:4‡ANALYSE-whisper-vs-whisper-cpp-macos-mvp.md](sediment://file_00000000c37872469f9f2f33a0827004)

### Begründung
Die zugrunde liegende Analyse kommt zum Schluss, dass `whisper.cpp` für den konkreten Use Case die passendere Produktbasis ist als das offizielle `openai/whisper`-Repository. Ausschlaggebend sind insbesondere:

- besserer Fit für lokale und offline-fähige Nutzung
- produktnähere Einbettung in eine native macOS-Anwendung
- C/C++- und Apple-nahe Integrationspfade
- Apple-Silicon-Optimierungen
- kontrollierbarere Runtime und Abhängigkeiten
- vorhandene Mic-/Streaming-Beispiele als Integrationshilfe  [oai_citation:5‡ANALYSE-whisper-vs-whisper-cpp-macos-mvp.md](sediment://file_00000000c37872469f9f2f33a0827004)

### Konsequenz
- Inferenzschicht wird um `whisper.cpp` herum gedacht
- Modellbereitstellung muss mit dem `whisper.cpp`-Runtime-Pfad zusammenpassen
- direkte Python-/Torch-Produktintegration ist nicht der Primärpfad

### Explizit nicht entschieden
- noch keine finale Modellgrösse
- noch keine finale Entscheidung zwischen CPU-only, Metal oder optional Core ML
- noch keine Aussage zur genauen Packaging-Strategie der Modelle

---

## Decision 004: OpenAI Whisper bleibt Modellreferenz, aber nicht primäre Produktruntime

### Status
**Entschieden**

### Entscheidung
Das offizielle `openai/whisper`-Repository wird als Modellreferenz und fachlicher Upstream verstanden, jedoch nicht als primäre Runtime-Basis für das macOS-MVP.  [oai_citation:6‡ANALYSE-whisper-vs-whisper-cpp-macos-mvp.md](sediment://file_00000000c37872469f9f2f33a0827004)

### Begründung
Die Analyse trennt klar zwischen **Modellfamilie** und **Produktruntime**.  
Die OpenAI-Whisper-Modelle bleiben inhaltlich relevant, aber das offizielle Repository ist für diesen Use Case stärker Python-, Datei- und Referenz-orientiert und weniger passend als direkte Basis für ein lokal installiertes, systemnahes macOS-Produkt.  [oai_citation:7‡ANALYSE-whisper-vs-whisper-cpp-macos-mvp.md](sediment://file_00000000c37872469f9f2f33a0827004)

### Konsequenz
- `openai/whisper` ist Referenz, nicht Kern der App-Runtime
- technische Entscheidungen im MVP werden nicht auf eine Python-/Torch-Produktarchitektur ausgerichtet
- spätere Verwechslung von Modellquelle und Runtime soll aktiv vermieden werden

### Explizit nicht entschieden
- keine Aussage gegen Experimente ausserhalb des Produktkerns
- keine Aussage über spätere interne Vergleichstests

---

## Decision 005: Inferenz-Layer und macOS-App-Layer werden getrennt betrachtet

### Status
**Entschieden**

### Entscheidung
Die Inferenz-Basis und der macOS-spezifische Anwendungsteil werden architektonisch getrennt betrachtet.

### Begründung
`whisper.cpp` löst nicht den vollständigen Produktfall. Globaler Hotkey, Mikrofonsteuerung, Berechtigungen, Zustandsführung und Texteinfügung an der Cursor-Position gehören nicht zur Inferenz-Engine, sondern zum App-Layer. Die Analyse benennt diese Trennung explizit.  [oai_citation:8‡ANALYSE-whisper-vs-whisper-cpp-macos-mvp.md](sediment://file_00000000c37872469f9f2f33a0827004)

### Konsequenz
- Systemarchitektur muss mindestens zwischen Inferenz und Plattformlogik unterscheiden
- Probleme im Bereich Hotkey, Berechtigungen oder Textinjektion dürfen nicht fälschlich der Inferenzschicht zugeschrieben werden
- Implementierungsaufträge müssen diese Trennung sauber abbilden

### Zum App-Layer gehören insbesondere
- globaler Hotkey
- Mikrofonaufnahme
- Berechtigungsmanagement unter macOS
- Zustands- und Fehlerbehandlung
- direkte Texteinfügung am Cursor

### Explizit nicht entschieden
- noch keine finale Modulstruktur
- noch keine Klassen- oder Dateistruktur
- noch keine konkrete Wahl des UI-Ansatzes

---

## Decision 006: Keine Multi-Engine-Architektur im MVP

### Status
**Entschieden**

### Entscheidung
PushWrite v0.1.0 verfolgt keine abstrakte Multi-Engine-Architektur.

### Begründung
Der Produktfokus ist eng, und das README hält diesen Fokus bereits fest: ein Produkt, eine Plattform, ein Kernworkflow, kein vorzeitiger Ausbau in Richtung mehrerer Engines.  [oai_citation:9‡README.md](sediment://file_000000003bec720a920b279259486e56)  
Eine frühe Abstraktion für hypothetische spätere Engines erhöht Komplexität, ohne dem MVP direkt zu helfen.

### Konsequenz
- keine generische Engine-Schnittstelle nur für spätere Optionen
- keine zusätzliche Abstraktionsschicht ohne unmittelbaren MVP-Nutzen
- Architektur darf konkret auf die gewählte Inferenzbasis zugeschnitten sein

### Explizit nicht entschieden
- keine Aussage, dass spätere Engine-Wechsel unmöglich sind
- keine Aussage gegen spätere Refaktorierung nach stabiler Version

---

## Decision 007: Keine Datei-Transkription im MVP

### Status
**Entschieden**

### Entscheidung
Datei-Transkription ist kein Bestandteil der technischen Zielarchitektur von v0.1.0.

### Begründung
Der MVP ist auf systemweite Spracheingabe ausgerichtet, nicht auf allgemeine Audioverarbeitung. README und MVP-Scope grenzen Datei-Transkription explizit aus.  [oai_citation:10‡README.md](sediment://file_000000003bec720a920b279259486e56)

### Konsequenz
- Architekturentscheidungen werden nicht auf Batch- oder Datei-Workflows optimiert
- Audiofluss des MVP wird aus Live-Aufnahme gedacht
- keine Dateiverwaltung als Produktkern

### Explizit nicht entschieden
- keine Aussage gegen spätere Erweiterung nach MVP-Stabilisierung

---

## Decision 008: Keine vorzeitige Multiplattform- oder Zukunftsabstraktion

### Status
**Entschieden**

### Entscheidung
Technische Entscheidungen im MVP werden nach aktuellem Nutzen für das macOS-Produkt getroffen, nicht nach hypothetischen späteren Plattformen.

### Begründung
Der aktuelle Scope ist absichtlich eng. Vorzeitige Generalisierung erhöht Komplexität, erschwert Entscheidungen und verwässert die Umsetzungsprioritäten. README und Analyse stützen genau diese Begrenzung. 

### Konsequenz
- pragmatische Entscheidungen sind zulässig, wenn sie den MVP schneller zu einem stabilen Kernworkflow führen
- spätere Plattformoffenheit ist kein eigenständiger Architekturtreiber
- “später vielleicht” ist kein Entscheidungsgrund für zusätzliche technische Schichten

### Explizit nicht entschieden
- keine Aussage gegen spätere Modularisierung, wenn sie aus realem Bedarf entsteht

---

## Offene technische Punkte, die bewusst noch nicht entschieden sind

Diese Punkte sind relevant, aber aktuell **noch keine Grundsatzentscheide**:

### 1. Modellwahl im Detail
Offen:
- `base.en` vs. `small.en`
- quantisierte Variante ja oder nein

### 2. Apple-Backend
Offen:
- CPU-only
- Metal
- optional Core ML für Encoder

### 3. Mechanismus der Textinjektion
Offen:
- konkrete technische Methode
- Robustheit über verschiedene Zielanwendungen hinweg

### 4. Berechtigungsfluss auf macOS
Offen:
- genaue UX und Reihenfolge für Mikrofon, Accessibility und weitere Rechte

### 5. Modell-Packaging
Offen:
- Modell im App-Bundle
- lokale Ressourcenablage ausserhalb des Bundles
- Update-Pfad der Modelldateien

### 6. Streaming-Strategie
Offen:
- press-and-hold
- start/stop-Verhalten
- Einfügezeitpunkt des Textes

Diese Punkte sind nachgelagerte Architektur- und Umsetzungsfragen, keine Gegenargumente gegen die bereits getroffenen Grundsatzentscheide.  [oai_citation:11‡ANALYSE-whisper-vs-whisper-cpp-macos-mvp.md](sediment://file_00000000c37872469f9f2f33a0827004)

---

## Nicht Teil dieses Dokuments

Dieses Dokument entscheidet **nicht**:

- konkrete Ordner- oder Klassenstruktur
- genaue Modulgrenzen
- UI-Design
- Teststrategie im Detail
- konkrete Codex-Arbeitspakete

Diese Themen gehören in:

- `system-components.md`
- `risks-open-questions.md`
- `codex-briefs.md`

---

## Änderungsregel

Dieses Dokument darf nur angepasst werden, wenn sich mindestens einer dieser Punkte ändert:

- Zielplattform von v0.1.0
- Grundsatz der lokalen Inferenz
- Wahl der bevorzugten Inferenz-Basis
- Trennung zwischen Inferenz-Layer und App-Layer
- Verzicht auf Multi-Engine-Architektur im MVP
- technische Scope-Grenzen des MVP