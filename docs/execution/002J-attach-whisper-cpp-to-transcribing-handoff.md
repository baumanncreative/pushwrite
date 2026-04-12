# Auftrag 002J: `whisper.cpp` an den bestehenden `transcribing`-Übergabepunkt von PushWrite.app anschliessen

## Ziel

Schliesse echte lokale Sprach-zu-Text-Inferenz an den bereits vorhandenen `transcribing`-Übergabepunkt von PushWrite.app an.

Der Auftrag dient nicht dazu, den gesamten MVP fertigzustellen oder eine breite Inferenzarchitektur einzuführen.  
Er dient dazu, den bestehenden produktnahen Kern um genau den nächsten fehlenden Baustein zu erweitern:

- vorhandenes WAV-Artefakt aus dem Recording-Pfad lesen
- den bisherigen Platzhalterzustand `transcribing` durch echten lokalen Inferenzaufruf ersetzen
- Transkriptionsergebnis oder Inferenzfehler in denselben Runtime-/Response-Artefakten dokumentieren
- den Produktfluss ohne neue Audioabstraktion weiterführen

Das Ergebnis soll so konkret sein, dass danach der erste echte End-to-End-Pfad
**Hotkey -> Recording -> lokale Inferenz -> Textresultat**
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

Nach 002I gilt:

- der Stable-Hotkey steuert echte Mikrofonaufnahme als `press-and-hold`
- Hotkey-Down startet Recording, Hotkey-Up beendet es
- das Produkt schreibt ein wiederverwendbares WAV-Artefakt plus Metadaten
- der Flow läuft bereits durch `triggered -> recording -> transcribing -> done|blocked|error`
- `transcribing` ist aktuell noch ein Platzhalterzustand ohne echte Inferenz
- Success, Accessibility-Blocked, Microphone-Denied und No-Mic sind bereits sauber getrennt beobachtbar

Die nächste sinnvolle Stufe ist deshalb nicht neue Aufnahme-Logik, sondern die Anbindung von `whisper.cpp` an genau diesen bestehenden Übergabepunkt.

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- `PushWrite.app` im Stable-Pfad ist das relevante Bundle
- der bestehende Hotkey-/Flow-/Recording-Kern bleibt gesetzt
- das bestehende WAV-Artefakt aus 002I wird wiederverwendet
- `whisper.cpp` ist die gesetzte Inferenz-Richtung
- keine neue Audioaufnahme-Abstraktion
- keine alternative Inferenz-Engine
- keine breite UI- oder Settings-Ausarbeitung
- keine Multiplattform-Betrachtung

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- wie `whisper.cpp` direkt an das in 002I erzeugte WAV-Artefakt angebunden wird
- ob das bestehende Artefaktformat ohne zusätzliche Vor-Konvertierung tragfähig ist
- wie Textresultate oder Inferenzfehler in denselben Runtime-/Response-Artefakten landen
- wie der Produktfluss von `transcribing` in einen echten Ergebnis- oder Fehlerzustand übergeht
- ob der erste echte End-to-End-Pfad vor der Textinjektion stabil genug ist

---

## Konkreter Auftrag

Erweitere PushWrite.app so, dass der bestehende `transcribing`-Übergabepunkt echte lokale Inferenz über `whisper.cpp` ausführt.

Der Auftrag soll mindestens diese Teile enthalten:

1. das bestehende WAV-Artefakt aus `runtime/.../recordings/<flow-id>.wav` lesen
2. `whisper.cpp` an diesen Pfad anbinden
3. den Platzhalterzustand `transcribing` durch echten lokalen Inferenzaufruf ersetzen
4. Transkriptionsergebnis in denselben Runtime-/Response-Artefakten persistieren
5. Inferenzfehler im selben Artefaktstil dokumentieren
6. die bestehenden Fehlerpfade `no-permission`, `no-mic` und `blocked` ohne Regression erhalten
7. eine kleine produktnahe Revalidierung durchführen
8. die verbleibende Resthärtung vor der Textinjektions-Anbindung benennen

Der Auftrag soll bewusst klein bleiben und noch **nicht** den finalen Insert am Cursor integrieren.

---

## Erwartetes Ergebnis

Liefere:

### 1. `whisper.cpp`-Anbindung am bestehenden WAV-Pfad
Binde `whisper.cpp` direkt an das in 002I erzeugte Recording-Artefakt an.

Zu klären ist:

- wie das WAV-Artefakt eingelesen wird
- ob das aktuelle Format (`wav-lpcm-16khz-mono`) direkt akzeptiert wird
- ob eine minimale, eng begrenzte Vorverarbeitung nötig ist
- wie dieser Pfad ohne neue Audioarchitektur in den bestehenden Flow eingebunden wird

### 2. Echter `transcribing`-Schritt
Ersetze den bisherigen Platzhalterzustand durch echten lokalen Inferenzlauf.

Zu dokumentieren ist:

- wann `transcribing` beginnt
- wann es endet
- wie Erfolg, Fehler oder Abbruch behandelt werden
- welche Zustandsübergänge daraus entstehen

### 3. Persistenz von Ergebnis und Fehlern
Schreibe Ergebnistext und Inferenzfehler in dieselben Runtime-/Response-Artefakte, die bereits für den bestehenden Produktfluss verwendet werden.

Mindestens sinnvoll sind:

- erkannter Text
- Inferenzstatus
- Fehlerbeschreibung bei Fehlschlag
- Verweis auf das zugrunde liegende Recording-Artefakt

### 4. Erhalt bestehender Fehlerpfade
Die bereits validierten Pfade dürfen nicht regressieren.

Mindestens zu erhalten und zu dokumentieren:

- Accessibility-Blocked
- Microphone-Denied
- No-Mic
- konsistenter Runtime-State bei Inferenzfehlern

### 5. Kleine produktnahe Revalidierung
Führe eine kleine, aber belastbare Revalidierung durch.

Mindestens zu prüfen sind:

- Recording success -> transcribing -> Textresultat vorhanden
- Inferenzfehler ohne inkonsistenten Runtime-State
- no-permission bleibt korrekt
- no-mic bleibt korrekt

Für diese Stufe ist noch keine Validierung der finalen Texteinfügung am Cursor erforderlich.

### 6. Dokumentierte Beobachtungen
Halte mindestens fest:

- ob `whisper.cpp` am bestehenden WAV-Artefakt direkt funktioniert
- ob zusätzliche Konvertierung nötig war oder nicht
- ob der Produktfluss jetzt ein echtes Textresultat erzeugt
- wie Inferenzfehler im State und in den Logs erscheinen
- welche Resthärtung vor der finalen Insert-Anbindung noch fehlt

### 7. MVP-Einordnung
Bewerte am Ende klar:

- stabil genug für die nächste Stufe der Textinjektions-Anbindung
- im Wesentlichen tragfähig, aber mit kleiner Resthärtung
- noch nicht stabil genug für den nächsten Integrationsschnitt

### 8. Konkrete Folgeempfehlung
Formuliere daraus einen kleinen Folgeauftrag für die nächste Stufe.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- auf dem gehärteten Stable-Hotkey-/Recording-Kern aufbauen
- das bestehende WAV-Artefakt wiederverwenden
- `whisper.cpp` direkt an den bestehenden `transcribing`-Übergabepunkt anschliessen
- Beobachtung, Interpretation und Empfehlung sauber trennen
- Runtime-State und Logs konsistent halten
- bewusst klein und risikoorientiert bleiben

Wenn Unsicherheiten bleiben, müssen sie als offene Punkte markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- neue Audioaufnahme-Abstraktion
- alternative Inferenz-Engines
- Modellwahl als breiter Vergleich
- finale Textinjektion am Cursor
- breite UI- oder Settings-Ausarbeitung
- Unterstützung aller macOS-Anwendungen
- Multiplattform-Betrachtung
- allgemeine Zukunftsarchitektur

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Lässt sich `whisper.cpp` direkt an das bestehende WAV-Artefakt anbinden?
2. Reicht das aktuelle Artefaktformat ohne neue Konvertierung?
3. Ist der `transcribing`-Übergang mit echter Inferenz stabil genug?
4. Bleiben bestehende Fehlerpfade und Runtime-Artefakte konsistent?
5. Welche kleinste Resthärtung fehlt noch vor der finalen Insert-Anbindung?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- erstellte oder geänderte Artefakte
- Beschreibung der `whisper.cpp`-Anbindung
- Beschreibung des echten `transcribing`-Schritts
- Ergebnisse der kleinen produktnahen Revalidierung
- technische Risiken oder offene Fragen
- klare MVP-Einordnung
- konkreten Folgeauftrag

Keine allgemeine Plattformdiskussion.  
Keine unnötige Theorie.  
Keine breite Zukunftsarchitektur.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- `whisper.cpp` an das bestehende WAV-Artefakt angebunden wurde
- der Platzhalterzustand `transcribing` durch echten lokalen Inferenzlauf ersetzt wurde
- Textresultate oder Inferenzfehler in denselben Runtime-/Response-Artefakten landen
- no-permission, no-mic und blocked ohne Regression erhalten bleiben
- eine kleine produktnahe Revalidierung durchgeführt wurde
- eine klare Einschätzung zur Reife vor der finalen Insert-Anbindung vorliegt
- ein direkt anschlussfähiger Folgeauftrag formuliert wurde