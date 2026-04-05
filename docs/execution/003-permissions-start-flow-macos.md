# Auftrag 003: Berechtigungs- und Startfluss auf macOS für PushWrite v0.1.0 strukturieren

## Ziel

Erstelle eine präzise Strukturierungs- und Entscheidungsgrundlage für den minimal nötigen Berechtigungs- und Erststartfluss von PushWrite auf macOS.

Der Auftrag dient nicht dazu, den vollständigen First-Run-Flow oder alle Permission-Dialoge bereits umzusetzen.  
Er dient dazu, für den MVP klar festzulegen:

- welche systemseitigen Berechtigungen oder Zugriffe tatsächlich nötig sind
- an welchen Stellen sie den Kernworkflow blockieren können
- in welcher Reihenfolge sie im Produktfluss behandelt werden sollten
- wie viel Start- und Fehlerführung der MVP minimal braucht, um benutzbar zu sein

Das Ergebnis soll so konkret sein, dass daraus direkt ein kleiner Implementierungsauftrag für den ersten Berechtigungs- oder Erststart-Prototypen abgeleitet werden kann.

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

Für diesen Workflow sind systemnahe Funktionen nötig.  
Wenn dafür erforderliche Rechte fehlen oder der Erststartfluss unklar ist, scheitert der Nutzer schon vor dem eigentlichen Produktnutzen.

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- Standardpfad ist lokaler, offline-fähiger Betrieb
- `whisper.cpp` bleibt gesetzte Inferenz-Richtung
- Inferenz-Layer und macOS-App-Layer sind getrennt zu betrachten
- keine Datei-Transkription
- keine Multiplattform-Betrachtung
- keine umfangreiche UI- oder Onboarding-Ausarbeitung
- Ziel ist ein minimaler, robuster und verständlicher Startfluss

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- welche macOS-Berechtigungen oder systemnahen Zugriffe für PushWrite im MVP tatsächlich erforderlich sind
- welche davon zwingend für Mikrofonaufnahme, Hotkey und Textinjektion relevant sind
- welche Rechte vermutlich optional, nachgelagert oder kontextabhängig sind
- wie der Erststartfluss so geschnitten werden kann, dass er den Nutzer nicht unnötig blockiert, aber den Kernworkflow trotzdem absichert
- wie Fehler- und Blockadezustände minimal verständlich gemacht werden sollen

---

## Konkreter Auftrag

Analysiere den minimal nötigen Berechtigungs- und Erststartfluss für PushWrite auf macOS und liefere eine strukturierte Entscheidungsgrundlage für den MVP.

Die Analyse soll sich nicht in allgemeiner macOS-Theorie verlieren, sondern direkt auf diesen Produktfall bezogen sein:

**globaler Hotkey, Mikrofonaufnahme, lokale Transkription und direkte Texteinfügung an der aktuellen Cursor-Position**

---

## Erwartetes Ergebnis

Liefere ein strukturiertes Dokument mit den folgenden Abschnitten:

### 1. Problemdefinition
Beschreibe, warum Berechtigungen und Erststartfluss für PushWrite produktkritisch sind.

Zu klären ist insbesondere:

- welche Teile des Kernworkflows durch fehlende Rechte blockiert werden können
- warum ein rein technischer Permission-Blick nicht genügt
- warum der Erststartfluss für Vertrauen und Benutzbarkeit relevant ist

### 2. Relevante Berechtigungen und Zugriffe
Benenne die realistisch relevanten macOS-Berechtigungen oder Systemzugriffe für den MVP.

Für jeden Punkt soll beschrieben werden:

- wofür er im Produktkontext gebraucht wird
- ob er sicher erforderlich, plausibel erforderlich oder noch unklar ist
- welche Produktfunktion davon betroffen ist
- was passiert, wenn dieser Zugriff fehlt

### 3. Bewertung nach Kritikalität
Ordne die Berechtigungen oder Zugriffe nach MVP-Relevanz.

Zum Beispiel:

- zwingend für Kernworkflow
- wahrscheinlich nötig, aber noch zu verifizieren
- optional oder nachgelagert

### 4. Empfohlene Reihenfolge im Startfluss
Empfiehl eine sinnvolle Reihenfolge für den Umgang mit fehlenden Rechten.

Zu beantworten ist:

- was sollte vor dem ersten echten Nutzungsversuch geklärt werden
- was kann erst bei Bedarf auftauchen
- welche Reihenfolge minimiert Friktion und Verwirrung
- welche Reihenfolge schützt den Kernworkflow am besten

### 5. Fehler- und Blockadezustände
Beschreibe die wichtigsten problematischen Zustände auf MVP-Niveau.

Zum Beispiel:

- Mikrofonzugriff fehlt
- Textinjektion scheitert wegen fehlender systemnaher Rechte
- Hotkey oder zugehöriger Zugriff ist nicht nutzbar
- Nutzer versteht nicht, warum der Workflow blockiert ist

Für jeden Zustand soll beschrieben werden:

- woran der Zustand erkannt werden kann
- welche Produktauswirkung er hat
- welche minimale Rückmeldung der MVP geben sollte

### 6. MVP-Empfehlung für den Erststart
Gib eine klare Empfehlung ab:

- wie minimal der First-Run-Flow sein darf
- welche Permission-Führung der MVP wirklich braucht
- was bewusst noch nicht ausgebaut werden soll
- welche Kompromisse im MVP vertretbar sind

### 7. Frühe Validierung
Definiere, was früh getestet oder verifiziert werden sollte, bevor grössere Implementierung sinnvoll ist.

Zum Beispiel:

- welche Rechte tatsächlich zwingend sind
- welche Reihenfolge im Produktfluss am wenigsten problematisch ist
- welche Fehlerfälle unbedingt reproduzierbar getestet werden müssen

### 8. Vorschlag für Folgeauftrag
Formuliere daraus einen kleinen, konkreten Folgeauftrag für Codex, der entweder:

- einen minimalen Permission-Prototypen vorbereitet
- oder den ersten robusten Startfluss für den MVP eng geschnitten umsetzt

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- nur den aktuellen Produktscope von PushWrite berücksichtigen
- zwischen gesichert, plausibel und offen sauber unterscheiden
- den Permission-Fluss aus Produktsicht und nicht nur aus API-Sicht bewerten
- minimale Benutzbarkeit höher gewichten als Vollständigkeit
- klar benennen, welche Rechte den MVP direkt blockieren können
- eine konkrete Empfehlung für einen kleinen, kontrollierbaren Erststartfluss geben

Wenn Aussagen unsicher sind, müssen sie als Annahme oder offene Frage markiert werden.

---

## Nicht-Ziele

Nicht Teil dieses Auftrags sind:

- vollständige Implementierung des First-Run-UI
- detailliertes Design von Onboarding-Screens
- allgemeine Systemeinstellungen ausserhalb des MVP-Bedarfs
- Ausarbeitung von Komfortfunktionen
- Multiplattform-Betrachtung
- allgemeine Datenschutz- oder Telemetriearchitektur
- Datei- oder Batch-Workflows
- tiefe UX-Optimierung jenseits des Kernnutzens

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Welche Rechte oder Systemzugriffe blockieren den MVP direkt?
2. Welche davon sind sicher nötig und welche nur plausibel?
3. In welcher Reihenfolge sollte der Nutzer durch den Startfluss geführt werden?
4. Welche minimale Rückmeldung braucht der Nutzer, um Blockaden zu verstehen?
5. Welche Teile dürfen im MVP bewusst schlicht bleiben?

---

## Form der Antwort

Die Antwort soll:

- klar gegliedert sein
- den Produktkontext ernst nehmen
- nicht in allgemeine macOS-Erklärungen ausweichen
- konkrete Berechtigungs- und Blockadepunkte benennen
- am Ende eine klare MVP-Empfehlung geben
- einen kleinen Folgeauftrag enthalten, der direkt weiterverwendet werden kann

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- die relevanten Berechtigungen oder Systemzugriffe für PushWrite identifiziert wurden
- ihre Kritikalität für den MVP nachvollziehbar eingeordnet wurde
- eine sinnvolle Reihenfolge für den Erststart- und Permission-Fluss vorgeschlagen wurde
- die wichtigsten Fehler- und Blockadezustände benannt wurden
- eine klare MVP-Empfehlung ausgesprochen wurde
- ein kleiner, direkt anschlussfähiger Folgeauftrag formuliert wurde