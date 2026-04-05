# 002A Results: Pasteboard plus Cmd+V

## Ziel und Scope

Dieser Spike validiert ausschliesslich den empfohlenen Erstpfad für PushWrite v0.1.0:

1. Plain-Text auf das macOS General Pasteboard schreiben
2. synthetisches `Cmd+V` in den aktiven Texteingabekontext senden

Nicht betrachtet wurden Audio, Hotkey-Produktintegration, alternative Injektionspfade oder breite App-Unterstützung.

## Erstellte Artefakte

- `scripts/validate_text_insertion_paste_cmd_v.swift`
- `tests/integration/browser-textarea-fixture.html`
- dieses Ergebnisdokument

## Testaufbau

### Testpayload

`PushWrite 002A test äöü ß €.`

### Testkontexte

- TextEdit mit neuem leerem Dokument
- Safari mit lokaler Fixture-Seite und einfachem `<textarea>`

### Testdatum

- 2026-04-05

## Beobachtungen

### 1. Berechtigungen und Systemhürden

- Der Spike konnte synthetisches `Cmd+V` nur ausfuehren, wenn er ausserhalb der Codex-Sandbox lief.
- Innerhalb der Sandbox meldete derselbe Binary-Stand `accessibilityTrusted=false`.
- Ausserhalb der Sandbox meldete derselbe Binary-Stand `accessibilityTrusted=true` und konnte `Cmd+V` posten.
- Fuer die eigentliche Paste-Validierung ist Accessibility zwingend.
- Zusaetzliche AppleScript-Automation fuer TextEdit und Safari war nur fuer die Testvorbereitung und die Ruecklese der Ergebnisse noetig, nicht fuer den Paste-Mechanismus selbst.

### 2. TextEdit

- 5 von 5 Wiederholungen waren erfolgreich.
- In allen erfolgreichen Runs blieb die Front-App vor und nach dem Paste `TextEdit`.
- Der Text wurde jedes Mal exakt als `PushWrite 002A test äöü ß €.` eingefuegt.
- Der aktive Fokus wurde im Spike als `AXTextArea` erkannt.
- Die Accessibility-Ruecklese des fokussierten Werts blieb in TextEdit trotz erfolgreichem Paste leer. Fuer diesen Kontext war die Dokument-Ruecklese per AppleScript der verlaesslichere Verifikationsweg.

### 3. Browser-Textarea in Safari

- 4 von 5 Wiederholungen waren erfolgreich.
- In den erfolgreichen Runs schrieb die Fixture-Seite den Payload korrekt in den URL-Hash:
  `#PushWrite%20002A%20test%20%C3%A4%C3%B6%C3%BC%20%C3%9F%20%E2%82%AC.`
- In erfolgreichen Runs blieb die Front-App `Safari`; nach dem Paste wurde der Fokus als `AXTextArea` erkannt.
- Ein Run schlug fehl, weil unmittelbar vor dem Paste nicht `Safari`, sondern `Codex` die Front-App war.
- Der Fehlschlag war damit kein Zeichen fuer falsches Paste-Verhalten im Textarea selbst, sondern fuer Fokus-Verlust kurz vor dem synthetischen `Cmd+V`.

### 4. Clipboard-Verhalten

- Ohne Restore wird das General Pasteboard erwartungsgemaess vom einzufuegenden Text ueberschrieben.
- Mit aktiviertem `--restore-clipboard` blieb die Einfuegung in TextEdit korrekt und ein zuvor gesetzter Plain-Text-Clipboard-Inhalt (`ORIGINAL_CLIPBOARD_002A`) wurde wiederhergestellt.
- Der Restore wurde in diesem Spike nur mit einem einfachen Plain-Text-Clipboard-Inhalt geprueft.
- Es wurde nicht validiert, wie sich Restore bei komplexeren Clipboard-Inhalten oder bei sehr schneller Folge mehrerer Inserts verhaelt.

## Bewertung

### Technische Einordnung

- Der Mechanismus `Pasteboard -> synthetisches Cmd+V` funktioniert in beiden Pflichtkontexten grundsaetzlich.
- Der Browser-Fall zeigt jedoch, dass der Ansatz nur dann verlaesslich ist, wenn PushWrite den Ziel-Fokus vor dem Paste wirklich haelt und selbst keinen Fokus zurueckholt.
- Die dominante praktische Huerde ist damit nicht das Paste selbst, sondern Fokus-Stabilitaet plus saubere Berechtigungsfuehrung.

### MVP-Einordnung

**Nur eingeschraenkt tragfaehig.**

Begruendung:

- Positiv: TextEdit ist im Spike stabil, Safari-Textarea funktioniert grundsaetzlich, Clipboard-Restore ist technisch moeglich.
- Einschraenkung: Im Browser-Kontext trat ein reproduzierbarer Fehlschlag auf, sobald der Fokus vor dem Paste wegrutschte.
- Konsequenz: Der Ansatz bleibt der beste Erstpfad fuer v0.1.0, ist aber noch nicht robust genug, um ohne Fokus-Haertung als belastbarer MVP-Pfad zu gelten.

## Konkrete Folgeempfehlung

### Folgeauftrag 002B

Validiere denselben Paste-basierten Pfad in einem minimalen, fokus-stabilen macOS-App-Harness mit folgendem engen Scope:

1. Accessibility-Preflight und klare Fehlerausgabe vor dem Insert
2. Insert aus einem App-Kontext, der selbst keinen Window-Fokus uebernimmt
3. derselbe Einfuegepfad: Plain-Text-Pasteboard plus synthetisches `Cmd+V`
4. Wiederholungstest mit mindestens 20 Runs in TextEdit und 20 Runs im Browser-Textarea
5. Clipboard-Restore erneut pruefen, diesmal mindestens fuer Plain Text und einen zweiten nicht-trivialen Clipboard-Inhalt

### Ziel des Folgeauftrags

Klaeren, ob der beobachtete Browser-Fehlschlag hauptsaechlich ein Codex-/Harness-Fokusproblem war oder ein echter Produkt-Risikoindikator fuer PushWrite v0.1.0 bleibt.
