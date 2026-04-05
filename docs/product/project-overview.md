# Project Overview

## Projektname

**PushWrite**

**Claim:** Local voice input for macOS  
**Tech-Zusatz:** Powered by Whisper

## Zweck dieses Dokuments

Dieses Dokument hält den aktuellen, verbindlichen Projektrahmen von PushWrite fest.

Es dient dazu,

- das Produkt in einem Satz klar zu definieren
- den Fokus des MVP sauber abzugrenzen
- getroffene Grundsatzentscheide zentral festzuhalten
- spätere Architektur- und Umsetzungsdokumente auf eine stabile Basis zu stellen

Dieses Dokument ist **keine** Detail-Spezifikation und **kein** Implementierungsauftrag.  
Es beschreibt den gemeinsamen Referenzrahmen, auf den sich Produkt-, Architektur- und Umsetzungsentscheidungen beziehen.

## Kurzbeschreibung

PushWrite ist eine lokal laufende, offline-fähige Open-Source-Software für macOS, die gesprochene Sprache per globalem Hotkey aufnimmt, lokal in Text umwandelt und den erkannten Text direkt an der aktuellen Cursor-Position einfügt.

## Produktziel

PushWrite wird als systemweites Spracheingabe-Werkzeug für macOS entwickelt.

Das Produkt soll in typischen Texteingabesituationen eine direkte Alternative zur Tastatureingabe bieten. Der Kernnutzen liegt nicht in allgemeiner Audioverarbeitung, sondern in schneller, lokaler, praktischer Sprache-zu-Text-Eingabe im laufenden Arbeitskontext.

## Aktueller Fokus

Der aktuelle Fokus liegt ausschliesslich auf einem klar begrenzten macOS-MVP.

Priorität hat ein stabiler Kernablauf:

1. globalen Hotkey drücken
2. Aufnahme starten
3. sprechen
4. Aufnahme beenden
5. lokal transkribieren
6. Text an Cursorposition einfügen

## MVP-Definition (Version 0.1.0)

Version `0.1.0` ist das erste bewusst eng geschnittene Produktinkrement.

### Im Scope

- globaler Push-to-talk-Hotkey
- Mikrofonaufnahme unter macOS
- lokale Sprach-zu-Text-Transkription
- direktes Einfügen des erkannten Textes an der aktuellen Cursor-Position
- nur die minimal nötigen Einstellungen für den Kernablauf

### Nicht im Scope

- Datei-Transkription
- MP3-/MP4-/Audio-/Video-Import
- Cloud-Transkription
- Windows-Support
- Linux-Support
- iOS- oder Android-Versionen
- erweiterte Editierfunktionen
- Multi-Engine-Architektur
- Optimierung auf zukünftige Plattformen vor dem stabilen macOS-MVP

## Plattformentscheidung

PushWrite startet ausschliesslich auf **macOS**.

Diese Einschränkung ist bewusst gewählt.  
Die Produktentwicklung erfolgt strikt sequenziell. Spätere Plattformen sind strategische Optionen, aber kein aktueller Architekturtreiber für das MVP.

## Technologieentscheidung

Für das macOS-MVP wird **`whisper.cpp`** als technische Basis für die lokale Sprach-zu-Text-Inferenz verwendet.

### Einordnung

- Die Whisper-Modelle von OpenAI bleiben die inhaltliche Modellbasis.
- Das offizielle OpenAI-Whisper-Repository wird als Referenz und Modellquelle verstanden.
- Die primäre Inferenz-Runtime für das Produkt soll jedoch auf `whisper.cpp` aufbauen.

### Begründung auf Projektebene

`whisper.cpp` passt besser zum konkreten Produktziel, weil die Basis für das MVP lokal, offline-fähig, systemnah integrierbar und für eine native macOS-Anwendung praktikabler ist als ein Python-/Torch-zentrierter Produktansatz.

## Wichtige Abgrenzung

`whisper.cpp` ist **nicht** die ganze App.

Folgende Teile müssen im Produkt separat entworfen und umgesetzt werden:

- globaler Hotkey
- Mikrofonsteuerung
- Berechtigungen unter macOS
- Zustands- und Fehlerbehandlung
- direktes Einfügen des Textes an der Cursor-Position

Die Inferenz-Basis und der macOS-App-Layer sind deshalb getrennt zu betrachten.

## Architekturprinzipien

Für PushWrite gelten aktuell diese Leitprinzipien:

- Core-Logik so weit wie sinnvoll von Plattformlogik trennen
- macOS-spezifische Funktionen klar im App-Layer halten
- keine vorzeitige Abstraktion für hypothetische spätere Plattformen
- Produktklarheit vor Funktionsbreite
- Stabilität vor Komfortfunktionen
- MVP-Scope aktiv schützen

## Zielbild des Produkts

PushWrite soll als kleines, professionell aufgebautes, lokal laufendes Werkzeug funktionieren, das sich im Alltag unaufdringlich verhält und genau einen Kernnutzen zuverlässig erfüllt:

**sprechen statt tippen – direkt im aktuellen Texteingabekontext**

## Open-Source-Rahmen

PushWrite wird als eigenständiges Open-Source-Projekt aufgebaut.

GitHub dient dabei als zentrale Plattform für:

- Repository
- Dokumentation
- Entwicklung
- Releases
- spätere Beitragsprozesse

## Aktueller Projektstatus

Das Projekt befindet sich in der **Fundamentphase**.

Das bedeutet:

- Grundsatzentscheidungen wurden getroffen
- Produktname und Positionierung sind festgelegt
- der MVP ist inhaltlich eingegrenzt
- die technische Basis ist vorentschieden
- die eigentliche Umsetzungsstruktur wird jetzt dokumentiert und vorbereitet

## Nächste Dokumente

Auf dieses Dokument sollen als Nächstes aufbauen:

- `mvp-definition.md`
- `technical-decisions.md`
- `system-components.md`
- `risks-open-questions.md`
- `codex-briefs.md`

## Änderungsregel

Dieses Dokument soll nur angepasst werden, wenn sich einer der folgenden Punkte tatsächlich ändert:

- Produktkern
- Plattformfokus
- MVP-Grenze
- Technologie-Grundsatzentscheid
- Architekturprinzipien auf Projektebene

Detailfragen und Umsetzungsfragen gehören nicht in dieses Dokument, sondern in die nachgelagerten Spezifikationen.