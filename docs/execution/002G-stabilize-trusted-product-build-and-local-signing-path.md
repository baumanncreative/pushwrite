# Auftrag 002G: Trusted Produktbuild und stabilen lokalen Signing-/Trust-Pfad für PushWrite.app festlegen

## Ziel

Stabilisiere den lokalen Produktbuild von PushWrite.app so, dass wiederholte Builds und Validierungen den Accessibility-/TCC-Trust des Produktbundles nicht unnötig verlieren oder zumindest reproduzierbar und kontrollierbar behandelt werden können.

Der Auftrag dient nicht dazu, Mikrofonaufnahme oder `whisper.cpp` zu integrieren.  
Er dient dazu, den nach 002F verbleibenden Engpass vor der Mikrofonstufe zu schliessen:

- stabilen lokalen Produktbuild festlegen
- reproduzierbaren Bundle-Pfad festlegen
- lokalen Signing-/Trust-Pfad klären
- Rebuild-bedingten Trust-Verlust minimieren oder sauber einhegen
- bestehende Produktvalidierung auf diesen stabilisierten Pfad umstellen

Das Ergebnis soll so konkret sein, dass danach Mikrofon-Start/Stop an denselben Hotkey-/Flow-Kern angebunden werden kann, ohne Build-/Trust-Probleme mit Audio-/Flow-Problemen zu vermischen.

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

Für diesen Workflow sind bereits folgende Schritte produktnah vorhanden:

- PushWrite.app als reales Produktbundle
- globaler Hotkey
- kleiner Flow
- simuliertes In-Memory-Transkript
- `insertTranscription(text:)`
- validierter paste-basierter Insert-Pfad
- ehrlicher Blocked-Fall für Accessibility

Nach 002F ist der verbleibende Engpass nicht mehr die Produktlogik selbst, sondern die Stabilität des lokalen Bundle-Builds im Zusammenspiel mit TCC/Accessibility.

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- PushWrite.app ist das relevante Produktbundle
- der bestehende Hotkey-/Flow-/Insert-Kern bleibt gesetzt
- Audioaufnahme ist nicht Teil dieses Auftrags
- `whisper.cpp`-Integration ist nicht Teil dieses Auftrags
- es geht um Build-/Signing-/Trust-Härtung, nicht um breite Funktionserweiterung
- keine alternative Textinjektionsmethode
- keine breite UI- oder Settings-Ausarbeitung
- keine Multiplattform-Betrachtung

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- wie ein stabiler lokaler Produktbuild für PushWrite.app festgelegt wird
- wie der Bundle-Pfad so stabil gehalten wird, dass TCC/Accessibility möglichst nicht unnötig neu invalidiert wird
- ob und wie lokales Signing verbessert oder fixiert werden sollte
- welche Teile des Trust-Verhaltens gesichert beobachtbar sind und welche nur plausibel abgeleitet werden
- wie die vorhandenen Validatoren und Validierungsskripte auf diesen stabilisierten Pfad umgestellt werden

---

## Konkreter Auftrag

Stabilisiere den lokalen Produktbuild und den Trust-/Signing-Pfad für PushWrite.app so, dass die nächste Integrationsstufe auf einer belastbaren Produktbasis aufsetzen kann.

Der Auftrag soll mindestens diese Teile enthalten:

1. einen stabilen lokalen Build- und Bundle-Pfad festlegen
2. den aktuellen Signing-Zustand des Bundles analysieren und dokumentieren
3. den Zusammenhang zwischen Rebuild, Signatur/CDHash und Accessibility-Trust einordnen
4. einen praktikablen lokalen Pfad festlegen:
   - Trust erhalten
   - oder Trust-Verlust reproduzierbar und kontrolliert behandeln
5. die vorhandenen Produkt-Validatoren auf diesen Pfad umstellen
6. eine kleine Revalidierung des bestehenden Produktkerns auf dem stabilisierten Pfad durchführen
7. die verbleibende Resthärtung vor Mikrofonintegration benennen

---

## Erwartetes Ergebnis

Liefere:

### 1. Stabilen lokalen Build-Pfad
Lege fest:

- wo das relevante PushWrite.app-Bundle liegt
- wie es reproduzierbar gebaut wird
- wie unnötige Bundle-Identitätswechsel vermieden werden
- welche Build-Variante für Entwicklung und Validierung als Standardpfad gilt

### 2. Signing- und Bundle-Identitätsanalyse
Dokumentiere mindestens:

- aktuellen Signing-Zustand
- Bundle Identifier
- relevante Beobachtungen zu CDHash / Rebuild-Verhalten
- welche Veränderungen plausibel den TCC-Trust beeinflussen

Wichtig:
Beobachtung und Schlussfolgerung sauber trennen.

### 3. Empfohlene lokale Strategie
Gib eine klare Empfehlung ab, welcher lokale Pfad ab jetzt gelten soll.

Zum Beispiel auf hoher Ebene:

- trusted Build einfrieren
- stabileren lokalen Signing-Pfad einziehen
- Rebuild-Strategie anpassen
- Pfad-/Bundle-Stabilität erhöhen

Die Empfehlung muss pragmatisch und für den MVP tauglich sein.

### 4. Umstellung der Validatoren
Stelle die vorhandenen Produkt-Validatoren auf den stabilisierten Pfad um.

Ziel ist:

- reproduzierbare Validierung auf genau dem relevanten Bundle
- keine unnötige Abhängigkeit von fragilen Launch-Varianten
- klare Trennung zwischen echtem Trust-Verhalten und Test-Overrides

### 5. Kleine produktnahe Revalidierung
Führe eine kleine, nachvollziehbare Revalidierung des bestehenden Kerns durch.

Mindestens zu prüfen sind:

- Produktstart
- Hotkey-Auslösung
- Success-Pfad in TextEdit
- Success-Pfad in Safari-Textarea
- Blocked-Pfad oder sauber begründete Ersatzbeobachtung
- Konsistenz der Logs und Statusartefakte

Die Serie darf eng bleiben. Fokus ist Stabilität des Build-/Trust-Pfads.

### 6. Dokumentierte Beobachtungen
Halte mindestens fest:

- welcher Build-/Bundle-Pfad als Standard gesetzt wird
- wie sich Rebuilds auf Trust auswirken
- ob ein stabilerer Signing-/Launch-Pfad erreicht wurde
- ob Validatoren nun belastbar auf diesem Pfad arbeiten
- welche Risiken vor Mikrofonintegration noch offen bleiben

### 7. MVP-Einordnung
Bewerte am Ende klar:

- stabil genug für Mikrofon-Start/Stop als nächste Stufe
- im Wesentlichen tragfähig, aber mit kleiner Resthärtung
- noch nicht stabil genug für die nächste Integrationsstufe

### 8. Konkrete Folgeempfehlung
Formuliere daraus einen kleinen Folgeauftrag.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- auf PushWrite.app und dem bestehenden Produktkern aufbauen
- Build-/Signing-/Trust-Stabilität des realen Bundles fokussieren
- gesichert, plausibel und offen sauber trennen
- pragmatisch statt akademisch vorgehen
- Validatoren auf den stabilisierten Pfad ausrichten
- bewusst klein und risikoorientiert bleiben

Wenn Unsicherheiten bleiben, müssen sie als offene Punkte markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- Mikrofonaufnahme
- Audio-Pufferung
- `whisper.cpp`-Integration
- Modellwahl oder Modell-Packaging
- breite UI- oder Settings-Oberfläche
- alternative Textinjektionsmethoden
- Unterstützung aller macOS-Anwendungen
- Multiplattform-Betrachtung
- allgemeine Zukunftsarchitektur

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Wie bleibt das konkrete Produktbundle für Entwicklung und Validierung stabil identifizierbar?
2. Was ist am aktuellen Trust-Verhalten direkt beobachtet und was nur plausibel?
3. Welcher lokale Signing-/Launch-Pfad ist für das MVP pragmatisch am tragfähigsten?
4. Können die vorhandenen Validatoren danach belastbar auf genau diesem Pfad laufen?
5. Welche kleinste Resthärtung fehlt noch vor Mikrofon-Start/Stop?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- erstellte oder geänderte Artefakte
- Beschreibung des stabilen Build-/Bundle-Pfads
- Beschreibung des Signing-/Trust-Verhaltens
- klare Trennung zwischen Beobachtung und Schlussfolgerung
- Beschreibung der Validator-Umstellung
- Ergebnisse der kleinen Revalidierung
- technische Risiken oder offene Fragen
- klare MVP-Einordnung
- konkreten Folgeauftrag

Keine allgemeine Plattformdiskussion.  
Keine unnötige Theorie.  
Keine breite Zukunftsarchitektur.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- ein stabiler lokaler Build-/Bundle-Pfad für PushWrite.app festgelegt wurde
- Signing-/Trust-Verhalten nachvollziehbar dokumentiert wurde
- eine pragmatische lokale Strategie für Trust-Erhalt oder kontrollierten Trust-Umgang empfohlen wurde
- die Produkt-Validatoren auf diesen Pfad umgestellt wurden
- eine kleine produktnahe Revalidierung durchgeführt wurde
- eine klare Einschätzung zur Stabilität vor Mikrofonintegration vorliegt
- ein direkt anschlussfähiger Folgeauftrag formuliert wurde