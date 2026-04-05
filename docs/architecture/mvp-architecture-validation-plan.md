# MVP Architektur- und Validierungsplan

## Zweck dieses Dokuments

Dieses Dokument übersetzt die bereits festgelegten Produkt- und Architekturentscheidungen für PushWrite v0.1.0 in eine risikoorientierte technische Reihenfolge.

Es ist:

- kein neuer Scope
- keine vollständige Implementierung
- keine allgemeine Zukunftsarchitektur

Es definiert:

- welche Punkte zuerst validiert werden müssen
- in welcher Reihenfolge der MVP technisch sinnvoll aufgebaut werden soll
- wie die ersten Arbeitspakete klein und überprüfbar geschnitten werden
- welche Themen im MVP bewusst nicht gebaut werden sollen

---

## 1. Technische Ausgangslage

PushWrite v0.1.0 ist als eng geschnittenes macOS-Werkzeug definiert. Der verbindliche Kernablauf ist:

1. globalen Hotkey auslösen
2. Aufnahme starten
3. sprechen
4. Aufnahme beenden
5. Audio lokal transkribieren
6. Text direkt an der aktuellen Cursor-Position einfügen

Daraus ergeben sich drei feste Leitplanken:

- **macOS only**: keine Multiplattform-Rücksicht im MVP
- **local first**: lokaler, offline-fähiger Standardpfad
- **`whisper.cpp` als Inferenz-Richtung**: keine Multi-Engine-Architektur

Architektonisch ist die Trennung bereits gesetzt:

- **macOS-App-Layer** für Hotkey, Berechtigungen, Aufnahme, Flow-Steuerung, Status und Textinjektion
- **Inferenz-Layer** für die lokale Sprach-zu-Text-Verarbeitung über `whisper.cpp`

Für die Umsetzungsreihenfolge ist entscheidend:

- Das grösste Projektrisiko liegt nicht primär in der Modellfamilie, sondern in der macOS-Systemintegration.
- Textinjektion ist kein Nebenaspekt, sondern Teil des Produktkerns.
- Hotkey, Berechtigungen, Aufnahme und Textinjektion dürfen technisch getrennt validiert werden, müssen am Ende aber in einem linearen Flow zuverlässig zusammenspielen.

### Annahmen

- **Annahme A1**: Für v0.1.0 ist Einfügen erst nach Abschluss der Aufnahme der stabilste Produktpfad.
- **Annahme A2**: Ein kleines Statusmodell mit `idle`, `recording`, `processing`, `error` reicht für den MVP aus.
- **Annahme A3**: Eine minimale Menüleisten- oder Statusoberfläche ist ausreichend; eine grössere UI ist nicht nötig.

### Offene Punkte

- konkrete Methode der Textinjektion
- genaue Rechte- und Startfluss-Reihenfolge unter macOS
- konkrete Standard-Modellgrösse für `whisper.cpp`
- exaktes Hotkey-Verhalten für den ersten Release

---

## 2. MVP-kritische Risiken

### Risiko 1: Textinjektion ist nicht robust genug

Das ist das direkteste Produktrisiko. Wenn PushWrite Text nicht verlässlich am aktuellen Cursor einfügen kann, bleibt nur ein Transkriptionswerkzeug übrig und der Produktkern wird verfehlt.

**Direkte Bedrohung für den MVP**

- Kernnutzen wird nicht eingelöst
- Verhalten variiert stark zwischen Zielanwendungen
- Copy-Paste-Fallback würde den Produktkern abschwächen

### Risiko 2: macOS-Berechtigungen blockieren den Kernablauf

Mikrofonzugriff ist zwingend. Je nach gewählter Einfügemethode und Hotkey-Technik können weitere systemnahe Rechte relevant werden. Wenn dieser Fluss unklar bleibt, scheitert der Nutzer vor der eigentlichen Funktion.

**Direkte Bedrohung für den MVP**

- Aufnahme startet nicht
- Einfügen scheitert trotz erfolgreicher Transkription
- Nutzer kann die Blockade nicht einordnen

### Risiko 3: Globaler Hotkey ist unzuverlässig oder kollidiert praktisch

Der MVP basiert auf einem globalen Trigger. Wenn der Auslöser unzuverlässig ist oder inkonsistente Zustandswechsel erzeugt, ist der gesamte Kernworkflow instabil.

**Direkte Bedrohung für den MVP**

- Aufnahme startet oder stoppt nicht sicher
- Zustände bleiben hängen
- Nutzung wirkt unberechenbar

### Risiko 4: Aufnahme, Transkription und Einfügen greifen nicht sauber ineinander

Auch wenn Einzelteile funktionieren, kann der Produktpfad an den Übergängen scheitern. Kritisch sind vor allem Zustandswechsel, Fehlerpfade und die Frage, wann ein Ergebnis als "einfügbar" gilt.

**Direkte Bedrohung für den MVP**

- doppelte oder leere Auslösungen
- Übergänge bleiben in `processing` oder `error` hängen
- erfolgreicher Teilfluss ohne sichtbaren Gesamterfolg

### Risiko 5: `whisper.cpp`-Baseline ist für den MVP zu langsam oder unpassend

Das ist ein relevantes, aber nachgelagertes Risiko. Die Richtung ist gesetzt, offen ist nur noch die konkrete Startkonfiguration.

**Direkte Bedrohung für den MVP**

- spürbare Latenz im Alltagsfall
- falsches Verhältnis aus Genauigkeit, Startzeit und Ressourcenbedarf
- unnötig schweres Packaging

### Priorisierung

Die Risiken sollten in dieser Reihenfolge behandelt werden:

1. Textinjektion
2. Berechtigungen
3. Hotkey-Steuerung
4. Ablaufübergänge zwischen Aufnahme, Transkription und Einfügen
5. Modell- und Runtime-Baseline

---

## 3. Frühe Validierungspunkte

Diese Punkte sollten vor grösserer Produktimplementierung verifiziert werden.

### Validierung 1: Textinjektion mit festem Testtext

**Ziel**

Früh klären, ob PushWrite in typischen macOS-Texteingabekontexten verlässlich direkt einfügen kann.

**Minimaler Nachweis**

- Einfügen funktioniert in mehreren typischen Zielkontexten
- Erfolg und Fehlschlag sind technisch erkennbar
- bekannte Grenzen können benannt werden

**Kill-Kriterium**

Wenn nur ein kleiner Spezialfall stabil funktioniert oder die Methode in typischen Texteingabefeldern regelmässig scheitert, ist der MVP in der aktuellen Form blockiert.

### Validierung 2: Rechte- und Blockade-Matrix

**Ziel**

Vor jeder breiteren App-Struktur klären, welche Rechte für Mikrofon, Hotkey und Textinjektion tatsächlich erforderlich sind und wie der Produktfluss bei fehlenden Rechten reagiert.

**Minimaler Nachweis**

- zwingende Rechte sind benannt
- fehlende Rechte lassen sich reproduzierbar erkennen
- ein minimaler Blockadepfad ist ableitbar

**Kill-Kriterium**

Wenn wesentliche Rechte technisch nicht klar prüfbar oder für Nutzer kaum steuerbar sind, muss der Startfluss enger geschnitten werden.

### Validierung 3: Globaler Hotkey als isolierter Trigger

**Ziel**

Prüfen, ob der globale Auslöser auf macOS stabil genug ist, bevor Aufnahme- und Inferenzlogik daran gehängt werden.

**Minimaler Nachweis**

- Hotkey kann zuverlässig registriert werden
- Start- und Stop-Signal sind eindeutig
- das gewählte Bedienmodell erzeugt keine offensichtlichen Hänger

**Kill-Kriterium**

Wenn press-and-hold oder das gewählte Trigger-Modell praktisch unzuverlässig ist, muss der Interaktionsansatz vor weiterer Integration angepasst werden.

### Validierung 4: `whisper.cpp`-Adapter mit deterministischem Audio

**Ziel**

Die Inferenz-Schicht unabhängig vom Live-Mikrofon validieren.

**Minimaler Nachweis**

- definierter Audio-Input kann lokal transkribiert werden
- Laufzeit und Ergebnisqualität sind für kurze Diktatsegmente bewertbar
- eine erste Modellentscheidung ist möglich

**Kill-Kriterium**

Wenn die Baseline auf Zielhardware für kurze Eingaben unbrauchbar langsam oder unpraktisch schwergewichtig ist, muss die Startkonfiguration geändert werden.

### Validierung 5: enger End-to-End-Pfad

**Ziel**

Früh beweisen, dass die Einzelteile im schmalsten realen Produktpfad zusammenspielen.

**Minimaler Nachweis**

- Hotkey startet Aufnahme
- Aufnahme endet sauber
- Transkriptionsresultat wird einmalig eingefügt
- Fehlerpfade führen zurück in einen kontrollierten Zustand

**Kill-Kriterium**

Wenn der Gesamtfluss schon im Minimalfall nicht stabil orchestrierbar ist, dürfen keine Komfortfunktionen hinzukommen.

---

## 4. Empfohlene Umsetzungsreihenfolge

Die Reihenfolge folgt Risiko, Blockadepotenzial und Abhängigkeiten, nicht optischer Vollständigkeit.

### Schritt 1: Textinjektion zuerst separat validieren

Begründung:

- höchstes Produktrisiko
- betrifft direkt die MVP-Definition
- kann isoliert mit festem Testtext geprüft werden

Ohne belastbaren Einfügepfad ist jeder weitere Ausbau nur Teiloptimierung um einen unsicheren Produktkern.

### Schritt 2: Berechtigungen und Blockadezustände festziehen

Begründung:

- Textinjektion, Hotkey und Mikrofonzugriff hängen an systemnahen Rechten
- der Startfluss kann erst sauber geschnitten werden, wenn diese Abhängigkeiten klar sind
- verhindert spätere Umbauten im Zustands- und Fehlerpfad

### Schritt 3: Hotkey-Ablauf vor Audio- und Inferenzintegration stabilisieren

Begründung:

- globaler Trigger ist Kern des Interaktionsmodells
- unklare Start-/Stop-Logik erzeugt später Kaskadenfehler
- Zustandsübergänge lassen sich mit Stubs einfacher prüfen als im kompletten Produktpfad

### Schritt 4: Aufnahme- und `whisper.cpp`-Pfad getrennt verifizieren

Begründung:

- Audio Capture und Inferenz sind zwar logisch verbunden, sollten aber nicht im ersten Schritt gemeinsam debuggt werden
- deterministische Audio-Inputs reduzieren Fehlersuche
- Modell- und Latenzfragen werden von Hotkey- und Permission-Fragen entkoppelt

### Schritt 5: Minimale Flow-Orchestrierung für den realen Kernablauf

Begründung:

- erst jetzt sind die grössten Blocker einzeln geprüft
- der erste echte Produktpfad kann schmal bleiben
- Integrationsfehler lassen sich klarer einzelnen Übergängen zuordnen

### Schritt 6: Minimale Statusoberfläche und wenige Einstellungen zuletzt

Begründung:

- Status ist wichtig, aber nicht der erste Blocker
- UI sollte an den bereits validierten Kernpfad angeschlossen werden
- verhindert frühe UI-Arbeit gegen noch ungeklärte technische Grundlagen

### Abhängigkeitslogik

Die empfohlene Reihenfolge ist:

1. Textinjektion
2. Berechtigungen
3. Hotkey-Zustandslogik
4. Aufnahme und Inferenz-Baseline
5. End-to-End-Flow
6. minimale Statusoberfläche und Basiseinstellungen

---

## 5. Empfohlene erste Arbeitspakete

Die Arbeitspakete sind absichtlich klein geschnitten und mischen nicht mehrere Problemarten gleichzeitig.

### Arbeitspaket 1: Textinjektion-PoC mit festem Testtext

**Scope**

- nur Textinjektion
- keine Mikrofonaufnahme
- keine lokale Inferenz
- kein globaler Hotkey

**Ergebnis**

- technischer Einfügepfad ist benannt
- erste Zielkontext-Matrix liegt vor
- bekannte Grenzen sind dokumentiert

**Überprüfbar durch**

- manuelles Einfügen eines festen Strings in mehrere typische Texteingabekontexte

### Arbeitspaket 2: Permission-Matrix und Blockadebehandlung

**Scope**

- nur Rechteprüfung und Blockadezustände
- keine produktionsreife UI
- keine vollständige End-to-End-Integration

**Ergebnis**

- klare Einordnung in zwingend, plausibel nötig, offen
- minimaler Erststart- und Fehlerpfad
- Entscheidung, welche Rechte vor dem ersten Nutzungsversuch geprüft werden

**Überprüfbar durch**

- reproduzierbare Tests mit erlaubten und verweigerten Rechten

### Arbeitspaket 3: Hotkey-Prototyp mit minimaler Zustandsmaschine

**Scope**

- nur globaler Trigger und Zustandswechsel
- Aufnahme kann zunächst gestubbt sein
- keine Inferenzintegration

**Ergebnis**

- gewähltes Interaktionsmodell ist validiert
- unzulässige Übergänge sind benannt
- Start, Stop und Abbruch sind logisch definiert

**Überprüfbar durch**

- manuelle Trigger-Tests mit Statuswechseln `idle -> recording -> processing -> idle`

### Arbeitspaket 4: `whisper.cpp`-Adapter mit Referenzaudio

**Scope**

- nur Inferenz-Layer
- keine globale Steuerung
- kein Texteinfügen

**Ergebnis**

- erste lauffähige Adapter-Schicht
- Entscheidungsvorlage für Default-Modell
- grobe Messwerte für Latenz und Ressourcenbedarf

**Überprüfbar durch**

- definierte Referenzclips mit reproduzierbaren Transkriptionsläufen

### Arbeitspaket 5: Minimaler End-to-End-Slice

**Scope**

- genau ein enger Kernpfad
- kein grosser Einstellungsdialog
- keine Komfortfunktionen

**Ergebnis**

- ein vollständiger, aber schmaler MVP-Durchstich
- kontrollierter Fehlerpfad zurück in `idle`
- Grundlage für nachgelagerte Robustheitsarbeit

**Überprüfbar durch**

- manueller Durchlauf des vollständigen Kernworkflows in typischen Texteingabekontexten

---

## 6. Architekturgrenzen

Folgende Themen sollen im MVP ausdrücklich **nicht** gebaut oder abstrahiert werden:

### Nicht bauen

- Datei-Transkription
- Import von Audio- oder Videodateien
- Cloud- oder Hybrid-Transkriptionspfade
- Verlauf, Export oder Dokumentverwaltung
- Live-Streaming-Transkription in Segmenten
- nachgelagerte Textbearbeitung, Umformung oder Prompt-Features
- breite Preference-Panels
- Plugin- oder Erweiterungssysteme

### Nicht abstrahieren

- keine Multi-Engine-Schnittstelle
- keine Multiplattform-Schicht
- keine generische Event-Bus-Architektur ohne aktuellen Bedarf
- keine frühe Packaging- oder Update-Architektur für spätere Plattformen
- keine vorgezogene Trennung für hypothetische Online-Features

### Technische Grenzregel

Eine zusätzliche Schicht ist im MVP nur dann gerechtfertigt, wenn sie:

- einen aktuellen Produktblocker reduziert
- zwei klar unterschiedliche Verantwortungen trennt
- den minimalen Kernpfad robuster macht

Eine zusätzliche Schicht ist **nicht** gerechtfertigt, wenn sie nur eine spätere Option vorbereiten würde.

---

## 7. Vorschlag für die nächsten 3 bis 5 Folgeaufträge

Die ersten Folgeaufträge sollten die grössten Risiken einzeln abarbeiten. Die bereits angelegten Aufträge `002` bis `004` passen in diese Reihenfolge und sollten durch zwei enge Folgeaufträge ergänzt werden.

### Folgeauftrag 1

**`002-text-insertion-macos.md`**

Ziel:

- tragfähigsten Einfügeansatz bestimmen
- Zielkontexte und Grenzen benennen
- Kill-Kriterien für den MVP explizit machen

### Folgeauftrag 2

**`003-permissions-start-flow-macos.md`**

Ziel:

- reale Rechte- und Blockadepunkte festziehen
- minimalen First-Run- und Fehlerpfad definieren
- Permission-Reihenfolge für den Produktfluss entscheiden

### Folgeauftrag 3

**`004-hotkey-recording-flow.md`**

Ziel:

- globales Hotkey-Modell festlegen
- minimales Zustandsmodell definieren
- Start-, Stop- und Abbruchlogik für den Aufnahmefluss stabil schneiden

### Folgeauftrag 4

**Neuer Auftrag: `005-whispercpp-baseline-macos.md`**

Empfohlener Inhalt:

- `whisper.cpp` für den MVP als Adapter-Schicht einbinden
- kleine Menge Referenzaudio definieren
- `base.en` gegen `small.en` und optional quantisierte Variante vergleichen
- Ergebnis nach Latenz, Nutzbarkeit und Ressourcenbedarf bewerten

Erwartetes Ergebnis:

- konkrete Default-Modell-Empfehlung
- erste belastbare Inferenz-Baseline für v0.1.0

### Folgeauftrag 5

**Neuer Auftrag: `006-minimal-end-to-end-slice-macos.md`**

Empfohlener Inhalt:

- validierten Einfügepfad, Permission-Handling, Hotkey-/Aufnahmefluss und `whisper.cpp`-Adapter in einem minimalen Durchstich verbinden
- nur den linearen Kernablauf umsetzen
- klare Fehlerpfade zurück nach `idle` definieren

Erwartetes Ergebnis:

- erster realer Produktpfad für PushWrite v0.1.0
- belastbare Grundlage für anschliessende Stabilisierung

---

## Entscheidungsregel für die Folgeaufträge

Nach jedem Folgeauftrag ist neu zu prüfen:

1. Ist ein MVP-Blocker entschärft oder bestätigt?
2. Ist der nächste Auftrag noch klein genug?
3. Wird gerade ein echter Kernpfad stabilisiert oder nur Komfort gebaut?

Wenn Frage 3 mit "Komfort" beantwortet wird, gehört der Schritt nicht in v0.1.0.
