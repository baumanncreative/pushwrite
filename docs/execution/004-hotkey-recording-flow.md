# Auftrag 004: Hotkey- und Aufnahmefluss für PushWrite v0.1.0 auf macOS strukturieren

## Ziel

Erstelle eine präzise Strukturierungs- und Entscheidungsgrundlage für den Hotkey- und Aufnahmefluss von PushWrite auf macOS.

Der Auftrag dient nicht dazu, den vollständigen Aufnahme-Stack oder die gesamte App bereits umzusetzen.  
Er dient dazu, den Kernablauf von globalem Hotkey, Aufnahmezustand und Übergabe an die nachgelagerte Verarbeitung so zu schneiden, dass daraus ein kleiner, kontrollierbarer Implementierungsauftrag abgeleitet werden kann.

Das Ergebnis soll so konkret sein, dass die erste technische Validierung oder erste enge Umsetzung des Aufnahmeflusses direkt daraus entstehen kann.

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

Für v0.1.0 ist dieser Ablauf bewusst eng und produktzentriert.

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- globaler Hotkey ist Teil des Produktkerns
- Mikrofonaufnahme ist Teil des Produktkerns
- Standardpfad ist lokaler, offline-fähiger Betrieb
- `whisper.cpp` bleibt gesetzte Inferenz-Richtung
- Inferenz-Layer und macOS-App-Layer sind getrennt zu betrachten
- keine Datei-Transkription
- keine Multiplattform-Betrachtung
- keine vorzeitige Zukunftsabstraktion
- der erste Ablauf soll robust sein, nicht maximal flexibel

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- wie der globale Hotkey produktseitig in einen sauberen Aufnahmefluss übersetzt werden soll
- welche Zustände und Zustandswechsel dafür minimal nötig sind
- wie Start, Stop, Abbruch und Übergabe an die Transkription logisch geschnitten werden sollten
- welche Fehler- und Randfälle früh berücksichtigt werden müssen
- welche Form des Hotkey-Verhaltens für den MVP am tragfähigsten ist

---

## Konkreter Auftrag

Analysiere den Hotkey- und Aufnahmefluss von PushWrite auf macOS und liefere eine strukturierte Entscheidungsgrundlage für den MVP.

Die Analyse soll sich explizit auf diesen Produktfall beziehen:

**globalen Hotkey auslösen, Aufnahme zuverlässig steuern, Audio klar begrenzen und sauber an die lokale Transkription übergeben**

Nicht gesucht ist eine allgemeine Diskussion über Desktop-Input-Patterns, sondern eine enge Strukturierung des produktkritischen Kernablaufs.

---

## Erwartetes Ergebnis

Liefere ein strukturiertes Dokument mit den folgenden Abschnitten:

### 1. Problemdefinition
Beschreibe den technischen und produktbezogenen Kern des Problems.

Zu klären ist insbesondere:

- was der Hotkey im System konkret auslösen soll
- warum Hotkey und Aufnahmefluss zusammen betrachtet werden müssen
- warum dieser Ablauf für den MVP nicht nur technisch, sondern produktseitig kritisch ist

### 2. Mögliche Interaktionsmodelle
Benenne die realistisch relevanten Bedienmodelle für den MVP.

Zum Beispiel auf hoher Ebene:

- press-and-hold
- toggle start/stop
- andere minimal plausible Varianten, falls relevant

Für jede Variante soll beschrieben werden:

- Grundidee
- erwartbare Vorteile
- erwartbare Schwächen
- Risiken für den MVP
- Auswirkung auf Einfachheit, Robustheit und Nutzerverständnis

### 3. Empfohlene Zustände und Zustandsübergänge
Definiere das minimale Zustandsmodell für den Aufnahmefluss.

Zum Beispiel auf hoher Ebene:

- idle
- recording
- processing
- error
- optional blocked oder permission-missing, falls nötig

Für jeden Zustand soll beschrieben werden:

- was ihn auslöst
- was in ihm erlaubt ist
- wodurch er verlassen wird
- welche unzulässigen Übergänge verhindert werden müssen

### 4. Start-, Stop- und Abbruchlogik
Beschreibe, wie der Ablauf logisch geschnitten werden sollte.

Zu beantworten ist:

- wann genau eine Aufnahme beginnt
- wann genau sie endet
- wie mit zu kurzen, leeren oder abgebrochenen Aufnahmen umzugehen ist
- wie die Übergabe an die Transkription ausgelöst wird
- welche Ereignisse den Ablauf blockieren oder zurücksetzen sollten

### 5. Fehler- und Randfälle
Benenne die wichtigsten problematischen Situationen auf MVP-Niveau.

Zum Beispiel:

- Hotkey wird ausgelöst, aber Aufnahme kann nicht starten
- Aufnahme läuft bereits und ein weiterer Trigger kommt herein
- Mikrofon ist nicht verfügbar
- Aufnahme ist leer oder zu kurz
- Aufnahme endet, aber Übergabe an die Transkription scheitert
- Status bleibt in einem inkonsistenten Zustand hängen

Für jeden Fall soll beschrieben werden:

- woran der Zustand erkannt wird
- welche Produktauswirkung er hat
- welche minimale Reaktion oder Rückmeldung der MVP braucht

### 6. MVP-Empfehlung
Gib eine klare Empfehlung ab:

- welches Hotkey-Modell für v0.1.0 zuerst verfolgt werden soll
- welches minimale Zustandsmodell ausreicht
- welche Komplexität bewusst noch nicht gebaut werden soll
- welche Kompromisse im MVP vertretbar sind

### 7. Frühe Validierung
Definiere, was vor grösserer Implementierung minimal verifiziert werden sollte.

Zum Beispiel:

- ob der globale Hotkey unter den geplanten Bedingungen zuverlässig arbeitet
- ob das gewählte Interaktionsmodell praktisch stabil genug ist
- ob der Aufnahmefluss sauber zwischen idle, recording und processing wechselt
- welche Beobachtungen ein Kill-Kriterium wären

### 8. Vorschlag für Folgeauftrag
Formuliere daraus einen kleinen, konkreten Folgeauftrag für Codex, der entweder:

- einen minimalen Hotkey-/Aufnahme-Prototypen vorbereitet
- oder den ersten engen Implementierungsschritt für den Ablauf beschreibt

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- den engen Produktscope von PushWrite respektieren
- Hotkey und Aufnahmefluss gemeinsam denken
- zwischen gesichert, plausible Annahme und offene Frage sauber trennen
- Robustheit höher gewichten als Flexibilität
- ein kleines, kontrollierbares Zustandsmodell bevorzugen
- klar benennen, welche Komplexität für den MVP bewusst vermieden werden soll

Wenn Aussagen unsicher sind, müssen sie als Annahme oder offene Frage markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- vollständige Implementierung des Aufnahme-Stacks
- detaillierte Audio-Engine-Optimierung
- UI-Design oder visuelle Ausarbeitung im Detail
- Multiplattform-Betrachtung
- Datei- oder Batch-Aufnahme
- kontinuierliche Diktiermodi ausserhalb des MVP-Bedarfs
- erweiterte Editier- oder Nachbearbeitungslogik
- tiefe Architektur für spätere Zukunftsszenarien

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Welches Hotkey-Modell ist für den MVP praktisch am tragfähigsten?
2. Welche Zustände und Übergänge sind minimal nötig, damit der Ablauf stabil bleibt?
3. Welche Fehler oder Randfälle können den Produktkern früh entwerten?
4. Welche Teile müssen zuerst validiert werden, bevor breitere Implementierung sinnvoll ist?
5. Welche Komplexität muss bewusst ausserhalb von v0.1.0 bleiben?

---

## Form der Antwort

Die Antwort soll:

- klar gegliedert sein
- konkrete Interaktions- und Ablaufoptionen benennen
- keine unnötige Theorie enthalten
- den Produktkontext ernst nehmen
- am Ende eine klare MVP-Empfehlung geben
- einen kleinen Folgeauftrag enthalten, der direkt weiterverwendet werden kann

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- die relevanten Hotkey- und Aufnahme-Modelle für den MVP identifiziert wurden
- ein klares minimales Zustandsmodell vorgeschlagen wurde
- Start-, Stop- und Abbruchlogik nachvollziehbar eingeordnet wurden
- die wichtigsten Fehler- und Randfälle benannt wurden
- eine klare MVP-Empfehlung ausgesprochen wurde
- ein kleiner, direkt anschlussfähiger Folgeauftrag formuliert wurde