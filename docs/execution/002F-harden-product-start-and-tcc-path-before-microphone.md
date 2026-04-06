# Auftrag 002F: Produkt-Startpfad und TCC-/Accessibility-Verhalten von PushWrite.app vor der Mikrofonintegration härten

## Ziel

Härte den realen Start- und Berechtigungspfad von PushWrite.app, bevor Mikrofonaufnahme an den bestehenden Hotkey-/Flow-Kern angebunden wird.

Der Auftrag dient nicht dazu, bereits Audioaufnahme oder `whisper.cpp` zu integrieren.  
Er dient dazu, den nach 002E verbleibenden technischen Engpass sauber zu schliessen:

- realen Produktstart stabilisieren
- echtes TCC-/Accessibility-Verhalten des Bundles belastbar machen
- Blocked-Fokusbeobachtung bereinigen
- Hotkey-Validierung auf den stabilen Produktstartpfad umstellen

Das Ergebnis soll so konkret sein, dass danach der nächste Integrationsschnitt für Mikrofon-Start/Stop ohne Vermischung von Fehlerklassen erfolgen kann.

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

Für diesen Workflow sind im Projekt bereits folgende Grundlagen gesetzt:

- macOS ist die einzige Zielplattform des MVP
- der Standardpfad ist lokal und offline-fähig
- `whisper.cpp` ist die bevorzugte Inferenz-Basis
- Inferenz-Layer und macOS-App-Layer sind getrennt zu betrachten
- keine Datei-Transkription
- keine Multi-Engine-Architektur
- keine vorzeitige Multiplattform-Abstraktion

Nach 002E ist der erste produktnahe Kern ohne Audio vorhanden:

- globaler Hotkey
- kleiner Flow
- simuliertes In-Memory-Transkript
- `insertTranscription(text:)`
- funktionierender Insert-Pfad im Produktbundle
- ehrlicher Blocked-Fall ohne falschen Success

Der verbleibende Engpass liegt nun im realen Start-/TCC-Pfad des Bundles und nicht mehr in der grundsätzlichen Insert-Logik.

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- PushWrite.app ist das relevante Produktbundle
- der bestehende paste-basierte Insert-Pfad bleibt gesetzt
- der bestehende Hotkey-/Flow-Kern aus 002E bleibt gesetzt
- Audioaufnahme ist nicht Teil dieses Auftrags
- `whisper.cpp`-Integration ist nicht Teil dieses Auftrags
- der Auftrag dient der Härtung, nicht der breiten Funktionserweiterung
- keine alternative Textinjektionsmethode
- keine breite UI- oder Settings-Ausarbeitung
- keine Multiplattform-Betrachtung

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- wie der reale Startpfad von PushWrite.app für Entwicklung und wiederholte Validierung stabil festgelegt wird
- wie das echte TCC-/Accessibility-Verhalten des konkreten Bundles beobachtet und belastbar behandelt werden kann
- wie Blocked-Verhalten diagnostisch sauber erfasst wird, insbesondere bei Fokusbeobachtung
- wie der Hotkey-Validator auf genau diesen stabilen Produktstartpfad umgestellt wird
- welche Resthärtung danach vor der Mikrofonintegration noch übrig bleibt

---

## Konkreter Auftrag

Härte den realen Produkt-Startpfad und das TCC-/Accessibility-Verhalten von PushWrite.app, ohne den bestehenden Produktkern unnötig zu verbreitern.

Der Auftrag soll mindestens diese Teile enthalten:

1. stabilen realen Startpfad für PushWrite.app festlegen
2. TCC-/Accessibility-Verhalten des konkreten Bundles belastbar dokumentieren
3. Blocked-Fokusbeobachtung bereinigen
4. Hotkey-Validator auf den stabilen Produktstartpfad umstellen
5. produktnahe Revalidierung des bestehenden Hotkey-/Flow-/Insert-Kerns auf diesem Pfad durchführen
6. verbleibende Resthärtung für die Mikrofonstufe benennen

---

## Erwartetes Ergebnis

Liefere:

### 1. Stabilen realen Produktstart
Lege einen reproduzierbaren Startpfad für PushWrite.app fest.

Zu klären ist:

- welcher Startpfad im Entwicklungs- und Validierungskontext tatsächlich belastbar ist
- warum alternative Startpfade scheitern oder unzuverlässig sind
- wie sich unnötige neue Accessibility-Freigaben durch Rebuilds oder Pfadwechsel minimieren lassen

### 2. Belastbare TCC-/Accessibility-Einordnung
Dokumentiere das reale Verhalten des konkreten Produktbundles im Umgang mit Accessibility.

Mindestens zu klären:

- wie ein echter trusted-Zustand des Bundles beobachtet und validiert wird
- wie ein echter oder reproduzierbar simulierter blocked-Zustand eingeordnet wird
- welche Grenzen die aktuelle Entwicklungsumgebung dabei setzt
- welche Aussagen gesichert sind und welche nur plausible Ableitungen bleiben

### 3. Bereinigte Blocked-Fokusbeobachtung
Untersuche und bereinige die noch unsaubere Fokusbeobachtung im Blocked-Fall.

Ziel ist:

- der Blocked-Pfad ist nicht nur funktional korrekt, sondern auch diagnostisch sauber
- Fokusbeobachtung und Blockadeursache werden nicht unnötig vermischt
- relevante Logs oder Zustände bleiben für spätere Fehlersuche brauchbar

### 4. Gehärteter Hotkey-Validator
Stelle den vorhandenen Hotkey-Validator auf den stabilen Produktstartpfad um.

Der Validator soll:

- mit dem realen Produktbundle arbeiten
- nicht an einem fragilen Launch-Pfad hängen
- den bestehenden Hotkey-/Flow-Kern verlässlich prüfen können

### 5. Produktnahe Revalidierung
Führe auf dem gehärteten Startpfad eine kleine, aber nachvollziehbare Revalidierung des vorhandenen Kerns durch.

Mindestens zu prüfen sind:

- Success-Pfad in TextEdit
- Success-Pfad in Safari-Textarea
- Blocked-Pfad
- Hotkey-Auslösung auf dem realen Bundle
- Logs und Statusartefakte auf Kohärenz

Die Serie darf bewusst eng bleiben. Ziel ist hier Härtung des Start-/TCC-Pfads, nicht breite Insert-Regression.

### 6. Dokumentierte Beobachtungen
Halte mindestens fest:

- welcher Startpfad als belastbar festgelegt wurde
- wie sich trusted und blocked auf genau diesem Bundle verhalten
- ob die Fokusbeobachtung im Blocked-Fall bereinigt werden konnte
- ob der Hotkey-Validator jetzt auf dem realen Produktpfad sauber läuft
- welche verbleibenden Risiken vor Mikrofonintegration noch bestehen

### 7. MVP-Einordnung
Bewerte am Ende klar:

- produktnah gehärtet genug für die nächste Integrationsstufe
- im Wesentlichen tragfähig, aber mit kleiner verbleibender Resthärtung
- noch nicht stabil genug für Mikrofon-Start/Stop

### 8. Konkrete Folgeempfehlung
Formuliere daraus einen kleinen Folgeauftrag für die nächste Stufe.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- auf PushWrite.app und dem bestehenden 002E-Kern aufbauen
- den Start-/TCC-Pfad des realen Bundles fokussieren
- Hotkey, Flow und Insert nicht neu erfinden, sondern gezielt härten
- Beobachtung, Ableitung und Empfehlung sauber trennen
- klare Aussagen zu gesichert, plausibel und offen ermöglichen
- bewusst klein und risikoorientiert bleiben

Wenn Unsicherheiten bleiben, müssen sie als offene Punkte markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- Mikrofonaufnahme
- Audio-Pufferung
- `whisper.cpp`-Integration
- Modellwahl oder Modell-Packaging
- finale Zustandsmaschine des Gesamtprodukts
- breite UI- oder Settings-Oberfläche
- alternative Textinjektionsmethoden
- Unterstützung aller macOS-Anwendungen
- Multiplattform-Betrachtung
- allgemeine Zukunftsarchitektur

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Ist der reale Startpfad des konkreten Produktbundles stabil genug für wiederholte Entwicklung und Validierung?
2. Ist das TCC-/Accessibility-Verhalten des Bundles belastbar genug verstanden?
3. Ist der Blocked-Fall diagnostisch sauber genug beobachtbar?
4. Lässt sich der Hotkey-Kern jetzt auf diesem Pfad verlässlich validieren?
5. Welche kleinste Resthärtung fehlt noch, bevor Mikrofon-Start/Stop dazukommt?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- erstellte oder geänderte Artefakte
- Beschreibung des gehärteten Startpfads
- Beschreibung des TCC-/Accessibility-Verhaltens
- Beobachtungen zum Blocked-Fokus
- Beschreibung der Hotkey-Validator-Umstellung
- Ergebnisse der produktnahen Revalidierung
- technische Risiken oder offene Fragen
- klare MVP-Einordnung
- konkreten Folgeauftrag

Keine allgemeine Plattformdiskussion.  
Keine unnötige Theorie.  
Keine breite Zukunftsarchitektur.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- ein belastbarer Startpfad für PushWrite.app festgelegt wurde
- das TCC-/Accessibility-Verhalten des konkreten Bundles nachvollziehbar dokumentiert wurde
- die Blocked-Fokusbeobachtung bereinigt oder klar eingegrenzt wurde
- der Hotkey-Validator auf den stabilen Produktstartpfad umgestellt wurde
- eine kleine produktnahe Revalidierung des bestehenden Kerns durchgeführt wurde
- eine klare Einschätzung zur Start-/TCC-Härtung vorliegt
- ein direkt anschlussfähiger Folgeauftrag formuliert wurde