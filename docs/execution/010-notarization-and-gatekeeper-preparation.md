# Auftrag für Codex 010: Notarisierungs- und Gatekeeper-Vorbereitung fuer PushWrite

## Ziel

Bereite den bestehenden Release-Candidate-Stand von PushWrite fuer einen sauberen macOS-Distributionspfad unter Gatekeeper-Bedingungen vor.

Der Auftrag dient dazu, die aktuelle Luecke zwischen:

- extern testbarem Release Candidate
- und notarization-/distribution-ready Produktstand

zu schliessen.

010 dient **nicht** dazu, neue Produktfunktionen zu bauen.
010 dient dazu, Packaging, Signierung, Notarisierungs-Vorbereitung und Gatekeeper-relevante Validierung fuer den bestehenden Produktstand sauber zu schneiden.

---

## Ausgangslage

Der Stand vor 010 ist:

- es gibt einen extern testbaren RC:
  - `PushWrite-v0.1.0-rc1`
- es gibt ein ZIP-Artefakt
- das Bundle enthaelt die benoetigten Whisper-Ressourcen
- der primaere gueltige Produktstartpfad ist dokumentiert
- externe Erstinstallation und Ersttest sind beschrieben
- die Distributionsgrenzen sind offen benannt:
  - kein notarisiertes Distributionsprodukt
  - kein finaler Installer
  - kein DMG-Installationsdesign

Genau diese Distributionsluecke soll 010 adressieren.

---

## Verbindliche Produktentscheidung fuer diesen Auftrag

Fuer 010 gilt verbindlich:

- Zielplattform bleibt **nur macOS**
- Fokus bleibt **nur MVP 0.1.0**
- bestehender Produktfluss bleibt fachlich unveraendert
- 010 baut **keine** neue Transkriptionslogik
- 010 baut **keine** neue Insert-Logik
- 010 baut **keine** neue Feedback-Logik
- 010 baut **keine** neue Accessibility-Architektur
- 010 baut **keine** neue UI
- 010 baut **kein** Auto-Update
- 010 baut **keinen** `.pkg`-Installer
- 010 baut **kein** DMG-Design, ausser wenn fuer einen minimalen Notarisierungs-/Verteilpfad technisch zwingend noetig und klar begrenzt
- Fokus ist:
  - saubere Signierungsbasis
  - notarization-ready Artefakt
  - Gatekeeper-relevante Validierung
  - ehrliche Dokumentation, was bereits geht und was noch fehlt

---

## Problemrahmen

Nach 009 ist PushWrite fuer kontrollierte externe Tests vorbereitet.
Aber fuer reale externe Verteilung unter macOS bleiben typische Huerden offen:

- Welche Signierungsbasis ist aktuell real vorhanden?
- Ist das Artefakt notarization-ready?
- Kann Notarisierung bereits ausgefuehrt werden oder fehlen noch Credentials/Voraussetzungen?
- Wie sieht der minimale Gatekeeper-relevante Pruefpfad aus?
- Was ist heute schon belastbar, und was ist noch blockiert?

Die zentrale Frage von 010 lautet:

**Ist PushWrite fuer einen minimal sauberen Gatekeeper-/Notarisierungsweg vorbereitet, und falls noch nicht, was ist der engste verbleibende Blocker?**

---

## Umsetzungsziel

Implementiere einen kleinen, kontrollierten Vorbereitungsschritt fuer Notarisierung und Gatekeeper-Validierung.

Am Ende dieses Auftrags soll **einer von zwei sauberen Zustaenden** erreicht sein:

### Ziel A: notarization-ready oder notarisierter Stand
- Signing-/Packaging-Basis ist sauber
- notarization-taugliches Artefakt ist erzeugt
- falls moeglich: Notarisierung wurde erfolgreich durchgefuehrt und dokumentiert
- Gatekeeper-relevanter Befund ist nachvollziehbar dokumentiert

### Ziel B: sauber vorbereiteter Stand mit dokumentiertem Blocker
- Signing-/Packaging-Basis ist geprueft
- notarization-tauglicher Pfad ist technisch vorbereitet
- engster reale Blocker ist dokumentiert
- es ist klar, was fuer den naechsten Schritt noch fehlt
- keine unscharfe „fast fertig“-Aussage

Beide Endzustaende sind akzeptabel.
Nicht akzeptabel ist ein unscharfer Zwischenstand.

---

## Verbindlicher Scope

### In Scope

- aktuellen Signierungsstand des RC-Bundles pruefen
- minimal sauberen Signierungs-/Packaging-Pfad fuer Notarisierung vorbereiten
- notarization-taugliches Artefakt bestimmen oder erzeugen
- falls Credentials/Umgebung vorhanden und sicher nutzbar: Notarisierung kontrolliert ausfuehren
- falls nicht moeglich: engsten realen Blocker dokumentieren
- Gatekeeper-relevante Pruefschritte definieren und minimal validieren
- ehrliche Distributionshinweise fuer den Stand dokumentieren
- persistierte Results-Datei im Repo anlegen oder aktualisieren

### Nicht in Scope

- neue Produktfeatures
- neue Hotkey-/Transkriptions-/Insert-Logik
- neue Accessibility-Architektur
- Auto-Update
- Sparkle
- GitHub-Release-Automatisierung
- finaler `.pkg`-Installer
- breit gestaltetes DMG-Design
- Multiplattform-Unterstuetzung
- neue UI-Flaechen
- Datei-Transkription
- Mehrmodell-Management

---

## Verbindliche Reihenfolge der Arbeit

Bitte arbeite in genau dieser Reihenfolge:

### 1. Ist-Zustand des aktuellen RC dokumentieren
Mindestens dokumentieren:
- aktueller RC-Name
- Bundle-Pfad
- ZIP-Pfad
- aktueller Codesign-Befund
- aktuelle Signing-Identity oder ad-hoc-Befund
- vorhandene Entitlements, falls relevant
- aktueller CDHash
- welche Distributionseigenschaften daraus heute folgen

### 2. Minimalen Notarisierungspfad bestimmen
Bitte entscheiden und dokumentieren:
- welches Artefakt fuer Notarisierung der kleinste saubere Kandidat ist
  - z. B. ZIP
  - oder anderes kleines, technisch begruendetes Format
- wie dieser Pfad reproduzierbar erzeugt wird
- ob das aktuelle Build-/Packaging-Skript dafuer reicht oder minimal ergaenzt werden muss

### 3. Signing-/Packaging-Basis pruefen
Zu pruefen und zu dokumentieren:
- ist die aktuelle Signierung fuer Notarisierung geeignet?
- falls nein: was ist der engste Grund?
- ist ein minimaler produktnaher Signed-Stand ohne Featureaenderung herstellbar?
- welche Voraussetzung ist extern/organisatorisch statt technisch?

### 4. Nur falls moeglich: Notarisierung ausfuehren
Nur wenn die noetigen Voraussetzungen wirklich vorhanden sind:
- kontrolliert ausfuehren
- Ergebnis sauber dokumentieren
- falls erfolgreich: Stapling / Nachpruefung dokumentieren
- falls fehlgeschlagen: exakte Fehlermeldung dokumentieren

### 5. Gatekeeper-relevante Validierung
Bitte minimal und ehrlich pruefen:
- welcher Start-/Verteilpfad fuer einen externen Mac nach 010 gilt
- welche Pruefschritte fuer Gatekeeper relevant sind
- was mit dem aktuellen Stand bereits belastbar gesagt werden kann
- was ohne echte Notarisierung bewusst noch nicht behauptet werden darf

---

## Verbindliche Ergebnislogik

Bitte arbeite mit diesen klaren Statuskategorien:

### A. `prepared`
- Notarisierungspfad ist vorbereitet
- aber echte Notarisierung wurde nicht ausgefuehrt
- oder ist wegen dokumentierter Voraussetzungen blockiert

### B. `notarized`
- Artefakt wurde notarisiert
- Befund ist dokumentiert
- nachgelagerte Pruefung ist dokumentiert

### C. `blocked`
- engster reale Blocker ist sauber dokumentiert
- keine unklare „fast fertig“-Aussage

Bitte genau einen dieser Status im Results-Dokument fuehren.

---

## Verbindliche Trennung von technischem und organisatorischem Blocker

Bitte sauber trennen zwischen:

### Technischer Blocker
Beispiele:
- Artefakt ungeeignet
- Signing-Setup unvollstaendig
- Packaging falsch
- notarization tooling bricht technisch

### Organisatorischer Blocker
Beispiele:
- Apple Developer Credentials fehlen
- notarization keychain profile fehlt
- Team-/Account-Zugriff fehlt
- erforderliches Zertifikat fehlt

Diese Trennung ist wichtig, damit nicht ein organisatorisches Thema faelschlich als Produktfehler erscheint.

---

## Gatekeeper-/Distributionsnotizen fuer externe Nutzung

Lege oder aktualisiere zusaetzlich eine kleine Datei an:

`docs/testing/010-gatekeeper-and-notarization-notes.md`

Diese Datei soll knapp und ehrlich erklaeren:

- was der aktuelle Distributionsstand ist
- ob der RC bereits notarisiert ist oder nicht
- was ein externer Tester beim ersten Start erwarten darf
- welche Warnungen oder Huerden aktuell normal sind
- was als gueltiger Befund gilt
- was bewusst noch nicht final gehaertet ist

Bitte klein und praktisch halten.
Keine juristische oder marketinghafte Sprache.

---

## Beobachtbarkeit

Bitte fuehre keine neue grosse Observability-Familie ein.

Nur soweit noetig:
- Release-/Packaging-/Signing-Befunde dokumentieren
- bestehende Build-/Validation-Artefakte nutzen
- ggf. ein kleines notarization-/signing-bezogenes Output-Artefakt erzeugen, wenn es fuer Nachvollziehbarkeit hilft

Wenn moeglich, dokumentierende Artefakte bevorzugen statt neue Produkt-Runtime-Logs.

---

## Fehler- und Randfaelle

Mindestens diese Faelle muessen sauber behandelt werden:

### 1. Notarisierung ist technisch vorbereitet, aber Credentials fehlen
Erwartung:
- klar als organisatorischer Blocker dokumentieren
- nicht als Produktfehler darstellen

### 2. Artefakt ist fuer Notarisierung ungeeignet
Erwartung:
- klarer technischer Befund
- minimalen Korrekturpfad dokumentieren
- kein Scope-Ausbau in neue Produktfunktionen

### 3. Signierung ist noch ad hoc und fuer echte Distribution unzureichend
Erwartung:
- klar dokumentieren
- genau benennen, was fuer echten Distribution-Stand fehlt

### 4. Gatekeeper-relevante Aussage waere zu stark
Erwartung:
- keine ueberzogene Behauptung
- nur das dokumentieren, was wirklich belegt ist

### 5. Eine Korrektur wuerde grossen Umbau verlangen
Erwartung:
- Stop
- sauber dokumentieren
- nicht heimlich Scope aufziehen

---

## Akzeptanzkriterien

Der Auftrag ist erfuellt, wenn **einer** der folgenden Zustaende sauber erreicht ist:

### Akzeptanz A: vorbereitet
1. Aktueller Signing-/Packaging-Stand ist dokumentiert.
2. Ein minimaler Notarisierungspfad ist bestimmt.
3. Das notarization-taugliche Artefakt ist benannt oder erzeugt.
4. Der engste verbleibende Blocker ist sauber dokumentiert, falls Notarisierung nicht ausgefuehrt wurde.
5. Gatekeeper-/Distributionsnotizen sind erstellt.

### Akzeptanz B: notarisiert
1. Aktueller Signing-/Packaging-Stand ist dokumentiert.
2. Das Artefakt wurde notarisiert.
3. Das Ergebnis ist sauber dokumentiert.
4. Nachpruefung / Stapling ist dokumentiert, soweit relevant.
5. Gatekeeper-/Distributionsnotizen sind aktualisiert.

### Akzeptanz C: blockiert, aber klar eingegrenzt
1. Signing-/Packaging-Basis ist dokumentiert.
2. Die Notarisierung wurde nicht erfolgreich erreicht.
3. Der technische oder organisatorische Blocker ist exakt dokumentiert.
4. Es ist klar, warum 010 noch nicht weitergeht.
5. Es wurde keine unzulaessige Scope-Ausweitung vorgenommen.

---

## Testhinweise, die Codex liefern soll

Bitte liefere am Ende:

1. exakten RC-Pfad
2. exakten Artefaktpfad fuer den Notarisierungskandidaten
3. aktuellen Signing-Befund
4. aktuellen CDHash
5. ob der Stand `prepared`, `notarized` oder `blocked` ist
6. falls `blocked`: exakten engsten Blocker
7. falls `notarized`: welche Nachpruefung erfolgt ist
8. exakten Pfad der Gatekeeper-/Notarisierungsnotizen
9. welche Dateien real geaendert wurden

---

## Persistierte Repo-Dokumentation ist Pflicht

Lege oder aktualisiere zusaetzlich eine Results-Datei im Repo unter genau diesem Pfad:

`docs/execution/010-results-notarization-and-gatekeeper-preparation.md`

Diese Datei muss den **tatsaechlich erreichten Stand** dokumentieren, nicht nur den Auftrag wiederholen.

Mindestens enthalten:

- Status (`prepared|notarized|blocked`)
- Kurzfassung
- geaenderte Dateien
- RC-Pfad
- Notarisierungskandidat-Pfad
- Signing-Befund
- CDHash
- technischer oder organisatorischer Blocker, falls vorhanden
- Gatekeeper-/Distributionsnotizen
- nicht umgesetzt
- bekannte Risiken / Annahmen
- Testhinweise
- Rollback

---

## Zusaetzliche Repo-Datei fuer externe Nutzung

Lege oder aktualisiere zusaetzlich:

`docs/testing/010-gatekeeper-and-notarization-notes.md`

Diese Datei soll:
- kurz
- ehrlich
- distributionsnah
- extern brauchbar

sein.

---

## Ausgabe von Codex

Bitte liefere am Ende:

1. den exakten Pfad der Auftragsumsetzung
2. den exakten Pfad der Results-Datei
3. den exakten Pfad der Gatekeeper-/Notarisierungsnotizen
4. die Liste aller real geaenderten Dateien
5. eine kurze Beschreibung, wie der Notarisierungspfad jetzt geschnitten ist
6. eine kurze Beschreibung, welcher reale Status erreicht wurde
7. eine kurze Beschreibung, was bewusst noch nicht gebaut wurde

---

## Prioritaet bei Zielkonflikten

Wenn waehrend der Umsetzung Zielkonflikte auftreten, gilt diese Prioritaet:

1. ehrlicher Notarisierungs-/Gatekeeper-Status statt Wunschdenken
2. sauber dokumentierter engster Blocker, falls vorhanden
3. keine unzulaessige Scope-Ausweitung
4. kleine Eingriffsflaeche in Build, Packaging und Doku
5. keine neuen Produktfeatures