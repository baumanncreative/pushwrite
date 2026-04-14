# Auftrag 002K: Transkriptionsergebnis an den bestehenden Insert-Pfad von PushWrite.app anschliessen

## Ziel

Schliesse den bestehenden `done`-Pfad von PushWrite.app an den bereits gehärteten Insert-Mechanismus an.

Der Auftrag dient nicht dazu, neue Insert-Methoden, neue Inferenzlogik oder eine breite Ergebnisnachbearbeitung einzuführen.  
Er dient dazu, den letzten fehlenden MVP-Baustein im bestehenden Produktfluss zu schliessen:

- `transcriptionArtifact.text` aus dem erfolgreichen Hotkey-/Recording-/Transcribing-Lauf übernehmen
- eine kleine Gate-Regel für leere oder zu kurze Ergebnisse anwenden
- den bestehenden Insert-Pfad wiederverwenden
- `done`, `blocked` und `error` im Runtime-State weiter klar beobachtbar halten

Das Ergebnis soll so konkret sein, dass danach der erste echte End-to-End-Pfad
**Hotkey -> Recording -> lokale Inferenz -> Insert am Cursor**
im Produkt vorhanden ist.

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

Nach 002J gilt:

- der Stable-Hotkey steuert echte Mikrofonaufnahme
- der Recording-Pfad schreibt ein wiederverwendbares WAV-Artefakt
- `whisper.cpp` ist an den bestehenden `transcribing`-Übergabepunkt angebunden
- erfolgreiche Läufe erzeugen ein echtes `transcriptionArtifact.text`
- Inferenzfehler, Accessibility-Blocked, Microphone-Denied und No-Mic bleiben bereits sauber getrennt
- der bestehende Insert-Pfad ist aus früheren Schritten im Produktkontext gehärtet

Die nächste sinnvolle Stufe ist deshalb nicht neue Inferenz- oder Insert-Forschung, sondern die Anbindung des echten Transkriptionsergebnisses an genau diesen bestehenden Insert-Schnitt.  [oai_citation:1‡002J-results-attach-whisper-cpp-to-transcribing-handoff.md](sediment://file_00000000e5c47246889bdf0d4376dcbe)  [oai_citation:2‡002J-results-attach-whisper-cpp-to-transcribing-handoff.md](sediment://file_00000000e5c47246889bdf0d4376dcbe)

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- `PushWrite.app` im Stable-Pfad ist das relevante Bundle
- der bestehende Hotkey-/Flow-/Recording-/Transcribing-Kern bleibt gesetzt
- der bestehende Insert-Pfad bleibt gesetzt
- `transcriptionArtifact.text` ist die Quelle für den Insert
- es wird keine neue Insert-Methode eingeführt
- es wird keine neue Inferenz- oder Audioarchitektur eingeführt
- es wird nur eine kleine Gate-Regel für leere oder zu kurze Ergebnisse ergänzt
- keine breite UI- oder Settings-Ausarbeitung
- keine Multiplattform-Betrachtung

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- wie `transcriptionArtifact.text` sauber in den bestehenden Insert-Pfad übergeben wird
- wie leere oder zu kurze Ergebnisse vor dem Paste abgefangen werden
- wie der Produktfluss bei Success, Empty/Too-Short, Blocked und Error konsistent bleibt
- ob der erste echte End-to-End-MVP-Pfad mit Insert am Cursor stabil genug ist

---

## Konkreter Auftrag

Erweitere PushWrite.app so, dass der bestehende `done`-Pfad erfolgreicher Transkriptionsläufe den vorhandenen Insert-Mechanismus mit `transcriptionArtifact.text` nutzt.

Der Auftrag soll mindestens diese Teile enthalten:

1. `transcriptionArtifact.text` als Quelle für den bestehenden Insert-Pfad anbinden
2. eine kleine Gate-Regel für leere oder zu kurze Transkriptionsergebnisse einführen
3. bei gegateten Ergebnissen keinen unerwünschten Paste auslösen
4. `done`, `blocked` und `error` im Runtime-State und in den Response-Artefakten klar beobachtbar halten
5. eine enge produktnahe Revalidierung durchführen
6. die verbleibende Resthärtung nach dem ersten echten End-to-End-Pfad benennen

Der Auftrag soll bewusst klein bleiben und keine breite Textnachbearbeitung einführen.

---

## Erwartetes Ergebnis

Liefere:

### 1. Insert-Anbindung des Transkriptionsergebnisses
Binde `transcriptionArtifact.text` an den bestehenden Insert-Pfad an.

Zu dokumentieren ist:

- an welcher Stelle im `done`-Pfad die Übergabe erfolgt
- dass kein zweiter paralleler Insert-Weg entsteht
- dass der bestehende gehärtete Insert-Mechanismus wiederverwendet wird

### 2. Kleine Gate-Regel für leere oder zu kurze Ergebnisse
Führe eine minimale Produktregel ein, die verhindert, dass inhaltlich unbrauchbare Ergebnisse eingefügt werden.

Zu klären ist:

- was in dieser Stufe als „leer“ gilt
- was als „zu kurz“ gilt
- wie dieser Zustand im Runtime-State und in den Artefakten sichtbar wird
- wie verhindert wird, dass trotzdem gepastet wird

Die Regel soll bewusst klein und pragmatisch bleiben.

### 3. Konsistenter Runtime-State
Der bestehende Produktfluss muss weiterhin klar beobachtbar bleiben.

Mindestens zu dokumentieren ist:

- Success mit tatsächlichem Insert
- gegatetes Empty/Too-Short-Ergebnis ohne Insert
- Accessibility-Blocked ohne Regression
- Inferenzfehler ohne Regression

### 4. Kleine produktnahe Revalidierung
Führe eine enge, aber belastbare Revalidierung durch.

Mindestens zu prüfen sind:

- Success: `Hotkey -> Recording -> Transcription -> Insert`
- Empty oder Too-Short: kein unerwünschter Paste
- Accessibility-Blocked ohne Regression

Wenn sinnvoll und klein genug, kann zusätzlich ein Inferenzfehlerpfad nochmals mitgeprüft werden.

### 5. Dokumentierte Beobachtungen
Halte mindestens fest:

- ob der Insert jetzt direkt aus `transcriptionArtifact.text` erfolgt
- wie die Gate-Regel greift
- ob Success im Zielkontext tatsächlich beobachtbar bleibt
- ob `blocked` und `error` weiterhin sauber getrennt bleiben
- welche Resthärtung nach dem ersten echten End-to-End-Pfad noch offen bleibt

### 6. MVP-Einordnung
Bewerte am Ende klar:

- erster End-to-End-MVP-Pfad tragfähig
- im Wesentlichen tragfähig, aber mit kleiner Resthärtung
- noch nicht stabil genug für MVP-Weiterführung

### 7. Konkrete Folgeempfehlung
Formuliere daraus einen kleinen Folgeauftrag für die nächste Stufe.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- auf dem bestehenden Stable-Produktpfad aufbauen
- den bestehenden Insert-Mechanismus wiederverwenden
- `transcriptionArtifact.text` direkt als Quelle nutzen
- eine kleine, klare Gate-Regel für leer/zu kurz enthalten
- Beobachtung, Interpretation und Empfehlung sauber trennen
- Runtime-State und Logs konsistent halten
- bewusst klein und risikoorientiert bleiben

Wenn Unsicherheiten bleiben, müssen sie als offene Punkte markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- neue Insert-Methode
- neue Inferenz-Engine oder Modelllogik
- breite Textnachbearbeitung
- Prompt-basierte Umformung
- breite UI- oder Settings-Ausarbeitung
- Unterstützung aller macOS-Anwendungen
- Multiplattform-Betrachtung
- allgemeine Zukunftsarchitektur

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Lässt sich `transcriptionArtifact.text` direkt in den bestehenden Insert-Pfad führen?
2. Reicht eine kleine Gate-Regel für leere oder zu kurze Ergebnisse?
3. Bleiben `done`, `blocked` und `error` sauber beobachtbar?
4. Ist der erste echte End-to-End-Pfad damit stabil genug?
5. Welche kleinste Resthärtung fehlt danach noch?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- erstellte oder geänderte Artefakte
- Beschreibung der Anbindung von `transcriptionArtifact.text`
- Beschreibung der Gate-Regel
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

- `transcriptionArtifact.text` an den bestehenden Insert-Pfad angebunden wurde
- eine kleine Gate-Regel für leere oder zu kurze Ergebnisse vorhanden ist
- Success mit tatsächlichem Insert produktnah validiert wurde
- Empty/Too-Short ohne unerwünschten Paste validiert wurde
- Accessibility-Blocked ohne Regression erhalten bleibt
- Runtime-State und Response-Artefakte konsistent bleiben
- eine klare Einschätzung zur Tragfähigkeit des ersten echten End-to-End-Pfads vorliegt
- ein direkt anschlussfähiger Folgeauftrag formuliert wurde