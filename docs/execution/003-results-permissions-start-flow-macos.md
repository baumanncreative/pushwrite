# 003 Ergebnisse: Berechtigungs- und Erststartfluss für PushWrite auf macOS vor der Mikrofonstufe

## Arbeitsgrundlage

Diese Einordnung basiert auf drei Quellen:

- aktuellem Produktcode in `app/macos/PushWrite/main.swift` und `app/macos/PushWrite/Info.plist`
- den validierten Ergebnisdokumenten `002E`, `002F` und `002H`
- offizieller Apple-Dokumentation zu Accessibility-Trust und Mikrofonfreigabe

Für die Bewertung gilt:

- `gesichert`: direkt durch aktuellen Produktcode, beobachtete Produktläufe oder Apple-Dokumentation belegt
- `plausibel`: starke Ableitung aus aktuellem Produktpfad, aber noch nicht direkt im Produkt mit Mikrofon validiert
- `offen`: vor oder in `002I` gezielt zu verifizieren

## 1. Problemdefinition

PushWrite ist in der aktuellen Projektphase nicht mehr in einer abstrakten Architekturvorstufe. Das Stable-Bundle existiert, der Hotkey-/Flow-/Insert-Kern läuft produktnah, und Accessibility ist bereits ein realer Blocker des bestehenden Kernpfads.

Produktkritisch ist das aus vier Gründen:

- Fehlende Accessibility blockiert den bestehenden Insert-Kern direkt. Der aktuelle Produktcode stoppt den Insert vor dem synthetischen `Cmd+V`, liefert `status=blocked` und schreibt den Blockierungsgrund sichtbar in Produktzustand und Hotkey-Response.
- Fehlende Mikrofonfreigabe wird den unmittelbar nächsten Produktschritt direkt blockieren. Nach der Mikrofonintegration scheitert der Kernworkflow sonst bereits zwischen Hotkey und Aufnahmebeginn.
- Ein rein technischer API-Blick reicht nicht aus, weil der Nutzer nicht "AXIsProcessTrusted" oder "AVCaptureDevice.requestAccess" erlebt, sondern einen globalen Trigger, der entweder funktioniert oder scheinbar grundlos nichts tut.
- Der Startfluss ist für Vertrauen und Benutzbarkeit relevant, weil PushWrite als Hintergrundwerkzeug ohne grosse Haupt-UI arbeitet. Wenn Berechtigungen oder Systemzustände unklar bleiben, wirkt das Produkt stumm oder defekt.

Der Permission-Fluss muss jetzt vor der Mikrofonstufe präzisiert werden, damit der nächste Schritt nicht zwei Fehlerklassen vermischt:

- bestehende Accessibility-/TCC-Blockaden des Insert-Pfads
- neue Mikrofon-Blockaden beim Aufnahmebeginn

Ohne diese Trennung wird der erste echte Push-to-talk-Lauf schwer debugbar und für Nutzer schlecht verständlich.

## 2. Relevante Berechtigungen und Zugriffe

| Zugriff oder Recht | Einordnung | Wofür im Produktkontext | Betroffene Produktfunktion | Was passiert bei Fehlen |
| --- | --- | --- | --- | --- |
| Accessibility-Trust fuer PushWrite als "trusted accessibility client" | `gesichert erforderlich` | Der Produktcode prüft `AXIsProcessTrustedWithOptions`, liest den Fokuskontext und blockiert den paste-basierten Insert-Pfad ohne Trust. | bestehender Insert-Kern, Fokusdiagnostik, ehrlicher Blocked-Flow | Insert wird vor dem Paste gestoppt, `syntheticPastePosted=false`, der Hotkey-Lauf endet `blocked`, und beim Launch erscheint die bestehende Accessibility-Blocked-UI. |
| Mikrofonfreigabe unter macOS | `gesichert erforderlich vor Mikrofonintegration` | Für Audioaufnahme muss das Produkt zur Laufzeit Mikrofonzugriff anfragen. Zusätzlich muss ein statischer `NSMicrophoneUsageDescription`-Text im Bundle vorhanden sein. | nächster Schritt: Aufnahmebeginn nach Hotkey | Ohne Freigabe kann keine Aufnahme starten. Der Kernworkflow bricht vor Transkription und Insert ab. Im aktuellen Produkt ist dieser Pfad noch nicht implementiert. |
| Verfuegbares Eingabegeraet beziehungsweise Recorder-Start | `plausibel erforderlich` | Auch mit erteilter Mikrofonfreigabe braucht PushWrite ein nutzbares Input-Device und einen funktionierenden Recorder-Start. | Mikrofonaufnahme, Übergang von `idle` nach `recording` | Der Workflow ist praktisch blockiert, obwohl die Permission formal erteilt sein kann. Das ist kein Permission-Fehler und muss separat behandelt werden. |
| Globale Hotkey-Registrierung ueber `RegisterEventHotKey` | `gesichert relevant, aber keine eigene TCC-Permission im aktuellen Produktpfad` | Der Hotkey ist der einzige Nutzer-Trigger des Kernflows. Die App registriert ihn beim Start und schreibt `registered` plus `registrationError` in den Produktzustand. | Start des Kernworkflows | Wenn die Registrierung scheitert, läuft die App zwar weiter, der Kernworkflow ist aber faktisch tot. Es gibt aktuell nur State-/stderr-Sichtbarkeit, keine eigene Hotkey-Blocked-UI. |
| Stabile Bundle-Identitaet fuer den Accessibility-Trust | `gesichert relevant im aktuellen Produktstand` | Die 002F-/002G-/002H-Läufe zeigen, dass der beobachtete Accessibility-Trust am Stable-Bundle hängt und nach Rebuilds verloren gehen kann. | verlässlicher First-Run- und Revalidierungspfad | Ein vormals freigegebenes Produkt kann sich nach Rebuild wieder wie "nicht freigegeben" verhalten. Das ist kein zusätzlicher Nutzerdialog, aber ein realer Blocker für ehrliche QA und reproduzierbaren Startfluss. |

Nicht als aktuell nötige MVP-Permissions belegt sind:

- `Input Monitoring` oder `Listen Event Access`: Der Produktpfad nutzt derzeit keinen globalen Event-Tap und kein Mitschneiden beliebiger Tastaturereignisse, sondern `RegisterEventHotKey` für genau einen Hotkey. Im aktuellen Code und in den validierten Läufen gibt es keinen Hinweis auf einen zusätzlichen Permission-Schritt.
- `Apple Events`, `Full Disk Access` oder ähnliche Systemrechte: Für den bestehenden Produktkern gibt es dafür aktuell keinen Beleg.
- explizite Pasteboard-Permissions als eigener First-Run-Schritt: Der Insert-Pfad schreibt auf die General Pasteboard. Das aktuelle Hotkey-Insert setzt `restoreClipboard=false`, liest also im Standardpfad nicht einmal den vorherigen Clipboard-Inhalt zurück. Im aktuellen MVP-Startfluss ist daraus kein eigener Permission-Dialog abzuleiten.

## 3. Bewertung nach Kritikalität

### Bereits praktisch zwingend fuer den bestehenden Produktkern

- Accessibility-Trust fuer `PushWrite.app`

Begründung:

- Der reale Stable-Produktkern `Hotkey -> Flow -> Insert` ist nur mit Accessibility grün validiert.
- Der aktuelle Launch zeigt bei fehlender Freigabe bereits einen Setup-Blocker.
- Accessibility ist damit kein theoretischer Systemzugriff mehr, sondern die jetzige Kernvoraussetzung.

### Zwingend vor Mikrofonintegration

- Mikrofonfreigabe unter macOS
- statischer `NSMicrophoneUsageDescription`-Eintrag im Produktbundle

Begründung:

- Ohne diese beiden Punkte gibt es keinen legalen und ehrlichen Aufnahmebeginn.
- Im aktuellen `Info.plist` fehlt der Usage-Description-Eintrag noch; das muss vor dem ersten echten Aufnahmeversuch ergänzt werden.

### Wahrscheinlich noetig, aber noch produktseitig zu verifizieren

- klare Unterscheidung zwischen `Mikrofon permission denied` und `kein nutzbares Mikrofon / Recorder start failed`
- verlässliches Verhalten des Startflusses auf einem frisch freigegebenen Stable-Bundle mit späterer Mikrofonanbindung
- konkrete Produktreaktion auf Hotkey-Registrierungsfehler ausserhalb von State und stderr

### Optional oder nachgelagert

- aktives Auslösen des systemseitigen Accessibility-Prompts statt reinem Deep-Link in die Systemeinstellungen
- Clipboard-Restore als Komfortpfad mit zusätzlicher Pasteboard-Rücklese
- umfassendes Onboarding, Mehrschritt-Setup oder Preferences-UI
- weitere Systemrechte, solange der Produktpfad bei `RegisterEventHotKey + Mikrofon + Accessibility + paste-based insert` bleibt

## 4. Empfohlene Reihenfolge im Startfluss

Die Reihenfolge sollte asymmetrisch sein: Accessibility frueh und proaktiv, Mikrofon spaeter und bedarfsnah.

### Empfohlener Ablauf

1. Beim Launch sofort den stillen Readiness-Check ausführen:
   - Hotkey registrieren
   - Accessibility ohne Systemprompt prüfen
   - Produktzustand schreiben
2. Wenn der Hotkey nicht registriert werden kann:
   - den Zustand nicht als "bereit" behandeln
   - einen kleinen, verständlichen Fehlerzustand anzeigen oder zumindest denselben Setup-Kanal wie bei Accessibility verwenden
3. Wenn Accessibility fehlt:
   - sofort den bestehenden Setup-/Blocked-Fall zeigen
   - Deep-Link in `System Settings > Privacy & Security > Accessibility` anbieten
   - keinen Mikrofon-Dialog starten
4. Erst wenn Accessibility und Hotkey benutzbar sind:
   - das Produkt als startklar behandeln
5. Mikrofon erst bei echter Aufnahmeabsicht behandeln:
   - beim ersten Recording-Versuch oder in einem sehr kleinen vorgeschalteten Mic-Preflight
   - nicht schon auf kaltem Launch
6. Nach erteilter Mikrofonfreigabe:
   - Aufnahme starten
   - getrennt von Permission-Fehlern noch `kein Geraet` oder `Recorder start failed` behandeln

### Warum Accessibility vor Mikrofon kommen sollte

- Accessibility blockiert bereits heute den existierenden Produktkern.
- Auch nach späterer Mikrofonfreigabe bleibt Accessibility zwingend für den finalen Nutzen.
- Die umgekehrte Reihenfolge erzeugt leicht ein irreführendes Erlebnis: Nutzer gibt Mikrofon frei, aber der eigentliche Produktnutzen scheitert trotzdem erst beim Insert.

### Warum Mikrofon nicht auf kaltem Launch angefragt werden sollte

- Vor der Mikrofonstufe braucht das Produkt diese Freigabe noch gar nicht.
- Auch im späteren Mic-Build minimiert eine bedarfsnahe Anforderung die Friktion.
- Ein kalter Sammel-Dialog würde dem MVP unnötig einen Onboarding-Charakter geben, obwohl PushWrite als kleines Hintergrundwerkzeug gedacht ist.

### Minimaler MVP-Kompromiss

Der MVP braucht keinen vollständigen Setup-Assistenten. Ausreichend ist:

- ein klarer Launch-Blocked-Zustand für Accessibility
- ein gleichwertig klarer Hotkey-Fehlerzustand
- ein später separater Mic-Blocked-Zustand bei der ersten Aufnahmeabsicht

## 5. Fehler- und Blockadezustände

| Zustand | Erkennung | Produktauswirkung | Minimale MVP-Rueckmeldung |
| --- | --- | --- | --- |
| Accessibility fehlt | `AXIsProcessTrustedWithOptions(..., prompt: false)` liefert `false`; Preflight oder Hotkey-Flow liefern `blocked` mit Accessibility-Reason | bestehender Insert-Kern ist blockiert; Mikrofon allein würde den Produktnutzen später nicht retten | bestehende Setup-UI mit klarer Ursache und Deep-Link in die Systemeinstellungen; derselbe Reason muss im State und in Hotkey-Responses sichtbar bleiben |
| Mikrofonzugriff fehlt oder wurde verweigert | nach Integration über AVFoundation-Authorization-Status oder `requestAccess`-Resultat `false` | Aufnahme startet nicht; kein Audio, keine Transkription, kein Insert | eigener Mic-Blocked-Zustand mit kurzer Erklärung und Verweis auf Systemeinstellungen; klar getrennt von Accessibility |
| Kein Mikrofon oder Geraetefehler | Mikrofonpermission ist erlaubt, aber kein Input-Device ist verfügbar oder Recorder-Start schlägt fehl | Workflow bricht vor oder direkt bei Aufnahmebeginn ab | Fehlermeldung "kein Mikrofon verfügbar" oder "Aufnahme konnte nicht starten"; nicht als Permission-Problem labeln |
| Hotkey oder zugehoeriger Zugriff ist nicht nutzbar | `hotKey.registered=false` oder `registrationError` gesetzt | App wirkt im Alltag stumm, weil der einzige Trigger fehlt | kleiner Startfehlerzustand mit Hinweis auf den Hotkey und den technischen Fehler; Zustand zusätzlich in `product-state.json` sichtbar halten |
| Nutzer versteht nicht, warum der Workflow blockiert ist | Produkt läuft im Hintergrund, aber es gibt kein Ergebnis an der Cursorposition | Vertrauen sinkt sofort; Tool wirkt kaputt | jeder Blocker braucht drei Dinge: klare Ursache, direkte nächste Aktion, beobachtbaren State. Ein reines Beep reicht allein nicht. |
| Accessibility-Trust ging nach Rebuild verloren | vormals freigegebener Stable-Pfad meldet nach Rebuild wieder `accessibilityTrusted=false` | QA und Entwicklungsvalidierung können falsche "First-Run"-Effekte zeigen | für Dev-/QA-Pfade explizit als Build-/Trust-Thema dokumentieren; nicht mit Mikrofonfehlern vermischen |

Wichtige Nuance im aktuellen Produktstand:

- Der Launch-Fall für fehlende Accessibility ist bereits relativ ehrlich.
- Der spaetere Hotkey-Blocked-Fall ist derzeit schlanker und nutzt ohne UI-Praesentation nur `beep + blocked response`.
- Fuer den MVP ist das nur dann vertretbar, wenn der Launch-Blocked-Zustand sichtbar bleibt und dieselbe Ursache in State und Logs auffindbar ist.

## 6. MVP-Empfehlung fuer den Erststart

### Klare Empfehlung

Der First-Run-Flow darf vor der Mikrofonstufe sehr klein bleiben, aber er darf nicht unklar sein.

Minimal noetig sind:

- Launch-Readiness-Check fuer `hotKey.registered` und `accessibilityTrusted`
- ein klarer, sofortiger Accessibility-Blocked-Zustand auf Launch
- ein sichtbarer Hotkey-Fehlerzustand statt rein technischer Nebenkanäle
- eine festgelegte spätere Mic-Reihenfolge: nicht auf Launch, sondern beim ersten echten Recording-Versuch

### Was der MVP wirklich braucht

- genau zwei echte Permission-Themen im Produktfluss:
  - Accessibility jetzt
  - Mikrofon als nächster Schritt
- eine kleine Produktsprache für Blocker:
  - `Accessibility fehlt`
  - `Mikrofon fehlt oder verweigert`
  - `kein Mikrofon / Aufnahmefehler`
  - `Hotkey nicht verfügbar`

### Was bewusst noch nicht ausgebaut werden soll

- kein mehrstufiges Onboarding
- keine Permission-Checkliste mit mehreren Screens
- keine UI fuer nachgelagerte Komfortrechte
- keine automatische Behandlung aller macOS-Sonderfaelle
- keine neue Insert- oder Hotkey-Grundsatzarchitektur

### Vertretbare MVP-Kompromisse

- Accessibility darf manuell ueber Systemeinstellungen freigegeben werden; ein Deep-Link reicht
- Mikrofon darf erst beim ersten Recording-Versuch angefordert werden
- Device-Fehler dürfen zunächst nur als kurzer Fehlerzustand erscheinen, ohne Audio-Settings-UI
- der Produktzustand darf technisch sichtbar bleiben, solange die Nutzerführung nicht widersprüchlich wird

### Was vor `002I` feststehen sollte

- welche Zustände als echte Blocker unterschieden werden
- welche Reihenfolge Launch, Accessibility und Mikrofon haben
- dass der Stable-Bundle-Pfad für QA nicht implizit ständig den Accessibility-Trust verliert
- dass `NSMicrophoneUsageDescription` in den ersten Mic-Build aufgenommen wird

### Was erst waehrend der Mikrofonintegration konkretisiert werden kann

- konkrete AVFoundation-API-Entscheidung
- genaue Erkennung von `no device` versus `recording failed`
- exakte Signalgebung waehrend `recording` und `processing`
- Feinschliff der Copy fuer Mic-Blocked und Device-Fehler

## 7. Fruehe Validierung

Vor groesserer Mikrofonintegration sollte Folgendes gezielt verifiziert werden:

1. Accessibility bleibt der einzige echte Launch-Blocker des bestehenden Produktkerns.
2. Hotkey-Registrierungsfehler sind reproduzierbar beobachtbar und nicht nur in stderr versteckt.
3. Ein Stable-Bundle mit gesetzter Accessibility-Freigabe bleibt über den geplanten QA-/Promote-Pfad konsistent genug.
4. Der Produktzustand bildet Blockaden schon jetzt sauber ab:
   - `accessibilityTrusted`
   - `hotKey.registered`
   - `registrationError`
   - `lastBlockedReason`
   - `flow-events.jsonl`
   - `hotkey-responses.jsonl`
5. Die erste Mikrofonstufe trennt drei Fehlerklassen sauber:
   - Permission fehlt
   - kein Geraet / Recorder start failed
   - Accessibility blockiert den spaeteren Insert

Zwingend reproduzierbar zu testen sind:

- frischer Launch ohne Accessibility-Freigabe
- Launch mit gültiger Accessibility-Freigabe
- Hotkey-Registrierungsfehler oder bewusst simulierter Unusable-Hotkey-Fall
- erster Mic-Run mit `not determined`
- Mic-Run mit `denied`
- Mic-Run mit erlaubt, aber ohne nutzbares Eingabegeraet

Kill-Kriterium fuer den weiteren Ausbau:

- wenn ein erster Mic-Build Permission-, Device- und Accessibility-Fehler nicht getrennt beobachtbar macht, sollte nicht direkt weiter in Transkription oder UX-Ausbau investiert werden

## 8. Vorschlag fuer Folgeauftrag

### Folgeauftrag 003A: Minimalen Readiness- und Permission-Flow vor `002I` umsetzen

Ziel:

- den bestehenden Startfluss so klein wie möglich, aber belastbar machen
- Accessibility und Hotkey im Produkt sofort ehrlich sichtbar machen
- die spätere Mikrofonstufe sauber vorbereiten, ohne sie schon zu implementieren

Scope:

1. Ergänze einen kleinen zentralen Readiness-Status im Produktzustand mit klaren Blockerklassen:
   - `ready`
   - `accessibilityBlocked`
   - `hotkeyUnavailable`
2. Erweitere den bestehenden Launch-Blocked-Kanal minimal, sodass er auch einen Hotkey-Fehlerzustand darstellen kann.
3. Reserviere im Zustands- und Reason-Modell bereits die späteren Mikrofonklassen, ohne Mikrofonfunktion einzubauen:
   - `microphonePermissionRequired`
   - `microphoneDenied`
   - `microphoneUnavailable`
4. Belasse Accessibility weiterhin als Launch-Check ohne erzwungenen Systemprompt.
5. Revalidiere auf dem Stable-Bundle nur diese Fälle:
   - Launch ohne Accessibility
   - Launch mit Accessibility
   - Hotkey nicht registrierbar oder simuliert unbenutzbar

Nicht Teil des Folgeauftrags:

- echte Mikrofonaufnahme
- AVFoundation-Integration
- grosse Onboarding-UI
- neue Insert-Strategien

Erwartetes Ergebnis des Folgeauftrags:

- ein kleiner, ehrlicher Startfluss fuer den bestehenden Produktstand
- klare State-/Reason-Vertraege fuer `002I`
- keine Vermischung von Accessibility-, Hotkey- und späteren Mikrofonblockern
