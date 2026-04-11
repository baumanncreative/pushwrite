# Auftrag 002H: Hotkey-Validator-Auslösung, Runtime-State und echten Stable-Success-Nachweis für PushWrite.app final härten

## Ziel

Härte den bestehenden produktnahen Kern von PushWrite.app so, dass vor der Mikrofonstufe drei verbleibende Unsicherheiten sauber geschlossen werden:

- der Hotkey-Validator muss auf dem Stable-Bundle wieder zuverlässig neue Hotkey-Responses erzeugen
- `product-state.json` muss nach Start und Stop konsistent bleiben
- je ein echter Stable-Run in TextEdit und Safari muss mit den neuen Beobachtungsfeldern zeigen, dass Erfolg nicht nur im Produktflow gemeldet, sondern im Zielkontext tatsächlich beobachtet wurde

Der Auftrag dient nicht dazu, Mikrofonaufnahme oder `whisper.cpp` zu integrieren.  
Er dient dazu, den bestehenden Kern vor der nächsten Integrationsstufe belastbar abzuschliessen.

---

## Projektkontext

PushWrite ist ein lokal laufendes Open-Source-Werkzeug für macOS.

Der aktuelle produktnahe Kern umfasst bereits:

- reales Produktbundle `PushWrite.app`
- stabilen lokalen Pfad `candidate -> promote -> stable`
- globalen Hotkey
- kleinen Flow
- simuliertes In-Memory-Transkript
- `insertTranscription(text:)`
- paste-basierten Insert-Pfad
- Blocked-Verhalten für fehlende Accessibility
- Validatoren mit gehärtetem Success-Kriterium

Nach 002G gilt:

- false success ist im Ergebnisformat ausgeschlossen
- Stable und Candidate sind getrennt
- Trust wird nur am Stable-Bundle beurteilt
- der verbleibende Engpass liegt nicht mehr in der Grundarchitektur, sondern in Validator-Auslösung, Runtime-Konsistenz und echtem Stable-Success-Nachweis

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- `PushWrite.app` im Stable-Pfad ist das relevante Bundle
- der bestehende Hotkey-/Flow-/Insert-Kern bleibt gesetzt
- die bestehenden Success-Kriterien bleiben gesetzt
- Audioaufnahme ist nicht Teil dieses Auftrags
- `whisper.cpp`-Integration ist nicht Teil dieses Auftrags
- keine alternative Textinjektionsmethode
- keine breite UI- oder Settings-Ausarbeitung
- keine Multiplattform-Betrachtung

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- warum der Hotkey-Validator auf dem Stable-Bundle in einzelnen Re-Runs keine neuen Hotkey-Responses mehr erzeugt
- wie `product-state.json` nach Stop und Runtime-Ende konsistent gehalten wird
- ob auf dem Stable-Bundle je ein echter Success-Run in TextEdit und Safari mit den neuen Beobachtungsfeldern sauber nachweisbar ist
- ob der bestehende Kern danach belastbar genug für die Mikrofonstufe ist

---

## Konkreter Auftrag

Härte den bestehenden Stable-Produktpfad in drei eng geschnittenen Bereichen:

1. Hotkey-Validator-Auslösung analysieren und stabilisieren
2. `product-state.json` und zugehörige Runtime-Artefakte konsistent machen
3. je einen echten Stable-Success-Run für TextEdit und Safari mit den neuen Beobachtungsfeldern durchführen und dokumentieren

Der Auftrag soll bewusst klein bleiben und keine neue Problemklasse einführen.

---

## Erwartetes Ergebnis

Liefere:

### 1. Analyse und Härtung der Hotkey-Validator-Auslösung
Untersuche, warum der Hotkey-Validator trotz Einzelinstanz in bestimmten Läufen keine neuen Hotkey-Responses erzeugt.

Zu klären ist:

- liegt das Problem im Validator
- im Triggerpfad
- in der Runtime-Wiederverwendung
- im Stable-Launch
- oder in einer Zustands-/Timing-Frage

Ergebnisziel:

- ein belastbarer Validatorpfad für das Stable-Bundle
- oder eine klare, eng eingegrenzte Restoffenheit mit Begründung

### 2. Härtung von `product-state.json`
Sorge dafür, dass die Runtime-Zustände konsistent bleiben.

Mindestens zu prüfen und zu beheben:

- `running=true` nach Stop
- inkonsistente Statusartefakte nach beendetem Lauf
- Widersprüche zwischen Produktzustand und Logs

Ziel ist:

- Start, Lauf und Stop sind im State nachvollziehbar
- State und Logs widersprechen sich nicht unnötig
- spätere Audiointegration baut auf kohärenten Runtime-Artefakten auf

### 3. Echter Stable-Success-Nachweis in TextEdit
Führe auf dem Stable-Bundle einen echten Success-Run in TextEdit durch.

Der Run gilt nur dann als Erfolg, wenn:

- der Produktflow `succeeded` meldet
- und `observedTargetValueMatches` den Zielwert wirklich bestätigt

### 4. Echter Stable-Success-Nachweis in Safari
Führe auf dem Stable-Bundle einen echten Success-Run in Safari-Textarea durch.

Auch hier gilt:

- kein Erfolg allein aufgrund des Produktflows
- Erfolg nur bei beobachtetem Zielwert-Match

### 5. Dokumentierte Beobachtungen
Halte mindestens fest:

- wie der Hotkey-Validator stabilisiert wurde oder woran er noch scheitert
- ob `product-state.json` jetzt konsistent bleibt
- ob TextEdit auf Stable sauber nachgewiesen werden konnte
- ob Safari auf Stable sauber nachgewiesen werden konnte
- welche Abweichungen, Timeouts oder Randfälle noch bestehen

### 6. MVP-Einordnung
Bewerte am Ende klar:

- stabil genug für die Mikrofonstufe
- im Wesentlichen tragfähig, aber mit kleiner Resthärtung
- noch nicht sauber genug für Mikrofon-Start/Stop

### 7. Konkrete Folgeempfehlung
Formuliere daraus einen kleinen Folgeauftrag für die nächste Stufe.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- auf dem Stable-Bundle und dem bestehenden 002G-Pfad aufbauen
- die neuen Success-Kriterien strikt respektieren
- Beobachtung, Interpretation und Empfehlung sauber trennen
- keine neue Produktbreite einführen
- bewusst risikoorientiert und klein bleiben

Wenn Unsicherheiten bleiben, müssen sie als offene Punkte markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- Mikrofonaufnahme
- Audio-Pufferung
- `whisper.cpp`-Integration
- Modellwahl oder Modell-Packaging
- neue UI-Flows
- alternative Textinjektionsmethoden
- Unterstützung aller macOS-Anwendungen
- Multiplattform-Betrachtung
- allgemeine Zukunftsarchitektur

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Warum erzeugt der Hotkey-Validator in Re-Runs teils keine neue Response?
2. Wie wird `product-state.json` nach Stop und Runtime-Ende wirklich konsistent?
3. Gibt es je einen echten Stable-Success-Nachweis für TextEdit und Safari mit beobachtetem Zielwert?
4. Ist der bestehende Kern damit belastbar genug für die Mikrofonstufe?
5. Welche kleinste Resthärtung bleibt danach noch offen?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- erstellte oder geänderte Artefakte
- Beschreibung der Hotkey-Validator-Härtung
- Beschreibung der Runtime-/State-Härtung
- Ergebnisse des echten Stable-Runs für TextEdit
- Ergebnisse des echten Stable-Runs für Safari
- technische Risiken oder offene Fragen
- klare MVP-Einordnung
- konkreten Folgeauftrag

Keine allgemeine Plattformdiskussion.  
Keine unnötige Theorie.  
Keine breite Zukunftsarchitektur.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- der Hotkey-Validator auf dem Stable-Bundle nachvollziehbar gehärtet oder sauber eingegrenzt wurde
- `product-state.json` nach Stop konsistent ist oder die verbleibende Restoffenheit klar dokumentiert wurde
- ein echter Stable-Success-Run für TextEdit mit beobachtetem Zielwert-Match dokumentiert ist
- ein echter Stable-Success-Run für Safari mit beobachtetem Zielwert-Match dokumentiert ist
- die bestehenden Success-Kriterien konsequent angewendet wurden
- eine klare Einschätzung zur Reife vor der Mikrofonstufe vorliegt
- ein direkt anschlussfähiger Folgeauftrag formuliert wurde