# Auftrag 002E: Minimalen Hotkey-, Flow- und In-Memory-Transcription-Pfad in PushWrite.app integrieren

## Ziel

Integriere den ersten echten produktnahen Kernablauf in PushWrite.app:

**ein minimaler globaler Hotkey löst einen kleinen Flow aus, der noch ohne echtes Audio und ohne echte Whisper-Transkription arbeitet, aber einen simulierten Transkriptions-Text über `insertTranscription(text:)` in den bereits validierten Insert-Pfad überführt.**

Der Auftrag dient nicht dazu, die vollständige PushWrite-App fertigzustellen.  
Er dient dazu, nach dem erfolgreichen Insert-Wiring im Produktbundle den nächsten echten Produktkern zu schliessen:

- Auslöser
- Ablaufsteuerung
- Textübergabe
- bestehender Insert-Pfad

Das Ergebnis soll so konkret sein, dass danach entschieden werden kann:

- ob der erste produktnahe End-to-End-Kern ohne Audio bereits stabil genug ist
- wie der nächste Integrationsschnitt für Mikrofonaufnahme geschnitten werden soll
- welche Resthärtung vor echter Audio- und Whisper-Anbindung noch fehlt

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

Für Schritt 6 wurde bereits erreicht:

- der paste-basierte Insert-Pfad ist technisch validiert
- der Insert-Pfad ist im echten PushWrite-Produktbundle verankert
- ein minimaler Accessibility-Blocked-Flow ist vorhanden
- `insertTranscription(text:)` ist an den Insert-Kern angebunden

Damit ist der nächste sinnvolle Schritt:

**einen ersten echten Produktfluss über Hotkey + Flow-Koordination + simulierten Transkriptions-Text aufzubauen, ohne bereits Audio und Whisper dazuzumischen.**

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- der bestehende paste-basierte Insert-Pfad bleibt gesetzt
- `insertTranscription(text:)` bleibt der produktinterne Einstieg für Textinjektion
- es wird noch kein echtes Audio aufgenommen
- es wird noch keine echte Whisper- oder `whisper.cpp`-Transkription integriert
- der Ablauf soll minimal, robust und gut beobachtbar sein
- keine breite UI-Ausarbeitung
- keine alternative Textinjektionsmethode
- keine Multiplattform-Betrachtung

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- wie ein minimaler globaler Hotkey an PushWrite.app angebunden wird
- wie ein sehr kleines Zustands- oder Flow-Modell den ersten Produktablauf steuert
- wie ein simuliertes Transkriptionsergebnis kontrolliert an `insertTranscription(text:)` übergeben wird
- wie Accessibility-Blocked-Zustände in diesem Ablauf wirken
- ob der erste produktnahe End-to-End-Kern ohne Audio bereits tragfähig ist

---

## Konkreter Auftrag

Erweitere PushWrite.app um einen minimalen Hotkey- und Flow-Pfad, der ohne Audio und ohne echte Inferenz arbeitet, aber den späteren Produktkern realistisch vorbereitet.

Der Auftrag soll mindestens diese Teile enthalten:

1. einen minimalen globalen Hotkey an PushWrite.app anbinden
2. einen kleinen Flow-Coordinator oder ein minimales Zustandsmodell einführen
3. einen simulierten In-Memory-Transkriptions-Text erzeugen oder entgegennehmen
4. diesen Text über `insertTranscription(text:)` in den bestehenden Insert-Pfad übergeben
5. den Ablauf bei fehlender Accessibility sauber blockieren
6. den Startpfad weiter härten, soweit für diese Stufe nötig
7. den Ablauf in TextEdit und Safari-Textarea mindestens als produktnahe Kurzserie validieren

Der Auftrag ist die erste kleine End-to-End-Produktintegration, aber noch nicht der volle MVP.

---

## Erwartetes Ergebnis

Liefere:

### 1. Minimalen globalen Hotkey
Integriere einen kleinen, reproduzierbaren globalen Hotkey-Pfad in PushWrite.app.

Zu klären ist:

- wie der Hotkey registriert wird
- wie stabil der Trigger im Entwicklungs- und Validierungskontext auslösbar ist
- wie Kollisionen oder Blockaden für diese Stufe minimal behandelt werden

Nicht gesucht ist schon ein ausgebautes Hotkey-Preference-System.

### 2. Kleinen Flow-Coordinator
Führe ein minimales Zustands- oder Flow-Modell ein.

Mindestens sinnvoll sind Zustände wie:

- idle
- triggered
- blocked
- inserting
- done oder error

Der Flow soll klein bleiben und nur jene Übergänge abbilden, die für diese Stufe wirklich nötig sind.

### 3. Simulierten In-Memory-Transkriptions-Text
Baue einen kleinen Testpfad, der produktintern einen Text bereitstellt, ohne echtes Audio und ohne echte Inferenz.

Zum Beispiel:

- fester Teststring
- interner Simulationswert
- kleiner kontrollierter Entwicklungs-Trigger

Dieser Teil soll nur den späteren Übergabepunkt vorbereiten, nicht eine Fake-Transkriptionsarchitektur aufbauen.

### 4. Anbindung an `insertTranscription(text:)`
Übergib den simulierten Text an denselben Produktpfad, der bereits für echte Textinjektion vorgesehen ist.

Ziel ist:

- ein produktinterner Aufrufpfad statt externer Teststeuerung
- dieselbe Insert-Logik wie in 002D
- keine zweite Parallelroute für Textinjektion

### 5. Accessibility-Blocked-Verhalten im echten Ablauf
Prüfe und dokumentiere, wie der neue Hotkey-/Flow-Pfad reagiert, wenn Accessibility fehlt oder blockiert ist.

Zu leisten ist mindestens:

- kein falscher Success-Zustand
- klare Blockade auf Flow-Ebene
- keine unnötige Fokusübernahme
- minimale, ehrliche Rückmeldung

### 6. Produktnahe Kurzvalidierung
Führe eine kleine, aber nachvollziehbare Validierung des neuen Ablaufs aus.

Mindestens zu prüfen sind:

- TextEdit
- Safari-Textarea

Die Serie darf bewusst kleiner bleiben als frühere Insert-Serien, weil hier der neue Fokus auf Hotkey- und Flow-Wiring liegt.

### 7. Dokumentierte Beobachtungen
Halte mindestens fest:

- ob der Hotkey reproduzierbar auslöst
- ob der kleine Flow stabil bleibt
- ob der simulierte Text korrekt in `insertTranscription(text:)` läuft
- ob der Insert auf Produktpfad-Ebene weiterhin funktioniert
- ob neue Fokus-, Blockade- oder Startpfadprobleme sichtbar werden
- welche Resthärtung vor echter Audiointegration noch fehlt

### 8. MVP-Einordnung
Bewerte am Ende klar:

- tragfähig als erster produktnaher End-to-End-Kern ohne Audio
- tragfähig mit kleiner Resthärtung
- noch nicht stabil genug für die nächste Integrationsstufe

### 9. Konkrete Folgeempfehlung
Formuliere daraus einen kleinen Folgeauftrag.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- auf PushWrite.app aufbauen
- den bestehenden Insert-Pfad wiederverwenden
- einen minimalen globalen Hotkey enthalten
- einen kleinen, klaren Flow einführen
- Audio und echte Inferenz bewusst noch ausschliessen
- Beobachtung und Bewertung sauber trennen
- bewusst klein und produktnah bleiben

Wenn Unsicherheiten bleiben, müssen sie als offene Punkte markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- Mikrofonaufnahme
- Audio-Pufferung
- Whisper- oder `whisper.cpp`-Integration
- finale Zustandsmaschine des Gesamtprodukts
- breite UI- oder Settings-Oberfläche
- alternative Textinjektionsmethoden
- Unterstützung aller macOS-Anwendungen
- Multiplattform-Betrachtung
- allgemeine Zukunftsarchitektur

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Lässt sich ein minimaler globaler Hotkey stabil an PushWrite.app anbinden?
2. Reicht ein sehr kleiner Flow aus, um den ersten Produktkern sauber zu steuern?
3. Läuft ein simuliertes Transkriptionsergebnis sauber durch `insertTranscription(text:)` in den bestehenden Insert-Pfad?
4. Bleibt der Ablauf auch bei fehlender Accessibility ehrlich und kontrolliert?
5. Welche kleinste Resthärtung fehlt vor echter Mikrofon- und Whisper-Anbindung?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- erstellte oder geänderte Artefakte
- Beschreibung des Hotkey-Ansatzes
- Beschreibung des minimalen Flows
- Beschreibung des In-Memory-Transcription-Wirings
- Beobachtungen zu Trigger, Flow, Insert und Blocked-Verhalten
- technische Risiken oder offene Fragen
- klare MVP-Einordnung
- konkreten Folgeauftrag

Keine allgemeine Plattformdiskussion.  
Keine unnötige Theorie.  
Keine breite Zukunftsarchitektur.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- ein minimaler globaler Hotkey in PushWrite.app integriert wurde
- ein kleiner Flow-Coordinator oder ein minimales Zustandsmodell vorhanden ist
- ein simuliertes In-Memory-Transkriptionsergebnis an `insertTranscription(text:)` angebunden wurde
- der Ablauf in PushWrite.app ohne echtes Audio ausführbar ist
- Blocked- und Success-Verhalten nachvollziehbar dokumentiert wurden
- eine kleine produktnahe Validierung in TextEdit und Safari-Textarea durchgeführt wurde
- eine klare Einschätzung zur Produktnähe vorliegt
- ein direkt anschlussfähiger Folgeauftrag formuliert wurde