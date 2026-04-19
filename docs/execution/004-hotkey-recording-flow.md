# 004 Entscheidung: Hotkey- und Aufnahmefluss fuer PushWrite v0.1.0 auf macOS

## Status

Entschieden fuer MVP 0.1.0.

Diese Datei haelt die Produktentscheidung fuer den Hotkey- und Aufnahmefluss fest.
Sie ist keine Implementierungsvorgabe im engeren Sinn, sondern die verbindliche Entscheidungsbasis fuer nachfolgende kleine Umsetzungsauftraege.

Der erste direkt anschlussfaehige Folgeauftrag ist:
`004A-minimal-hotkey-recording-prototype.md`

---

## Ziel

PushWrite soll im MVP auf macOS einen engen, robusten und gut beobachtbaren Kernablauf bieten:

1. Nutzer drueckt einen globalen Hotkey
2. PushWrite startet eine Mikrofonaufnahme
3. Nutzer spricht
4. PushWrite beendet die Aufnahme
5. das Audio wird an die lokale Weiterverarbeitung uebergeben
6. der weitere Produktfluss kann darauf aufbauen

Diese Entscheidung betrifft nur den Abschnitt von Hotkey bis zur sauberen Audio-Uebergabe.

---

## Gesichert

- Fokus ist ausschliesslich macOS
- Fokus ist ausschliesslich MVP 0.1.0
- globaler Hotkey ist Teil des Produktkerns
- Mikrofonaufnahme ist Teil des Produktkerns
- der Ablauf soll lokal und offlinefaehig sein
- `whisper.cpp` bleibt die gesetzte Inferenz-Richtung
- Inferenz-Layer und macOS-App-Layer werden getrennt betrachtet
- Robustheit ist wichtiger als Flexibilitaet
- der erste Aufnahmefluss soll klein und kontrollierbar sein

---

## Problemkern

Der Hotkey und der Aufnahmefluss koennen fuer den MVP nicht getrennt betrachtet werden.

Der Grund ist produktseitig einfach:

- der Hotkey definiert, wann Aufnahme beginnt
- der Hotkey definiert, wann Aufnahme endet
- daraus ergibt sich direkt die Begrenzung des Audiosegments
- genau diese Begrenzung bestimmt, was spaeter an die Transkription uebergeben wird
- wenn dieser Ablauf unscharf ist, wird der Produktkern instabil

Es geht hier nicht primaer um eine allgemeine UI-Frage, sondern um den zentralen Nutzungsmechanismus des Produkts.

---

## Gepruefte Interaktionsmodelle

### Option A: press-and-hold

Grundidee:
- Aufnahme startet beim Druecken des Hotkeys
- Aufnahme laeuft nur waehrend der Hotkey gehalten wird
- Aufnahme endet beim Loslassen

Vorteile:
- klare Start- und Stop-Grenze
- enger Zustandsraum
- weniger Fehlinterpretation im MVP
- geringere Gefahr fuer doppelte oder haengende Start-/Stop-Zyklen
- produktseitig leicht erklaerbar

Schwaechen:
- setzt aktives Halten voraus
- kann fuer laengere Diktate unbequemer sein
- spaetere Komfortwuensche werden nicht abgedeckt

MVP-Risiko:
- gering
- technisch und produktseitig der engere Pfad

### Option B: toggle start/stop

Grundidee:
- erster Hotkey startet Aufnahme
- zweiter Hotkey beendet Aufnahme

Vorteile:
- bequemer fuer laengeres Sprechen
- kein permanentes Halten noetig

Schwaechen:
- groesserer Zustandsraum
- hoehere Gefahr fuer Fehlbedienung
- schwierigeres Recovery bei verpasstem Stop
- mehr Randfaelle im MVP

MVP-Risiko:
- erhoeht
- bringt frueh mehr Logik, als fuer den ersten Kernfluss sinnvoll ist

### Option C: weitere Varianten

Beispiele:
- VAD-gestuetzte Automatik
- Hybridmodelle
- kontinuierlicher Diktiermodus

Einordnung:
- fuer spaetere Produktstufen denkbar
- fuer MVP 0.1.0 bewusst ausgeschlossen

---

## Entscheidung

Fuer PushWrite v0.1.0 wird als erstes Interaktionsmodell **press-and-hold** festgelegt.

### Begruendung

Diese Entscheidung wird getroffen, weil press-and-hold fuer den ersten Produktkern die beste Kombination aus:

- Einfachheit
- Beobachtbarkeit
- kontrollierbarer Audio-Begrenzung
- kleinem Zustandsraum
- klarer Nutzerlogik

bietet.

Das Ziel des MVP ist nicht maximaler Komfort, sondern ein stabiler, enger, nachvollziehbarer Grundfluss.

---

## Minimales Zustandsmodell

Fuer den MVP wird folgendes minimales Hauptmodell festgelegt:

- `idle`
- `recording`
- `processing`

Weitere Fehlerdetails oder Hilfsflags sind erlaubt, aber kein grosses allgemeines Zustandsframework.

### `idle`

Bedeutung:
- nichts laeuft
- System ist bereit fuer einen neuen Start

Erlaubt:
- Hotkey down kann Aufnahme starten

Nicht erlaubt:
- direkte Verarbeitung ohne abgeschlossene Aufnahme

### `recording`

Bedeutung:
- Mikrofonaufnahme laeuft aktiv

Erlaubt:
- Stop ueber Hotkey up
- kontrollierter Abbruch bei technischem Fehler

Nicht erlaubt:
- zweite parallele Aufnahme
- wiederholtes Starten aus laufender Aufnahme heraus

### `processing`

Bedeutung:
- Aufnahme ist beendet
- Audio wird intern uebergeben oder vorbereitet
- der Ablauf wird sauber abgeschlossen

Erlaubt:
- Rueckkehr nach `idle`

Nicht erlaubt:
- neuer Start vor sauberem Abschluss

---

## Verbindliche Uebergaenge

Der verbindliche Standardfluss fuer den MVP lautet:

`idle -> recording -> processing -> idle`

Zusaetzlich ist als kontrollierter Fehler- oder Abbruchpfad erlaubt:

- `recording -> idle`
- `processing -> idle`

Nicht gewuenscht sind breite Seitenaeste oder mehrere konkurrierende Parallelpfade.

---

## Start-, Stop- und Abbruchlogik

### Start

Eine Aufnahme beginnt genau dann, wenn:

- der globale Hotkey gedrueckt wird
- der Zustand `idle` ist
- Aufnahme technisch gestartet werden kann

Wenn Start scheitert:
- kein haengender Zwischenzustand
- Rueckkehr nach `idle`
- Fehler muss beobachtbar sein

### Stop

Eine Aufnahme endet genau dann, wenn:

- der Hotkey losgelassen wird
- der Zustand `recording` ist

Dann gilt:
- Aufnahme sauber beenden
- Audio abschliessen
- auf `processing` wechseln
- Audio an einen klaren Weiterverarbeitungspunkt uebergeben
- danach nach `idle` zurueckkehren

### Abbruch

Ein Abbruch ist zulaessig, wenn z. B.:

- Aufnahme nicht gestartet werden kann
- Aufnahme technisch fehlschlaegt
- Audio leer oder unbrauchbar ist
- Uebergabe an die Weiterverarbeitung fehlschlaegt

Dann gilt:
- kein Hängenbleiben in `recording`
- kein Hängenbleiben in `processing`
- Rueckkehr in einen definierten Zustand
- Befund muss beobachtbar sein

---

## Fehler- und Randfaelle auf MVP-Niveau

### 1. Hotkey wird erkannt, aber Aufnahme startet nicht
Minimale Reaktion:
- Start abbrechen
- Fehler sichtbar machen
- nach `idle` zurueck

### 2. Hotkey up kommt ohne laufende Aufnahme
Minimale Reaktion:
- ignorieren
- keinen Zusatzfluss oeffnen

### 3. Während `recording` kommt ein weiterer Trigger
Minimale Reaktion:
- ignorieren oder strikt blockieren
- keine zweite Aufnahme starten

### 4. Während `processing` kommt ein neuer Startversuch
Minimale Reaktion:
- blockieren
- keine Parallelaufnahme

### 5. Aufnahme ist leer oder offensichtlich zu kurz
Minimale Reaktion:
- technisch kontrolliert abschliessen
- Befund festhalten
- sauber nach `idle` zurueck

### 6. Audio-Uebergabe scheitert
Minimale Reaktion:
- Fehler sichtbar machen
- keine haengende Verarbeitung
- Rueckkehr nach `idle`

### 7. Zustand bleibt inkonsistent stehen
Minimale Reaktion:
- aktiv verhindern
- lieber enger schneiden als flexible Sonderpfade bauen

---

## Was bewusst noch nicht gebaut wird

Bewusst ausserhalb von v0.1.0 beziehungsweise ausserhalb dieses Entscheidungskerns bleiben:

- toggle start/stop
- VAD-gesteuerte Automatik
- kontinuierlicher Diktiermodus
- Datei-Transkription
- breite UI-Ausgestaltung
- finale Textinjektion am Cursor
- grosse Recovery- oder Retry-Mechaniken
- vorgezogene Zukunftsabstraktion fuer andere Plattformen
- breite Konfigurierbarkeit des Hotkeys
- komplexe Session-Modelle

---

## Fruehe Validierung

Vor groesserer Implementierung soll minimal verifiziert werden:

1. globaler Hotkey ist im geplanten App-Kontext stabil erkennbar
2. press-and-hold fuehlt sich im Nutzungspfad eindeutig an
3. Aufnahme startet nur aus `idle`
4. Aufnahme endet nur aus `recording`
5. `processing` blockiert neue Aufnahmeversuche sauber
6. der Ablauf kehrt nach Erfolg oder Fehler immer nach `idle` zurueck
7. Audio wird als klar definierte Einheit an einen Verarbeitungspunkt uebergeben

### Kill-Kriterien

Die gewaehlte Richtung waere frueh zu hinterfragen, wenn:

- Hotkey-Ereignisse nicht stabil genug beobachtbar sind
- press-and-hold im realen Nutzungspfad unpraktisch oder technisch unzuverlaessig ist
- der Ablauf regelmaessig in inkonsistenten Zwischenzustaenden landet
- eine einfache Umsetzung bereits unverhaeltnismaessig viele Sonderfaelle erzwingt

---

## Empfehlung

Fuer PushWrite v0.1.0 gilt:

- zuerst **press-and-hold**
- zuerst nur **idle -> recording -> processing -> idle**
- zuerst kleiner technischer Prototyp
- erst danach Ausbau

Der Produktkompromiss ist bewusst:

- weniger Komfort im ersten Schritt
- dafuer hoehere Klarheit und Stabilitaet

Das ist fuer den MVP vertretbar und erwuenscht.

---

## Naechster Schritt

Der direkte Folgeauftrag ist:

`004A-minimal-hotkey-recording-prototype.md`

Dieser Folgeauftrag soll:

- den globalen press-and-hold Hotkey technisch validieren
- den minimalen Aufnahmefluss umsetzen
- einen klaren Audio-Uebergabepunkt schaffen
- die Beobachtbarkeit der Zustaende sichern
- bewusst noch nicht die finale Inferenz- und Insert-Logik ausbauen

---

## Kennzeichnung des Entscheidungsstatus

### Gesichert
- Hotkey und Aufnahmefluss muessen gemeinsam gedacht werden
- press-and-hold ist fuer den ersten MVP-Schritt der engere Pfad
- ein kleines Zustandsmodell ist fuer den MVP vorzuziehen
- `whisper.cpp` bleibt gesetzte Inferenz-Richtung
- der macOS-App-Layer bleibt separat zu schneiden

### Plausible Annahme
- press-and-hold wird im realen Nutzungspfad frueh stabiler sein als toggle
- ein dreistufiges Zustandsmodell reicht fuer den ersten Prototyp aus

### Offene Frage
- welche konkrete technische Form der Audio-Uebergabe im aktuellen Code am saubersten ist
- welche Heuristik fuer leer oder zu kurz im ersten Prototyp minimal sinnvoll ist
- welche lokale Beobachtbarkeit im bestehenden Projekt am wenigsten Reibung erzeugt