# Auftrag 003: Berechtigungs- und Erststartfluss für PushWrite auf macOS vor der Mikrofonstufe präzisieren

## Ziel

Erstelle eine präzise Entscheidungs- und Strukturierungsgrundlage für den minimal nötigen Berechtigungs- und Erststartfluss von PushWrite auf macOS, bezogen auf den aktuellen Produktstand vor der Mikrofonintegration.

Der Auftrag dient nicht dazu, den vollständigen First-Run-Flow oder alle Permission-Dialoge bereits umzusetzen.  
Er dient dazu, für den MVP klar festzulegen:

- welche systemseitigen Berechtigungen oder Zugriffe im aktuellen Produktstand tatsächlich nötig sind
- welche davon den Kernworkflow direkt blockieren
- in welcher Reihenfolge Accessibility, Mikrofon und weitere relevante Zugriffe im Produktfluss behandelt werden sollten
- wie viel Start-, Blockade- und Fehlerführung der MVP minimal braucht, um benutzbar und ehrlich zu sein

Das Ergebnis soll so konkret sein, dass daraus direkt ein kleiner Implementierungsauftrag für den ersten belastbaren Permission-/First-Run-Flow vor der Mikrofonstufe abgeleitet werden kann.

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

Der aktuelle Produktstand ist weiter als bei der ursprünglichen Formulierung dieses Auftrags:

- ein reales Stable-Produktbundle existiert
- der Hotkey-/Flow-/Insert-Kern ist produktnah aufgebaut
- der paste-basierte Insert-Pfad ist im Produktkontext bereits gehärtet
- Accessibility ist für den Insert-Pfad praktisch relevant und kein rein theoretisches Thema mehr
- der nächste technische Schritt ist die Mikrofonintegration

Genau deshalb wird jetzt ein enger, produktbezogener Berechtigungs- und Erststartfluss benötigt.

### Verbindliche Rahmenbedingungen

- Zielplattform ist ausschliesslich macOS
- Fokus ist ausschliesslich Version 0.1.0
- betrachtet wird nur der MVP-Scope
- Standardpfad ist lokaler, offline-fähiger Betrieb
- `whisper.cpp` bleibt gesetzte Inferenz-Richtung für spätere lokale Transkription
- Inferenz-Layer und macOS-App-Layer sind getrennt zu betrachten
- keine Datei-Transkription
- keine Multiplattform-Betrachtung
- keine umfangreiche UI- oder Onboarding-Ausarbeitung
- Ziel ist ein minimaler, robuster und verständlicher Startfluss
- keine erneute Grundsatzanalyse des Insert-Pfads
- keine erneute Grundsatzanalyse des Hotkey-Kerns

---

## Zweck dieses Auftrags

Dieser Auftrag soll klären:

- welche macOS-Berechtigungen oder systemnahen Zugriffe im aktuellen PushWrite-Produktstand tatsächlich erforderlich sind
- welche davon für Accessibility/Insert bereits praktisch gesetzt sind
- welche davon für die nächste Stufe mit Mikrofonaufnahme zwingend hinzukommen
- welche Rechte vermutlich optional, nachgelagert oder kontextabhängig sind
- wie der Erststartfluss so geschnitten werden kann, dass der Nutzer nicht unnötig blockiert wird, aber der Kernworkflow trotzdem ehrlich abgesichert bleibt
- wie Blockadezustände minimal verständlich und produktnah gemacht werden sollen

---

## Konkreter Auftrag

Analysiere den minimal nötigen Berechtigungs- und Erststartfluss für PushWrite auf macOS auf Basis des aktuellen Produktstands und liefere eine strukturierte Entscheidungsgrundlage für den MVP vor der Mikrofonstufe.

Die Analyse soll sich nicht in allgemeiner macOS-Theorie verlieren, sondern direkt auf diesen Produktfall bezogen sein:

**Stable-Bundle, bestehender Hotkey-/Flow-/Insert-Kern, Accessibility als bereits praktisch relevanter Faktor, Mikrofon als nächster Integrationsschritt**

---

## Erwartetes Ergebnis

Liefere ein strukturiertes Dokument mit den folgenden Abschnitten:

### 1. Problemdefinition
Beschreibe, warum Berechtigungen und Erststartfluss für PushWrite in der aktuellen Projektphase produktkritisch sind.

Zu klären ist insbesondere:

- welche Teile des Kernworkflows durch fehlende Rechte blockiert werden können
- warum ein rein technischer Permission-Blick nicht genügt
- warum der Erststartfluss für Vertrauen, Benutzbarkeit und Fehlersicherheit relevant ist
- warum der Permission-Fluss jetzt vor der Mikrofonstufe präzisiert werden muss

### 2. Relevante Berechtigungen und Zugriffe
Benenne die realistisch relevanten macOS-Berechtigungen oder Systemzugriffe für den MVP im aktuellen Produktstand.

Für jeden Punkt soll beschrieben werden:

- wofür er im Produktkontext gebraucht wird
- ob er sicher erforderlich, plausibel erforderlich oder noch unklar ist
- welche Produktfunktion davon betroffen ist
- was passiert, wenn dieser Zugriff fehlt

Dabei soll ausdrücklich berücksichtigt werden:

- Accessibility bzw. systemnahe Rechte für den bestehenden Insert-Pfad
- Mikrofonberechtigung für die nächste Integrationsstufe
- Hotkey-bezogene Systemabhängigkeiten nur soweit sie den Start- und Blockadefluss beeinflussen

### 3. Bewertung nach Kritikalität
Ordne die Berechtigungen oder Zugriffe nach MVP-Relevanz.

Zum Beispiel:

- bereits praktisch zwingend für den bestehenden Produktkern
- zwingend vor Mikrofonintegration
- wahrscheinlich nötig, aber noch zu verifizieren
- optional oder nachgelagert

### 4. Empfohlene Reihenfolge im Startfluss
Empfiehl eine sinnvolle Reihenfolge für den Umgang mit fehlenden Rechten.

Zu beantworten ist:

- was sollte vor dem ersten echten Nutzungsversuch geklärt werden
- was kann erst bei Bedarf auftauchen
- in welcher Reihenfolge sollten Accessibility und Mikrofon im Produktfluss behandelt werden
- welche Reihenfolge minimiert Friktion und Verwirrung
- welche Reihenfolge schützt den Kernworkflow am besten

### 5. Fehler- und Blockadezustände
Beschreibe die wichtigsten problematischen Zustände auf MVP-Niveau im aktuellen Produktstand.

Mindestens relevant sind:

- Accessibility fehlt
- Mikrofonzugriff fehlt
- kein Mikrofon oder Gerätefehler
- Hotkey oder zugehöriger Zugriff ist nicht nutzbar
- Nutzer versteht nicht, warum der Workflow blockiert ist

Für jeden Zustand soll beschrieben werden:

- woran der Zustand erkannt werden kann
- welche Produktauswirkung er hat
- welche minimale Rückmeldung der MVP geben sollte

### 6. MVP-Empfehlung für den Erststart
Gib eine klare Empfehlung ab:

- wie minimal der First-Run-Flow vor der Mikrofonstufe sein darf
- welche Permission-Führung der MVP wirklich braucht
- was bewusst noch nicht ausgebaut werden soll
- welche Kompromisse im MVP vertretbar sind
- was vor 002I feststehen sollte und was erst während der Mikrofonintegration konkretisiert werden kann

### 7. Frühe Validierung
Definiere, was früh getestet oder verifiziert werden sollte, bevor grössere Mikrofonintegration sinnvoll ist.

Zum Beispiel:

- welche Rechte tatsächlich zwingend sind
- welche Reihenfolge im Produktfluss am wenigsten problematisch ist
- welche Fehlerfälle unbedingt reproduzierbar getestet werden müssen
- welche Zustände im Produkt bereits jetzt sauber beobachtbar sein sollten

### 8. Vorschlag für Folgeauftrag
Formuliere daraus einen kleinen, konkreten Folgeauftrag für Codex, der entweder:

- einen minimalen Permission-/First-Run-Prototypen vorbereitet
- oder den ersten robusten Startfluss für den MVP eng geschnitten umsetzt

---

## Anforderungen

Das Ergebnis muss:

- ausschliesslich den macOS-MVP betrachten
- nur den aktuellen Produktscope von PushWrite berücksichtigen
- zwischen gesichert, plausibel und offen sauber unterscheiden
- den Permission-Fluss aus Produktsicht und nicht nur aus API-Sicht bewerten
- minimale Benutzbarkeit höher gewichten als Vollständigkeit
- klar benennen, welche Rechte den MVP direkt blockieren
- Accessibility als bereits praktisch relevanten Faktor einordnen
- Mikrofon als nächsten Permission-Schwerpunkt klar verorten
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
- erneute Grundsatzanalyse der Textinjektion
- erneute Grundsatzanalyse des Hotkey-Kerns
- Mikrofonimplementierung selbst

---

## Gewünschte Denklogik

Bitte arbeite nach dieser Priorität:

1. Welche Rechte oder Systemzugriffe blockieren den bestehenden und den unmittelbar nächsten Produktschritt direkt?
2. Welche davon sind sicher nötig und welche nur plausibel?
3. In welcher Reihenfolge sollte der Nutzer durch den Startfluss geführt werden?
4. Welche minimale Rückmeldung braucht der Nutzer, um Blockaden zu verstehen?
5. Welche Teile dürfen im MVP bewusst schlicht bleiben?
6. Was muss vor der Mikrofonstufe feststehen und was nicht?

---

## Form der Antwort

Die Antwort soll:

- klar gegliedert sein
- den aktuellen Produktkontext ernst nehmen
- nicht in allgemeine macOS-Erklärungen ausweichen
- konkrete Berechtigungs- und Blockadepunkte benennen
- Accessibility und Mikrofon klar getrennt, aber zusammenhängend einordnen
- am Ende eine klare MVP-Empfehlung geben
- einen kleinen Folgeauftrag enthalten, der direkt weiterverwendet werden kann

---

## Akzeptanzkriterien

Der Auftrag ist erfüllt, wenn:

- die relevanten Berechtigungen oder Systemzugriffe für PushWrite im aktuellen Produktstand identifiziert wurden
- ihre Kritikalität für den MVP nachvollziehbar eingeordnet wurde
- eine sinnvolle Reihenfolge für den Erststart- und Permission-Fluss vorgeschlagen wurde
- die wichtigsten Fehler- und Blockadezustände benannt wurden
- eine klare MVP-Empfehlung vor der Mikrofonstufe ausgesprochen wurde
- ein kleiner, direkt anschlussfähiger Folgeauftrag formuliert wurde