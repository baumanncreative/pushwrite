# Auftrag für Codex: PushWrite 0.2.0-alpha.1 vollständig implementieren, validieren und als installierbare macOS-Alpha bereitstellen

## Rolle und Arbeitsmodus

Du arbeitest als verantwortlicher Lead Engineer für die erste installierbare Alpha-Version von PushWrite.

Dieser Auftrag ist kein Analyseauftrag und kein kleiner Prototyp.

Du sollst:

- den aktuellen Stand des Repositories vollständig untersuchen
- bestehende Entscheidungen und vorhandenen Code berücksichtigen
- fehlende Produktteile implementieren
- die App bauen
- automatisiert und manuell prüfbare Tests durchführen
- Sicherheits-, Datenschutz- und Berechtigungsfragen prüfen
- ein installierbares Release-Artefakt erzeugen
- die Projektdokumentation auf den tatsächlich erreichten Stand bringen
- erst aufhören, wenn der definierte Abschlusszustand erreicht oder ein objektiv nicht lösbarer externer Blocker sauber belegt ist

Arbeite selbstständig durch den gesamten Auftrag.

Stelle keine Rückfragen zu Punkten, die du durch:

- Repository-Analyse
- bestehende Dokumentation
- Company-Handbook
- aktuelle offizielle Apple-Dokumentation
- aktuelle offizielle Dokumentation von whisper.cpp
- Tests und technische Validierung

selbst beantworten kannst.

Nutze geeignete Skills und Sub-Agents nach eigenem Ermessen, insbesondere für:

- macOS- und Swift-Architektur
- SwiftUI/AppKit-Integration
- UX- und Interface-Design
- Icon-Design
- Audioverarbeitung
- whisper.cpp-Integration
- Accessibility und globale Eingabe
- lokale maschinelle Übersetzung
- Packaging, Codesigning und Notarisierung
- Tests und Qualitätssicherung
- Security- und Privacy-Review
- Release Engineering
- Dokumentationsprüfung

Sub-Agents dürfen analysieren, implementieren und prüfen. Du bleibst für Konsistenz, Integration und das Endergebnis verantwortlich.

---

# 1. Verbindliches Release-Ziel

Erzeuge:

`PushWrite 0.2.0-alpha.1`

Diese Version ist die erste im grösseren Umfang installierbare und nutzbare Alpha-Version.

Sie muss auf einem unterstützten macOS-System als echte Anwendung installiert und gestartet werden können.

Die Versionsnummer muss konsistent gesetzt werden in:

- App-Metadaten
- Bundle-Version
- Marketing-Version
- About-/Informationsansicht
- Changelog
- Roadmap
- README
- Release-Artefakten
- Release Notes
- Git-Tag oder vorbereitetem Tagging-Prozess

Verwende für die interne Build-Nummer ein nachvollziehbares numerisches Schema.

Prüfe zuerst vorhandene Tags, Releases und Versionsangaben. Dokumentiere erkannte Inkonsistenzen und gleiche sie auf `0.2.0-alpha.1` ab.

---

# 2. Verbindliche Quellen und Priorität

## 2.1 PushWrite-Repository

Das aktuelle PushWrite-Repository ist die primäre Quelle für:

- Produktumfang
- vorhandene Architektur
- bestehende technische Entscheidungen
- bisherige Prototypen
- Tests
- bekannte Risiken
- vorhandene Dokumentation

Lies vor Änderungen mindestens:

- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `CONTRIBUTING.md`
- `AGENTS.md`, falls vorhanden
- alle Dateien unter `docs/product/`
- alle Dateien unter `docs/architecture/`
- alle Dateien unter `docs/execution/`
- vorhandene Quellcode-, Test-, Build- und Release-Dateien

Behandle bestehende Entscheidungen nicht als unverbindliche Ideen.

Wenn der aktuelle Code von dokumentierten Entscheidungen abweicht:

1. stelle die Abweichung fest
2. prüfe, ob der Code oder die Dokumentation den neueren belastbaren Stand enthält
3. entscheide anhand des Produktziels
4. dokumentiere die Entscheidung
5. stelle Code und Dokumentation wieder konsistent her

## 2.2 Company-Handbook

Das Repository `baumanncreative/company-handbook` ist die verbindliche Quelle für:

- Markenfarben
- Typografie
- Icons
- Bildsprache
- Sprachregeln
- Schweizer Rechtschreibung
- Qualitätsregeln
- Gestaltungsprinzipien

Das Company-Handbook ist für diesen Auftrag grundsätzlich nur lesend zu verwenden.

Verändere es nicht.

Lies mindestens:

- Root-`README.md`
- `AGENTS.md`
- `docs/01_marke/INDEX.md`
- `docs/01_marke/farben.md`
- `docs/01_marke/typografie.md`
- `docs/01_marke/icons.md`
- `docs/01_marke/marken-qualitaetscheckliste.md`
- relevante Sprach- und Codex-Regeln

Beachte den Reifegrad einzelner Handbook-Dateien:

- `aktiv` hat Vorrang
- `entwurf` ist eine Orientierung und muss auf innere Konsistenz geprüft werden
- offene Konflikte oder ungeklärte Werte dürfen nicht als gesicherte Vorgabe ausgegeben werden

## 2.3 Externe technische Quellen

Verwende bei aktuellen technischen Fragen ausschliesslich belastbare Primärquellen:

- offizielle Apple Developer Documentation
- offizielle Apple Human Interface Guidelines
- offizielles Swift- und Swift-Package-Manager-Umfeld
- offizielles Repository und offizielle Dokumentation von `ggml-org/whisper.cpp`
- offizielle Dokumentation der gewählten lokalen Übersetzungsengine
- offizielle Dokumentation der verwendeten Übersetzungsmodelle
- offizielle GitHub-Dokumentation für Releases und Actions

Keine Architekturentscheidung allein auf Blogposts, Forenbeiträge oder veraltete Tutorials stützen.

---

# 3. Produktdefinition

PushWrite ist eine lokal laufende, downloadbare Open-Source-macOS-Anwendung.

Hauptfunktion:

1. Nutzer hält einen globalen Hotkey gedrückt
2. PushWrite nimmt währenddessen Sprache über das Mikrofon auf
3. beim Loslassen endet die Aufnahme
4. die Aufnahme wird lokal mit Whisper transkribiert
5. der erkannte Text wird direkt an der aktuellen Cursor-Position der zuvor aktiven Anwendung eingefügt

Zusatzfunktion:

1. Nutzer aktiviert die lokale Clipboard-Übersetzung ausdrücklich
2. Nutzer markiert Text und kopiert ihn mit `Command-C`
3. PushWrite erkennt den kopierten Text lokal
4. PushWrite erkennt die Ausgangssprache lokal oder verwendet eine manuell gewählte Ausgangssprache
5. PushWrite übersetzt den Text vollständig lokal
6. PushWrite zeigt Original und Übersetzung in einer kompakten Menu-Bar-Oberfläche an

Produktname:

`PushWrite`

Claim:

`Local voice input for macOS`

Technologiehinweis:

`Powered by Whisper`

Aktive Zielplattform:

`macOS`

Für dieses Release nicht aktiv zu unterstützen:

- Windows
- Linux
- iOS
- Android
- Datei-Transkription
- MP3-/MP4-Import
- allgemeine Audio- oder Videoverarbeitung
- Cloud-Transkription
- Cloud-Übersetzung
- komplexe Textbearbeitung
- KI-Umschreiben
- Team- oder Accountfunktionen
- Synchronisation zwischen Geräten

---

# 4. Verbindliches Datenschutzprinzip

Sämtliche Sprachdaten, Audiodaten, Transkripte, kopierten Texte und Übersetzungen werden ausschliesslich lokal auf dem Gerät verarbeitet und verlassen den Mac zu keinem Zeitpunkt.

Verbindlich:

- keine Cloud-Inferenz
- keine Cloud-Übersetzung
- keine externen Sprach- oder Übersetzungs-APIs
- keine Übertragung von Audio, Transkripten, Clipboard-Inhalten oder Übersetzungen
- kein Account
- kein API-Key
- keine versteckte Netzwerkabhängigkeit
- keine Telemetrie mit Nutzinhalten
- nach vollständiger Installation offline nutzbar

Netzwerkzugriffe sind nur für klar getrennte, transparente Installations- oder Update-Schritte zulässig, beispielsweise für einen einmaligen Modell-Download, sofern Modelle nicht direkt mitgeliefert werden.

Nach vollständiger Installation müssen Transkription und Übersetzung ohne Internetverbindung funktionieren.

---

# 5. Technologische Leitentscheidung für Transkription

Verwende `whisper.cpp` als lokale Inferenzbasis.

Einordnung:

- OpenAI Whisper ist die Modellfamilie
- `whisper.cpp` ist die bevorzugte lokale Runtime
- keine Python-/PyTorch-Runtime als primärer Produktpfad
- keine cloudabhängige Inferenz
- kein externer API-Schlüssel für die Kernfunktion

Die Inferenzschicht muss gegenüber dem macOS-App-Layer klar abgegrenzt sein.

Baue aber keine generische Multi-Engine-Architektur.

Erforderlich ist eine kleine, nachvollziehbare Schnittstelle zwischen:

- Audioaufnahme
- Transkription
- Textinjektion

---

# 6. Pflichtfunktion A: Systemweite Spracheingabe

## 6.1 Interaktionsmodell

Verbindlich ist `press-and-hold`.

Hauptzustände:

- `idle`
- `recording`
- `processing`

Verbindlicher Normalfluss:

`idle -> recording -> processing -> idle`

Erlaubte kontrollierte Fehlerpfade:

- `recording -> idle`
- `processing -> idle`

Nicht zulässig:

- parallele Aufnahmen
- parallele Transkriptionen
- Start einer neuen Aufnahme während `processing`
- hängende Zwischenzustände
- stilles Scheitern ohne sichtbaren Zustand
- Toggle-Modus als Ersatz für press-and-hold

## 6.2 Globaler Hotkey

Implementiere einen global funktionierenden Hotkey.

Anforderungen:

- funktioniert ausserhalb von PushWrite
- Hotkey down startet die Aufnahme
- Hotkey up beendet die Aufnahme
- autorepeat oder mehrfach eintreffende Events starten keine zweite Aufnahme
- bei deaktivierter oder fehlender Berechtigung erfolgt eine verständliche Reaktion
- der Hotkey ist mindestens in den Einstellungen sichtbar
- verwende einen sinnvollen Standard-Hotkey
- verhindere offensichtlich problematische Systemkonflikte soweit technisch zuverlässig erkennbar

Eine breite Hotkey-Konfigurationsoberfläche ist nicht Pflicht, sofern sie für die Stabilität unnötige Komplexität erzeugt.

Mindestens ein belastbarer Standard-Hotkey muss funktionieren.

## 6.3 Mikrofonaufnahme

Implementiere native Audioaufnahme für macOS.

Anforderungen:

- Aufnahme startet nur aus `idle`
- Aufnahme stoppt nur aus `recording`
- Audioformat ist für whisper.cpp geeignet
- unnötige Formatkonvertierungen vermeiden
- leere und offensichtlich zu kurze Aufnahmen erkennen
- temporäre Audiodaten kontrolliert behandeln
- temporäre Dateien nach erfolgreicher oder fehlgeschlagener Verarbeitung entfernen
- keine dauerhafte Audioarchivierung
- Mikrofonfehler führen zurück nach `idle`
- Aufnahme darf bei verlorenen Events nicht dauerhaft weiterlaufen

Prüfe mindestens:

- kein Mikrofon vorhanden
- Mikrofonzugriff verweigert
- Eingabegerät wechselt
- Aufnahme startet nicht
- Aufnahme stoppt nicht normal
- leerer Audiobuffer
- sehr kurze Aufnahme
- App wird während Aufnahme beendet
- Hotkey wird ungewöhnlich schnell gedrückt und losgelassen

## 6.4 Lokale Transkription

Integriere whisper.cpp real in die App.

Anforderungen:

- keine Mock-Transkription im Release-Pfad
- lokale Verarbeitung
- kein Netzwerk für die Transkription
- reproduzierbare Modellintegration
- Modellherkunft und Lizenz dokumentieren
- Modellintegrität soweit sinnvoll prüfbar machen
- sinnvolle Initialisierung und Fehlerbehandlung
- Inferenz ausserhalb des UI-Hauptthreads
- UI und Hotkey-Verarbeitung bleiben responsiv
- wiederholte Nutzung ohne Neustart der App
- kein unnötiges erneutes Laden des Modells pro Aufnahme
- kontrollierter Speicherverbrauch
- klare Meldung, falls Modell fehlt, beschädigt oder inkompatibel ist

Prüfe anhand realer Hardware, soweit die Umgebung dies zulässt:

- erste Transkription
- mehrere Transkriptionen nacheinander
- deutsche Sprache
- englische Sprache
- kurze Sätze
- längere Sätze im sinnvollen Alpha-Rahmen
- Stille
- Hintergrundgeräusche
- Abbruch- und Fehlerpfade

Sprache:

- mindestens automatische Spracherkennung oder eine klar gesetzte Standardsprache
- Deutsch und Englisch müssen im Alpha-Test berücksichtigt werden
- keine breite Sprachverwaltungsoberfläche bauen, falls dafür kein belastbarer Bedarf besteht

## 6.5 Direkte Texteingabe am Cursor

Nach erfolgreicher Transkription muss der Text in die zuvor aktive Zielanwendung eingefügt werden.

Anforderungen:

- Zielanwendung beziehungsweise Zielkontext vor dem PushWrite-Fokuswechsel sichern
- Text möglichst direkt an der aktuellen Einfügemarke einsetzen
- Zwischenablage des Nutzers nicht dauerhaft überschreiben
- falls ein kontrollierter Clipboard-Fallback technisch nötig ist:
  - vorherigen Clipboard-Inhalt sichern
  - Einfügevorgang nachvollziehbar ausführen
  - ursprünglichen Clipboard-Inhalt zuverlässig wiederherstellen
  - Race Conditions berücksichtigen
  - Fallback klar dokumentieren
- keine sichtbaren Copy-Paste-Zwischenschritte für den Nutzer
- keine doppelte Texteingabe
- kein Einfügen bei leerem oder ungültigem Transkript
- Whitespace und Zeilenumbrüche kontrollieren
- bestehender Text darf nicht unbeabsichtigt gelöscht werden

Mindestens testen in:

- TextEdit
- Safari oder einem verbreiteten Browser
- Notes
- Mail oder vergleichbarem Standard-Textfeld
- einem typischen Code- oder Markdown-Editor, sofern vorhanden
- einem nicht editierbaren Kontext
- einem geschützten Passwortfeld

Passwort- und andere geschützte Felder:

- dort keinen Text erzwingen
- sicher und nachvollziehbar abbrechen
- keine sensiblen Inhalte protokollieren

---

# 7. Pflichtfunktion B: Menu-Bar-App

PushWrite soll als native Menu-Bar-Anwendung funktionieren.

## 7.1 Menu-Bar-Icon

Erstelle ein eigenständiges PushWrite-Icon für die macOS-Menu-Bar.

Vorgaben:

- kein Kopieren des Symbols einer bestehenden Übersetzer-App
- kein OpenAI-Logo
- kein Whisper-Logo als Produktlogo
- keine Verwechslungsgefahr mit Apple-Systemicons
- eigenständige, reduzierte PushWrite-Symbolik
- in kleinen Grössen klar erkennbar
- als monochromes macOS-Template-Icon geeignet
- sauber in Light Mode und Dark Mode
- funktional, nicht dekorativ
- keine feinen Details, die in der Menu-Bar verschwinden
- optisch mit den Vorgaben des Company-Handbooks vereinbar
- Akzentfarbe nur dort einsetzen, wo macOS kein Template-Rendering verlangt

Entwickle mindestens mehrere nachvollziehbare Icon-Richtungen intern und wähle anhand klarer Kriterien die stärkste Variante.

Mögliche semantische Bausteine:

- Sprache oder Schall
- Einfügemarke beziehungsweise Cursor
- Schreiben
- gerichtete Bewegung von Sprache zu Text

Das Endsymbol soll nicht mehrere komplexe Metaphern gleichzeitig zeigen.

Liefere:

- bearbeitbare Vektorquelle, vorzugsweise SVG
- passende PDF- oder Asset-Catalog-Versionen
- Menu-Bar-Template-Asset
- App-Icon-Set, falls für die installierbare Anwendung erforderlich
- Dokumentation zur Symbolidee und Verwendung

Keine externen proprietären Icon-Assets ungeprüft übernehmen.

## 7.2 Menu-Bar-Zustände

Das Icon oder die Menu-Bar-Darstellung muss mindestens diese Zustände nachvollziehbar machen:

- bereit
- Aufnahme läuft
- Verarbeitung läuft
- Fehler oder Handlungsbedarf

Die Zustände müssen zurückhaltend und macOS-gerecht sein.

Keine hektischen oder dauerhaft störenden Animationen.

## 7.3 Menu-Bar-Popover oder Fenster

Erstelle eine kompakte Menu-Bar-Oberfläche.

Sie soll mindestens enthalten:

- aktueller PushWrite-Status
- sichtbarer aktiver Hotkey
- Zugriff auf Einstellungen
- Zugriff auf Berechtigungsstatus
- Zugriff auf die Übersetzungs-Zusatzfunktion
- About-/Versionsinformation
- Beenden

Die Oberfläche darf nicht zu einem komplexen Texteditor werden.

---

# 8. Zusatzfunktion: vollständig lokale Clipboard-Übersetzung

## 8.1 Produktzweck

PushWrite soll optional erkennen können, wenn der Nutzer Text markiert und mit `Command-C` kopiert.

Der kopierte Text soll anschliessend vollständig lokal in eine gewählte Zielsprache übersetzt und in der Menu-Bar-Oberfläche angezeigt werden.

Beispiel:

- Ausgangssprache: automatisch erkennen oder Englisch
- Zielsprache: Deutsch

Diese Funktion ist eine Zusatzfunktion und klar vom Diktier-Kernfluss zu trennen.

Sie darf den Abschluss des installierbaren Kernprodukts nicht gefährden.

## 8.2 Datenschutz- und Sicherheitsprinzip

Clipboard-Überwachung ist datenschutzsensitiv.

Deshalb verbindlich:

- standardmässig deaktiviert
- explizite Aktivierung durch den Nutzer
- klare Erklärung, was beobachtet wird
- keine Speicherung einer dauerhaften Clipboard-Historie
- keine Übertragung des kopierten Textes
- keine Cloud-API
- kein externer Account
- kein API-Key
- keine Protokollierung des vollständigen Clipboard-Inhalts
- Passwort- und sensible Felder soweit technisch möglich ausschliessen
- identische Clipboard-Inhalte nicht endlos erneut verarbeiten
- leere, binäre oder nicht textuelle Inhalte ignorieren
- grosse Inhalte mit einem begründeten Limit behandeln
- Überwachung jederzeit leicht deaktivierbar
- Status in der Oberfläche sichtbar

## 8.3 Verbindlicher lokaler Übersetzungspfad

Die Übersetzungsfunktion muss vollständig lokal auf dem Gerät ausgeführt werden.

Verbindlich:

- keine Cloud-Übersetzungsdienste
- keine externen APIs
- keine Übertragung von kopiertem Text
- keine Abhängigkeit von einer Internetverbindung während der Übersetzung
- keine Apple-Systemfunktion verwenden, falls deren Verarbeitung oder Modellbereitstellung nicht nachweislich vollständig lokal erfolgt
- keine versteckte Fallback-Verbindung zu einem Onlinedienst
- keine Telemetrie mit Originaltext oder Übersetzung

Untersuche geeignete lokale Übersetzungsengines und Modelle für macOS.

Bewerte mindestens:

- Qualität für Deutsch ↔ Englisch
- Modellgrösse
- RAM-Bedarf
- Latenz
- Apple-Silicon-Eignung
- Intel-Mac-Eignung, sofern Intel unterstützt werden soll
- Lizenz
- Weiterverteilbarkeit
- Offlinefähigkeit
- Einbettung in eine native macOS-App
- Wartbarkeit
- Initialisierungszeit
- Verhalten bei längeren Texten
- Build- und Packaging-Aufwand
- Supply-Chain-Risiken

Bevorzuge eine lokal einbettbare Engine mit klarer Lizenz und reproduzierbarem Modellbezug.

Mögliche technische Richtungen dürfen geprüft werden, sind aber nicht vorgegeben:

- Marian-NMT-basierte Modelle
- CTranslate2-basierte lokale Inferenz
- ONNX-Runtime-basierte Übersetzungsmodelle
- Core-ML-konvertierte Übersetzungsmodelle
- andere geeignete Open-Source-Modelle mit lokaler Inferenz

Die konkrete Auswahl muss anhand realer Tests begründet werden.

Für die erste Alpha ist mindestens verbindlich:

- Englisch → Deutsch
- Deutsch → Englisch
- automatische Spracherkennung oder klarer manueller Ausgangssprachmodus
- vollständig lokale Verarbeitung
- reproduzierbare Modellinstallation
- dokumentierte Modellherkunft
- dokumentierte Lizenz
- dokumentierte Prüfsumme
- dokumentierter Speicherbedarf
- dokumentierter Offline-Nachweis

## 8.4 Funktionsverhalten

Bei aktivierter Überwachung:

1. Nutzer kopiert Text mit `Command-C`
2. PushWrite erkennt eine relevante Änderung des Textinhalts
3. PushWrite bestimmt die Ausgangssprache lokal oder verwendet eine gewählte Ausgangssprache
4. PushWrite übersetzt vollständig lokal in die konfigurierte Zielsprache
5. PushWrite zeigt Original und Übersetzung in einer kompakten Ansicht
6. der originale Clipboard-Inhalt bleibt erhalten

Mindestens konfigurierbar:

- Überwachung ein/aus
- Ausgangssprache:
  - automatisch erkennen
  - mindestens Deutsch
  - mindestens Englisch
- Zielsprache:
  - mindestens Deutsch
  - mindestens Englisch

Bevorzuge eine einfache Sprachauswahl statt einer breiten Verwaltungsoberfläche.

## 8.5 Abbruchregel für das Alpha-Release

Eine cloudbasierte oder teilweise cloudbasierte Übersetzung ist nicht zulässig.

Falls keine ausreichend stabile lokale Übersetzung innerhalb des Auftrags belastbar integriert werden kann:

- keinen Cloud-Ersatz einbauen
- keine Systemfunktion mit unklarem Verarbeitungsort verwenden
- Übersetzungsfunktion nicht als fertig kennzeichnen
- technische Architektur und Oberfläche vorbereiten
- die Funktion im Alpha-Build deaktiviert lassen
- den konkreten technischen Blocker dokumentieren
- die geprüften lokalen Engines und Modelle aufführen
- die Messergebnisse zu Qualität, Latenz, Speicherbedarf und Lizenz dokumentieren
- das Kernrelease trotzdem fertigstellen

Diese Abbruchregel gilt nur für die Übersetzungs-Zusatzfunktion.

Sie gilt nicht für:

- Hotkey
- Aufnahme
- lokale Transkription
- Textinjektion
- installierbare App

---

# 9. Einstellungen

Baue nur Einstellungen, die für die Alpha-Version wirklich nötig sind.

Mindestens:

- globaler Hotkey oder dessen Anzeige
- Mikrofon beziehungsweise Eingabegerät, falls notwendig
- Transkriptionssprache oder automatische Erkennung
- Clipboard-Übersetzung ein/aus
- Ausgangssprache der Übersetzung
- Zielsprache der Übersetzung
- Berechtigungsstatus
- gegebenenfalls Start bei Anmeldung, nur wenn sauber und stabil umsetzbar
- Debug-Logging ein/aus nur für Alpha-Diagnose, ohne sensible Inhalte

Keine grosse Einstellungsarchitektur.

---

# 10. Berechtigungen und First-Run

PushWrite benötigt je nach technischer Umsetzung mindestens:

- Mikrofonzugriff
- Accessibility-Berechtigung
- gegebenenfalls Input Monitoring oder weitere macOS-Berechtigungen

Baue einen klaren First-Run- und Permission-Flow.

Anforderungen:

- vor der Systemabfrage verständlich erklären, warum die Berechtigung gebraucht wird
- Systemdialog korrekt auslösen
- Berechtigungsstatus prüfen
- bei Ablehnung nicht abstürzen
- gezielten Weg zu den passenden Systemeinstellungen anbieten
- nach späterer Freigabe Status neu erkennen
- unnötige Berechtigungen vermeiden
- keine Berechtigung nur auf Vorrat anfordern

Beachte für Accessibility-Tests:

- belastbare Bewertung über ein stabiles App-Bundle
- Start über LaunchServices
- Bundle-Identität und Code-Signatur nachvollziehbar halten
- CDHash beziehungsweise Signaturzustand bei relevanten QA-Läufen dokumentieren
- direkte Debug-Starts nicht als alleinigen Accessibility-Nachweis verwenden

---

# 11. Oberfläche und Design

## 11.1 Gestaltungsrichtung

Die Anwendung soll:

- ruhig
- präzise
- reduziert
- funktional
- professionell
- klar macOS-nativ

wirken.

Kein visuelles Kopieren der bereitgestellten Übersetzer-App.

Das Referenzbild dient nur zum Verständnis des Nutzungsmusters:

- kompakte Menu-Bar-Oberfläche
- schnelle Anzeige
- klare Sprachpaarung
- gut sichtbarer Status
- direkter Zugriff auf Zusatzfunktionen

Entwickle eine eigenständige PushWrite-Oberfläche.

## 11.2 Markenbezug

Nutze die Vorgaben des Company-Handbooks angemessen.

Beachte:

- Menu-Bar-Template-Icons werden durch macOS gerendert und nicht in Markenrot erzwungen
- Markenfarben nur dort einsetzen, wo sie funktional und systemkonform sind
- keine nicht mitgelieferten oder nicht ausreichend lizenzierten Fonts in das App-Bundle kopieren
- Systemschrift verwenden, wenn die Handbook-Typografie technisch oder lizenzrechtlich nicht sauber bundelbar ist
- Schweizer Rechtschreibung für deutschsprachige Texte
- keine unnötigen Anglizismen in der deutschen Oberfläche
- technische Produktbegriffe konsistent halten

## 11.3 Accessibility der Oberfläche

Mindestens:

- klare Accessibility-Labels
- vollständige Tastaturbedienbarkeit
- VoiceOver-taugliche Steuerelemente
- ausreichende Kontraste
- Dark Mode und Light Mode
- sinnvolle Fokusreihenfolge
- keine Information ausschliesslich über Farbe
- reduzierte Bewegung respektieren
- verständliche Fehlertexte

---

# 12. Architektur

Halte die Architektur klein und wartbar.

Sinnvolle Komponenten können sein:

- App-/Menu-Bar-Layer
- Hotkey-Service
- Audio-Capture-Service
- Transcription-Service
- Text-Insertion-Service
- Permission-Service
- Clipboard-Monitoring-Service
- Local-Translation-Service
- Settings
- zentraler, kleiner Workflow-State

Verbindlich:

- keine überdimensionierte Clean-Architecture
- kein generisches Plugin-System
- keine Multi-Plattform-Abstraktion
- kein Dependency-Injection-Framework ohne nachweisbaren Bedarf
- keine Event-Bus-Architektur für drei Zustände
- klare Eigentümerschaft von Zuständen
- UI-Updates auf dem Main Actor
- lang laufende Arbeiten nicht auf dem Main Thread
- saubere Behandlung von Cancellation und App-Beendigung
- keine Datenrennen

Die Übersetzungsfunktion darf nicht eng mit dem Diktierworkflow gekoppelt werden.

Transkription und Übersetzung dürfen unterschiedliche lokale Engines verwenden, sollen aber gemeinsame Regeln für:

- Modellablage
- Integritätsprüfung
- Fehlerbehandlung
- Offlinebetrieb
- Logging
- Ressourcenmanagement

konsistent umsetzen.

---

# 13. Modell- und Distributionsstrategie

## 13.1 Whisper-Modell

Entscheide anhand von:

- Modellgrösse
- erwarteter Genauigkeit
- Downloadgrösse
- RAM-Bedarf
- Inferenzlatenz
- unterstützter Hardware
- Lizenz und Weiterverteilung

ob das Whisper-Modell:

- im App-Artefakt enthalten ist
- als separates Release-Artefakt bereitgestellt wird
- beim ersten Start ausdrücklich heruntergeladen wird

## 13.2 Übersetzungsmodell

Entscheide separat anhand von:

- Qualität Deutsch ↔ Englisch
- Modellgrösse
- RAM-Bedarf
- Initialisierungszeit
- Latenz
- Apple-Silicon-Eignung
- Lizenz
- Weiterverteilbarkeit
- native Einbettung
- Wartbarkeit

ob das Übersetzungsmodell:

- im App-Artefakt enthalten ist
- als separates Release-Artefakt bereitgestellt wird
- beim ersten Start ausdrücklich heruntergeladen wird

## 13.3 Gemeinsame Anforderungen

Das Produktziel ist offlinefähige Nutzung.

Ein Modell-Download darf daher nur ein einmaliger, transparenter Einrichtungsschritt sein. Nach vollständiger Installation müssen Transkription und Übersetzung offline funktionieren.

Bevorzuge für die erste Alpha den einfachsten reproduzierbaren Distributionsweg.

Dokumentiere für jedes Modell:

- exakte Modellvariante
- Herkunft
- Prüfsumme
- Lizenz
- Speicherbedarf
- RAM-Bedarf
- Ablageort
- Austausch- oder Aktualisierungsprozess
- Verhalten bei fehlendem Modell
- Verhalten bei beschädigtem Modell
- Offline-Nachweis

---

# 14. Packaging, Signierung und Installation

## 14.1 Pflichtartefakt

Erzeuge mindestens ein installierbares macOS-Artefakt:

- bevorzugt signiertes und notarisiertes `.dmg` oder
- eine sauber verpackte, signierte und notarisiert auslieferbare `.app` in einem geeigneten Archiv

Das Artefakt muss:

- PushWrite korrekt enthalten
- alle notwendigen Runtime-Bestandteile enthalten
- auf einem sauberen Zielsystem installierbar sein
- nach Installation aus `/Applications` starten
- keine Entwicklungsumgebung voraussetzen
- keinen Python- oder Homebrew-Installationsschritt voraussetzen
- keine manuellen Pfadkorrekturen benötigen

## 14.2 Signierung und Notarisierung

Prüfe vorhandene Developer-ID- und Notarisierungsumgebung.

Wenn gültige Credentials verfügbar sind:

- mit Developer ID signieren
- Hardened Runtime korrekt konfigurieren
- notwendige Entitlements minimal halten
- notarisierten Build erzeugen
- Ticket stapeln
- Gatekeeper-Prüfung durchführen

Wenn Credentials objektiv fehlen:

- vollständig signierbaren Release-Prozess vorbereiten
- unsigned oder ad-hoc Alpha-Artefakt nur klar gekennzeichnet erzeugen
- exakt dokumentieren, welche externen Credentials fehlen
- keine Secrets erfinden
- keine Secrets committen
- alle übrigen Prüfungen durchführen
- einen reproduzierbaren Signier- und Notarisierungsbefehl beziehungsweise Workflow liefern

Ein fehlendes Developer-Zertifikat ist ein externer Blocker für die notarisiert veröffentlichte Form, aber kein Grund, Build, Packaging und lokale Validierung abzubrechen.

## 14.3 Bundle-Identität

Lege eine stabile Bundle-ID fest oder verwende die bereits entschiedene Bundle-ID.

Sie darf zwischen QA-Builds nicht unnötig wechseln.

Bundle-ID, Signing Identity, Team-ID, Entitlements und Versionsdaten dokumentieren.

---

# 15. Security- und Privacy-Review

Führe vor Abschluss einen eigenen Security- und Privacy-Check durch.

Mindestens prüfen:

- Netzwerkzugriffe
- eingebundene Drittanbieter-Abhängigkeiten
- Lizenzen
- Secrets
- temporäre Dateien
- Dateiberechtigungen
- Mikrofonlebenszyklus
- Clipboard-Zugriff
- lokale Übersetzungsmodelle
- Logging
- Passwortfelder
- Accessibility-Rechte
- Eingabesimulation
- Update-/Downloadpfade
- Pfadmanipulation
- unsichere Shell-Aufrufe
- Code-Signing-Entitlements
- Hardened Runtime
- Abhängigkeiten mit bekannten Schwachstellen
- Supply-Chain-Risiken

Verbindlich:

- keine Audioinhalte loggen
- keine vollständigen Transkripte in normalen Logs
- keine vollständigen Clipboard-Inhalte loggen
- keine vollständigen Übersetzungen in normalen Logs
- keine API-Keys oder Credentials im Repository
- keine unverschlüsselten geheimen Konfigurationswerte
- keine versteckten Netzwerkaufrufe
- keine unnötigen Entitlements
- keine Shell-Befehle mit ungeprüften Nutzereingaben
- keine automatische Übertragung von Fehlerberichten mit Nutzinhalten

Erstelle einen dokumentierten Security-Report mit:

- geprüften Bereichen
- gefundenen Befunden
- behobenen Befunden
- verbleibenden Risiken
- Risikoeinstufung
- Release-Entscheid

---

# 16. Tests

## 16.1 Automatisierte Tests

Erweitere die automatisierte Testabdeckung sinnvoll.

Mindestens testen:

- erlaubte und unerlaubte State-Transitions
- wiederholte Hotkey-Events
- Hotkey up ohne Aufnahme
- neuer Start während `processing`
- Fehler beim Aufnahmestart
- leere Aufnahme
- Transkriptionsfehler
- leeres Transkript
- Textinjektion nur bei gültigem Resultat
- Rückkehr nach `idle`
- Clipboard-Deduplizierung
- deaktivierte Clipboard-Überwachung
- Sprachpaar-Konfiguration
- lokale Übersetzung ohne Netzwerk
- Verhalten bei fehlendem Übersetzungsmodell
- Verhalten bei beschädigtem Übersetzungsmodell
- sensible Logs enthalten keine Nutzinhalte

Mache technische Services soweit nötig testbar, ohne eine übergrosse Abstraktionsschicht einzuführen.

## 16.2 Integrations- und manuelle Tests

Erstelle eine nachvollziehbare Alpha-Testmatrix.

Mindestens:

### Kernfluss

- App starten
- Berechtigungen erteilen
- Hotkey halten
- Deutsch sprechen
- Hotkey loslassen
- Text erscheint am Cursor
- Vorgang mehrfach wiederholen
- App zwischen Zielanwendungen wechseln
- Fehlerpfade testen

### Übersetzung

- Funktion aktivieren
- Netzwerk vollständig deaktivieren
- englischen Text kopieren
- deutsche Übersetzung anzeigen
- deutschen Text kopieren
- englische Übersetzung anzeigen
- automatische Spracherkennung prüfen
- manuelle Ausgangssprache prüfen
- Funktion deaktivieren
- Clipboard bleibt unverändert
- kein Verlauf bleibt nach Neustart erhalten
- keine Netzwerkverbindung wird aufgebaut

### Oberfläche

- Light Mode
- Dark Mode
- VoiceOver
- Tastatursteuerung
- unterschiedliche Display-Skalierungen
- Menu-Bar mit wenig Platz
- App-Neustart
- System-Neustart, falls Login-Start implementiert wurde

### Installation

- Build-Artefakt auf sauberem Benutzerkonto installieren
- Start aus `/Applications`
- Gatekeeper prüfen
- Berechtigungen aus sauberem Zustand durchlaufen
- App entfernen und neu installieren
- Modellpfade prüfen
- Offlinebetrieb von Transkription und Übersetzung prüfen

## 16.3 Kill-Kriterien

Das Release ist nicht fertig, wenn einer dieser Punkte zutrifft:

- Kerntranskription ist nur ein Mock
- Transkription benötigt unbemerkt Internet
- Übersetzung überträgt Text, Metadaten oder Inhalte an einen externen Dienst
- Übersetzung funktioniert nur mit Internetverbindung
- der lokale Übersetzungsweg ist nicht technisch nachgewiesen
- Lizenz oder Weiterverteilbarkeit des Übersetzungsmodells ist ungeklärt
- Hotkey funktioniert nur bei fokussierter App
- Aufnahme kann hängen bleiben
- Text wird nicht zuverlässig an der Cursor-Position eingefügt
- Clipboard wird dauerhaft überschrieben
- Passwortfelder werden aktiv beschrieben
- App verlangt Entwicklungswerkzeuge
- App startet nur aus Xcode
- notwendige Modelle fehlen im vorgesehenen Installationsprozess
- normale Nutzung erzeugt Abstürze oder Datenrennen
- sensible Inhalte stehen in Logs
- installierbares Artefakt fehlt
- Release-Dokumentation behauptet Tests, die nicht durchgeführt wurden

---

# 17. CI und reproduzierbarer Build

Richte oder vervollständige einen reproduzierbaren Build- und Testprozess.

Mindestens:

- dokumentierter lokaler Build
- dokumentierter Testlauf
- Release-Konfiguration
- reproduzierbare whisper.cpp-Einbindung
- reproduzierbare Einbindung der lokalen Übersetzungsengine
- festgelegte Abhängigkeitsversionen
- festgelegte Modellversionen
- Lizenzübersicht
- GitHub-Actions-Workflow soweit ohne Secrets möglich
- klar getrennte Schritte für:
  - Build
  - Tests
  - Packaging
  - Signierung
  - Notarisierung
  - Release

Notarisierungs-Secrets dürfen ausschliesslich über sichere GitHub-Secrets oder lokale Keychain-Konfiguration eingebunden werden.

---

# 18. Dokumentation aktualisieren

Bringe mindestens folgende Dokumente auf den realen Stand:

- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- Architekturübersicht
- Systemkomponenten
- Berechtigungsmodell
- Whisper-Modellintegration
- lokale Übersetzungsintegration
- lokale Build-Anleitung
- Release-Anleitung
- Alpha-Testanleitung
- bekannte Einschränkungen
- Security-/Privacy-Dokumentation
- Lizenz- und Third-Party-Hinweise

README muss nach Abschluss nicht mehr behaupten, die vollständige App sei nicht implementiert.

Dokumentiere klar:

- was `0.2.0-alpha.1` kann
- was noch nicht stabil ist
- unterstützte macOS-Versionen
- unterstützte Hardware
- Installationsweg
- benötigte Berechtigungen
- Offline-Eigenschaften
- Modellgrössen
- Datenschutzverhalten
- bekannte Probleme
- Übersetzungsfunktion und deren Reifegrad
- Nachweis, dass Transkription und Übersetzung lokal laufen

Keine Funktionen als fertig beschreiben, die nur geplant oder teilweise umgesetzt sind.

---

# 19. Git- und Arbeitsweise

Arbeite in einer eigenen Branch, beispielsweise:

`release/0.2.0-alpha.1`

Erstelle kleine, nachvollziehbare Commits.

Geeignete Bereiche:

1. Repository- und Architekturprüfung
2. whisper.cpp-Integration
3. Aufnahme- und Workflow-Härtung
4. Textinjektion
5. Menu-Bar und Zustandsanzeige
6. Icon und Assets
7. Berechtigungsfluss
8. lokale Clipboard-Übersetzung
9. Tests
10. Packaging und Release
11. Security-Review
12. Dokumentation

Keine grossen unkommentierten Sammelcommits.

Verändere das Company-Handbook nicht.

Führe keine destruktiven Git-Operationen auf `main` aus.

---

# 20. Abschlussdefinition

Du bist erst fertig, wenn alle folgenden Punkte erfüllt sind:

## Kernprodukt

- [ ] globale press-and-hold Tastenkombination funktioniert
- [ ] Aufnahme startet beim Drücken
- [ ] Aufnahme endet beim Loslassen
- [ ] whisper.cpp transkribiert lokal
- [ ] Deutsch wurde real getestet
- [ ] Englisch wurde real getestet
- [ ] Text wird am Cursor der Zielanwendung eingefügt
- [ ] Clipboard des Nutzers bleibt erhalten
- [ ] Fehler führen zurück nach `idle`
- [ ] wiederholte Nutzung funktioniert

## Anwendung

- [ ] native Menu-Bar-App vorhanden
- [ ] eigenständiges PushWrite-Icon vorhanden
- [ ] Status bereit/aufnehmend/verarbeitend/Fehler sichtbar
- [ ] Einstellungen vorhanden
- [ ] Permission-Flow vorhanden
- [ ] Light und Dark Mode geprüft
- [ ] Accessibility-Labels vorhanden

## Übersetzung

- [ ] Clipboard-Überwachung standardmässig deaktiviert
- [ ] explizit aktivierbar
- [ ] Originaltext wird nicht dauerhaft gespeichert
- [ ] Englisch → Deutsch funktioniert vollständig lokal
- [ ] Deutsch → Englisch funktioniert vollständig lokal
- [ ] automatische oder manuelle Ausgangssprache funktioniert
- [ ] Original-Clipboard bleibt erhalten
- [ ] Übersetzung funktioniert ohne Internetverbindung
- [ ] keine Netzwerkübertragung findet statt
- [ ] Modellherkunft, Lizenz und Prüfsumme sind dokumentiert
- [ ] Übersetzung blockiert den Diktierworkflow nicht

Falls die lokale Übersetzungsfunktion trotz belastbarer Prüfung nicht integriert werden kann:

- [ ] Funktion bleibt deaktiviert
- [ ] kein Cloud-Ersatz wurde eingebaut
- [ ] technische Blocker sind dokumentiert
- [ ] geprüfte Engines und Modelle sind dokumentiert
- [ ] Kernrelease ist vollständig fertiggestellt

## Qualität

- [ ] automatisierte Tests laufen erfolgreich
- [ ] Integrationsprüfungen dokumentiert
- [ ] Release-Build läuft
- [ ] Security-Check abgeschlossen
- [ ] Privacy-Check abgeschlossen
- [ ] Drittanbieter-Lizenzen geprüft
- [ ] keine Secrets im Repository
- [ ] keine sensiblen Inhalte in Logs

## Distribution

- [ ] installierbares Artefakt erzeugt
- [ ] Start aus `/Applications` geprüft
- [ ] Signatur geprüft
- [ ] Notarisierung durchgeführt oder fehlende externe Credentials exakt dokumentiert
- [ ] Gatekeeper-Prüfung durchgeführt, soweit technisch möglich
- [ ] Prüfsumme des Release-Artefakts erzeugt

## Dokumentation

- [ ] README aktualisiert
- [ ] Changelog aktualisiert
- [ ] Roadmap aktualisiert
- [ ] Build-Anleitung aktualisiert
- [ ] Installationsanleitung vorhanden
- [ ] Alpha-Testanleitung vorhanden
- [ ] bekannte Einschränkungen dokumentiert
- [ ] Security-Report vorhanden
- [ ] Release Notes vorhanden

---

# 21. Erlaubte externe Blocker

Nur folgende Punkte dürfen als externe Blocker ausgewiesen werden:

- fehlende Apple Developer-ID-Credentials
- fehlende Notarisierungs-Credentials
- nicht verfügbare physische Testhardware
- eine durch offizielle Dokumentation belegte Einschränkung einer öffentlichen Apple-API
- ein extern nicht erreichbarer oder technisch defekter Release-Dienst
- keine lokal einbettbare Übersetzungsengine erfüllt trotz realer Prüfung gleichzeitig die Mindestanforderungen an Lizenz, Offlinebetrieb, Qualität und Packaging

Ein externer Blocker entbindet nicht von allen übrigen Arbeiten.

Beispiel:

Fehlt die Developer ID, müssen trotzdem fertig sein:

- funktionierende App
- Release-Build
- lokales Packaging
- Tests
- Security-Review
- dokumentierter Signing-Prozess
- vorbereitete Notarisierung
- klar gekennzeichnetes Alpha-Artefakt

Fehlt eine tragfähige lokale Übersetzungsengine, müssen trotzdem fertig sein:

- vollständiger Diktier-Kernfluss
- Menu-Bar-App
- Übersetzungsoberfläche vorbereitet und deaktiviert
- geprüfte lokale Engines dokumentiert
- keine Cloud-Lösung eingebaut

---

# 22. Verbotene Abkürzungen

Nicht akzeptabel:

- Kernfunktion durch Mock ersetzen
- Tests nur beschreiben statt ausführen
- Security-Check nur behaupten
- Übersetzungsfunktion über eine Cloud-API lösen
- eine teilweise cloudbasierte Übersetzung als lokal bezeichnen
- eine Apple-Systemfunktion verwenden, deren lokaler Verarbeitungsweg nicht nachgewiesen ist
- sensible Clipboard-Inhalte loggen
- vorhandene Projektdokumentation ignorieren
- komplette Architektur ohne Not neu schreiben
- neue Plattformen vorbereiten
- Datei-Transkription ergänzen
- App-Store-Veröffentlichung als Teil dieses Auftrags beginnen
- Company-Handbook verändern
- ungeprüfte fremde Icons oder Markenassets übernehmen
- bei erstem Buildfehler abbrechen
- Warnungen pauschal ignorieren
- einen erfolgreichen Debug-Start mit einem installierbaren Release gleichsetzen

---

# 23. Erwartete Schlusslieferung

Gib am Ende einen strukturierten Abschlussbericht aus.

## A. Ergebnis

- erreichte Version
- Branch
- letzter Commit
- unterstützte macOS-Version
- unterstützte Hardware
- gewählte Whisper-Modellvariante
- gewählte lokale Übersetzungsengine
- gewählte Übersetzungsmodelle
- Status der Kernfunktion
- Status der Übersetzungsfunktion

## B. Umsetzung

- zentrale implementierte Komponenten
- wichtigste Architekturentscheidungen
- verwendete öffentliche macOS-APIs
- whisper.cpp-Integrationsform
- Textinjektionsmechanismus
- Clipboard-Mechanismus
- lokale Übersetzungsengine
- lokaler Spracherkennungsmechanismus
- Modellablage und Integritätsprüfung

## C. Validierung

Für jeden Test:

- Testname
- Testart
- Umgebung
- Ergebnis
- Beleg oder Logpfad

Trenne:

- automatisiert bestanden
- manuell bestanden
- nicht ausführbar
- fehlgeschlagen

Liefere einen expliziten Offline-Testnachweis für:

- Transkription
- Deutsch → Englisch
- Englisch → Deutsch

## D. Security und Privacy

- gefundene Befunde
- behobene Befunde
- verbleibende Risiken
- Einstufung
- Release-Empfehlung
- nachgewiesene Netzwerkzugriffe
- Bestätigung, dass keine Nutzinhalte übertragen werden

## E. Artefakte

Liefere exakte Pfade und Prüfsummen für:

- `.app`
- `.dmg` oder Release-Archiv
- Symbol- und Icon-Quellen
- Whisper-Modell oder Modellpaket
- Übersetzungsmodelle oder Modellpakete
- Testreport
- Security-Report
- Release Notes
- Lizenzübersicht

## F. Externe Blocker

Nur tatsächlich bestehende Blocker aufführen.

Für jeden Blocker:

- was fehlt
- weshalb es extern ist
- welche Arbeiten trotzdem abgeschlossen wurden
- exakt welcher nächste menschliche Schritt nötig ist

## G. Endurteil

Gib genau eines dieser Urteile ab:

1. `READY FOR ALPHA TEST`
2. `READY FOR ALPHA TEST AFTER SIGNING`
3. `NOT READY`

`READY FOR ALPHA TEST` ist nur zulässig, wenn ein installierbares, ausreichend geprüftes Artefakt vorhanden ist.

`READY FOR ALPHA TEST AFTER SIGNING` ist nur zulässig, wenn ausschliesslich Developer-ID- oder Notarisierungs-Credentials fehlen.

Bei `NOT READY` müssen die verbleibenden Blocker konkret, reproduzierbar und priorisiert sein.

---

# 24. Priorität bei Zielkonflikten

Bei Zielkonflikten gilt:

1. funktionierender Diktier-Kernfluss
2. vollständige lokale Verarbeitung
3. Datenschutz und Sicherheit
4. zuverlässige Textinjektion
5. stabile Installation
6. nachvollziehbare Fehlerbehandlung
7. Menu-Bar-Bedienung
8. lokale Übersetzungs-Zusatzfunktion
9. visueller Feinschliff
10. spätere Erweiterbarkeit

Keine Zusatzfunktion darf die Fertigstellung des Kernprodukts verhindern.

Cloudbasierte oder teilweise cloudbasierte Verarbeitung ist auch dann nicht zulässig, wenn sie die Umsetzung beschleunigen würde.
