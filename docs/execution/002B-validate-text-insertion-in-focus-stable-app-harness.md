# Auftrag 002B: Paste-basierte Textinjektion in einem fokusstabilen macOS-App-Harness validieren

## Ziel

Validiere den bisher besten MVP-Erstpfad für die direkte Texteinfügung auf macOS unter realistischeren, fokusstabilen Bedingungen:

**Plain-Text in das Pasteboard schreiben und anschliessend per synthetischem `Cmd+V` einfügen, diesmal aus einem minimalen macOS-App-Harness heraus, der selbst keinen unerwünschten Fokuswechsel verursacht.**

Der Auftrag dient nicht dazu, die endgültige Textinjektionslösung oder die vollständige PushWrite-App zu bauen.  
Er dient dazu, die zentrale offene Frage aus 002A zu klären:

**Ist Fokusverlust ein Artefakt des bisherigen Test-/Codex-Harness oder ein grundsätzlicher Schwachpunkt dieses Ansatzes?**

Das Ergebnis soll so konkret sein, dass danach entschieden werden kann:

- ob Pasteboard plus synthetisches `Cmd+V` als MVP-Erstpfad belastbar genug ist
- ob zusätzliche Fokus-Härtung zwingend nötig ist
- oder ob der Ansatz als Erstpfad verworfen werden sollte

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

Die bisherige Validierung von 002A hat gezeigt:

- der paste-basierte Pfad funktioniert technisch grundsätzlich
- TextEdit war stabil erfolgreich
- der Browser-Fall war grundsätzlich möglich
- der dominante Risikotreiber war Fokusverlust direkt vor dem Paste
- Clipboard-Restore war für einfachen Plain-Text grundsätzlich möglich

Damit ist der Ansatz nicht verworfen, aber noch nicht robust genug für eine MVP-Festlegung.

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- zu validieren ist nur der paste-basierte Erstpfad
- Robustheit ist wichtiger als technische Eleganz
- der Harness soll minimal bleiben
- der Harness darf selbst keinen unnötigen Fokuswechsel auslösen
- keine finale App-Architektur
- keine Multiplattform-Betrachtung
- keine Datei- oder Batch-Workflows
- keine breite UI-Ausarbeitung

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- ob derselbe paste-basierte Einfügepfad in einem kleinen, fokusstabilen App-Kontext zuverlässiger arbeitet als im bisherigen Spike-Kontext
- wie reproduzierbar der Ansatz in typischen Zielkontexten wirklich ist
- ob Clipboard-Restore weiterhin sauber funktioniert
- ob der Browser-Fall unter fokusstabilen Bedingungen tragfähig genug wird
- welche klare MVP-Einordnung sich daraus ergibt

---

## Konkreter Auftrag

Erstelle einen minimalen macOS-App-Harness, mit dem der paste-basierte Textinjektionspfad unter möglichst fokusneutralen Bedingungen validiert werden kann.

Der Harness soll:

1. Plain-Text programmatisch in das Pasteboard schreiben
2. ein synthetisches `Cmd+V` auslösen
3. selbst nach Möglichkeit keinen Fokus übernehmen oder den Fokuswechsel minimieren
4. nur die minimal nötigen Kontroll- und Testmechanismen enthalten
5. gezielt für wiederholbare Validierung des Einfügepfads nutzbar sein

Der Auftrag ist ein **Spike zur Härtung der Validierung**, nicht die endgültige Produktimplementierung.

---

## Erwartetes Ergebnis

Liefere:

### 1. Minimalen macOS-App-Harness
Einen kleinen, gezielt gebauten Harness zur Validierung des paste-basierten Einfügepfads.

Der Harness soll möglichst klein bleiben und nur die für diese Validierung nötigen Funktionen enthalten.

### 2. Accessibility-Preflight
Prüfe und dokumentiere vor der Testausführung mindestens:

- ob die nötigen macOS-Rechte vorhanden sind
- welche Rechte für den Testlauf zwingend sind
- wie sich fehlende Rechte auf den Ablauf auswirken

### 3. Wiederholungstests
Führe mindestens diese Testserien durch:

- 20 Wiederholungen in TextEdit
- 20 Wiederholungen in einem Browser-Textarea auf macOS

Die Tests sollen möglichst unter identischen Bedingungen laufen.

### 4. Clipboard-Restore-Test
Validiere erneut Clipboard-Restore und dokumentiere das Verhalten mindestens für:

- einfachen Plain-Text
- einen zweiten, nicht-trivialen Clipboard-Inhalt

Nicht-trivial bedeutet: nicht bloss ein weiterer kurzer String, sondern ein Inhalt, bei dem Restore-Friktion realistischer sichtbar werden kann.

### 5. Dokumentierte Beobachtungen
Halte mindestens fest:

- Erfolgsquote pro Zielkontext
- Art und Häufigkeit von Fehlschlägen
- ob Fokusverlust weiterhin auftritt
- ob der Harness selbst Fokusprobleme erzeugt
- ob der Paste-Vorgang korrekt im Zielkontext landet
- ob Clipboard-Restore korrekt funktioniert
- welche Rechte- oder Systemgrenzen sichtbar wurden

### 6. Klare MVP-Einordnung
Bewerte am Ende eindeutig:

- tragfähig als erster MVP-Pfad
- nur mit zusätzlicher Fokus-Härtung tragfähig
- nicht tragfähig

### 7. Konkrete Folgeempfehlung
Formuliere daraus einen kleinen Folgeauftrag.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- nur den paste-basierten Einfügepfad validieren
- bewusst klein und fokussiert bleiben
- den Harness fokusneutral halten, soweit praktisch möglich
- Beobachtung und Interpretation sauber trennen
- Wiederholbarkeit ernst nehmen
- Clipboard-Restore explizit mitprüfen
- am Ende eine klare Entscheidungsempfehlung liefern

Wenn Unsicherheiten bleiben, müssen sie als offene Punkte markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- vollständige Implementierung der PushWrite-App
- globale Hotkey-Integration in den Produktfluss
- Mikrofonaufnahme oder Transkriptionsintegration
- finale Textinjektionsarchitektur
- breiter Vergleich weiterer Injektionsmethoden
- allgemeine Accessibility-Komplettlösung
- UI-Design
- Multiplattform-Betrachtung
- Unterstützung aller macOS-Anwendungen

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Verschwindet oder sinkt das Fokusproblem in einem fokusstabilen App-Harness deutlich?
2. Wie reproduzierbar funktioniert der paste-basierte Pfad in TextEdit und Browser-Textarea?
3. Ist Clipboard-Restore auch unter etwas realistischeren Bedingungen vertretbar?
4. Reicht dieser Pfad damit als MVP-Erstlösung?
5. Falls nein: liegt das Problem primär an Fokus, Rechten oder am Ansatz selbst?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- erstellte oder geänderte Artefakte
- Testaufbau
- Testergebnisse mit Erfolgsquoten
- Beobachtungen zu Fokus, Rechten und Clipboard-Restore
- technische Risiken oder offene Fragen
- klare MVP-Einordnung
- konkreten Folgeauftrag

Keine allgemeine Plattformdiskussion.  
Keine unnötige Theorie.  
Keine breite Zukunftsarchitektur.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- ein minimaler fokusstabiler macOS-App-Harness erstellt wurde
- ein Accessibility-Preflight dokumentiert wurde
- 20 Wiederholungen in TextEdit durchgeführt wurden
- 20 Wiederholungen in einem Browser-Textarea durchgeführt wurden
- Clipboard-Restore für einfachen und einen zweiten nicht-trivialen Clipboard-Inhalt geprüft wurde
- Fokus-, Fehler- und Erfolgsverhalten nachvollziehbar dokumentiert wurden
- eine klare Einordnung als tragfähig, nur mit zusätzlicher Härtung tragfähig oder nicht tragfähig vorliegt
- ein direkt anschlussfähiger Folgeauftrag formuliert wurde