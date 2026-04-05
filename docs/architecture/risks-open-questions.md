# Risks and Open Questions

## Zweck dieses Dokuments

Dieses Dokument hält die aktuell wichtigsten Unsicherheiten, Risiken und offenen Fragen für PushWrite v0.1.0 fest.

Es dient dazu,

- technische und produktbezogene Risiken sichtbar zu machen
- offene Fragen von bereits entschiedenen Punkten zu trennen
- Prüfbedarf vor der Umsetzung klar zu benennen
- Scope Creep durch unsaubere Problemvermischung zu vermeiden

Dieses Dokument ist **kein** Implementierungsplan und **keine** Entscheidungssammlung.  
Es dokumentiert Unsicherheiten, die für Architektur, MVP-Erreichung oder Produktstabilität relevant sind.

---

## 1. Einordnung

Für PushWrite sind die grössten Risiken im MVP **nicht** primär modelltheoretisch.

Die Hauptunsicherheiten liegen aktuell in:

- macOS-Systemintegration
- Berechtigungsfluss
- Robustheit der Textinjektion
- Zusammenspiel von Hotkey, Audioaufnahme und Transkriptionsablauf
- Wahl einer tragfähigen, kleinen und stabilen Erstkonfiguration

Die Inferenz-Basis ist als Richtung entschieden, aber die Produktrisiken liegen vor allem im App-Layer.

---

## 2. Arbeitskategorien

Zur sauberen Trennung werden Punkte in vier Kategorien geführt:

### Risiko
Etwas, das den MVP gefährden, verzögern oder qualitativ entwerten kann.

### Offene Frage
Etwas, das noch entschieden oder verifiziert werden muss.

### Annahme
Etwas, das aktuell plausibel ist, aber noch nicht belastbar verifiziert wurde.

### Prüfpunkt
Eine konkrete Verifikation, ein Test oder eine Entscheidungsvorbereitung.

---

## 3. Hauptrisiken

## Risiko 001: Textinjektion an der Cursor-Position ist nicht robust genug

### Typ
Technisches Produktrisiko

### Beschreibung
Der Produktkern verlangt, dass erkannter Text direkt an der aktuellen Cursor-Position eingefügt wird.  
Wenn das nur in einzelnen Apps oder unzuverlässig funktioniert, verliert PushWrite seinen zentralen Nutzen.

### Warum kritisch
PushWrite ist kein allgemeines Transkriptionswerkzeug.  
Der Unterschied liegt gerade in der direkten Texteingabe im aktiven Kontext.

### Mögliche Auswirkungen
- Kernnutzen nicht eingelöst
- inkonsistentes Verhalten zwischen Apps
- hoher Support- und Frustrationsaufwand
- MVP wirkt unfertig trotz funktionierender Transkription

### Aktueller Status
Offen

### Prüfpunkt
Es muss früh verifiziert werden:
- in welchen typischen Texteingabefeldern das Einfügen stabil funktioniert
- welche technische Methode dafür am zuverlässigsten ist
- welche Grenzen klar dokumentiert werden müssen

### Kill-Kriterium
Wenn direkte Texteinfügung nicht verlässlich genug erreichbar ist, ist der MVP in seiner jetzigen Definition zu hinterfragen.

---

## Risiko 002: macOS-Berechtigungen erzeugen Friktion oder Blockaden

### Typ
Plattform- und UX-Risiko

### Beschreibung
Für Mikrofon, eventuell Accessibility und weitere systemnahe Funktionen sind macOS-Berechtigungen relevant.  
Wenn dieser Fluss unklar oder störanfällig ist, scheitert der MVP schon vor dem Kernnutzen.

### Warum kritisch
Der Nutzer erlebt das Produkt zuerst über Installation, Freigaben und ersten Einsatz.  
Ein schlechter Berechtigungsfluss zerstört Vertrauen früh.

### Mögliche Auswirkungen
- Aufnahme funktioniert nicht
- Textinjektion funktioniert nicht
- Nutzer versteht Ursache nicht
- Supportbedarf steigt stark

### Aktueller Status
Offen

### Prüfpunkt
Zu verifizieren:
- welche Rechte tatsächlich zwingend nötig sind
- in welcher Reihenfolge diese Rechte angefragt oder erklärt werden sollten
- wie Fehlerzustände verständlich signalisiert werden

---

## Risiko 003: Globaler Hotkey ist technisch oder praktisch unzuverlässig

### Typ
Technisches Interaktionsrisiko

### Beschreibung
Der gesamte MVP basiert auf einem globalen Push-to-talk-Ablauf.  
Wenn der Hotkey nicht stabil registriert, mit anderen Shortcuts kollidiert oder uneinheitlich reagiert, wird der Kernablauf instabil.

### Warum kritisch
Ohne verlässlichen Auslöser gibt es kein sauberes Produktverhalten.

### Mögliche Auswirkungen
- Aufnahme startet oder stoppt nicht sauber
- unbeabsichtigte Aktivierungen
- Konflikte mit anderen Apps oder Systemshortcuts
- Kernworkflow wird untrustworthy

### Aktueller Status
Offen

### Prüfpunkt
Zu prüfen:
- welche Hotkey-Strategie robust genug ist
- wie Kollisionen minimiert werden
- wie sich press-and-hold praktisch verhält
- ob eine erste Standardbelegung tragfähig ist

---

## Risiko 004: Modellwahl liefert unpassendes Verhältnis aus Qualität, Latenz und Ressourcenbedarf

### Typ
Technisches Qualitätsrisiko

### Beschreibung
Auch bei passender Runtime kann die falsche Modellwahl den MVP entwerten:
- zu langsam
- zu ressourcenintensiv
- zu ungenau

### Warum kritisch
Der MVP muss alltagstauglich wirken, nicht nur technisch funktionieren.

### Mögliche Auswirkungen
- spürbare Wartezeiten
- schlechte Transkriptionsqualität
- unnötig hoher Ressourcenverbrauch
- negative Wahrnehmung trotz richtiger Produktidee

### Aktueller Status
Offen

### Annahme
Eine kleinere oder mittlere Modellvariante könnte für den Start das bessere Produktverhältnis liefern als maximale Modellqualität.

### Prüfpunkt
Vergleich von:
- `base.en`
- `small.en`
- optional quantisierte Varianten

Bewertet werden soll:
- wahrgenommene Reaktionszeit
- Nutzbarkeit im typischen Diktierfall
- RAM- und Disk-Budget

---

## Risiko 005: Architektur wird zu früh für Zukunftsszenarien überbaut

### Typ
Projekt- und Architekturrisiko

### Beschreibung
Das Projekt hat eine nachvollziehbare Zukunftsvision.  
Gerade deshalb besteht das Risiko, dass das MVP früh auf spätere Plattformen, Datei-Transkription oder Multi-Engine-Szenarien hin überabstrahiert wird.

### Warum kritisch
Vorzeitige Generalisierung kostet Fokus, Zeit und Klarheit.

### Mögliche Auswirkungen
- unnötige technische Komplexität
- langsameres Vorankommen
- unklare Modulgrenzen
- MVP wird breiter statt stabiler

### Aktueller Status
Dauerhaft aktiv zu beobachten

### Prüfpunkt
Jede neue technische Schicht muss beantworten:
- Löst sie ein aktuelles MVP-Problem?
- Oder nur ein hypothetisches Zukunftsproblem?

Wenn Letzteres, gehört sie nicht in v0.1.0.

---

## Risiko 006: Fehler- und Statuskommunikation ist zu schwach

### Typ
UX-Risiko

### Beschreibung
Auch ein enger MVP braucht minimale Zustandsklarheit:
- nimmt gerade auf
- transkribiert gerade
- Berechtigung fehlt
- Einfügen fehlgeschlagen

Wenn diese Zustände nicht erkennbar sind, wirkt das Produkt unzuverlässig.

### Warum kritisch
Bei Spracheingabe ist Feedback Teil der Funktion, nicht nur Dekoration.

### Mögliche Auswirkungen
- Nutzer weiss nicht, was gerade passiert
- Fehlersuche wird unnötig schwer
- Produktvertrauen sinkt

### Aktueller Status
Offen

### Prüfpunkt
Es ist zu klären:
- welches minimale Statusmodell der MVP braucht
- welche Zustände sichtbar sein müssen
- welche Fehlermeldungen zwingend sind und welche nicht

---

## 4. Offene Fragen

## Offene Frage 001: Welche Modellvariante ist für den MVP die richtige Startkonfiguration?

### Relevanz
Hoch

### Warum offen
Die Inferenz-Basis ist entschieden, aber nicht die konkrete Modellgrösse.

### Zu klären
- `base.en` oder `small.en`
- quantisiert oder nicht
- welches Default-Modell liefert das beste Verhältnis aus Qualität und Responsiveness

### Entscheidungskriterium
Nicht maximale theoretische Genauigkeit, sondern bestes Produktverhältnis im Alltag.

---

## Offene Frage 002: Wann genau wird der Text eingefügt?

### Relevanz
Hoch

### Warum offen
Der Kernworkflow ist entschieden, aber der genaue Einfügezeitpunkt beeinflusst UX und Komplexität.

### Optionen
- nur nach Ende der Aufnahme
- schrittweise in Segmenten
- verzögert nach finaler Bestätigung

### Arbeitshypothese
Für v0.1.0 ist Einfügen **nach Ende der Aufnahme** wahrscheinlich der stabilste Start.

### Kill-Kriterium
Wenn inkrementelles Einfügen die Komplexität stark erhöht, gehört es nicht in den MVP.

---

## Offene Frage 003: Welche technische Methode ist für die Textinjektion am tragfähigsten?

### Relevanz
Sehr hoch

### Warum offen
Der Produktkern hängt direkt daran.

### Zu klären
- welche Methode unter macOS technisch praktikabel ist
- welche Zielanwendungen zuverlässig unterstützt werden
- welche Grenzen dokumentiert werden müssen

### Entscheidungskriterium
Robustheit vor Eleganz.

---

## Offene Frage 004: Welche Minimal-UI braucht der MVP tatsächlich?

### Relevanz
Mittel bis hoch

### Warum offen
Ein reiner Hintergrundprozess ohne verständliche Zustände kann zu wenig sein.  
Eine zu grosse UI wäre aber Overhead.

### Zu klären
- braucht es ein Menüleisten-Element
- braucht es ein minimales Einstellungsfenster
- welche Statusanzeige ist nötig, welche nur nice-to-have

### Arbeitshypothese
Eine sehr kleine, funktionale UI ist wahrscheinlich sinnvoller als gar keine sichtbare Oberfläche.

---

## Offene Frage 005: Wie sollen Modelle lokal bereitgestellt werden?

### Relevanz
Mittel

### Warum offen
Offline-Fähigkeit ist gesetzt, aber Packaging und Update-Pfad noch nicht.

### Zu klären
- Modell direkt im Bundle
- Modell als lokale Ressource ausserhalb des Bundles
- Erststart-Handling
- Auswirkungen auf App-Grösse und Updates

---

## 5. Annahmen

## Annahme 001
Ein enger Push-to-talk-Ablauf ist für den ersten Release wertvoller als freies kontinuierliches Diktieren.

### Status
Plausibel, aber noch zu verifizieren

### Begründung
Das reduziert Interaktionskomplexität und erleichtert die erste Systemintegration.

---

## Annahme 002
Die grössten MVP-Risiken liegen im macOS-App-Layer, nicht in der reinen Wahl der Whisper-basierten Inferenz.

### Status
Plausibel

### Begründung
Hotkey, Permissions und Textinjektion sind direkt produktkritisch.

---

## Annahme 003
Ein kleines, klares Statusmodell verbessert die Nutzbarkeit deutlich, ohne den MVP unnötig aufzublähen.

### Status
Plausibel

### Begründung
Ohne Statusfeedback wirken Aufnahme- und Transkriptionsphasen schnell unklar.

---

## 6. Prüfmatrix

## Kurzfristig zuerst zu prüfen
1. Machbarkeit und Robustheit der Textinjektion
2. notwendige macOS-Berechtigungen
3. verlässlicher globaler Hotkey
4. sinnvolle Standard-Modellwahl
5. minimales Status- und Fehlerkonzept

## Später im MVP zu verfeinern
1. Modell-Packaging
2. Standard-Hotkey-Optimierung
3. Feinschliff der UI
4. dokumentierte App-Kompatibilitätsgrenzen

---

## 7. Entscheidungslogik für offene Punkte

Offene Punkte werden nicht nach technischer Eleganz priorisiert, sondern nach dieser Reihenfolge:

1. Gefährdet der Punkt den Kernnutzen?
2. Blockiert der Punkt den MVP?
3. Erhöht der Punkt Stabilität oder nur Komfort?
4. Ist der Punkt jetzt entscheidungsreif oder erst nach erstem Testlauf?

Diese Reihenfolge ist verbindlich, um Scope Creep und Scheingenauigkeit zu vermeiden.

---

## 8. Nicht Teil dieses Dokuments

Dieses Dokument legt nicht fest:

- konkrete Architekturmodule
- konkrete Code-Struktur
- genaue UI-Gestaltung
- konkrete Testfälle
- Implementierungsaufträge für Codex

Diese Themen gehören in andere Dokumente.

---

## 9. Änderungsregel

Dieses Dokument wird angepasst, wenn:

- ein Risiko verifiziert oder entschärft wurde
- eine offene Frage entschieden wurde
- eine Annahme widerlegt wurde
- ein neuer MVP-kritischer Unsicherheitsbereich sichtbar wird

Erledigte Punkte sollen nicht gelöscht, sondern als entschieden oder entschärft markiert werden, damit die Entscheidungsentwicklung nachvollziehbar bleibt.