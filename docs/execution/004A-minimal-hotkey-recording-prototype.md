# Auftrag für Codex 004A: Minimalen Hotkey-/Aufnahme-Prototyp für PushWrite auf macOS umsetzen

## Ziel

Baue einen kleinen, kontrollierbaren Prototypen für den produktkritischen Kernablauf von PushWrite auf macOS:

- globalen Hotkey erkennen
- Aufnahme zuverlässig starten
- Aufnahme zuverlässig beenden
- Audio klar begrenzen
- Audio sauber an einen nachgelagerten Verarbeitungspunkt übergeben

Dieser Auftrag dient nicht dazu, bereits den vollständigen Whisper-Stack, die vollständige Textinjektion oder eine breite UI zu bauen.

Der Auftrag dient dazu, den engsten praktikablen Aufnahmefluss für das MVP technisch zu validieren.

---

## Getroffene Produktentscheidung für diesen Auftrag

Für diesen Prototyp gilt verbindlich:

- Hotkey-Modell: **press-and-hold**
- minimaler Hauptzustandsfluss: **idle -> recording -> processing -> idle**
- Fokus: **nur macOS**
- Fokus: **nur MVP 0.1.0**
- Inferenz-Richtung bleibt **whisper.cpp**
- dieser Auftrag baut **nicht** die vollständige Inferenz ein
- dieser Auftrag baut **nicht** die finale Texteingabe am Cursor ein
- Robustheit ist wichtiger als Flexibilität

### Begründung für die Entscheidung

Press-and-hold ist für diesen ersten Schritt enger und kontrollierbarer als toggle start/stop:

- Start und Stop sind semantisch eindeutig
- die Audio-Grenzen sind klarer
- der Zustandsraum bleibt kleiner
- Fehlverhalten durch Mehrfach-Trigger wird reduziert
- der Ablauf ist produktseitig leichter beobachtbar

Für diesen Auftrag wird diese Entscheidung nicht erneut offen diskutiert, sondern umgesetzt.

---

## Problemrahmen

PushWrite soll später per globalem Hotkey eine Mikrofonaufnahme starten, gesprochene Sprache lokal transkribieren und den Text an der aktuellen Cursor-Position einfügen.

Bevor dieser Gesamtfluss belastbar gebaut werden kann, muss der engste Aufnahmefluss technisch funktionieren:

1. Hotkey down
2. Start Aufnahme
3. Aufnahme läuft stabil
4. Hotkey up
5. Stop Aufnahme
6. Übergabe des aufgenommenen Audios an einen klaren Verarbeitungspunkt
7. Rückkehr in einen sauberen idle-Zustand

Genau dieser Kern ist jetzt zu validieren.

---

## Umsetzungsziel dieses Prototyps

Implementiere einen minimalen, testbaren Hotkey-/Aufnahmefluss mit diesen Eigenschaften:

- globaler Hotkey kann registriert werden
- Hotkey down startet Aufnahme nur aus `idle`
- Hotkey up beendet Aufnahme nur aus `recording`
- nach Stop wird das Audio als klar definierte Einheit übergeben
- der Ablauf wechselt nachvollziehbar durch die Zustände
- Fehlerfälle führen nicht zu einem hängenbleibenden Zwischenzustand

Die Übergabe an die nachgelagerte Verarbeitung darf in diesem Auftrag zunächst ein klar definierter interner Hook, Callback oder Funktionsaufruf sein.

---

## Verbindlicher Scope

### In Scope

- globalen Hotkey für press-and-hold registrieren
- Start der Aufnahme bei Hotkey down
- Stop der Aufnahme bei Hotkey up
- minimale Zustandssteuerung
- minimale Blockierungslogik gegen unzulässige Parallelabläufe
- Übergabe des fertigen Audios an einen Verarbeitungspunkt
- Logging oder andere schlanke Beobachtbarkeit für Zustände und Übergänge
- sauberes Zurücksetzen nach Erfolg oder Fehler

### Nicht in Scope

- toggle start/stop
- VAD-Logik
- kontinuierlicher Diktiermodus
- Datei-Transkription
- Ausbau der UI
- finale Textinjektion am Cursor
- Accessibility- oder Input-Monitoring-Umbau
- Modelloptimierung
- Backend-Vergleich
- Multiplattform-Betrachtung
- breite Architektur für spätere Erweiterungen

---

## Funktionslogik

### Interaktionsmodell

Der Hotkey wird als press-and-hold verwendet.

Regeln:

- **Hotkey down**:
  - wenn Zustand `idle`: Aufnahme starten
  - wenn Zustand nicht `idle`: ignorieren oder kontrolliert blockieren

- **Hotkey up**:
  - wenn Zustand `recording`: Aufnahme stoppen und Verarbeitung anstossen
  - wenn Zustand nicht `recording`: ignorieren

### Erwartetes Nutzungsverhalten

- Nutzer drückt den Hotkey
- PushWrite beginnt sofort mit der Aufnahme
- Nutzer spricht
- Nutzer lässt den Hotkey los
- PushWrite beendet die Aufnahme und übergibt das Audio weiter

---

## Minimales Zustandsmodell

Verwende für diesen Auftrag nur dieses kleine Hauptmodell:

- `idle`
- `recording`
- `processing`

Zusätzliche technische Flags oder Fehlerobjekte sind erlaubt, aber bitte **kein grosses State-Machine-Framework** einführen.

### Zustände

#### `idle`
Bedeutung:
- nichts läuft
- Hotkey down darf eine Aufnahme starten

Erlaubte Übergänge:
- `idle -> recording`

Nicht erlaubt:
- direkter Übergang nach `processing` ohne vorherige Aufnahme

#### `recording`
Bedeutung:
- Mikrofonaufnahme läuft aktiv

Erlaubte Übergänge:
- `recording -> processing`
- `recording -> idle` nur bei kontrolliertem Abbruch oder Startfehler-Rollback

Nicht erlaubt:
- zweites gleichzeitiges Starten einer Aufnahme
- erneuter Start über zusätzlichen Trigger

#### `processing`
Bedeutung:
- Aufnahme ist beendet
- Audio wird intern übergeben oder vorbereitet
- keine neue Aufnahme darf starten

Erlaubte Übergänge:
- `processing -> idle`

Nicht erlaubt:
- `processing -> recording` ohne saubere Rückkehr nach `idle`

---

## Start-, Stop- und Abbruchlogik

### Startlogik

Eine Aufnahme beginnt genau dann, wenn:

- der globale Hotkey gedrückt wird
- der Zustand aktuell `idle` ist
- die nötigen Voraussetzungen für Aufnahme erfüllt sind

Der Start muss scheitern dürfen. In diesem Fall gilt:

- kein halb gestarteter Zustand darf hängen bleiben
- Rückkehr nach `idle`
- Fehler muss beobachtbar sein

### Stoplogik

Eine Aufnahme endet genau dann, wenn:

- der Hotkey losgelassen wird
- der Zustand aktuell `recording` ist

Dann muss:

- die Aufnahme sauber beendet werden
- das Audio als abgeschlossene Einheit verfügbar sein
- der Zustand auf `processing` wechseln
- danach die Audio-Übergabe ausgelöst werden

### Abbruchlogik

Ein Abbruch liegt vor, wenn z. B.:

- Aufnahme nicht gestartet werden kann
- Aufnahme unerwartet fehlschlägt
- Audio unbrauchbar ist
- interner Übergabeschritt scheitert

Dann gilt minimal:

- kein Hängenbleiben in `recording` oder `processing`
- Rückkehr in einen definierten Zustand
- Fehler oder Blockierung beobachtbar machen

---

## Umgang mit kurzen oder leeren Aufnahmen

Für diesen Auftrag ist noch keine endgültige Produktpolitik für Insert-Gates nötig.

Aber technisch muss der Prototyp unterscheiden können zwischen:

- brauchbarer Aufnahme
- leerer Aufnahme
- offensichtlich zu kurzer Aufnahme

Minimale Anforderung:

- die Aufnahme-Metadaten oder Resultate müssen so vorliegen, dass spätere Gate-Logik darauf aufbauen kann
- leere oder unbrauchbare Aufnahmen dürfen den Ablauf nicht inkonsistent machen
- Rückkehr nach `idle` muss immer möglich sein

Ob die Klassifikation bereits über Dauer, Sampleanzahl oder andere einfache Heuristik erfolgt, darf pragmatisch entschieden werden. Bitte dokumentieren, welche Heuristik gewählt wurde.

---

## Übergabe an die Verarbeitung

In diesem Auftrag ist nicht die vollständige Whisper-Integration gefordert.

Es muss aber einen klaren, kleinen Übergabepunkt geben.

Anforderung:

- nach Stop der Aufnahme wird das Audio an genau einen klar definierten Verarbeitungspunkt übergeben
- dieser Verarbeitungspunkt soll so geschnitten sein, dass später `whisper.cpp` dort angeschlossen werden kann
- bitte keine grosse Vorab-Abstraktion bauen
- einfache, saubere Schnittstelle bevorzugen

Beispiele für akzeptable Formen:

- Übergabe eines Dateipfads auf temporäres Audio
- Übergabe eines Audio-Buffers
- Übergabe eines kleinen Request-Objekts mit den nötigsten Feldern

Bitte die einfachste Variante wählen, die für den jetzigen Code am wenigsten Komplexität erzeugt.

---

## Fehler- und Randfälle

Mindestens diese Fälle müssen sauber behandelt oder bewusst blockiert werden:

### 1. Hotkey down kommt, aber Aufnahme startet nicht
Erwartung:
- Fehler beobachten
- kein Hängenbleiben
- Rückkehr nach `idle`

### 2. Hotkey up kommt, obwohl keine Aufnahme läuft
Erwartung:
- ignorieren
- kein Fehlerzustand erzwingen

### 3. Während `recording` kommt ein weiterer Trigger
Erwartung:
- ignorieren oder kontrolliert blockieren
- keine zweite Aufnahme eröffnen

### 4. Während `processing` kommt ein neuer Startversuch
Erwartung:
- blockieren
- keine Parallelverarbeitung und keine zweite Aufnahme starten

### 5. Aufnahme liefert leeres oder unbrauchbares Audio
Erwartung:
- kontrollierter Abschluss
- beobachtbarer Befund
- Rückkehr nach `idle`

### 6. Übergabe an den Verarbeitungspunkt scheitert
Erwartung:
- Fehler beobachten
- sauber nach `idle` zurückkehren

### 7. Status bleibt inkonsistent hängen
Erwartung:
- aktiv verhindern
- lieber klein und strikt schneiden als zu flexibel bauen

---

## Beobachtbarkeit

Dieser Prototyp muss gut beobachtbar sein.

Bitte baue schlanke, klare Beobachtbarkeit ein, z. B. über Logging.

Mindestens sichtbar sein sollen:

- Hotkey down erkannt
- Startversuch Aufnahme
- Zustand `recording` erreicht
- Hotkey up erkannt
- Stop erfolgt
- Zustand `processing` erreicht
- Audio-Übergabe gestartet
- Erfolg oder Fehler
- Rückkehr nach `idle`

Bitte keine grosse Telemetrie bauen. Es geht nur um lokale technische Nachvollziehbarkeit.

---

## Technische Leitplanken

- bestehende Projektstruktur respektieren
- keine breite Neustrukturierung des Projekts
- keine hypothetische Architektur für spätere Plattformen
- keine unnötige Abstraktionsschicht
- kleine, nachvollziehbare Änderungen bevorzugen
- wenn ein Helper nötig ist, klein halten
- nur den minimal nötigen Code hinzufügen

---

## Erwartetes Ergebnis

Am Ende dieses Auftrags soll ein enger Prototyp existieren, der technisch zeigt:

- globaler press-and-hold Hotkey funktioniert
- Aufnahme startet und stoppt kontrolliert
- Zustandswechsel sind nachvollziehbar
- Audio wird an einen klaren Verarbeitungspunkt übergeben
- der Ablauf bleibt auch bei Fehlern kontrollierbar

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn Folgendes belegbar ist:

1. Ein globaler Hotkey kann im laufenden App-Kontext erkannt werden.
2. Hotkey down startet aus `idle` eine Aufnahme.
3. Hotkey up beendet aus `recording` die Aufnahme.
4. Der Ablauf verwendet mindestens die Zustände `idle`, `recording`, `processing`.
5. Während `processing` startet keine neue Aufnahme.
6. Leere, zu kurze oder fehlgeschlagene Aufnahmen lassen den Zustand nicht hängen.
7. Nach Erfolg oder Fehler kehrt der Ablauf wieder in `idle` zurück.
8. Es gibt einen klaren Übergabepunkt für die spätere `whisper.cpp`-Anbindung.
9. Der Prototyp verändert noch nicht die finale Textinjektion.
10. Die Umsetzung bleibt eng und führt keine unnötige Zusatzkomplexität ein.

---

## Gewünschte Lieferung von Codex

Bitte liefere:

1. die Umsetzung des minimalen Prototyps
2. eine kurze Beschreibung der konkret gewählten Schnittstelle für die Audio-Übergabe
3. eine kurze Beschreibung der Zustandslogik
4. eine Liste der bewusst noch nicht gebauten Punkte
5. einen kurzen Testhinweis, wie der Ablauf lokal nachvollzogen werden kann

---

## Wichtige Abgrenzung

Nicht lösen in diesem Auftrag:

- endgültige Whisper-Inferenz
- endgültige Modellwahl
- endgültige Accessibility- oder Insert-Strategie
- UX-Polish
- Produktentscheid für spätere Diktiermodi

Wenn du an eine Stelle kommst, an der diese Themen den Auftrag aufblähen würden, stoppe die Ausweitung und halte die Umsetzung bewusst eng.

---

## Priorität bei Entscheidungen

Wenn während der Umsetzung Zielkonflikte auftreten, gilt diese Priorität:

1. Stabiler, enger Ablauf
2. Saubere Zustandsgrenzen
3. Klare Beobachtbarkeit
4. Kleine Eingriffsfläche im Code
5. Erst danach Bequemlichkeit oder spätere Erweiterbarkeit