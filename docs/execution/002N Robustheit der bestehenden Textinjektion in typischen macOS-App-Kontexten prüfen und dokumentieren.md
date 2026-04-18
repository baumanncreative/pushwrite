# Auftrag 002N: Robustheit der bestehenden Textinjektion in typischen macOS-App-Kontexten prüfen und dokumentieren

## Ziel

Prüfe, wie verlässlich der bestehende Insert-Pfad von PushWrite.app in typischen macOS-App-Kontexten funktioniert, ohne den aktuellen Insert-Mechanismus zu verändern.

Der Auftrag dient nicht dazu, neue Insert-Methoden, neue Accessibility-Strategien oder breite Kompatibilitätsarchitektur einzuführen.  
Er dient dazu, nach dem technisch geschlossenen MVP-Kern die zentrale verbleibende Stabilitätsfrage zu klären:

- in welchen typischen Zielkontexten der bestehende Insert-Pfad bereits stabil genug funktioniert
- wo erkennbare Grenzen oder Fehlermuster auftreten
- ob für den MVP vorerst Dokumentation der Grenzen reicht oder ob später wirklich Codeänderung nötig wird

Das Ergebnis soll so konkret sein, dass daraus direkt eine klare MVP-Einschätzung zur App-Kompatibilität entsteht.

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

Nach den bisherigen Schritten gilt:

- der Hotkey-/Recording-/Transcribing-/Insert-Kern ist vorhanden
- lokale `whisper.cpp`-Inferenz ist eingebunden
- der End-to-End-Pfad bis zum Cursor-Insert ist produktnah beobachtet
- Gate-Fälle für `empty|tooShort` sind produktnah gehärtet
- der bestehende Insert-Pfad basiert auf dem bereits gesetzten produktiven Route-Wert `pasteboardCommandV`

Der nächste sinnvolle Stabilitätsschritt ist deshalb nicht neue Kernlogik, sondern die gezielte Prüfung der bestehenden Textinjektion in typischen Zielanwendungen.

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- `PushWrite.app` im Stable-Pfad ist das relevante Bundle
- der bestehende Insert-Pfad bleibt unverändert
- der bestehende Hotkey-/Recording-/Transcribing-Kern bleibt unverändert
- es werden keine neuen Insert-Methoden eingeführt
- es werden keine UI-Änderungen eingeführt
- es wird keine breite App-Kompatibilitätsarchitektur gebaut
- Ziel ist eine belastbare Kompatibilitäts- und Stabilitätseinschätzung

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- ob der bestehende Insert-Pfad für den MVP in typischen macOS-App-Kontexten bereits ausreichend robust ist
- welche Unterschiede zwischen nativen Textfeldern, Web-Textfeldern und mindestens einer typischen Drittanbieter-App auftreten
- welche Fehlermuster erkennbar sind
- ob für den MVP vorerst Dokumentation der Grenzen genügt oder ob ein späterer technischer Nachschnitt nötig wird

---

## Konkreter Auftrag

Prüfe den bestehenden Insert-Pfad produktnah in wenigen, bewusst gewählten App-Kontexten und dokumentiere die Ergebnisse.

Der Auftrag soll mindestens diese Teile enthalten:

1. den bestehenden Insert-Pfad im aktuellen Produktstand kurz verorten
2. produktnahe Revalidierung in genau diesen Zielkontexten durchführen:
   - TextEdit als native Baseline
   - Safari-Textarea als Web-Baseline
   - genau eine typische Drittanbieter-App, bevorzugt Slack oder Notion, je nachdem was lokal verfügbar und sinnvoll testbar ist
3. für jeden Kontext denselben kurzen, kontrollierten PushWrite-End-to-End-Lauf prüfen
4. Auffälligkeiten, Fehlermuster und Grenzen dokumentieren
5. klar bewerten, ob für den MVP vorerst Dokumentation reicht oder ob später ein neuer technischer Auftrag nötig wird

---

## Erwartetes Ergebnis

Liefere:

### 1. Kurze Einordnung des bestehenden Insert-Pfads
Beschreibe knapp:

- welcher Insert-Pfad aktuell genutzt wird
- dass dieser Auftrag diesen Pfad nur prüft und nicht verändert
- warum gerade die App-Kompatibilität jetzt der relevante Stabilitätsschritt ist

### 2. Produktnahe Revalidierung in drei Kontexten
Prüfe mindestens:

- **TextEdit** als native Baseline
- **Safari-Textarea** als Web-Baseline
- **eine** Drittanbieter-App als Fremd-Baseline

Für jeden Kontext soll festgehalten werden:

- ob der Text korrekt eingefügt wurde
- ob der Fokus korrekt erhalten blieb
- ob Auffälligkeiten oder Reibung sichtbar wurden
- ob der Lauf als stabil genug für den MVP einzustufen ist

### 3. Vergleich der Kontexte
Arbeite die Unterschiede klar heraus:

- native Texteingabe
- Browser-Textfeld
- Drittanbieter-App

Nicht im Sinne einer Vollmatrix, sondern als pragmatische MVP-Einordnung.

### 4. Fehlermuster und Grenzen
Dokumentiere mindestens:

- erkennbare gemeinsame Fehlerbilder
- app-spezifische Auffälligkeiten
- Fälle, in denen Dokumentation der Grenze wahrscheinlich genügt
- Fälle, in denen später wirklich technischer Handlungsbedarf entsteht

### 5. MVP-Einordnung
Bewerte am Ende klar:

- bestehender Insert-Pfad für typische App-Kontexte ausreichend robust
- im Wesentlichen tragfähig, aber mit klar dokumentierten Grenzen
- noch nicht robust genug für die MVP-Festlegung

### 6. Konkrete Folgeempfehlung
Formuliere daraus genau einen kleinen Folgeauftrag.

Wenn die Ergebnisse gut genug sind, kann der Folgeauftrag auch rein dokumentarisch sein.  
Wenn die Ergebnisse zu schwach sind, soll der Folgeauftrag einen kleinen technischen Nachschnitt vorbereiten.

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- auf dem bestehenden Stable-Produktpfad aufbauen
- den bestehenden Insert-Pfad unverändert lassen
- nur wenige, bewusst gewählte Zielkontexte prüfen
- Beobachtung, Interpretation und Empfehlung sauber trennen
- klar zwischen gesichert, plausibel und offen unterscheiden
- bewusst klein und risikoorientiert bleiben

Wenn Unsicherheiten bleiben, müssen sie als offene Punkte markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- neue Insert-Methode
- Änderung an `insertTranscription(...)`
- Änderung an `performInsert(...)`
- Änderung an `pasteboardCommandV`
- neue Accessibility- oder Event-Tap-Strategie
- breite Kompatibilitätsmatrix über viele Apps
- UI-Änderungen
- Multiplattform-Betrachtung
- allgemeine Zukunftsarchitektur

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Reicht der bestehende Insert-Pfad in typischen App-Kontexten für den MVP praktisch aus?
2. Wo liegen erkennbare Grenzen?
3. Reicht Dokumentation dieser Grenzen vorerst aus?
4. Nur falls nein: welcher kleinste technische Nachschnitt wäre später nötig?
5. Welche gesicherten Kompatibilitätsaussagen kann PushWrite nach diesem Schritt bereits machen?

---

## Form der Antwort

Die Antwort soll enthalten:

- kurze Zusammenfassung
- erstellte oder geänderte Artefakte
- Ergebnisse je Zielkontext
- gesichert beobachtet
- plausible Schlussfolgerung
- noch offen
- Ausführung / Testen
- MVP-Einordnung
- konkreten Folgeauftrag
- Rollback

Keine allgemeine Plattformdiskussion.  
Keine sofortige Erweiterung des Insert-Codes.  
Keine breite App-Kompatibilitätsstrategie.

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- der bestehende Insert-Pfad in TextEdit geprüft wurde
- der bestehende Insert-Pfad in Safari-Textarea geprüft wurde
- der bestehende Insert-Pfad in genau einer typischen Drittanbieter-App geprüft wurde
- die Ergebnisse pro Kontext klar dokumentiert sind
- eine klare MVP-Einordnung zur App-Kompatibilität vorliegt
- nachvollziehbar entschieden wurde, ob vorerst Dokumentation reicht oder ein technischer Folgeauftrag nötig ist
- gesichert, plausibel und offen sauber getrennt dokumentiert sind