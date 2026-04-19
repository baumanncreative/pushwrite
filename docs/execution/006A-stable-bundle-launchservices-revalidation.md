# Auftrag für Codex 006A: Stable-Bundle-/LaunchServices-Revalidierung fuer 006

## Ziel

Fuehre fuer den bereits umgesetzten 006-Stand eine **produktnahe Revalidierung ueber Stable-Bundle + LaunchServices** durch und dokumentiere den Befund sauber.

Dieser Auftrag dient **nicht** dazu, neue Produktfunktionen zu bauen.

Er dient dazu, die noch offene QA-Luecke nach 006 zu schliessen:

- 006 ist funktional implementiert
- der gueltige produktnahe Nachweis ueber Stable-Bundle + LaunchServices fehlt in der aktuellen Session
- dokumentiert ist ein LaunchServices-Fehler `kLSNoExecutableErr` (`Code=-10827`)
- 006A soll diesen Befund **revalidieren**, **eingrenzen** und – nur falls noetig – mit einer **minimalen launch-/bundle-bezogenen Korrektur** beheben

---

## Ausgangslage

Der Stand aus 006 ist:

- der 005-Produktpfad bleibt erhalten:
  - `Hotkey -> Aufnahme -> Handoff -> lokale Transkription -> InsertGate -> InsertAttempt`
- fuer no-insert- und insert-failed-Endlagen gibt es jetzt genau einmal eine kleine lokale Rueckmeldung
- erfolgreiche Inserts bleiben stumm
- die funktionale 006-Logik wurde ueber Direktstarts nachgewiesen
- fuer den **primaeren** Stable-Bundle-/LaunchServices-Pfad liegt in der dokumentierten Session **kein neuer gueltiger Laufbefund** vor
- dokumentierter CDHash fuer den Stable-Bundle-Pfad:
  - `00b1aaa0b4a2017a9bb9892df95a2a1417956f20`
- dokumentierter LaunchServices-Fehler:
  - `kLSNoExecutableErr` (`Code=-10827`)

Genau diese offene Luecke soll 006A schliessen.

---

## Verbindliche Produkt- und QA-Entscheidung fuer diesen Auftrag

Fuer 006A gilt verbindlich:

- Zielplattform bleibt **nur macOS**
- Fokus bleibt **nur MVP 0.1.0**
- 006A ist **kein** neuer Feature-Auftrag
- der bestehende 006-Produktpfad soll **nicht** funktional erweitert werden
- primaerer Gueltigkeitspfad bleibt:
  - **Stable-Bundle + LaunchServices + dokumentierter CDHash**
- Direct-/Control-Starts bleiben nur **sekundaere Debug-Hilfe**
- wenn eine Korrektur noetig ist, dann **nur minimal** und nur im Bereich:
  - Bundle-/Launch-/Packaging-/Startpfad
- keine neue Accessibility-Architektur
- keine neue Insert-Architektur
- keine neue UI
- keine Scope-Ausweitung Richtung 007

---

## Problemrahmen

Nach 006 gibt es zwei Ebenen, die sauber getrennt bleiben muessen:

### 1. Funktionale Ebene
Diese ist bereits nachgewiesen:
- Gate- und Fehlerfaelle loesen lokale Rueckmeldung aus
- Erfolgsfall bleibt stumm
- pro Flow genau eine Rueckmeldung

### 2. Produktnahe QA-Ebene
Diese ist noch offen:
- derselbe 006-Befund ist im gueltigen Stable-Bundle-/LaunchServices-Pfad in der aktuellen Session nicht erneut belegt
- statt eines gueltigen LS-Laufs wurde `kLSNoExecutableErr` (`Code=-10827`) dokumentiert

006A soll **nicht** erneut 006 bauen, sondern diesen offenen QA-/Launch-Punkt sauber behandeln.

---

## Umsetzungsziel

Pruefe und dokumentiere, ob der bestehende Stable-Bundle-Pfad fuer PushWrite ueber LaunchServices wieder gueltig gestartet und fuer 006 bewertet werden kann.

Das Ziel ist einer von zwei sauberen Endzustaenden:

### Ziel A: gueltige Revalidierung gelungen
- Stable-Bundle startet ueber LaunchServices
- CDHash ist dokumentiert
- mindestens ein produktnaher Erfolgspfad und ein produktnaher no-insert- oder insert-failed-Pfad sind nachvollziehbar bewertet
- 006 kann QA-seitig sauber abgehakt werden

### Ziel B: Revalidierung weiterhin blockiert
- der Blocker ist sauber eingegrenzt
- die genaue Ursache oder engste technische Verdachtslage ist dokumentiert
- der Fehler ist reproduzierbar beschrieben
- falls noetig wurde nur eine **minimale** Korrektur am Launch-/Bundle-Pfad vorgenommen oder bewusst unterlassen
- es liegt eine klare Entscheidungsgrundlage fuer den naechsten Schritt vor

Beide Endzustaende sind akzeptabel.
Nicht akzeptabel ist ein unscharfer Zwischenstand.

---

## Verbindlicher Scope

### In Scope

- Stable-Bundle-Pfad fuer PushWrite pruefen
- LaunchServices-Startpfad erneut ausfuehren und dokumentieren
- dokumentierten CDHash erneut pruefen oder aktualisiert dokumentieren
- primären QA-Pfad gegen sekundaeren Debug-Pfad sauber abgrenzen
- falls noetig eine **minimale** bundle-/launch-bezogene Korrektur vornehmen
- 006-relevante Produktfaelle ueber den gueltigen Pfad revalidieren, sofern der Launch gelingt
- persistierte Results-Datei im Repo anlegen oder aktualisieren

### Nicht in Scope

- neue Produktfeatures
- neue Feedback-Faelle
- neue Insert-Mechanik
- neue Accessibility-Strategie
- neue Rechte-Dialog-Strategie
- neue Menubar-/UI-Architektur
- Toggle/VAD/Continuous Dictation
- breite Refactors
- tiefe Zukunftsarchitektur
- Performance-Tuning
- Modell-/Transkriptionsumbau

---

## Verbindliche Prueffrage

Die zentrale Frage von 006A lautet:

**Ist der 006-Stand im gueltigen Stable-Bundle-/LaunchServices-Pfad belastbar bewertbar?**

Nicht:
- „funktioniert 006 grundsaetzlich irgendwie“
- „funktioniert es per Direktstart“
- „koennen wir noch neue Features bauen“

Sondern exakt:
- laesst sich der Produktstand im gueltigen Produktpfad belastbar nachweisen?

---

## Reihenfolge der Arbeit

Bitte arbeite in genau dieser Reihenfolge:

### 1. Ist-Zustand des Stable-Bundles dokumentieren
Mindestens dokumentieren:
- Bundle-Pfad
- enthaltenes Executable
- aktueller CDHash
- relevante Launch-/Codesign-Befunde
- exakter LaunchServices-Befehl, der verwendet wird

### 2. LaunchServices-Revalidierung ausfuehren
- produktnahen Launch ueber LaunchServices ausfuehren
- Ergebnis sauber dokumentieren
- Erfolg oder Fehler inkl. Code/Befund festhalten

### 3. Nur falls blockiert: minimal eingrenzen
Wenn der Launch erneut scheitert:
- engste Ursache isolieren
- nur launch-/bundle-nahe Punkte pruefen
- keine breite Produktausweitung
- keine neue Architektur bauen

### 4. Nur falls noetig: minimale Korrektur
Falls der Blocker klein und klar ist, darf eine **minimale** Korrektur vorgenommen werden.
Beispiele fuer akzeptable Richtung:
- Bundle-/Executable-Zuordnung
- Packaging-/Build-Artefakt
- Launch-/Startskript, soweit es den gueltigen Pfad korrekt abbildet
- kleine inkonsistente Produktbundle-Eigenschaft

Nicht akzeptabel:
- grossflaechiger Umbau
- neue Funktionslogik
- neue Produktfeatures

### 5. Revalidierung wiederholen
Nach minimaler Korrektur:
- LaunchServices-Pfad erneut pruefen
- Ergebnis dokumentieren
- nur dann 006-relevante Produktfaelle darueber bewerten

### 6. 006-spezifische Produktfaelle bewerten
Nur wenn der Stable-Bundle-/LaunchServices-Pfad gueltig laeuft, bitte mindestens diese zwei Faelle produktnah bewerten:

#### a) Erfolgsfall
- Insert gelingt
- Erfolgsfall bleibt stumm

#### b) Ein negativer Fall
- entweder Gate-Fall
- oder insert-failed-Fall

Mehr ist erlaubt, aber nicht noetig.
Wichtig ist:
- gueltiger Produktpfad
- sauber dokumentierter Befund

---

## Verbindliche Dokumentation des Bundle-Befunds

Bitte dokumentiere in der Results-Datei mindestens:

- exakter Stable-Bundle-Pfad
- exakter Executable-Pfad im Bundle
- dokumentierter CDHash
- exakter LaunchServices-Startbefehl
- Ergebnis des Launch-Versuchs
- falls Fehler:
  - exakter Fehlercode / Fehlermeldung
  - reproduzierbarer Kontext
- falls Erfolg:
  - welcher 006-Fall darueber gueltig bewertet wurde

---

## Verbindliche Trennung von primaer und sekundaer

Bitte halte in der Results-Datei und in deiner Codex-Antwort strikt getrennt:

### Primaer (gueltig)
- Stable-Bundle
- LaunchServices
- dokumentierter CDHash
- produktnaher Befund

### Sekundaer (Debug)
- Direct-/Control-Starts
- Zwischenverifikation
- Diagnosehilfe
- kein Ersatz fuer den primaeren QA-Befund

Wenn der primaere Pfad weiterhin blockiert ist, darf der sekundaere Pfad **nicht** als gueltiger Produktnachweis verkauft werden.

---

## Beobachtbarkeit

Bitte fuehre keine neue Beobachtbarkeitsfamilie ein, wenn die bestehenden Artefakte reichen.

Bevorzugt weiterverwenden:

- `logs/last-hotkey-response.json`
- `logs/hotkey-responses.jsonl`
- `logs/hotkey-recording-prototype.jsonl`
- `logs/flow-events.jsonl`
- `logs/last-insert-result.json` falls relevant

Nur wenn fuer LaunchServices-/Bundle-Revalidierung ein kleines zusaetzliches Artefakt wirklich noetig ist, ist es erlaubt.
Dann bitte klein halten und begruenden.

---

## Fehler- und Randfaelle

Mindestens diese Faelle muessen sauber behandelt werden:

### 1. LaunchServices startet weiterhin nicht
Erwartung:
- Fehlercode und Befehl sauber dokumentieren
- engste Ursache oder Verdachtslage benennen
- kein unscharfer Zwischenstand

### 2. Stable-Bundle startet, aber 006-Fall ist nicht sauber beobachtbar
Erwartung:
- klar dokumentieren, was genau fehlt
- keine Behauptung eines gueltigen Produktnachweises ohne Evidenz

### 3. Korrektur waere nur ueber groesseren Umbau moeglich
Erwartung:
- Stop
- sauber dokumentieren
- nicht heimlich Scope ausweiten

### 4. Stable-Bundle-Start gelingt, aber CDHash hat sich geaendert
Erwartung:
- neuen CDHash dokumentieren
- alten und neuen Befund sauber trennen
- keine Vermischung der QA-Basis

---

## Akzeptanzkriterien

Der Auftrag ist erfuellt, wenn **einer** der folgenden beiden Zustaende sauber erreicht ist:

### Akzeptanz A: Revalidierung gelungen
1. Stable-Bundle-Pfad ist exakt dokumentiert.
2. LaunchServices-Start wurde erfolgreich ausgefuehrt.
3. CDHash ist dokumentiert.
4. Mindestens ein produktnaher Erfolgsfall und ein produktnaher negativer Fall wurden ueber den gueltigen Pfad bewertet.
5. 006 kann damit QA-seitig als produktnah revalidiert gelten.

### Akzeptanz B: Revalidierung blockiert, aber sauber eingegrenzt
1. Stable-Bundle-Pfad ist exakt dokumentiert.
2. LaunchServices-Start wurde erneut ausgefuehrt.
3. Fehlercode / Fehlermeldung sind exakt dokumentiert.
4. Die engste Ursache oder Verdachtslage ist beschrieben.
5. Es ist klar dokumentiert, warum 006 QA-seitig noch nicht abgeschlossen ist.
6. Es wurde keine unzulaessige Scope-Ausweitung vorgenommen.

---

## Testhinweise, die Codex liefern soll

Bitte liefere am Ende:

1. exakten Stable-Bundle-Pfad
2. exakten Executable-Pfad im Bundle
3. dokumentierten CDHash
4. exakten LaunchServices-Befehl
5. Ergebnis des LaunchServices-Versuchs
6. falls Erfolg:
   - welche 006-Faelle darueber gueltig bewertet wurden
7. falls Fehler:
   - exakten Fehlercode / Fehltext
   - engste Ursache oder Verdachtslage
8. welche Dateien real geaendert wurden
9. ob ueberhaupt Code/Build/Packaging angepasst werden musste oder nur Doku entstand

---

## Persistierte Repo-Dokumentation ist Pflicht

Lege oder aktualisiere zusaetzlich eine Results-Datei im Repo unter genau diesem Pfad:

`docs/execution/006A-results-stable-bundle-launchservices-revalidation.md`

Diese Datei muss den **tatsaechlich erreichten Stand** dokumentieren, nicht nur den Auftrag wiederholen.

Mindestens enthalten:

- Status
- Kurzfassung
- geaenderte Dateien
- Stable-Bundle-Pfad
- Executable-Pfad im Bundle
- CDHash
- LaunchServices-Befehl
- LaunchServices-Ergebnis
- primaerer gueltiger Befund oder sauber dokumentierter Blocker
- sekundaere Debug-Hinweise, falls verwendet
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
4. eine kurze Aussage, ob 006 jetzt QA-seitig produktnah revalidiert ist oder nicht
5. falls nein: den engsten dokumentierten Blocker
6. falls ja: welche 006-Faelle ueber den gueltigen Pfad bestaetigt wurden

---

## Prioritaet bei Zielkonflikten

Wenn waehrend der Umsetzung Zielkonflikte auftreten, gilt diese Prioritaet:

1. gueltiger Stable-Bundle-/LaunchServices-Befund oder sauber dokumentierter Blocker
2. klare Trennung zwischen primaerem QA-Pfad und sekundaerem Debug-Pfad
3. keine unzulaessige Scope-Ausweitung
4. minimale launch-/bundle-nahe Korrektur nur wenn wirklich noetig
5. kleine Eingriffsflaeche im Code