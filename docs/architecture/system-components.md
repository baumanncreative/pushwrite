# System Components

## Zweck dieses Dokuments

Dieses Dokument beschreibt die technischen Hauptkomponenten von PushWrite v0.1.0 auf Systemebene.

Es dient dazu,

- den MVP in klar verständliche technische Bausteine zu zerlegen
- Verantwortlichkeiten sauber zu trennen
- Schnittstellen zwischen den Bausteinen sichtbar zu machen
- Architekturgespräche von Implementierungsdetails zu entkoppeln

Dieses Dokument definiert **keine** Klassenstruktur, **keine** Dateistruktur und **keine** konkrete API im Detail.  
Es beschreibt die logischen Systemkomponenten, die für den MVP erforderlich sind.

---

## 1. Systemkontext

PushWrite ist ein lokal laufendes Spracheingabe-Werkzeug für macOS.

Der Systemkern des MVP besteht aus einem linearen Hauptablauf:

1. globalen Hotkey auslösen
2. Aufnahmezustand starten
3. Mikrofon-Audio erfassen
4. Audio zur lokalen Transkription übergeben
5. Ergebnistext empfangen
6. Text an der aktiven Cursor-Position einfügen
7. Nutzer über Zustand oder Fehler minimal informieren

Daraus folgt:
Das System braucht nicht “viele Features”, sondern wenige, klar getrennte Komponenten mit sauberer Verantwortung.

---

## 2. Architekturgrundsatz

Für den MVP gelten zwei grobe Ebenen:

### A. macOS-App-Layer
Verantwortlich für alles, was systemnah, interaktionsnah oder plattformspezifisch ist.

### B. Inferenz-Layer
Verantwortlich für die lokale Sprach-zu-Text-Verarbeitung auf Basis der gewählten Runtime.

Diese Trennung ist verbindlich.  
Die Inferenz-Komponente löst nicht selbst Hotkey, Berechtigungen, Statusführung oder Textinjektion.

---

## 3. Hauptkomponenten

## 3.1 Hotkey Controller

### Rolle
Erkennt und verwaltet den globalen Auslöser für den Aufnahmeablauf.

### Verantwortung
- globalen Hotkey registrieren
- Hotkey-Ereignisse empfangen
- Start- und Stop-Signal an den Aufnahmefluss geben
- Konflikte oder ungültige Zustände erkennen, soweit für den MVP nötig

### Gehört ausdrücklich dazu
- press-and-hold- oder start/stop-bezogene Auslöse-Logik
- Basiskonfiguration des Hotkeys, falls im MVP vorgesehen

### Gehört ausdrücklich nicht dazu
- Audioaufnahme
- Transkription
- Textinjektion
- umfangreiche Einstellungslogik

### Eingaben
- Nutzerinteraktion über definierten Hotkey
- eventuell gespeicherte Hotkey-Konfiguration

### Ausgaben
- Signal: Aufnahme starten
- Signal: Aufnahme beenden
- Signal: Hotkey nicht verfügbar oder ungültig

---

## 3.2 Recording Controller

### Rolle
Steuert den Aufnahmeablauf aus Produktsicht.

### Verantwortung
- Aufnahme starten
- Aufnahme beenden
- Audiofluss zeitlich korrekt begrenzen
- Recording-Zustand an andere Komponenten kommunizieren
- Übergabe des aufgezeichneten Audios an die nächste Verarbeitungsstufe auslösen

### Gehört ausdrücklich dazu
- Start/Stop-Logik
- Übergang zwischen idle, recording und processing
- Schutz gegen doppelte oder inkonsistente Zustandswechsel

### Gehört ausdrücklich nicht dazu
- globale Hotkey-Erkennung
- Modell-Inferenz
- direkte Textinjektion in Zielanwendungen

### Eingaben
- Start-/Stop-Signal vom Hotkey Controller
- Rückmeldungen der Audio-Komponente
- Status des Systemzustands

### Ausgaben
- Signal an Audio Capture: aufnehmen / stoppen
- Audio-Payload oder Referenz an die Transkriptionskomponente
- Zustandsänderung an Status-/UI-Komponente

---

## 3.3 Audio Capture

### Rolle
Erfasst das Mikrofon-Audio lokal auf macOS.

### Verantwortung
- Zugriff auf Eingabegerät
- Start und Ende der Audioaufnahme
- Bereitstellung eines transkriptionsfähigen Audioformats oder Puffers
- Umgang mit Aufnahmefehlern auf Basisebene

### Gehört ausdrücklich dazu
- Mikrofonzugriff
- Aufnahme aus dem aktiven Eingabegerät
- Aufnahmedaten für den Transkriptionspfad vorbereiten

### Gehört ausdrücklich nicht dazu
- globale Benutzersteuerung
- Modellentscheidung
- Texteinfügung
- Dateiverwaltung als Nutzerfeature

### Eingaben
- Start-/Stop-Anweisungen vom Recording Controller
- Systemberechtigungsstatus
- gegebenenfalls Basiskonfiguration für Audio

### Ausgaben
- Audio-Daten für die Transkription
- Fehlerstatus bei fehlendem Zugriff oder fehlerhafter Aufnahme

---

## 3.4 Permission Manager

### Rolle
Verwaltet die für den MVP notwendigen macOS-Berechtigungen auf Produktebene.

### Verantwortung
- prüfen, welche Rechte nötig sind
- Status der relevanten Berechtigungen erfassen
- fehlende Rechte im Produktfluss erkennbar machen
- Berechtigungsprobleme in verständliche Zustände übersetzen

### Gehört ausdrücklich dazu
- Mikrofonrechte
- weitere systemnahe Rechte, soweit für Hotkey oder Textinjektion erforderlich
- Basiskontrolle des Permission-Flows

### Gehört ausdrücklich nicht dazu
- vollständige UX-Ausgestaltung beliebiger Settings
- eigentliche Audioaufnahme
- eigentliche Textinjektion

### Eingaben
- Systemstatus
- Anfragen anderer Komponenten, die Rechte voraussetzen

### Ausgaben
- Status: erlaubt / nicht erlaubt / unklar
- Signal an Status-/UI-Komponente
- Blockierung des Flows, wenn Kernvoraussetzungen fehlen

---

## 3.5 Transcription Engine Adapter

### Rolle
Bindet die gewählte lokale Inferenz-Basis an den Produktfluss an.

### Verantwortung
- Audio-Daten an die Inferenz-Runtime übergeben
- Transkriptionsprozess starten
- Textresultat entgegennehmen
- transkriptionsrelevante Fehler zurückmelden
- technische Details der Inferenz von restlichen Produktkomponenten abschirmen

### Gehört ausdrücklich dazu
- Anbindung an `whisper.cpp`
- Übergabe von Audio an die Runtime
- Rückgabe von Transkriptionsresultaten
- Umgang mit modell- oder runtimebezogenen Fehlerzuständen

### Gehört ausdrücklich nicht dazu
- Hotkey-Logik
- Aufnahme-UI
- Textinjektion
- umfangreiche Multi-Engine-Abstraktion

### Eingaben
- Audio-Daten oder Audio-Puffer
- modell- und laufzeitrelevante Konfiguration

### Ausgaben
- transkribierter Text
- Fehlerstatus
- optional technische Laufzeitinformationen für Logging oder Status

---

## 3.6 Text Insertion Controller

### Rolle
Fügt den transkribierten Text in den aktiven Texteingabekontext ein.

### Verantwortung
- Textinjektion an der aktuellen Cursor-Position auslösen
- mit dem aktiven Zielkontext auf systemnaher Ebene umgehen
- Erfolg oder Fehlschlag des Einfügens zurückmelden
- bekannte Grenzen des Einfügens vom restlichen Produktfluss trennen

### Gehört ausdrücklich dazu
- eigentliche Übergabe des Textes an den aktiven Eingabekontext
- produktrelevante Fehlerbehandlung bei fehlgeschlagener Einfügung
- Rückmeldung an den Systemstatus

### Gehört ausdrücklich nicht dazu
- Transkription
- Audioaufnahme
- Hotkey-Steuerung
- Textnachbearbeitung als Komfortfunktion

### Eingaben
- finaler transkribierter Text
- aktueller Berechtigungs- und Systemstatus

### Ausgaben
- Signal: Einfügen erfolgreich
- Signal: Einfügen fehlgeschlagen
- Fehlerkontext für Status-/UI-Komponente

---

## 3.7 App State / Flow Coordinator

### Rolle
Koordiniert den übergeordneten Ablauf zwischen den Komponenten.

### Verantwortung
- den Kernworkflow als Zustandsmaschine oder vergleichbare Ablaufsteuerung führen
- Übergänge zwischen idle, recording, transcribing, inserting und error verwalten
- unzulässige Zustandsübergänge verhindern
- zentrale Ablauflogik kapseln

### Gehört ausdrücklich dazu
- Orchestrierung des Hauptablaufs
- Übergangsregeln
- Reaktion auf Erfolg, Fehler oder Abbruch

### Gehört ausdrücklich nicht dazu
- eigentliche Umsetzung von Audioaufnahme
- eigentliche Inferenz
- eigentliche Textinjektion
- grosse UI-Logik

### Eingaben
- Ereignisse aus Hotkey, Permissions, Recording, Transcription und Text Insertion

### Ausgaben
- Folgeaktionen an Systemkomponenten
- Zustandsupdates an Status-/UI-Komponente
- Fehler- oder Abbruchpfade

---

## 3.8 Status / Minimal UI Layer

### Rolle
Macht den Produktzustand für den Nutzer minimal verständlich.

### Verantwortung
- relevante Zustände sichtbar machen
- minimale Fehlerkommunikation ermöglichen
- produktkritische Rückmeldungen anzeigen, ohne den MVP aufzublähen

### Mögliche Zustände
- bereit
- nimmt auf
- transkribiert
- Einfügen läuft
- Berechtigung fehlt
- Fehler

### Gehört ausdrücklich dazu
- minimale, funktionale Zustandsanzeige
- basale Fehlerrückmeldung
- gegebenenfalls Menüleisten- oder kleine Statusoberfläche

### Gehört ausdrücklich nicht dazu
- umfangreiche Oberflächenlogik
- History, Dokumentenverwaltung oder Komfortfunktionen
- tiefe Einstellungen ohne MVP-Bezug

### Eingaben
- Zustände und Fehlersignale aus dem Flow Coordinator
- Berechtigungsstatus
- Ergebnis des Einfügevorgangs

### Ausgaben
- sichtbare Statusinformation für den Nutzer

---

## 3.9 Settings Store

### Rolle
Hält nur die minimal nötige Konfiguration des MVP.

### Verantwortung
- kleine Menge produktrelevanter Einstellungen speichern
- beim Start bereitstellen
- Änderungen kontrolliert verfügbar machen

### Zulässige Inhalte im MVP
- Hotkey-Basiskonfiguration
- minimal notwendige Audio- oder Modellparameter
- gegebenenfalls einfache Präferenzen zur Kernnutzung

### Gehört ausdrücklich nicht dazu
- umfangreiche Preference-Verwaltung
- experimentelle Expertenoptionen
- allgemeines Feature-Flag-System für Zukunftsszenarien

### Eingaben
- Nutzeränderungen an erlaubten Basisoptionen
- Systemdefaults

### Ausgaben
- Konfigurationswerte an relevante Komponenten

---

## 4. Hauptdatenfluss

Der geplante Standardfluss des MVP sieht so aus:

1. **Hotkey Controller** erkennt Auslöser
2. **App State / Flow Coordinator** wechselt in Aufnahmezustand
3. **Permission Manager** bestätigt benötigte Rechte oder blockiert den Ablauf
4. **Recording Controller** startet Aufnahme
5. **Audio Capture** erfasst Audiodaten
6. **Recording Controller** beendet Aufnahme nach Stop-Signal
7. **Transcription Engine Adapter** verarbeitet Audio lokal
8. **Text Insertion Controller** fügt das Ergebnis in den aktiven Texteingabekontext ein
9. **Status / Minimal UI Layer** meldet Zustand oder Fehler

---

## 5. Minimale Systemgrenzen

Zum MVP-System gehören nur Komponenten, die direkt für den Kernworkflow nötig sind.

Nicht als eigene Hauptkomponenten für v0.1.0 vorgesehen sind:

- Dateiimport
- Export
- Verlauf
- Cloud-Sync
- Analytics-Plattform
- Plugin-System
- Benutzerkonto-System
- Multi-Engine-Manager
- umfangreiche Dokumenten- oder Projektverwaltung

---

## 6. Kritische Schnittstellen

Für die weitere Architektur sind besonders diese Übergänge kritisch:

### A. Hotkey → Recording
Frage:
Wird der Aufnahmefluss zuverlässig und eindeutig ausgelöst?

### B. Recording → Audio Capture
Frage:
Ist der Audiozustand sauber steuerbar?

### C. Audio Capture → Transcription
Frage:
Kommt das Audio im passenden Format und in stabiler Qualität an?

### D. Transcription → Text Insertion
Frage:
Ist klar, wann ein Text als “final genug” zum Einfügen gilt?

### E. Text Insertion → User Feedback
Frage:
Wird Erfolg oder Fehlschlag sichtbar genug rückgemeldet?

Diese Schnittstellen sind wichtiger als frühe Diskussionen über interne Detailabstraktionen.

---

## 7. Was dieses Dokument bewusst noch nicht festlegt

Dieses Dokument entscheidet noch nicht:

- konkrete Programmiersprache des App-Layers
- exakte Modul- oder Ordnernamen im Repository
- konkrete API-Form einzelner Komponenten
- UI-Technologie im Detail
- Teststrategie im Detail
- Persistenzformat der Einstellungen
- exakte technische Methode der Textinjektion

Diese Punkte folgen erst nach der groben Systemzerlegung.

---

## 8. Architekturregel für die nächsten Schritte

Neue Komponenten sind nur dann zulässig, wenn sie mindestens eines dieser Kriterien erfüllen:

- sie sind für den MVP-Kernworkflow zwingend nötig
- sie reduzieren reale technische Komplexität
- sie entkoppeln zwei tatsächlich unterschiedliche Verantwortungen

Eine neue Komponente ist **nicht** gerechtfertigt, nur weil sie theoretisch später nützlich sein könnte.

---

## 9. Änderungsregel

Dieses Dokument wird angepasst, wenn:

- eine Hauptkomponente neu hinzukommt oder entfällt
- eine Verantwortung wesentlich verschoben wird
- der Kernworkflow des MVP geändert wird
- eine kritische Schnittstelle anders geschnitten werden muss

Kleine Implementierungsdetails sind kein Grund, dieses Dokument zu ändern.