# Auftrag 002D: Produkt-Bundle-Startpfad, Accessibility-Blocked-Flow und insertTranscription(text:) für PushWrite v0.1.0 integrieren

## Ziel

Überführe den in 002C produktnah aufgebauten paste-basierten Insert-Pfad in den ersten echten PushWrite-Produktkontext.

Der Auftrag dient nicht dazu, die vollständige PushWrite-App mit Hotkey, Audioaufnahme und Transkription fertigzustellen.  
Er dient dazu, den bereits validierten Insert-Pfad an das konkrete PushWrite-Produktbundle zu binden, einen minimalen produktgerechten Start- und Blocked-Flow für Accessibility zu schaffen und einen internen Produkt-Trigger `insertTranscription(text:)` an denselben Pfad anzuschliessen.

Das Ergebnis soll so konkret sein, dass danach entschieden werden kann:

- ob der Insert-Pfad im echten Produktbundle stabil genug verankert ist
- ob der minimale produktseitige Accessibility-Flow tragfähig ist
- wie der nächste Integrationsschritt mit Hotkey, Audio und Transkription geschnitten werden soll

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

- der paste-basierte Pfad ist technisch validiert
- ein fokusstabiler Harness war im getesteten Scope tragfähig
- ein kleiner produktnaher Hintergrund-Agent wurde aufgebaut
- der Blocked-Pfad für fehlende Accessibility wurde beobachtet
- offen ist noch die produktnahe Revalidierung des Success-Pfads auf genau dem neuen Produktbundle

Der nächste sinnvolle Schritt ist deshalb nicht ein weiterer abstrakter Spike, sondern die Anbindung an das konkrete PushWrite-Produktbundle.

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- der paste-basierte Insert-Pfad bleibt der gesetzte Insert-Erstpfad
- Accessibility ist für diesen Pfad als zwingende Voraussetzung zu behandeln
- integriert wird in das konkrete PushWrite-Produktbundle
- der Schritt bleibt minimal und produktnah
- keine Mikrofonaufnahme in diesem Auftrag
- keine Whisper- oder `whisper.cpp`-Integration in diesem Auftrag
- keine vollständige Hotkey-Produktintegration in diesem Auftrag
- keine breite UI-Ausarbeitung
- keine alternative Textinjektionsmethode in diesem Auftrag

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- wie der produktnahe Insert-Agent an die konkrete PushWrite-App-Datei gebunden wird
- wie der stabile Produkt-Startpfad für genau dieses Bundle aussieht
- wie ein minimaler First-Run- und Blocked-Flow für fehlende Accessibility im Produktkontext aussehen muss
- wie ein interner Produkt-Trigger `insertTranscription(text:)` an denselben Insert-Pfad angebunden wird
- ob der Success-Pfad auf genau diesem Bundle für TextEdit, Safari-Textarea und Clipboard-Restore erneut stabil bestätigt werden kann

---

## Konkreter Auftrag

Integriere den validierten paste-basierten Insert-Pfad in das konkrete PushWrite-Produktbundle und schaffe die minimalen produktseitigen Voraussetzungen für dessen reproduzierbare Nutzung.

Der Auftrag soll mindestens diese Teile enthalten:

1. stabilen Startpfad für die konkrete PushWrite-App-Datei festlegen
2. minimalen First-Run-/Blocked-Flow für fehlende Accessibility implementieren
3. internen Produkt-Trigger `insertTranscription(text:)` an den bestehenden Insert-Pfad anbinden
4. Success-Regression auf genau diesem Produktbundle erneut ausführen
5. Ergebnisse und verbleibende Resthärtung dokumentieren

Der Auftrag ist eine produktnahe Integrationsstufe, aber noch nicht die vollständige MVP-App.

---

## Erwartetes Ergebnis

Liefere:

### 1. Stabilen Produkt-Startpfad
Definiere und implementiere einen reproduzierbaren Startpfad für die konkrete PushWrite-App-Datei.

Dabei ist zu klären:

- wie genau das Produktbundle gestartet wird
- wie verhindert wird, dass für denselben Entwicklungsschritt unnötig neue Accessibility-Freigaben nötig werden
- welche Startvariante für Entwicklung und wiederholte Validierung stabil genug ist

### 2. Minimalen Accessibility-First-Run-/Blocked-Flow
Implementiere einen kleinen, produktgerechten Flow für den Fall fehlender Accessibility-Freigabe.

Der Flow soll mindestens leisten:

- fehlende Freigabe erkennen
- den Zustand klar als Blockade markieren
- dem Nutzer minimal verständlich sagen, was fehlt
- keinen falschen Success-Zustand vortäuschen

Nicht gesucht ist ein ausgebautes Onboarding, sondern ein minimal belastbarer Produktfluss.

### 3. Internen Produkt-Trigger `insertTranscription(text:)`
Binde einen internen Trigger an den bestehenden Insert-Pfad an.

Ziel ist:

- der Agent oder Produktkern kann programmatisch Text an den Insert-Pfad übergeben
- der Trigger ist klein, klar und produktnah
- der Trigger dient als Vorstufe für spätere Hotkey-/Audio-/Transkriptionsintegration

### 4. Success-Regression auf genau diesem Produktbundle
Führe die produktnahe Revalidierung auf genau dieser App-Datei erneut aus.

Mindestens zu prüfen sind:

- TextEdit
- Safari-Textarea
- Clipboard-Restore für Plain Text
- Clipboard-Restore für den bereits definierten nicht-trivialen Clipboard-Inhalt

### 5. Dokumentierte Beobachtungen
Halte mindestens fest:

- ob der Success-Pfad auf genau diesem Produktbundle stabil bestätigt wurde
- ob neue Fokusprobleme auftreten
- wie sich der Blocked-Flow verhält
- ob `insertTranscription(text:)` sauber am Insert-Pfad hängt
- welche Resthärtung für den MVP noch fehlt

### 6. MVP-Einordnung
Bewerte am Ende klar:

- produktnah tragfähig
- tragfähig mit kleiner verbleibender Resthärtung
- noch nicht stabil genug für weitere Produktintegration

### 7. Konkrete Folgeempfehlung
Formuliere daraus einen kleinen Folgeauftrag für den nächsten echten Integrationsschritt.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- auf dem validierten paste-basierten Insert-Pfad aufbauen
- an das konkrete PushWrite-Produktbundle gebunden sein
- Accessibility-Blocked-Flow explizit behandeln
- `insertTranscription(text:)` als internen Produkt-Trigger bereitstellen
- Success- und Blocked-Pfad sauber unterscheiden
- Beobachtung und Bewertung sauber trennen
- bewusst klein und produktnah bleiben

Wenn Unsicherheiten bleiben, müssen sie als offene Punkte markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- vollständige PushWrite-App
- globale Hotkey-Produktintegration
- Mikrofonaufnahme
- Whisper- oder `whisper.cpp`-Integration
- vollständige Zustandsmaschine des Gesamtprodukts
- breite UI- oder Settings-Oberfläche
- alternative Textinjektionsmethoden
- Unterstützung aller macOS-Anwendungen
- Multiplattform-Betrachtung
- generische Architektur für spätere Major-Releases

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Ist der Insert-Pfad auf dem konkreten PushWrite-Bundle reproduzierbar stabil?
2. Ist der Produkt-Startpfad so gewählt, dass Entwicklung und Validierung nicht unnötig an TCC/Freigaben scheitern?
3. Ist der Accessibility-Blocked-Flow minimal, ehrlich und verständlich genug?
4. Ist `insertTranscription(text:)` als interner Trigger klein und sauber genug für weitere Integration?
5. Welche kleinste Resthärtung fehlt vor der Anbindung an Hotkey, Audio und Transkription?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- erstellte oder geänderte Artefakte
- Beschreibung des Startpfads
- Beschreibung des First-Run-/Blocked-Flows
- Beschreibung von `insertTranscription(text:)`
- Ergebnisse der Success-Regression
- technische Risiken oder offene Fragen
- klare MVP-Einordnung
- konkreten Folgeauftrag

Keine allgemeine Plattformdiskussion.  
Keine unnötige Theorie.  
Keine breite Zukunftsarchitektur.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- ein stabiler Startpfad für die konkrete PushWrite-App-Datei festgelegt wurde
- ein minimaler Accessibility-First-Run-/Blocked-Flow implementiert wurde
- `insertTranscription(text:)` an den bestehenden Insert-Pfad angebunden wurde
- die Success-Regression für TextEdit, Safari-Textarea und Clipboard-Restore auf genau diesem Bundle erneut ausgeführt wurde
- Success- und Blocked-Verhalten nachvollziehbar dokumentiert wurden
- eine klare Einschätzung zur Produktnähe vorliegt
- ein direkt anschlussfähiger Folgeauftrag formuliert wurde