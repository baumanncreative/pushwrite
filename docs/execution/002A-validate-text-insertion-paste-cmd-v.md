# Auftrag 002A: Textinjektion per Pasteboard plus synthetischem Cmd+V für PushWrite v0.1.0 validieren

## Ziel

Validiere den pragmatischsten ersten MVP-Pfad für die direkte Texteinfügung auf macOS:

**Plain-Text in das Pasteboard schreiben und anschliessend per synthetischem `Cmd+V` in den aktiven Texteingabekontext einfügen.**

Der Auftrag dient nicht dazu, die endgültige universelle Textinjektionslösung für PushWrite zu bauen.  
Er dient dazu, in einem kleinen, kontrollierbaren Spike zu prüfen, ob dieser Weg als erster robuster MVP-Pfad tragfähig genug ist.

Das Ergebnis soll so konkret sein, dass danach entschieden werden kann:

- ob dieser Ansatz als erster Implementierungspfad für v0.1.0 verfolgt wird
- ob er nur eingeschränkt tragfähig ist
- oder ob ein anderer Ansatz priorisiert werden muss

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

Gerade Schritt 6 ist produktkritisch.

Die technische Analyse des Projekts hält ausdrücklich fest, dass die Textinjektion am Cursor für das macOS-MVP separat verifiziert werden muss und dass app- bzw. systemnahe Rechte dafür relevant sein können. Die Inferenz-Basis allein löst diesen Teil nicht. 

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- Ziel ist direkte Texteinfügung in typische Texteingabekontexte
- Robustheit ist wichtiger als technische Eleganz
- der Spike darf bewusst schmal und pragmatisch sein
- keine Multiplattform-Betrachtung
- keine Datei- oder Batch-Workflows
- keine finale Accessibility-Vollstrategie
- keine breite UI-Ausarbeitung

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- ob Pasteboard plus synthetisches `Cmd+V` für PushWrite als erster MVP-Weg praktikabel ist
- in welchen einfachen Zielkontexten dieser Weg zuverlässig funktioniert
- welche Rechte, Friktionen oder technischen Grenzen dabei sichtbar werden
- ob Clipboard-Restore oder ähnliche Schutzmassnahmen nötig sind
- welche Beobachtungen gegen diesen Ansatz als MVP-Erstpfad sprechen würden

---

## Konkreter Auftrag

Erstelle einen kleinen technischen Spike, der den folgenden Ablauf validiert:

1. Plain-Text wird programmatisch in das Pasteboard geschrieben
2. in einem aktiven Texteingabekontext wird ein synthetisches `Cmd+V` ausgelöst
3. das Einfügeverhalten wird in wenigen, bewusst gewählten Testkontexten beobachtet
4. die Risiken und Grenzen dieses Ansatzes werden dokumentiert

Der Spike soll **nicht** als endgültige Produktimplementierung verstanden werden, sondern als gezielte MVP-Validierung.

---

## Erwartetes Ergebnis

Liefere:

### 1. Einen kleinen technischen Spike
Ein minimaler Prototyp oder Validierungscode, der Pasteboard plus synthetisches `Cmd+V` in engem Umfang testet.

### 2. Klare Testdurchführung
Prüfe den Spike mindestens in diesen Zielkontexten:

- TextEdit
- ein Browser-Textarea auf macOS

Weitere Kontexte sind nur zulässig, wenn sie den Auftrag nicht unnötig aufblasen.

### 3. Dokumentierte Beobachtungen
Halte mindestens fest:

- ob das Einfügen technisch funktioniert
- ob der Text korrekt eingefügt wird
- ob der aktive Fokus korrekt genutzt wird
- ob erkennbare Rechte- oder Systemhürden auftreten
- ob der Ablauf reproduzierbar wirkt
- ob das Clipboard-Verhalten problematisch ist

### 4. MVP-Einordnung
Bewerte am Ende klar:

- tragfähig als erster MVP-Pfad
- nur eingeschränkt tragfähig
- nicht tragfähig

### 5. Konkrete Folgeempfehlung
Formuliere daraus den nächsten kleinen Folgeauftrag.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- nur den konkreten Validierungsansatz Pasteboard plus `Cmd+V` prüfen
- bewusst klein bleiben
- sich auf typische Texteingabekontexte beschränken
- Beobachtung und Bewertung sauber trennen
- Rechte- und Clipboard-Friktion explizit benennen
- am Ende eine klare Entscheidungsempfehlung liefern

Wenn etwas unsicher ist, muss es als offene Frage markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- endgültige universelle Textinjektionsarchitektur
- breiter Vergleich aller denkbaren Injektionsmethoden
- Accessibility-Komplettlösung
- finale App-Integration mit Hotkey, Audio und Transkription
- UI-Design
- Historien-, Undo- oder Komfortfunktionen
- Multiplattform-Betrachtung
- Unterstützung aller macOS-Anwendungen

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Funktioniert der Ansatz in einfachen, typischen Zielkontexten reproduzierbar?
2. Welche Rechte oder Systemgrenzen blockieren ihn?
3. Ist die Clipboard-Friktion für einen MVP vertretbar?
4. Reicht dieser Weg als erster robuster Pfad für v0.1.0?
5. Welche minimale nächste Validierung oder Härtung folgt daraus?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- geänderte oder erstellte Artefakte
- Testkontexte und Beobachtungen
- technische Risiken oder offene Fragen
- klare MVP-Einordnung
- konkreten Folgeauftrag

Keine allgemeine Plattformabhandlung.  
Keine unnötige Theorie.  
Keine breite Zukunftsarchitektur.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- ein kleiner Spike für Pasteboard plus synthetisches `Cmd+V` erstellt wurde
- der Spike mindestens in TextEdit und einem Browser-Textarea geprüft wurde
- Beobachtungen zu Funktion, Fokus, Reproduzierbarkeit und Clipboard-Verhalten dokumentiert wurden
- erkennbare Rechte- oder Systemhürden benannt wurden
- eine klare Einordnung als tragfähig, eingeschränkt tragfähig oder nicht tragfähig vorliegt
- ein direkt anschlussfähiger Folgeauftrag formuliert wurde