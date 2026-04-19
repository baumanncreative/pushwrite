# Auftrag für Codex 007: Whisper-Runtime und Minimalmodell in das Produktbundle integrieren

## Ziel

Mache PushWrite fuer das macOS-MVP einen klaren Schritt produktnaeher und standalone-faehiger:

- die fuer den Hotkey-Pfad benoetigte lokale whisper.cpp-Runtime
- sowie ein minimales, bewusst gewaehltes Modell
- sollen aus dem Produktbundle heraus aufloesbar und nutzbar sein

Dieser Auftrag dient dazu, die aktuelle Produktluecke zu schliessen, dass die lokale Transkription bisher noch an expliziten oder fallbackenden Repo-Pfaden haengt.

007 dient **nicht** dazu, neue Produktfeatures zu bauen.
007 dient dazu, den bestehenden 004A-006-Pfad fuer ein downloadbares, lokal laufendes Produkt sauberer zu schneiden.

---

## Ausgangslage

Der Stand vor 007 ist:

- der MVP-Kern funktioniert bereits:
  - Hotkey
  - Aufnahme
  - Handoff
  - lokale Transkription
  - Insert-Gate
  - Insert-Versuch
  - minimale Rueckmeldung
- der produktnahe Stable-Bundle-/LaunchServices-Pfad ist fuer 006 revalidiert
- die lokale Transkription nutzt jedoch bisher noch:
  - explizite Pfadangaben fuer `--whisper-cli-path` und `--whisper-model-path`
  - oder Repo-Fallbacks wie:
    - `<repo>/build/whispercpp/build/bin/whisper-cli`
    - `<repo>/models/ggml-tiny.bin`

Genau diese Standalone-Luecke soll 007 schliessen.

---

## Verbindliche Produktentscheidung fuer diesen Auftrag

Fuer 007 gilt verbindlich:

- Zielplattform bleibt **nur macOS**
- Fokus bleibt **nur MVP 0.1.0**
- Inferenzbasis bleibt **whisper.cpp**
- bestehender Hotkey-/Insert-/Feedback-Pfad bleibt fachlich erhalten
- 007 baut **keine neue Produktlogik**
- 007 baut **kein** Mehrmodell-Management
- 007 baut **keinen** Modell-Downloader
- 007 baut **keine** Datei-Transkription
- 007 baut **keine** neue UI
- 007 macht den bestehenden Produktpfad **bundle-naher und standalone-faehiger**

---

## Problemrahmen

Aktuell ist der Produktfluss zwar funktional vorhanden, aber die Runtime-Aufloesung fuer lokale Transkription ist noch nicht sauber produktisiert:

- Tests und Launches arbeiten mit expliziten CLI-/Modellpfaden
- die Default-Aufloesung greift in Repo-/Build-Strukturen
- das ist fuer Entwicklung brauchbar
- fuer ein downloadbares, offline laufendes Produkt aber noch nicht sauber genug

Die zentrale Frage fuer 007 lautet:

**Kann PushWrite im Stable-Bundle die benoetigte lokale Whisper-Runtime und das Minimalmodell aus appnahen Ressourcen aufloesen, ohne auf Repo-Pfade angewiesen zu sein?**

---

## Umsetzungsziel

Implementiere einen kleinen, kontrollierten Produktisierungsschritt fuer die lokale Transkriptionsbasis.

Am Ende dieses Auftrags soll gelten:

1. Das Produktbundle enthaelt die minimal benoetigten Ressourcen fuer lokale Transkription.
2. Die Runtime-Aufloesung bevorzugt appgebundene Ressourcen.
3. Der bestehende Hotkey-Produktpfad bleibt fachlich unveraendert.
4. Ein produktnaher Lauf soll ohne explizite externe `--whisper-cli-path`- und `--whisper-model-path`-Angaben moeglich sein.
5. Repo-Fallbacks duerfen fuer Dev/Debug bewusst bestehen bleiben, muessen aber klar als sekundaer eingeordnet werden.

---

## Verbindlicher Scope

### In Scope

- geeigneten appnahen Ort fuer die benoetigte whisper.cpp-Runtime bestimmen
- geeigneten appnahen Ort fuer genau ein Minimalmodell bestimmen
- Bundle-/Build-Pfad so anpassen, dass diese Ressourcen im Produktbundle oder in klar appnahen Produktressourcen landen
- Runtime-Aufloesung so anpassen, dass zuerst die gebundelten Produktressourcen verwendet werden
- bestehende Override-Pfade fuer Dev/Debug nur als sekundaeren Pfad erhalten, wenn sinnvoll
- bestehende Produktlogik nicht fachlich veraendern
- produktnahen Test ohne explizite externe CLI-/Modellpfade dokumentieren
- persistierte Results-Datei im Repo anlegen oder aktualisieren

### Nicht in Scope

- Mehrmodell-Auswahl
- Downloader / On-Demand-Download
- Modellwechsel per UI
- Optimierung verschiedener Modellgroessen
- Core-ML-/Metal-Umbau
- neue Transkriptionsarchitektur
- neue Insert-Architektur
- neue Feedback-Architektur
- Datei-Transkription
- Multiplattform-Unterstuetzung
- breiter Packaging-Refactor ueber diesen Bedarf hinaus

---

## Verbindliche Runtime-Regel

Die Aufloesung fuer lokale Transkription soll kuenftig in dieser Prioritaet erfolgen:

### 1. Primaer: appgebundene Produktressourcen
- CLI und Modell aus Bundle oder klar appnaher Produktressource

### 2. Sekundaer: explizite Overrides fuer Dev/Debug
- `--whisper-cli-path`
- `--whisper-model-path`
- ggf. bestehende Environment-Varianten

### 3. Tertiaer: bestehende Repo-/Build-Fallbacks
- nur wenn sie fuer Dev/Debug noch noetig sind
- klar als Entwicklungsfallback dokumentieren
- nicht mehr als primaerer Produktpfad verkaufen

Wichtig:
- die Produktlogik soll den Bundle-Pfad bevorzugen
- Dev/Debug darf moeglich bleiben
- aber das Produkt darf nicht mehr primaer von Repo-Strukturen abhaengen

---

## Modellwahl fuer 007

Bitte waehle fuer 007 **genau ein** Minimalmodell als gebundelte MVP-Default-Ressource.

Anforderung:

- klein genug fuer vernuenftigen Produktstart
- ausreichend fuer den bestehenden MVP-Nachweis
- keine breite Diskussion ueber mehrere Modelle in diesem Auftrag
- die Wahl muss in der Results-Datei klar dokumentiert werden

Falls bereits `ggml-tiny.bin` der praktisch genutzte MVP-Stand ist, ist das der naheliegende Startpunkt.
Bitte nicht ohne zwingenden Grund auf Mehrmodell-Logik ausweiten.

---

## Erwartete Bundle-/Ressourcenstruktur

Bitte waehle die einfachste saubere Produktstruktur.

Erlaubt sind z. B.:

- Ressource im App-Bundle
- klar definierter Unterordner in `Contents/Resources`
- oder anderer appnaher Standardpfad, wenn technisch sauberer

Wichtig ist:

- Pfad ist fuer das Produkt stabil
- Aufloesung ist im Code klar nachvollziehbar
- Build integriert die Ressource reproduzierbar
- Results-Datei dokumentiert den realen Ort

Nicht gewuenscht:
- versteckte Sonderpfade
- harter Repo-Pfad als primaere Produktloesung
- neue komplexe Packaging-Abstraktion

---

## Fachliche Nichtveraenderung des Produktpfads

007 darf den bestehenden Produktfluss **nicht** fachlich umbauen.

Folgendes soll nach 007 weiter gelten:

- `Hotkey -> Aufnahme -> Handoff -> lokale Transkription -> InsertGate -> InsertAttempt`
- Gate-Regeln aus 005 bleiben unveraendert
- Feedback-Regeln aus 006 bleiben unveraendert
- QA-Pfad aus 006A bleibt unveraendert

007 ist ein Packaging-/Runtime-Auftrag, kein neuer Feature-Schritt.

---

## Beobachtbarkeit

Bitte fuehre keine neue grosse Beobachtbarkeitsfamilie ein.

Nur falls noetig klein ergaenzen, damit nachvollziehbar wird:

- welcher CLI-Pfad effektiv verwendet wurde
- welcher Modellpfad effektiv verwendet wurde
- ob der Lauf ueber gebundelte Produktressourcen lief oder ueber Debug-Override
- dass der Produktfluss weiterhin sauber abschliesst

Wenn bestehende Artefakte dafuer ausreichen, diese bevorzugt weiterverwenden.

---

## Fehler- und Randfaelle

Mindestens diese Faelle muessen behandelt werden:

### 1. Gebundelte Produktressource fehlt unerwartet
Erwartung:
- klarer Fehlerbefund
- keine stille Fallback-Magie ohne Beobachtbarkeit
- sauberer Abschluss

### 2. Gebundelte CLI ist vorhanden, aber nicht nutzbar
Erwartung:
- klarer Fehlerbefund
- sauber dokumentieren
- kein Scope-Ausbau in Richtung neuer Architektur

### 3. Dev-Override ist gesetzt
Erwartung:
- Override darf bewusst Vorrang vor tertiaerem Repo-Fallback haben
- aber Bundle-Prioritaet gegenueber Repo-Pfad muss erkennbar bleiben

### 4. Produktlauf funktioniert nur noch im Dev-Setup
Erwartung:
- das waere ein Fehlschlag fuer 007
- Ziel ist gerade die Produktnaehe, nicht nur eine neue Dev-Variante

---

## Akzeptanzkriterien

Der Auftrag ist erfuellt, wenn Folgendes belegbar ist:

1. Das Produktbundle oder eine klar appnahe Produktressource enthaelt die benoetigte lokale whisper.cpp-Runtime.
2. Das Produktbundle oder eine klar appnahe Produktressource enthaelt genau ein dokumentiertes Minimalmodell.
3. Die Runtime-Aufloesung bevorzugt appgebundene Produktressourcen.
4. Ein produktnaher Lauf ist ohne explizite externe `--whisper-cli-path`- und `--whisper-model-path`-Angaben moeglich.
5. Der bestehende Hotkey-/Transkriptions-/Insert-/Feedback-Pfad funktioniert weiterhin.
6. Dev-/Debug-Overrides bleiben, falls noetig, klar als sekundaer dokumentiert.
7. Es wurde kein Mehrmodell- oder Downloader-Scope eingefuehrt.
8. Die Results-Datei dokumentiert reale Bundle-/Ressourcenpfade und den realen Produktlauf.

---

## Testhinweise, die Codex liefern soll

Bitte liefere am Ende:

1. wie 007 gebaut wird
2. wo CLI und Modell im Produktstand real liegen
3. wie der Produktlauf **ohne** explizite externe CLI-/Modellpfade gestartet wird
4. welcher Pfad effektiv verwendet wurde
5. wie ein erfolgreicher produktnaher Lauf belegt wurde
6. welche Debug-Overrides weiterhin bestehen
7. welche Dateien real geaendert wurden

---

## Persistierte Repo-Dokumentation ist Pflicht

Lege oder aktualisiere zusaetzlich eine Results-Datei im Repo unter genau diesem Pfad:

`docs/execution/007-results-bundle-whisper-runtime-and-model-into-app.md`

Diese Datei muss den **tatsaechlich umgesetzten Stand** dokumentieren, nicht nur den Auftrag wiederholen.

Mindestens enthalten:

- Status
- Kurzfassung
- geaenderte Dateien
- reale Bundle-/Ressourcenpfade
- effektive Aufloesungsreihenfolge
- gewaehltes Minimalmodell
- produktnaher Test ohne explizite externe CLI-/Modellpfade
- Debug-/Override-Pfade
- Beobachtbarkeit
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
4. eine kurze Beschreibung, wie CLI und Modell jetzt produktnah aufgeloest werden
5. eine kurze Beschreibung, welcher Bundle-/Ressourcenort konkret verwendet wird
6. eine kurze Beschreibung, welche Dev-/Debug-Fallbacks bewusst geblieben sind
7. eine kurze Beschreibung, was bewusst noch nicht gebaut wurde

---

## Prioritaet bei Zielkonflikten

Wenn waehrend der Umsetzung Zielkonflikte auftreten, gilt diese Prioritaet:

1. produktnaher Standalone-Pfad ohne Repo-Abhaengigkeit fuer den MVP-Kern
2. Bundle-/Ressourcenauflosung klar vor Dev-Fallback
3. bestehender Produktfluss bleibt fachlich unveraendert
4. kleine Eingriffsflaeche im Code
5. kein Scope-Ausbau in Mehrmodell-/Downloader-/Feature-Richtung