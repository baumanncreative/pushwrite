# Auftrag 002L: Minimale Nutzer-Rückmeldung für gegatete `done`-Läufe in PushWrite.app ergänzen

## Ziel

Ergänze für gegatete erfolgreiche Läufe eine minimale, lokale Nutzer-Rückmeldung, ohne den bestehenden Insert-Pfad zu verändern.

Der Auftrag dient nicht dazu, neue UI-Flächen, neue Insert-Logik oder neue Transkriptionsregeln einzuführen.  
Er dient dazu, die kleine verbleibende Produktlücke nach 002K zu schliessen:

- `transcriptionInsertGate=empty|tooShort` bleibt weiter ohne Paste
- der Lauf bleibt weiter als `done` beobachtbar
- der Nutzer erhält aber eine minimale, ehrliche Rückmeldung, dass bewusst nichts eingefügt wurde

Das Ergebnis soll so konkret sein, dass danach der MVP-Kern nicht nur technisch funktioniert, sondern auch in diesen Gate-Fällen nicht mehr still und unverständlich bleibt.

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

Nach 002K gilt:

- der Hotkey-`done`-Pfad führt erfolgreiche Transkriptionen direkt aus `transcriptionArtifact.text` in den bestehenden `insertTranscription(...)`-Pfad
- es wurde kein zweiter Insert-Mechanismus eingeführt
- eine kleine Gate-Regel verhindert Paste bei `empty` und `tooShort`
- diese Gate-Fälle bleiben als `done` sichtbar, aber aktuell ohne aktive Rückmeldung an den Nutzer
- `success`, `blocked` und `error` bleiben bereits sauber getrennt beobachtbar

Die nächste sinnvolle Stufe ist deshalb nicht neue Kernlogik, sondern eine minimale Produkt-Rückmeldung für diese bewusst gegateten Fälle.  [oai_citation:1‡002K-results-connect-transcription-result-to-existing-insert-path.md](sediment://file_000000008b70720a9d95c7337e9f22c1)  [oai_citation:2‡002K-results-connect-transcription-result-to-existing-insert-path.md](sediment://file_000000008b70720a9d95c7337e9f22c1)

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- `PushWrite.app` im Stable-Pfad ist das relevante Bundle
- der bestehende Hotkey-/Flow-/Recording-/Transcribing-/Insert-Kern bleibt gesetzt
- die bestehende Gate-Regel bleibt inhaltlich gesetzt
- der bestehende Insert-Pfad bleibt unverändert
- es wird keine neue UI-Fläche eingeführt
- die Rückmeldung soll minimal, lokal und nicht aufdringlich sein
- keine Multiplattform-Betrachtung

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- wie gegatete `done`-Läufe für `empty|tooShort` minimal rückgemeldet werden
- wie diese Rückmeldung in den bestehenden Produktfluss passt, ohne neue Breite zu erzeugen
- wie `success` ohne Regression erhalten bleibt
- ob die verbleibende UX-Lücke damit klein genug für den MVP geschlossen ist

---

## Konkreter Auftrag

Erweitere PushWrite.app so, dass gegatete erfolgreiche Läufe mit `transcriptionInsertGate=empty|tooShort` eine minimale lokale Rückmeldung erzeugen, ohne den bestehenden Insert-Pfad oder die bestehende Gate-Logik zu verändern.

Der Auftrag soll mindestens diese Teile enthalten:

1. eine minimale lokale Rückmeldung für `empty` ergänzen
2. eine minimale lokale Rückmeldung für `tooShort` ergänzen
3. den bestehenden Insert-Pfad unverändert lassen
4. `done`, `blocked` und `error` weiter klar beobachtbar halten
5. eine enge produktnahe Revalidierung für `gated_empty`, `gated_too_short` und `success` durchführen
6. die verbleibende Resthärtung nach diesem UX-Schritt benennen

---

## Erwartetes Ergebnis

Liefere:

### 1. Minimale lokale Rückmeldung
Führe eine kleine, bewusst schmale Rückmeldung für gegatete Läufe ein.

Zu dokumentieren ist:

- welche Form der Rückmeldung gewählt wurde
- warum sie für den MVP klein genug ist
- warum sie keine neue UI-Fläche im eigentlichen Sinn darstellt
- dass sie nur bei `empty|tooShort` greift

Geeignete Formen können zum Beispiel sein:

- kurzer Systemton
- sehr kleine lokale Statusrückmeldung
- andere minimal-invasive Produktsignale

Nicht gesucht ist ein neues Fenster-, Panel- oder Preferences-Konzept.

### 2. Unveränderter Insert-Pfad
Dokumentiere ausdrücklich, dass:

- der bestehende Insert-Pfad unverändert bleibt
- bei `empty|tooShort` weiterhin kein Paste ausgelöst wird
- `success` weiterhin denselben Produktpfad nutzt wie bisher

### 3. Beobachtbarkeit im Runtime-State
Halte die Zustände weiter klar beobachtbar.

Mindestens relevant:

- `gated_empty`
- `gated_too_short`
- `success`
- keine Regression bei `blocked` oder `error`, falls sie durch den Umbau berührt werden

Zu dokumentieren ist:

- wie die Rückmeldung in Response/State/Logs sichtbar oder ableitbar bleibt
- dass Gate-Fälle weiterhin als `done` und nicht als `error` erscheinen

### 4. Enge produktnahe Revalidierung
Führe eine kleine Revalidierung durch.

Mindestens zu prüfen sind:

- `gated_empty` mit sichtbarer Rückmeldung und weiter ohne Paste
- `gated_too_short` mit sichtbarer Rückmeldung und weiter ohne Paste
- `success` ohne Regression beim echten Insert

Wenn klein und ohne Scope-Ausweitung möglich, kann zusätzlich kurz geprüft werden, dass `blocked` unverändert bleibt.

### 5. Dokumentierte Beobachtungen
Halte mindestens fest:

- wie die Rückmeldung konkret aussieht
- ob sie zuverlässig nur in Gate-Fällen ausgelöst wird
- ob `success` unverändert produktnah funktioniert
- ob Gate-Fälle weiter sauber von `blocked` und `error` getrennt bleiben
- welche kleine Resthärtung danach noch offen bleibt

### 6. MVP-Einordnung
Bewerte am Ende klar:

- Gate-UX für den MVP ausreichend geschlossen
- im Wesentlichen tragfähig, aber mit kleiner Resthärtung
- noch nicht klein und klar genug

### 7. Konkrete Folgeempfehlung
Formuliere daraus einen kleinen Folgeauftrag für die nächste Stufe.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- auf dem bestehenden Stable-Produktpfad aufbauen
- die bestehende Gate-Regel unverändert lassen
- den bestehenden Insert-Pfad unverändert lassen
- nur minimale lokale Rückmeldung ergänzen
- Beobachtung, Interpretation und Empfehlung sauber trennen
- bewusst klein und risikoorientiert bleiben

Wenn Unsicherheiten bleiben, müssen sie als offene Punkte markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- neue Gate-Logik
- Änderung der Schwelle für `empty` oder `tooShort`
- neue Insert-Methode
- neue Inferenz- oder Audioarchitektur
- breite UI- oder Settings-Ausarbeitung
- Unterstützung aller macOS-Anwendungen
- Multiplattform-Betrachtung
- allgemeine Zukunftsarchitektur

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Welche minimale Rückmeldung reicht für `empty|tooShort` im MVP?
2. Wie bleibt der bestehende Insert-Pfad komplett unverändert?
3. Bleiben Gate-Fälle weiter klar als `done` und nicht als Fehler sichtbar?
4. Bleibt `success` ohne Regression erhalten?
5. Welche kleinste Resthärtung bleibt danach noch offen?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- erstellte oder geänderte Artefakte
- Beschreibung der minimalen Rückmeldung
- Ergebnisse der engen produktnahen Revalidierung
- technische Risiken oder offene Fragen
- klare MVP-Einordnung
- konkreten Folgeauftrag

Keine allgemeine Plattformdiskussion.  
Keine unnötige Theorie.  
Keine breite Zukunftsarchitektur.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- `gated_empty` eine minimale lokale Rückmeldung auslöst, weiter ohne Paste
- `gated_too_short` eine minimale lokale Rückmeldung auslöst, weiter ohne Paste
- der bestehende Insert-Pfad unverändert bleibt
- `success` ohne Regression produktnah validiert wurde
- Gate-Fälle weiter klar als `done` beobachtbar bleiben
- eine klare Einschätzung zur verbleibenden Resthärtung vorliegt
- ein direkt anschlussfähiger Folgeauftrag formuliert wurde