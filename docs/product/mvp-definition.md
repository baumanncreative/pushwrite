# MVP Definition

## Zweck dieses Dokuments

Dieses Dokument definiert den verbindlichen Scope für **PushWrite v0.1.0**.

Es legt fest:

- welchen konkreten Nutzen das erste Release liefern muss
- welche Funktionen zwingend enthalten sein müssen
- welche Themen bewusst ausgeschlossen sind
- nach welchen Kriterien der MVP als erreicht gilt

Dieses Dokument dient der Scope-Kontrolle.  
Es ist keine Architekturdatei und kein Implementierungsauftrag.

## Produktziel des MVP

PushWrite v0.1.0 soll einen klaren, alltagstauglichen Kernnutzen liefern:

Ein Nutzer kann auf macOS per globalem Hotkey eine Aufnahme starten, sprechen, die Aufnahme beenden, die Sprache lokal transkribieren lassen und den erkannten Text direkt an der aktuellen Cursor-Position einfügen.

Der MVP ist dann erfolgreich, wenn genau dieser Ablauf in typischen Texteingabesituationen stabil funktioniert.

## Zielbild des MVP

Der MVP ist **kein** allgemeines Transkriptionsprodukt und **keine** breite Voice-Plattform.

Er ist ein eng fokussiertes macOS-Werkzeug für eine einzige Hauptaufgabe:

**sprechen statt tippen – direkt im aktuellen Texteingabekontext**

## Enthaltene Kernfunktion

PushWrite v0.1.0 muss den folgenden Kernablauf unterstützen:

1. Nutzer befindet sich in einem Texteingabekontext auf macOS
2. Nutzer aktiviert einen globalen Push-to-talk-Hotkey
3. PushWrite nimmt Sprache über das Mikrofon auf
4. Nach dem Beenden der Aufnahme wird die Sprache lokal transkribiert
5. Der erkannte Text wird direkt an der aktuellen Cursor-Position eingefügt

## Verbindlicher Funktionsumfang

### 1. Globaler Hotkey

Das Produkt muss einen globalen Hotkey bereitstellen, der den Aufnahmeablauf auslöst.

Mindestanforderung:

- Hotkey ist systemweit nutzbar
- Hotkey startet den Aufnahmeprozess zuverlässig
- Hotkey beendet die Aufnahme zuverlässig

### 2. Mikrofonaufnahme

Das Produkt muss Sprache lokal über das Systemmikrofon oder das gewählte Eingabegerät aufnehmen können.

Mindestanforderung:

- Aufnahme funktioniert unter macOS
- Aufnahme ist auf den Kernablauf ausgelegt
- keine Dateiverwaltung als Nutzerfunktion im MVP

### 3. Lokale Transkription

Die erkannte Sprache muss lokal auf dem Gerät in Text umgewandelt werden.

Mindestanforderung:

- keine Cloud-Pflicht
- keine serverbasierte Standardverarbeitung
- Transkriptionspfad ist für den Offline-Betrieb ausgelegt

### 4. Direkte Texteinfügung

Der transkribierte Text muss direkt an der aktuellen Cursor-Position eingefügt werden.

Mindestanforderung:

- kein manueller Copy-Paste-Zwischenschritt
- Einfügen funktioniert in typischen Texteingabefeldern auf macOS
- Einfügen gehört zum eigentlichen Produktkern

### 5. Minimale Einstellungen

Es dürfen nur jene Einstellungen enthalten sein, die für den Kernablauf zwingend nötig sind.

Zulässig im MVP sind nur Einstellungen wie:

- Hotkey-Grundeinstellung
- Basisauswahl relevanter Audio- oder Modellparameter, falls technisch zwingend
- notwendige Berechtigungsführung

Nicht zulässig sind umfangreiche Preference-Panels ohne direkte MVP-Relevanz.

## Definition of Done für v0.1.0

Der MVP gilt als erreicht, wenn alle folgenden Bedingungen erfüllt sind:

### Funktional

- Aufnahme kann per globalem Hotkey gestartet werden
- Sprache kann über das Mikrofon aufgenommen werden
- Audio wird lokal transkribiert
- erkannter Text wird direkt an der Cursor-Position eingefügt
- der Kernablauf funktioniert ohne Copy-Paste-Umweg

### Produktbezogen

- der Nutzen ist für einen einzelnen Nutzer direkt erlebbar
- das Produkt erfüllt eine klare Hauptaufgabe statt mehrerer halbfertiger Nebenfunktionen
- der Scope bleibt auf macOS und den Kernworkflow begrenzt

### Technisch

- die Transkription basiert auf einer lokalen Inferenz-Basis
- der Ablauf ist grundsätzlich offline-fähig
- der macOS-spezifische App-Layer ist für Hotkey, Berechtigungen und Texteinfügung vorhanden
- die Lösung ist als erste wartbare Produktbasis verwendbar

### Qualität

- der Kernablauf ist in typischen Texteingabesituationen reproduzierbar
- Fehler im Berechtigungs- oder Aufnahmefluss werden nicht vollständig unkontrolliert dem Nutzer überlassen
- das Produkt ist klein, fokussiert und nicht durch Nebenfunktionen verwässert

## Explizit nicht Teil des MVP

Die folgenden Themen gehören **nicht** zu v0.1.0:

### Plattformen

- Windows
- Linux
- iOS
- Android

### Funktionsausbau

- Datei-Transkription
- MP3-, MP4-, Audio- oder Video-Import
- Batch-Verarbeitung
- Live-Untertitel
- Übersetzungsfunktionen
- Prompt-basierte Textumformung
- Zusammenfassungen
- Sprechertrennung
- Verlaufsverwaltung
- Exportfunktionen
- Mehrbenutzerfunktionen
- Cloud-Sync
- Plugin-Systeme
- Multi-Engine-Architektur

### Produktausbau

- Optimierung auf spätere Plattformen vor Stabilisierung des macOS-MVP
- vorzeitige Generalisierung der Architektur für hypothetische Zukunftsszenarien
- breite UI-Komfortfunktionen ohne Einfluss auf den Kernablauf

## Bewusste Produktgrenzen

Der MVP ist absichtlich eng geschnitten.

Diese Grenzen sind gewollt, weil sie:

- Fokus sichern
- technische Komplexität begrenzen
- Scope Creep vermeiden
- schnelle Validierung des Kernnutzens ermöglichen

Ein Thema wird nicht deshalb Teil des MVP, weil es später sinnvoll sein könnte.

## Annahmen auf MVP-Ebene

### Plausible Annahme 1
Ein enger Push-to-talk-Ablauf ist für den Start wertvoller als eine breite Sammlung von Sprachfunktionen.

### Plausible Annahme 2
Direkte Texteinfügung an der Cursor-Position ist der entscheidende Unterschied zwischen einem allgemeinen Transkriptionswerkzeug und dem Produktkern von PushWrite.

### Plausible Annahme 3
Ein lokaler, offline-fähiger Ablauf ist nicht nur technische Präferenz, sondern Teil des Produktversprechens.

## Abhängigkeiten des MVP

Der MVP hängt konzeptionell von vier Dingen ab:

- macOS-Berechtigungen
- verlässlicher globaler Hotkey
- lokale Audioaufnahme
- lokale Transkriptionsintegration
- direkte Texteinfügung in den aktiven Texteingabekontext

Wichtig:
Diese Abhängigkeiten definieren noch keine vollständige Architektur.  
Sie markieren nur die notwendigen Produktbausteine.

## Offene Punkte, die noch keine Scope-Erweiterung sind

Diese Punkte sind relevant, gehören aber nicht als neue Features in den MVP:

- welche Modellgrösse für den Start verwendet wird
- wie genau der Aufnahmezustand signalisiert wird
- wie robust die Texteinfügung über unterschiedliche Apps hinweg ist
- welche minimale Fehlerkommunikation nötig ist
- welche Hotkey-Voreinstellung sinnvoll ist
- wie Modelle lokal bereitgestellt werden

Diese Punkte sind innerhalb des MVP zu klären, nicht ausserhalb davon.

## Kill-Kriterien für Scope-Disziplin

Folgende Aussagen sind Warnsignale und dürfen nicht automatisch zu neuem Scope führen:

- „Wenn wir schon dabei sind, können wir auch noch Datei-Import machen.“
- „Wir sollten die Architektur sofort für alle Plattformen vorbereiten.“
- „Ein Verlauf wäre für Nutzer sicher auch hilfreich.“
- „Eine zweite Engine wäre strategisch klug.“
- „Wir könnten gleich noch Übersetzung integrieren.“

Solche Themen sind nur dann zulässig, wenn v0.1.0 bereits als stabiler Kernworkflow erreicht ist.

## Beziehung zu anderen Dokumenten

- `project-overview.md` definiert den übergeordneten Projektrahmen.
- `mvp-definition.md` definiert die harte Produktgrenze für v0.1.0.
- `technical-decisions.md` dokumentiert die zugrunde liegenden Technologieentscheide.
- `system-components.md` zerlegt den MVP in technische Hauptbausteine.
- `codex-briefs.md` enthält erst danach konkrete Umsetzungsaufträge.

## Änderungsregel

Dieses Dokument darf nur geändert werden, wenn sich mindestens einer dieser Punkte ändert:

- der verbindliche Funktionsumfang von v0.1.0
- die expliziten Nicht-Ziele
- die Definition of Done
- die Grundannahme des Kernworkflows

Detailfragen der Umsetzung gehören nicht hierhin, sondern in Architektur- und Ausführungsdokumente.