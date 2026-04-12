# Auftrag 002I: Mikrofon-Start/Stop in den gehärteten Stable-Hotkey-Flow von PushWrite.app integrieren

## Ziel

Integriere echte Mikrofonaufnahme in den bestehenden, gehärteten Stable-Hotkey-Kern von PushWrite.app.

Der Auftrag dient nicht dazu, bereits `whisper.cpp`, Modellintegration oder echte Transkription einzubauen.  
Er dient dazu, den nächsten echten MVP-Baustein zu schliessen:

- Hotkey löst nicht mehr nur einen simulierten Textfluss aus
- sondern steuert reale Mikrofonaufnahme
- mit sauberem Start/Stop
- mit erweitertem Runtime-State
- und mit klaren Blocked-/No-Mic-/No-Permission-Pfaden

Das Ergebnis soll so konkret sein, dass danach der nächste Schnitt für lokale Transkription vorbereitet werden kann.

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

Nach 002H gilt:

- der Stable-Hotkey-Kern ist gehärtet
- der Flow ist beobachtbar
- der Insert-Pfad ist auf dem Stable-Bundle belegt
- echte Stable-Success-Nachweise für TextEdit und Safari liegen vor
- der Blocked-Fall ist sauber validiert

Nach 003 gilt zusätzlich:

- Accessibility ist bereits praktisch relevanter Produktfaktor
- Mikrofon ist der nächste zwingende Permission-Schritt
- Mikrofon-Prompt soll erst bei echter Aufnahmeabsicht erfolgen, nicht pauschal beim App-Start
- der First-Run-Flow soll minimal, ehrlich und nicht unnötig blockierend sein

Damit ist der nächste sinnvolle Schritt:

**echte Mikrofonaufnahme an denselben Hotkey-/Flow-Kern anbinden, aber noch ohne echte Whisper-Transkription.**

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- `PushWrite.app` im Stable-Pfad ist das relevante Bundle
- der bestehende Hotkey-/Flow-/Insert-Kern bleibt gesetzt
- echte Mikrofonaufnahme ist Teil dieses Auftrags
- `whisper.cpp`-Integration ist nicht Teil dieses Auftrags
- Modellwahl ist nicht Teil dieses Auftrags
- Mikrofonberechtigung wird erst bei echter Aufnahmeabsicht angefragt
- Accessibility bleibt Voraussetzung für den bestehenden Insert-/Produktpfad
- keine alternative Textinjektionsmethode
- keine breite UI- oder Settings-Ausarbeitung
- keine Multiplattform-Betrachtung

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- wie echte Mikrofonaufnahme an den bestehenden Stable-Hotkey-Kern angebunden wird
- wie Hotkey-Down und Hotkey-Up den Aufnahmefluss steuern
- wie der Runtime-State dafür minimal erweitert werden muss
- wie der Mikrofon-Permission-Schritt produktnah und minimal in den bestehenden Flow eingebettet wird
- wie no-mic, no-permission und blocked im selben Evidenzstil beobachtbar werden
- ob der Produktkern mit echter Aufnahme vor der Transkriptionsstufe stabil genug ist

---

## Konkreter Auftrag

Erweitere PushWrite.app so, dass der bestehende Stable-Hotkey-/Flow-Kern echte Mikrofonaufnahme steuert.

Der Auftrag soll mindestens diese Teile enthalten:

1. Mikrofonaufnahme an denselben Stable-Hotkey-Kern anbinden
2. Hotkey-Down/Hotkey-Up sauber in Aufnahme-Start/Stop übersetzen
3. Runtime-State um mindestens `recording` und `transcribing` erweitern
4. Mikrofon-Permission erst beim ersten echten Aufnahmeversuch anfordern
5. `NSMicrophoneUsageDescription` korrekt in den Produktpfad aufnehmen
6. no-mic, no-permission und blocked sauber behandeln
7. produktnahe Validierung dieser Pfade durchführen
8. die verbleibende Resthärtung vor echter Transkriptionsintegration benennen

Der Auftrag soll bewusst klein bleiben und noch keine echte Modell-/Inferenzlogik einführen.

---

## Erwartetes Ergebnis

Liefere:

### 1. Echte Mikrofonanbindung
Integriere echte Mikrofonaufnahme in PushWrite.app.

Zu klären ist:

- wie Aufnahme gestartet wird
- wie sie beendet wird
- wie der Audiofluss minimal bereitgestellt oder gespeichert wird
- wie verhindert wird, dass neue Fehlerklassen unnötig breit werden

### 2. Hotkey-Down/Hotkey-Up-Steuerung
Der bestehende Hotkey soll für diese Stufe sauber in Start/Stop-Logik übersetzt werden.

Zu dokumentieren ist:

- welches Interaktionsmodell konkret verwendet wird
- wann recording beginnt
- wann recording endet
- wie doppelte oder ungültige Trigger behandelt werden

### 3. Erweiterter Runtime-State
Erweitere den beobachtbaren Produktzustand mindestens um:

- `recording`
- `transcribing`

Wenn `transcribing` in dieser Stufe nur ein Übergangszustand ohne echte Inferenz ist, muss das klar benannt werden.

### 4. Permission-Verhalten im echten Produktfluss
Implementiere und dokumentiere das Permission-Verhalten produktnah.

Mindestens zu leisten ist:

- Mikrofonberechtigung wird nicht pauschal beim App-Start angefragt
- der Prompt erscheint erst bei echter Aufnahmeabsicht
- Verhalten bei erteilter Freigabe ist klar
- Verhalten bei verweigerter Freigabe ist klar
- Wiederverhalten bei erneutem Aufnahmeversuch ist klar

### 5. Fehler- und Blockadepfade
Mindestens zu behandeln und zu beobachten:

- Mikrofonberechtigung fehlt
- kein Mikrofon verfügbar
- blocked-Zustand
- Hotkey löst aus, Aufnahme startet aber nicht
- Stop erfolgt, aber Runtime-Artefakte sind inkonsistent

### 6. Produktnahe Validierung
Führe eine kleine, aber belastbare Validierung durch.

Mindestens zu prüfen sind:

- ein echter Recording-Start/Stop-Pfad
- Erstprompt beim ersten echten Aufnahmeversuch
- Verhalten nach erteilter Freigabe
- Verhalten nach verweigerter Freigabe
- ein no-permission-Pfad
- ein no-mic- oder plausibel äquivalenter Gerätefehlerpfad
- Konsistenz von Runtime-State und Logs

Für diese Stufe ist noch kein beobachteter Zielwert im Texteingabekontext erforderlich, solange keine echte Transkription angeschlossen ist.

### 7. Dokumentierte Beobachtungen
Halte mindestens fest:

- ob der Hotkey den Aufnahmefluss zuverlässig steuert
- ob recording und stop konsistent im State landen
- ob der Permission-Prompt an der richtigen Stelle erscheint
- ob no-permission und no-mic sauber unterscheidbar sind
- ob blocked korrekt behandelt wird
- welche Runtime-Artefakte später für die Transkriptionsstufe weiterverwendet werden können

### 8. MVP-Einordnung
Bewerte am Ende klar:

- stabil genug für die Transkriptionsstufe
- im Wesentlichen tragfähig, aber mit kleiner Resthärtung
- noch nicht stabil genug für `whisper.cpp`-Anbindung

### 9. Konkrete Folgeempfehlung
Formuliere daraus einen kleinen Folgeauftrag für die nächste Stufe.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- auf dem gehärteten Stable-Hotkey-Kern aufbauen
- echte Mikrofonaufnahme integrieren
- `whisper.cpp` bewusst noch ausschliessen
- den Permission-Fluss aus Produktsicht behandeln
- Mikrofonberechtigung erst bei echter Aufnahmeabsicht anfragen
- `NSMicrophoneUsageDescription` korrekt berücksichtigen
- Beobachtung, Interpretation und Empfehlung sauber trennen
- Runtime-State und Logs konsistent halten
- bewusst klein und risikoorientiert bleiben

Wenn Unsicherheiten bleiben, müssen sie als offene Punkte markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- `whisper.cpp`-Integration
- Modellwahl oder Modell-Packaging
- echte Sprach-zu-Text-Inferenz
- breite UI- oder Settings-Ausarbeitung
- alternative Textinjektionsmethoden
- Unterstützung aller macOS-Anwendungen
- Multiplattform-Betrachtung
- allgemeine Zukunftsarchitektur
- vollständiger First-Run-/Onboarding-Ausbau

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Lässt sich echte Mikrofonaufnahme sauber an den bestehenden Stable-Hotkey-Kern anbinden?
2. Ist Hotkey-Down/Hotkey-Up als Aufnahme-Start/Stop stabil genug?
3. Erscheint der Mikrofon-Prompt erst bei echter Aufnahmeabsicht?
4. Sind recording und transcribing im Runtime-State klar und konsistent?
5. Sind no-permission, no-mic und blocked sauber beobachtbar?
6. Welche kleinste Resthärtung fehlt noch vor `whisper.cpp`-Anbindung?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- erstellte oder geänderte Artefakte
- Beschreibung der Mikrofonanbindung
- Beschreibung des Hotkey-Start/Stop-Modells
- Beschreibung des Permission-Verhaltens
- Beschreibung des erweiterten Runtime-State
- Ergebnisse der produktnahen Validierung
- technische Risiken oder offene Fragen
- klare MVP-Einordnung
- konkreten Folgeauftrag

Keine allgemeine Plattformdiskussion.  
Keine unnötige Theorie.  
Keine breite Zukunftsarchitektur.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- echte Mikrofonaufnahme an PushWrite.app angebunden wurde
- der Hotkey Aufnahme-Start/Stop auf dem Stable-Kern steuert
- `recording` und `transcribing` im Runtime-State nachvollziehbar sind
- Mikrofonberechtigung erst bei echter Aufnahmeabsicht angefragt wird
- `NSMicrophoneUsageDescription` korrekt berücksichtigt ist
- no-permission, no-mic oder äquivalente Gerätefehler und blocked dokumentiert wurden
- eine kleine produktnahe Validierung durchgeführt wurde
- eine klare Einschätzung zur Reife vor der Transkriptionsstufe vorliegt
- ein direkt anschlussfähiger Folgeauftrag formuliert wurde