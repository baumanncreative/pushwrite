# Auftrag für Codex 006: Minimale Hotkey-Rueckmeldung fuer Gate- und Fehlerfaelle

## Ziel

Ergaenze den bestehenden 005-Hotkey-Pfad um eine **minimale, ehrliche, lokale Nutzer-Rueckmeldung** fuer Faelle, in denen **kein Text eingefuegt wurde** oder der Insert-Versuch **fehlschlaegt**.

Der Auftrag dient dazu, die verbleibende Produktluecke nach 005 zu schliessen:

- Hotkey-Aufnahme bleibt wie bisher
- lokale whisper.cpp-Transkription bleibt wie bisher
- kontrollierter Insert-Pfad bleibt wie bisher
- bei Gate- und Fehlerfaellen bleibt der Ablauf nicht mehr still
- der Nutzer erhaelt eine kleine, ehrliche Rueckmeldung, warum nichts eingefuegt wurde oder warum der Insert fehlgeschlagen ist

Dieser Auftrag dient **nicht** dazu, neue grosse UI-Flaechen, neue Diktiermodi, neue Accessibility-Strategien oder Editierlogik einzufuehren.

---

## Ausgangslage

Der Stand aus 005 ist:

- der Produktfluss ist technisch geschlossen:
  - `Hotkey -> Aufnahme -> Handoff -> lokale Transkription -> InsertGate -> InsertAttempt`
- Gate-, Erfolgs- und Fehlerfaelle sind technisch beobachtbar und persistiert
- bei `passed` wird ueber den bestehenden Produktpfad eingefuegt
- Gate-Faelle und Insert-Fehler enden kontrolliert
- bei Gate-Faellen wird derzeit **kein zusaetzliches UX-Feedback** erzwungen

Genau diese stille Restluecke soll 006 schliessen.

---

## Verbindliche Produktentscheidung fuer diesen Auftrag

Fuer 006 gilt verbindlich:

- Zielplattform bleibt **nur macOS**
- Fokus bleibt **nur MVP 0.1.0**
- Hotkey-Modell bleibt **press-and-hold**
- der bestehende 005-Produktpfad bleibt erhalten
- es wird **kein neuer Insert-Stack** gebaut
- es wird **keine neue Accessibility-Architektur** gebaut
- es wird **keine neue grosse UI-Flaeche** gebaut
- Rueckmeldung soll **nur minimal und lokal** sein
- ein erfolgreicher Insert bleibt **stumm**
- Rueckmeldung ist nur fuer **no-insert** oder **insert-failed** relevant

---

## Problemrahmen

Nach 005 ist das technische Verhalten sauber, aber die Produktsicht ist noch unvollstaendig:

- Gate-Faelle sind intern sichtbar, fuer den Nutzer aber zu still
- ein Insert-Fehler ist intern sichtbar, fuer den Nutzer aber zu still oder zu technisch
- der Nutzer braucht eine kleine, ehrliche Antwort auf die Produktfrage:
  - **Warum wurde gerade nichts eingefuegt?**

006 soll diesen Produktrest schliessen, ohne den bisherigen engen Kernfluss aufzublasen.

---

## Umsetzungsziel

Implementiere eine minimale lokale Rueckmeldung fuer genau diese Endlagen:

1. **kein Insert wegen Gate**
2. **Insert-Versuch fehlgeschlagen**

Die Rueckmeldung soll:

- klein sein
- lokal sein
- einmalig pro Flow sein
- ehrliche Produktsprache verwenden
- nicht technisch ueberladen sein
- keine neue grosse UI-Struktur einziehen

---

## Verbindlicher Scope

### In Scope

- bestehende Gate- und Fehlerfaelle des 005-Pfads nutzen
- minimale lokale Nutzer-Rueckmeldung fuer no-insert und insert-failed ausgeben
- bestehenden lokalen Response-/Dialog-/Feedback-Pfad bevorzugt wiederverwenden
- bestehende Beobachtbarkeit sinnvoll erweitern
- bestehende Response-Artefakte bevorzugt weiterverwenden
- persistierte Results-Datei im Repo anlegen oder aktualisieren
- gueltige Produktpruefung nur ueber Stable-Bundle-/LaunchServices-Pfad dokumentieren

### Nicht in Scope

- neue Haupt-UI
- neue Menubar-Oberflaechen
- neue umfangreiche Dialoglandschaft
- neue Accessibility-Strategie
- neue Rechte-Dialog-Strategie
- Toggle/VAD/Continuous Dictation
- Editier- oder Nachbearbeitungslogik
- Multiplattform-Erweiterung
- neue Retry-Mechanik
- neue Architektur fuer spaetere Produktstufen

---

## Verbindliche Rueckmeldefaelle

Mindestens diese Faelle muessen eine lokale Rueckmeldung ausloesen:

### Gate-Faelle
- `transcriptionSkipped`
- `transcriptionFailed`
- `emptyTranscriptionText`
- `whitespaceOnlyTranscriptionText`

### Fehlerfall
- `insertFailed`

Ein erfolgreicher Insert (`status=succeeded`) soll in diesem Auftrag **keine zusaetzliche Rueckmeldung** ausloesen.
Der eingefuegte Text selbst ist dort die Nutzerbestaetigung.

---

## Verbindliche Rueckmeldungslogik

Die Rueckmeldung muss diese Regeln einhalten:

1. **genau einmal pro Flow**
2. **nur am Endpunkt des Flows**
3. **keine Dopplungen** zwischen Gate, Fehler und Abschluss
4. **keine technische Entwickler-Sprache**
5. **keine irrefuehrende Erfolgsbotschaft**
6. **kein Feedback bei erfolgreichem Insert**
7. **kein haengender UI-Zustand**

---

## Inhaltliche Leitlinie fuer die Rueckmeldung

Die Formulierung soll klein und ehrlich sein.

Die Rueckmeldung muss sinngemaess vermitteln:

- **Kein Text eingefuegt. Aufnahme zu kurz.**
- **Kein Text eingefuegt. Transkription fehlgeschlagen.**
- **Kein Text eingefuegt. Kein brauchbarer Text erkannt.**
- **Text konnte nicht eingefuegt werden.**

Die exakte Formulierung darf leicht abweichen, aber sie muss:

- kurz sein
- produkthaft sein
- ehrlich sein
- ohne interne Begriffe wie `gate`, `flow`, `CDHash`, `processing` oder Dateipfade auskommen

---

## Wiederverwendung bestehender Rueckmeldungslogik

Bitte baue **keinen neuen parallelen Feedback-Mechanismus**, wenn im Projekt bereits ein passender kleiner lokaler Response-/Dialog-Pfad existiert.

Anforderung:

- zuerst vorhandene Hotkey-Response-/Produkt-Response-Mechanik pruefen
- wenn moeglich: bestehenden Pfad eng wiederverwenden
- nur wenn technisch wirklich noetig: minimalen Glue-Code bauen

Nicht gewuenscht:

- zweite konkurrierende Feedback-Implementierung
- neue grosse Toast-/Notification-/Panel-Architektur
- breite UI-Abstraktion fuer spaetere Plattformen

Bitte in der Results-Datei klar dokumentieren, **welcher** lokale Feedback-Pfad konkret verwendet wurde.

---

## Bestehende Response-Artefakte bevorzugen

Falls bereits Response-Artefakte wie z. B. die Hotkey-Response-Logs existieren, sollen diese **bevorzugt erweitert oder wiederverwendet** werden.

Bitte **keine neue parallele Artefaktfamilie** einfuehren, wenn die bestehenden Logs denselben Zweck bereits tragen koennen.

Ziel:
- eine konsistente Produktbeobachtbarkeit
- keine doppelte Semantik
- kein Log-Wildwuchs

Falls doch ein neues Artefakt technisch zwingend noetig ist, kurz begruenden.

---

## Erwartete semantische Faelle

Bitte schneide die Rueckmeldungssemantik mindestens in diese Produktfaelle:

- `tooShortRecording`
- `transcriptionFailed`
- `noUsableText`
- `insertFailed`

Dabei darf `emptyTranscriptionText` und `whitespaceOnlyTranscriptionText` intern getrennt bleiben, aber produktseitig koennen sie unter einem gemeinsamen no-usable-text-Fall zusammengefasst werden, wenn das den Nutzertext klarer macht.

Wichtig ist:
- intern sauber
- nach aussen klein und ehrlich

---

## Beobachtbarkeit

Erweitere die bestehende Beobachtbarkeit nur so weit, wie fuer 006 noetig.

Mindestens nachvollziehbar sein sollen:

- Feedback-Fall ausgewertet
- Feedback lokal ausgeloest
- welcher Produkttyp von Rueckmeldung gesendet wurde
- keine Rueckmeldung im Erfolgsfall
- kontrollierter Flow-Abschluss bleibt erhalten

Wenn passende bestehende Event-Namen existieren, diese bevorzugen.
Neue Event-Namen bitte kurz und klar halten.

---

## Fehler- und Randfaelle

Mindestens diese Faelle muessen behandelt werden:

### 1. Gate-Fall `transcriptionSkipped`
Erwartung:
- kein Insert
- lokale Rueckmeldung
- kontrollierter Abschluss

### 2. Gate-Fall `transcriptionFailed`
Erwartung:
- kein Insert
- lokale Rueckmeldung
- kontrollierter Abschluss

### 3. Gate-Fall `emptyTranscriptionText`
Erwartung:
- kein Insert
- lokale Rueckmeldung
- kontrollierter Abschluss

### 4. Gate-Fall `whitespaceOnlyTranscriptionText`
Erwartung:
- kein Insert
- lokale Rueckmeldung
- kontrollierter Abschluss

### 5. Insert-Fehler nach `passed`
Erwartung:
- lokale Rueckmeldung
- Fehler bleibt beobachtbar
- kein Haengenbleiben in `processing`

### 6. Erfolgreicher Insert
Erwartung:
- **keine** zusaetzliche Rueckmeldung
- keine Regression im Erfolgsfall

### 7. Mehrfache Ausloesung derselben Rueckmeldung
Erwartung:
- aktiv verhindern
- genau eine Rueckmeldung pro Flow

---

## QA- und Testdisziplin

Dieser Auftrag soll die bekannte Accessibility-Trust-Drift **nicht** neu loesen.

Fuer die Bewertung von produktnahen Erfolgsfaellen gilt weiterhin:

- belastbare Accessibility-/Insert-Befunde nur ueber **Stable-Bundle + LaunchServices + dokumentierten CDHash**
- Direct-/Control-Starts nur als Nebenbeobachtung
- keine neue Diagnose- oder Reparaturlogik fuer Rechte-Themen bauen

Bitte in den Testhinweisen und in der Results-Datei klar trennen zwischen:

- **produktnah gueltiger Stable-Bundle-Pruefung**
- **sekundaeren Direktstarts zu Debug-Zwecken**

---

## Technische Leitplanken

- bestehende Projektstruktur respektieren
- keine breite Neustrukturierung
- bestehenden 005-Pfad beibehalten
- bestehende Insert- und Response-Mechanik bevorzugt wiederverwenden
- keine neue Parallel-Implementierung
- kleine Eingriffsflaeche im Code bevorzugen
- keine hypothetische Zukunftsarchitektur

---

## Akzeptanzkriterien

Der Auftrag ist erfuellt, wenn Folgendes belegbar ist:

1. Gate-Faelle loesen eine minimale lokale Nutzer-Rueckmeldung aus.
2. Ein Insert-Fehler loest eine minimale lokale Nutzer-Rueckmeldung aus.
3. Ein erfolgreicher Insert loest **keine** zusaetzliche Rueckmeldung aus.
4. Pro Flow wird hoechstens **eine** Rueckmeldung lokal ausgespielt.
5. Die Rueckmeldung verwendet ehrliche, kurze Produktsprache.
6. Es wird kein neuer grosser UI- oder Feedback-Stack gebaut.
7. Die bestehende Produktbeobachtbarkeit bleibt konsistent oder wird klein erweitert.
8. Der Ablauf bleibt kontrolliert und haengt nicht im `processing`-Pfad.
9. Die Results-Datei dokumentiert klar, welcher Feedback-Pfad verwendet wurde.
10. Die Testbewertung trennt gueltige Stable-Bundle-Pruefung von sekundaeren Debug-Starts.

---

## Testhinweise, die Codex liefern soll

Bitte liefere am Ende:

1. wie 006 gebaut und gestartet wird
2. wie ein Gate-Fall lokal geprueft wird
3. wie ein Insert-Fehlerfall lokal geprueft wird
4. wie nachgewiesen wird, dass der Erfolgsfall stumm bleibt
5. welche Runtime-Artefakte oder bestehenden Response-Artefakte den Fall zeigen
6. wie der gueltige Stable-Bundle-/LaunchServices-Testpfad dokumentiert wurde
7. welcher CDHash fuer den gueltigen Bundle-Test dokumentiert wurde

---

## Persistierte Repo-Dokumentation ist Pflicht

Lege oder aktualisiere zusaetzlich eine Results-Datei im Repo unter genau diesem Pfad:

`docs/execution/006-results-minimal-hotkey-feedback-for-gated-and-failed-paths.md`

Diese Datei muss den **tatsaechlich umgesetzten Stand** dokumentieren, nicht nur den Auftrag wiederholen.

Mindestens enthalten:

- Status
- Kurzfassung
- geaenderte Dateien
- verwendeter Feedback-Pfad / Response-Pfad
- abgedeckte Rueckmeldungsfaelle
- Beobachtbarkeit
- QA-Abgrenzung Stable-Bundle vs. Debug-Start
- dokumentierter CDHash fuer den gueltigen Bundle-Test
- nicht umgesetzt
- bekannte Risiken / Annahmen
- Testhinweise
- Rollback

---

## Ausgabe von Codex

Bitte liefere am Ende:

1. den exakten Pfad der Auftragsumsetzung
2. den exakten Pfad der Results-Datei
3. die Liste aller real geaenderten Dateien
4. eine kurze Beschreibung, welcher lokale Feedback-Pfad verwendet wurde
5. eine kurze Beschreibung, welche Rueckmeldungsfaelle konkret umgesetzt wurden
6. eine kurze Beschreibung, wie Mehrfachausloesungen verhindert wurden
7. eine kurze Beschreibung, wie der gueltige Stable-Bundle-Test dokumentiert wurde

---

## Prioritaet bei Zielkonflikten

Wenn waehrend der Umsetzung Zielkonflikte auftreten, gilt diese Prioritaet:

1. ehrliche minimale Rueckmeldung bei no-insert und insert-failed
2. kein neuer grosser UI-/Feedback-Stack
3. genau eine Rueckmeldung pro Flow
4. gueltige Produktpruefung nur ueber Stable-Bundle-/LaunchServices-Pfad
5. kleine Eingriffsflaeche im Code