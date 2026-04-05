# Auftrag 002: Textinjektion auf macOS für PushWrite v0.1.0 strukturieren

## Ziel

Erstelle eine präzise Machbarkeits- und Strukturierungsanalyse für die direkte Texteinfügung von PushWrite auf macOS.

Der Auftrag dient nicht dazu, die vollständige Textinjektion produktionsreif zu implementieren.  
Er dient dazu, die technisch tragfähigsten Wege für das Einfügen von transkribiertem Text an der aktuellen Cursor-Position zu identifizieren, zu vergleichen und für den MVP einzugrenzen.

Das Ergebnis soll so konkret sein, dass daraus direkt ein kleiner, sauber geschnittener Implementierungsauftrag für die erste technische Validierung oder Umsetzung abgeleitet werden kann.

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

Gerade Schritt 6 ist für den Produktkern kritisch.

PushWrite ist nicht als allgemeines Transkriptionswerkzeug gedacht, sondern als systemweites Spracheingabe-Werkzeug.  
Wenn die direkte Texteinfügung nicht tragfähig lösbar ist, ist der MVP in seiner aktuellen Form gefährdet.

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- Betrachtet wird nur der MVP-Scope
- keine Datei-Transkription
- keine Multi-Plattform-Betrachtung
- keine Zukunftsarchitektur für Windows, Linux oder Mobile
- keine allgemeine UI-Ausarbeitung
- Robustheit ist wichtiger als technische Eleganz
- Ziel ist Einfügen in typische Texteingabekontexte auf macOS, nicht theoretische Universalität

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- welche technischen Wege zur Textinjektion auf macOS für PushWrite grundsätzlich realistisch sind
- welche Rechte, Einschränkungen und Risiken mit den jeweiligen Wegen verbunden sind
- welche Methode für den MVP am tragfähigsten erscheint
- welche Zielanwendungen oder Textkontexte voraussichtlich zuverlässig unterstützt werden können
- welche Grenzen des MVP dabei offen kommuniziert oder bewusst akzeptiert werden müssen

---

## Konkreter Auftrag

Analysiere die direkte Texteinfügung auf macOS für den Produktkontext von PushWrite und liefere eine strukturierte Entscheidungsgrundlage für den MVP.

Die Analyse soll nicht abstrakt bleiben, sondern sich explizit an diesem Produktziel orientieren:

**transkribierten Text nach Abschluss einer Aufnahme direkt an der aktuellen Cursor-Position in typischen Texteingabefeldern auf macOS einfügen**

---

## Erwartetes Ergebnis

Liefere ein strukturiertes Dokument mit den folgenden Abschnitten:

### 1. Problemdefinition
Beschreibe den technischen Kern des Problems:

- Was bedeutet „direkt an der aktuellen Cursor-Position einfügen“ auf macOS konkret?
- Welche System- oder Zielkontextabhängigkeiten machen diesen Schritt schwierig?
- Warum ist dieser Teil produktkritisch?

### 2. Mögliche technische Ansätze
Benenne die realistisch in Frage kommenden Ansätze zur Textinjektion auf macOS.

Für jeden Ansatz soll beschrieben werden:

- Grundidee
- technische Voraussetzungen
- notwendige Berechtigungen
- erwartbare Stärken
- erwartbare Schwächen
- Risiken für den MVP

### 3. Vergleich der Ansätze
Vergleiche die Ansätze nicht allgemein, sondern für PushWrite v0.1.0.

Vergleichskriterien:

- Robustheit in typischen Texteingabefeldern
- Abhängigkeit von macOS-Berechtigungen
- Komplexität der ersten Umsetzung
- Verhalten bei App-übergreifender Nutzung
- Fehleranfälligkeit
- MVP-Tauglichkeit

### 4. Typische Zielkontexte
Ordne ein, in welchen Kontexten die Texteinfügung voraussichtlich leichter oder schwieriger ist.

Zum Beispiel auf hoher Ebene:

- native Texteingabefelder
- Browser-Textfelder
- Editoren
- Sonderfälle oder problematische Kontexte

Es geht nicht um Vollständigkeit, sondern um eine brauchbare MVP-Einordnung.

### 5. MVP-Empfehlung
Gib eine klare Empfehlung ab:

- welcher Ansatz für den MVP zuerst verfolgt werden soll
- warum genau dieser Ansatz am besten zum engen Scope passt
- welche Einschränkungen dabei bewusst akzeptiert werden sollten

### 6. Frühe Validierung
Definiere, was vor einer grösseren Implementierung minimal validiert werden sollte.

Zum Beispiel:

- welche Testkontexte zuerst geprüft werden sollen
- welches Verhalten als ausreichend robust gelten kann
- welche Beobachtungen ein Kill-Kriterium wären

### 7. Vorschlag für Folgeauftrag
Formuliere daraus einen kleinen, konkreten Folgeauftrag für Codex, der entweder:
- eine technische Validierung vorbereitet
- oder den ersten eng geschnittenen Implementierungsschritt beschreibt

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- den engen Produktscope von PushWrite respektieren
- zwischen Daten, Annahmen und Empfehlung sauber trennen
- Robustheit höher gewichten als theoretische Eleganz
- typische Zielkontexte berücksichtigen
- die Produktkritikalität der Textinjektion ernst nehmen
- klar benennen, was verlässlich erreichbar scheint und was nicht

Wenn eine Aussage nicht sicher ist, muss sie als Annahme oder offene Frage markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- vollständige Implementierung der Textinjektion
- UI-Design oder UX-Ausarbeitung im Detail
- allgemeine Accessibility-Strategie ausserhalb des MVP-Bedarfs
- Lösung für alle denkbaren macOS-Anwendungen
- Multiplattform-Architektur
- Datei- oder Batch-Workflows
- nachgelagerte Textbearbeitung
- Autoformatierung oder Prompt-basierte Nachverarbeitung

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Welcher Ansatz ist für den MVP praktisch am tragfähigsten?
2. Welche Rechte oder Systemgrenzen können den Produktkern blockieren?
3. In welchen Zielkontexten kann PushWrite realistisch stabil funktionieren?
4. Welche technische Lösung ist klein genug, um zuerst validiert zu werden?
5. Welche weitergehenden Wünsche müssen bewusst ausserhalb des MVP bleiben?

---

## Form der Antwort

Die Antwort soll:

- klar gegliedert sein
- konkrete technische Optionen benennen
- keine unnötige Theorie enthalten
- keine generische Plattformdiskussion führen
- am Ende eine klare MVP-Empfehlung geben
- einen kleinen Folgeauftrag enthalten, der direkt weiterverwendet werden kann

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- die relevanten technischen Wege zur Textinjektion auf macOS identifiziert wurden
- ihre Risiken und Voraussetzungen nachvollziehbar verglichen wurden
- eine klare Empfehlung für den MVP ausgesprochen wurde
- typische Zielkontexte sinnvoll eingeordnet wurden
- frühe Validierungspunkte benannt wurden
- ein kleiner, direkt anschlussfähiger Folgeauftrag formuliert wurde