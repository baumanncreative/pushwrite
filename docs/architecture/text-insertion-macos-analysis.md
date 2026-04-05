# Textinjektion auf macOS für PushWrite v0.1.0

## Zweck dieses Dokuments

Dieses Dokument liefert die technische Entscheidungsgrundlage für die direkte Texteinfügung im macOS-MVP von PushWrite.

Es beantwortet für den engen Produktscope:

- welche realistischen Einfügepfade es auf macOS gibt
- welche Rechte und Systemgrenzen dabei relevant sind
- welcher Pfad für v0.1.0 zuerst verfolgt werden sollte
- welche Zielkontexte realistisch unterstützt werden können
- welche frühe Validierung vor grösserer Implementierung nötig ist

Dieses Dokument ist keine vollständige Implementierung und keine allgemeine macOS-Eingabearchitektur.

## Datenbasis

### Verifizierte Daten

- Die öffentliche macOS-Accessibility-API stellt mit `AXIsProcessTrustedWithOptions` einen expliziten Trust-Check für Accessibility-Clients bereit.
- Die öffentliche Accessibility-API stellt mit `kAXFocusedUIElementAttribute`, `kAXValueAttribute`, `kAXSelectedTextAttribute` und `kAXSelectedTextRangeAttribute` die Grundbausteine bereit, um den fokussierten Eingabekontext, seinen Textwert und seine Selektion zu lesen oder teilweise zu setzen.
- `kAXSelectedTextRangeAttribute` ist laut Apple-Header für editierbare Textelemente schreibbar.
- `AXUIElementSetAttributeValue` kann bei Zielanwendungen unter anderem mit `kAXErrorAttributeUnsupported`, `kAXErrorCannotComplete` oder `kAXErrorNotImplemented` fehlschlagen.
- `NSPasteboard` ist die offizielle Schnittstelle zum systemweiten Pasteboard. Die General Pasteboard ist systemweit geteilt.
- `NSPasteboard` unterstützt explizites Leeren und Schreiben von String-Daten sowie seit neueren macOS-Versionen ein konfigurierbares Pasteboard-Zugriffsverhalten pro App.
- `CGEventCreateKeyboardEvent`, `CGEventKeyboardSetUnicodeString` und `CGEventPost` erlauben synthetische Keyboard-Events. Apple weist im Header darauf hin, dass Frameworks den Unicode-String eines Keyboard-Events ignorieren und stattdessen eigene Keycode-Übersetzung verwenden können.
- `InputMethodKit` ist die offizielle Eingabemethoden-Infrastruktur auf macOS. Sie basiert auf `IMKServer` und `IMKInputController` pro Input-Session.

### Annahmen

- Typische Drittanwendungen auf macOS unterscheiden sich stark darin, wie vollständig sie editierbare Textflächen über Accessibility modellieren.
- Browser-basierte, Electron-basierte oder sonstige Custom-Editoren sind bei direkter Accessibility-Manipulation riskanter als bei normalem Paste-Verhalten.
- Für PushWrite ist Fokus-Stabilität kritisch: Wenn die App beim Einfügen den Fokus übernimmt, landet Text im falschen Ziel oder gar nicht.
- Für den MVP ist nicht theoretische Universalität relevant, sondern ob typische Texteingabefelder stabil genug funktionieren.

### Offene Fragen

- Welche minimale macOS-Version für v0.1.0 unterstützt werden soll.
- Ob PushWrite für eine spätere Distribution App Sandbox oder andere Packaging-Einschränkungen berücksichtigen muss.
- Wie stark Clipboard-Erhalt für v0.1.0 als Produktanforderung gewichtet wird, falls dieser technisch Friktion erzeugt.

## 1. Problemdefinition

Direkt an der aktuellen Cursor-Position einfügen bedeutet auf macOS nicht nur, dass Text in die gerade sichtbare App gelangt. Der Text muss in genau das aktuell fokussierte editierbare Ziel gelangen, dort eine bestehende Selektion korrekt ersetzen oder an der Insertion Position landen, und das ohne manuellen Copy-Paste-Zwischenschritt.

Technisch schwierig ist dieser Schritt aus drei Gründen:

- PushWrite arbeitet app-übergreifend. Die Zielanwendung gehört PushWrite nicht und kann AppKit, WebView, Electron, eigene Editorkomponenten oder geschützte Eingabefelder verwenden.
- macOS bietet keinen einzigen universellen, öffentlichen Einfügebefehl für fremde Textziele. Realistische Wege sind immer indirekt: Accessibility-Manipulation, Pasteboard plus Paste-Aktion, synthetische Tastenereignisse oder eine tiefere Integration als Input Method.
- Der Einfügemoment liegt am Ende eines globalen Flows. Sobald Aufnahme, Statusanzeige oder Fehlermeldung den Fokus verschieben, ist der Cursor-Kontext verloren.

Produktkritisch ist dieser Teil, weil PushWrite ohne verlässliche Direkteinfügung seinen Kernnutzen verliert. Dann bleibt ein lokales Transkriptionswerkzeug mit schlechterem Workflow statt eines systemweiten Spracheingabe-Werkzeugs.

## 2. Mögliche technische Ansätze

### Ansatz A: Direkte Accessibility-Manipulation des fokussierten Textelements

**Grundidee**  
PushWrite ermittelt über Accessibility das fokussierte UI-Element der Frontmost App, liest Textwert und Selektion und ersetzt den selektierten Bereich oder erweitert den Wert an der Cursor-Position.

**Technische Voraussetzungen**  
Die Zielanwendung muss den fokussierten Textkontext über Accessibility sauber exponieren. Praktisch braucht PushWrite mindestens Zugriff auf fokussiertes Element, aktuellen Textwert und aktuelle Selektion. Da die öffentliche API keinen allgemeinen "insert text"-Befehl bereitstellt, müsste die Einfügung typischerweise als Lesen des Werts, Berechnen des neuen Strings und Zurückschreiben umgesetzt werden.

**Notwendige Berechtigungen**  
Accessibility-Vertrauen.

**Erwartbare Stärken**

- kein Clipboard-Zwischenschritt
- Zielselektion kann explizit berücksichtigt werden
- Fehler sind API-seitig genauer klassifizierbar als bei reinem Paste
- potenziell sauberer Produktpfad in gut unterstützten nativen Textfeldern

**Erwartbare Schwächen**

- starke Abhängigkeit von der Accessibility-Qualität der Zielanwendung
- keine universelle Einfügeoperation; häufig muss der gesamte Textwert manipuliert werden
- Risiken bei Rich-Text, grossen Dokumenten, Custom-Editoren und nicht standardisierten Textsystemen
- Undo-Verhalten und Editor-Semantik werden eher indirekt beeinflusst als bei normalem Paste

**Risiken für den MVP**

- hohe Inkompatibilität zwischen Zielanwendungen
- grösserer Implementierungsaufwand schon für die erste Validierung
- Gefahr, dass eine "elegante" Lösung gerade in den wichtigsten Alltagskontexten unzuverlässig ist

### Ansatz B: Plain-Text-Paste über General Pasteboard plus synthetisches `Cmd+V`

**Grundidee**  
PushWrite schreibt den transkribierten Text als Plain Text auf die General Pasteboard und löst anschliessend im aktuell fokussierten Ziel ein Paste per synthetischem `Cmd+V` aus.

**Technische Voraussetzungen**  
Das Ziel muss normales Paste akzeptieren und der Fokus muss auf dem gewünschten Texteingabefeld bleiben. Wenn der bestehende Clipboard-Inhalt erhalten bleiben soll, muss PushWrite ihn vorher sichern und nach dem Paste wiederherstellen. Für Privacy sollte der transkribierte Text nur als Plain Text und nach Möglichkeit `current-host-only` geschrieben werden.

**Notwendige Berechtigungen**  
Wahrscheinlich Accessibility für das synthetische Tastaturereignis. Für reines Schreiben auf die Pasteboard ist keine zusätzliche Spezialberechtigung ersichtlich. Für Clipboard-Erhalt ist jedoch programmgesteuertes Lesen der General Pasteboard nötig; neueres macOS behandelt Pasteboard-Zugriffe pro App konfigurierbar.

**Erwartbare Stärken**

- kleinster realistischer Implementierungspfad
- folgt dem etablierten Verhalten der Zielanwendung statt eigene Editierlogik zu erzwingen
- ersetzt bestehende Selektion im Normalfall automatisch korrekt
- erwartbar gute Breite in nativen Textfeldern, Browser-Textfeldern und vielen Custom-Editoren, solange normales Paste funktioniert

**Erwartbare Schwächen**

- Clipboard-Seiteneffekte, wenn Erhalt oder Restore nicht sauber funktionieren
- Erfolg ist schlechter direkt nachweisbar als bei einer expliziten API-Antwort
- Paste kann in einzelnen Zielapps deaktiviert, umgebogen oder speziell behandelt werden
- Timing, Fokusverlust und Clipboard-Restore sind praktische Fehlerquellen

**Risiken für den MVP**

- Clipboard-Pfad kann UX-Friktion erzeugen
- Restore des Clipboards kann auf neueren macOS-Versionen zusätzliche Pasteboard-Fragen oder Ablehnungen berühren
- Problematische Zielkontexte bleiben problematisch, obwohl Paste grundsätzlich breit getragen wird

### Ansatz C: Synthetisches Tippen per Keyboard-Events oder Unicode-Events

**Grundidee**  
PushWrite sendet den transkribierten Text als Folge synthetischer Tastenereignisse oder Unicode-Strings direkt in die Frontmost App.

**Technische Voraussetzungen**  
Die Zielanwendung muss synthetische Keyboard-Events in derselben Weise wie echte Eingabe akzeptieren. Der Zeichensatz, das Keyboard-Layout und eventuelle Kompositionen müssen korrekt abgebildet werden.

**Notwendige Berechtigungen**  
Accessibility.

**Erwartbare Stärken**

- kein Clipboard-Zwischenschritt
- zunächst konzeptionell einfach

**Erwartbare Schwächen**

- Apple dokumentiert explizit, dass Frameworks den Unicode-String eines Keyboard-Events ignorieren können
- stark abhängig von Keyboard-Layout, Dead Keys, Sonderzeichen und IME-Verhalten
- langsam und fehleranfällig bei längeren Transkripten
- höheres Risiko für unerwünschte Shortcuts oder fehlerhafte Zeichenfolgen

**Risiken für den MVP**

- zu hohe Fehleranfälligkeit schon bei Standardsätzen mit Satzzeichen, Umlauten oder längeren Texten
- wenig robustes Verhalten über App-Grenzen hinweg
- kein sinnvoller First Path für v0.1.0

### Ansatz D: Eigene Input Method über `InputMethodKit`

**Grundidee**  
PushWrite würde nicht als externe App Text "hineindrücken", sondern als systemweite Eingabemethode am Textinput-Layer teilnehmen.

**Technische Voraussetzungen**  
Eigene Input-Method-Struktur mit `IMKServer`, `IMKInputController`, Session-Handling und Aktivierung als Input Source. Das Interaktionsmodell muss mit globalem Hotkey, Mikrofonaufnahme und Commit von Text in den jeweiligen Client zusammengesetzt werden.

**Notwendige Berechtigungen**  
Keine offensichtliche Accessibility-Pflicht für das eigentliche Committen von Text, aber deutlich mehr Systemintegration und Setup-Komplexität. Mikrofon- und gegebenenfalls Hotkey-Rechte bleiben separat relevant.

**Erwartbare Stärken**

- am nächsten am systemischen Textinput-Modell
- kein Clipboard-Zwischenschritt
- potenziell korrekteres Verhalten in Textsystemen, die reguläre Input Methods gut unterstützen

**Erwartbare Schwächen**

- deutlich grösserer Architektur- und Packaging-Scope
- schwerer mit einem engen, globalen Push-to-talk-MVP zu verheiraten
- mehr Produkt- und Setup-Friktion, weil Aktivierung und Systemintegration tiefer gehen

**Risiken für den MVP**

- klarer Scope-Sprung
- verlängert Validierung und Debugging erheblich
- ungeeignet als erster technischer Beweis für v0.1.0

### Bewusst nicht als eigener MVP-Ansatz geführt

AppleScript oder `System Events` sind für PushWrite kein eigener technischer Weg. Sie enden praktisch in derselben Fehlerklasse wie synthetische Tastaturevents und liefern keinen klaren Robustheitsgewinn.

## 3. Vergleich der Ansätze für PushWrite v0.1.0

Die folgende Matrix ist eine MVP-Bewertung, keine allgemeine macOS-Rangliste.

| Kriterium | Accessibility direkt | Pasteboard + `Cmd+V` | Synthetisches Tippen | Input Method |
| --- | --- | --- | --- | --- |
| Robustheit in typischen Texteingabefeldern | Mittel bis niedrig | Hoch bis mittel | Niedrig | Potenziell hoch, aber nicht für MVP validierbar |
| Abhängigkeit von macOS-Berechtigungen | Hoch | Mittel bis hoch | Hoch | Mittel |
| Komplexität der ersten Umsetzung | Mittel bis hoch | Niedrig bis mittel | Niedrig | Sehr hoch |
| Verhalten bei App-übergreifender Nutzung | Mittel bis niedrig | Hoch | Niedrig bis mittel | Unklar ohne grossen Integrationsaufwand |
| Fehleranfälligkeit | Mittel bis hoch | Mittel | Hoch | Mittel bis hoch |
| MVP-Tauglichkeit | Mittel | Hoch | Niedrig | Niedrig |

### Einordnung

- **Accessibility direkt** ist der technisch präzisere, aber praktisch schmalere Weg. Er ist als möglicher späterer Zusatzpfad interessant, aber kein guter Erstpfad.
- **Pasteboard plus `Cmd+V`** ist der pragmatischste Weg, weil er das Zielsystem dort nutzt, wo Textanwendungen ohnehin app-übergreifend interoperabel sein müssen: beim Paste.
- **Synthetisches Tippen** ist für kurze Demos denkbar, für transkribierte Alltagstexte aber zu fragil.
- **Input Method** ist architektonisch legitim, aber für PushWrite v0.1.0 zu gross und zu riskant.

## 4. Typische Zielkontexte

### Native Standard-Texteingabefelder

Beispiele auf hoher Ebene: AppKit-Textfelder, `NSTextView`-basierte Flächen, einfache Compose-Felder nativer Apps.

**MVP-Einordnung**

- günstigster Zielkontext
- Paste-basierter Ansatz sollte hier zuerst validiert werden
- Accessibility-direkt ist hier am ehesten ebenfalls realistisch

### Browser-Textfelder und einfache Web-Editoren

Beispiele auf hoher Ebene: `<textarea>`, einfache `contenteditable`-Felder, Web-Compose-Flächen.

**MVP-Einordnung**

- wichtiger Zielkontext für den Produktnutzen
- Paste-basierter Ansatz ist hier wahrscheinlicher tragfähig als direkte Accessibility-Manipulation
- Rich-Web-Editoren bleiben risikoreicher als einfache Textareas

### Editoren

Beispiele auf hoher Ebene: native Texteditoren, Code-Editoren, Electron-basierte Editoren, Markdown- und Dokumenteditoren.

**MVP-Einordnung**

- heterogene Klasse
- Standard-Editoren mit normalem Paste-Verhalten sind gute MVP-Kandidaten
- Custom-Editoren mit eigener Rendering- oder Shortcut-Logik sind für direkte Accessibility-Manipulation unattraktiv
- Paste ist hier realistischer als Zeichen-für-Zeichen-Tippen

### Sonderfälle und problematische Kontexte

Beispiele auf hoher Ebene: Passwortfelder, geschützte Eingaben, Terminal-Prompts, Remote-Desktop-Sessions, Games, Canvas-basierte UI, paste-deaktivierte Felder.

**MVP-Einordnung**

- keine sinnvolle Zusage für v0.1.0
- Passwort- und andere Secure-Fields sollten bewusst nicht als unterstützter Produktkontext kommuniziert werden
- Terminale sind funktional zwar oft paste-fähig, aber semantisch riskant, weil mehrzeilige oder fehlformatierte Inhalte direkte Shell-Auswirkungen haben können

## 5. MVP-Empfehlung

Für PushWrite v0.1.0 sollte **Plain-Text-Paste über General Pasteboard plus synthetisches `Cmd+V`** als erster und primärer Einfügepfad verfolgt werden.

### Warum dieser Ansatz am besten zum Scope passt

- Er maximiert nicht theoretische API-Sauberkeit, sondern praktische Breite in typischen Texteingabefeldern.
- Er nutzt das Verhalten, das Zielanwendungen ohnehin für normalen App-übergreifenden Texttransfer unterstützen müssen.
- Er behandelt Selektion, Caret-Position und Editor-spezifische Insert-Semantik eher so, wie die Zielanwendung sie selbst erwartet.
- Er ist klein genug für eine frühe Validierung, ohne gleichzeitig Accessibility-Textmodellierung, Editor-Semantik und Rich-Text-Verhalten selbst nachbauen zu müssen.

### Bewusst akzeptierte Einschränkungen

- v0.1.0 sollte nur Kontexte als unterstützt betrachten, in denen normales Paste bei fokussiertem Texteingabefeld grundsätzlich funktioniert.
- Passwortfelder, paste-deaktivierte Eingaben, Sonder-Canvas und andere geschützte oder atypische Ziele bleiben explizit ausserhalb der Zusage.
- Accessibility-direkte Einfügung sollte nicht parallel als zweite MVP-Strategie gebaut werden. Das erhöht Komplexität, bevor der robustere Erstpfad validiert ist.
- Clipboard-Erhalt ist wichtig, aber nicht als Grund zu behandeln, den Paste-Pfad vor der Basisvalidierung zu verwerfen. Falls Restore technisch oder UX-seitig untragbar ist, muss die Einschränkung explizit dokumentiert werden statt stillschweigend komplizierte Alternativpfade zu bauen.

### Konkrete MVP-Interpretation

- **Primärpfad**: Pasteboard schreiben, `Cmd+V` auslösen, Fokus nicht stehlen.
- **Nicht im ersten Schritt**: zweiter Injektionsmechanismus, generische Mehrfachstrategie, breite Editor-spezifische Sonderlogik.
- **Optional spätere Ergänzung nach Validierung**: direkte Accessibility-Manipulation nur als gezielter Fallback für ausgewählte Fälle, nicht als frühe Parallelarchitektur.

## 6. Frühe Validierung

Vor grösserer Implementierung sollte nur der schmalste technische Beweis geführt werden.

### Minimal zu prüfende Testkontexte

1. Ein nativer Standard-Editor auf macOS, zum Beispiel TextEdit.
2. Ein Browser-Textarea oder ein sehr einfacher Web-Editor in Safari oder Chrome.
3. Ein dritter, praxisnäherer Editor-Kontext mit normalem Paste-Verhalten, falls lokal verfügbar.
4. Ein expliziter Negativfall, zum Beispiel Passwortfeld oder Terminal, um Grenzen sauber zu beobachten statt versehentlich als Support zu interpretieren.

### Verhalten, das als ausreichend robust gelten sollte

- Ein definierter Plain-Text-Teststring wird an der Caret-Position eingefügt oder ersetzt die aktuelle Selektion.
- Keine UI von PushWrite übernimmt beim Einfügen den Fokus.
- Der Text erscheint genau einmal.
- Satzzeichen und Nicht-ASCII-Zeichen des gewählten Teststrings bleiben erhalten.
- Fehlschläge sind technisch erkennbar, zum Beispiel über Timeout, fehlenden Focus-Context oder expliziten Permission-Status.

### Sinnvolle Validierungsgrenze

Für die erste technische Validierung reicht kein subjektiver "hat einmal funktioniert"-Nachweis. Tragfähig wäre zum Beispiel:

- 20 wiederholte Inserts in einem nativen Standard-Editor ohne Fehleinfügung
- 20 wiederholte Inserts in einem Browser-Textarea ohne Fehleinfügung
- dokumentierte Beobachtung in einem problematischeren Drittkontext

### Kill-Kriterien

- Der Paste-Pfad scheitert bereits in nativen Standard-Textfeldern oder einfachen Browser-Textareas nicht nur sporadisch, sondern reproduzierbar.
- PushWrite verliert beim Einfügen regelmässig den Fokus und kann den Zielkontext dadurch nicht stabil halten.
- Clipboard-Restore erzeugt in der Zielkonfiguration so starke Friktion oder so unzuverlässiges Verhalten, dass der Kernnutzen praktisch entwertet wird.
- Synthetisches `Cmd+V` ist mit den benötigten macOS-Rechten nicht kontrollierbar ausführbar.

## 7. Vorschlag für Folgeauftrag

### Folgeauftrag 002A: Technische Validierung des Paste-basierten Einfügepfads

Erstelle einen eng geschnittenen macOS-Validierungsspike für den `TextInsertionController` von PushWrite v0.1.0 mit ausschliesslich folgendem Scope:

- fester Teststring statt echter Transkription
- Plain-Text-Schreiben auf die General Pasteboard
- synthetisches `Cmd+V` in den aktuellen Fokuskontext
- Permission-Check für den dafür nötigen Systemzugriff
- Logging von Start, Zielkontext, Erfolg, Fehlschlag und Fehlerursache
- keine Audioaufnahme
- keine `whisper.cpp`-Integration
- keine UI-Ausarbeitung ausser minimal notwendigem Trigger
- keine zweite Textinjektionsstrategie

### Akzeptanzkriterien für den Folgeauftrag

- Der Spike kann in mindestens einem nativen Textfeld und einem Browser-Textarea reproduzierbar Text einfügen.
- Der Spike erkennt fehlende Berechtigungen explizit.
- Der Spike dokumentiert, ob der Clipboard-Inhalt erhalten oder überschrieben wurde.
- Der Spike hält beobachtete Grenzen und Fehlerszenarien in kurzer Form fest.

## Quellen

- Apple Developer Documentation: `AXIsProcessTrustedWithOptions`  
  <https://developer.apple.com/documentation/applicationservices/1460720-axisprocesstrustedwithoptions>
- Apple Developer Documentation: `AXUIElementCopyAttributeValue`  
  <https://developer.apple.com/documentation/applicationservices/1462085-axuielementcopyattributevalue>
- Apple Developer Documentation: `NSAccessibility.Attribute.selectedTextRange`  
  <https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct/attribute/selectedtextrange>
- Apple Developer Documentation: `NSPasteboard`  
  <https://developer.apple.com/documentation/appkit/nspasteboard>
- Apple Developer Documentation: `NSPasteboard.AccessBehavior.default`  
  <https://developer.apple.com/documentation/appkit/nspasteboard/accessbehavior-swift.enum/default>
- Apple Developer Documentation: `NSPasteboardContentsOptions`  
  <https://developer.apple.com/documentation/appkit/nspasteboard/contentsoptions>
- Apple Developer Documentation: `IMKServer`  
  <https://developer.apple.com/documentation/inputmethodkit/imkserver>
- Apple Developer Documentation: `IMKInputController`  
  <https://developer.apple.com/documentation/inputmethodkit/imkinputcontroller>
- Verifiziert gegen öffentliche macOS-SDK-Header: `ApplicationServices/HIServices/AXUIElement.h`, `ApplicationServices/HIServices/AXAttributeConstants.h`, `CoreGraphics/CGEvent.h`, `AppKit/NSPasteboard.h`, `InputMethodKit/IMKServer.h`, `InputMethodKit/IMKInputController.h`
