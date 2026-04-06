# 002B Results: Focus-Stable Paste Harness

## Ziel und Scope

Dieser Spike validiert ausschliesslich den Paste-basierten Erstpfad fuer PushWrite v0.1.0 unter fokusstabilen Bedingungen:

1. Plain-Text auf das macOS General Pasteboard schreiben
2. synthetisches `Cmd+V` in den aktuellen Fokuskontext senden
3. den Einfuegevorgang aus einem minimalen macOS-App-Harness ausloesen, der selbst keinen Fensterfokus uebernimmt

Nicht betrachtet wurden Produkt-UI, Hotkey-Integration, Audio, alternative Injektionspfade oder breite App-Abdeckung.

## Erstellte Artefakte

- `app/macos/FocusStablePasteHarness/main.swift`
- `app/macos/FocusStablePasteHarness/Info.plist`
- `scripts/build_focus_stable_paste_harness.sh`
- `scripts/run_focus_stable_paste_validation.swift`
- `build/focus-stable-paste-harness/FocusStablePasteHarness.app`
- `docs/execution/002B-results-focus-stable-paste-harness.json`
- dieses Ergebnisdokument

## Testaufbau

### Harness

- Agent-App mit `LSUIElement`, ohne sichtbares Hauptfenster
- Bundle Identifier: `ch.baumanncreative.pushwrite.FocusStablePasteHarness`
- gleiche Einfuegelogik wie in 002A: General Pasteboard plus synthetisches `Cmd+V`
- Messpunkte pro Run:
  - Front-App und Fokuskontext beim Start
  - Fokuskontext direkt vor dem Paste
  - Fokuskontext direkt nach dem Paste
  - ob der Harness selbst jemals frontmost wurde

### Testpayload

`PushWrite 002B test äöü ß €.`

### Testkontexte

- TextEdit mit leerem Dokument
- Safari mit lokaler Browser-Textarea-Fixture

### Laufparameter

- `settleDelayMs=150`
- `pasteDelayMs=120`
- `restoreDelayMs=350`
- 20 Wiederholungen pro Zielkontext

### Testdatum

- 2026-04-05

## Beobachtungen

### 1. Accessibility-Preflight

- Der Harness meldete im finalen Testlauf `accessibilityTrusted=true`.
- Der Harness war weder beim Eintritt noch direkt vor dem Paste frontmost.
- Fehlende Accessibility-Rechte blockieren den Testlauf vollstaendig vor dem ersten Paste.
- Apple Events fuer TextEdit und Safari wurden nur fuer Testvorbereitung und Ruecklese verwendet.
- Safari-`do JavaScript` war in der lokalen Umgebung nicht freigegeben. Die Browser-Verifikation wurde deshalb bewusst auf URL-/Hash-basierte Ruecklese der Fixture umgestellt. Das betrifft den Testaufbau, nicht den Paste-Mechanismus selbst.

### 2. TextEdit

- 20 von 20 Wiederholungen waren erfolgreich.
- In 20 von 20 Runs war direkt vor dem Paste `TextEdit` die Front-App.
- In 20 von 20 Runs war direkt nach dem Paste weiter `TextEdit` die Front-App.
- In 20 von 20 Runs wurde der Fokus als `AXTextArea` erkannt.
- In 20 von 20 Runs wurde der Payload exakt eingefuegt.
- Der Harness wurde in 0 von 20 Runs frontmost.

### 3. Browser-Textarea in Safari

- 20 von 20 Wiederholungen waren erfolgreich.
- In 20 von 20 Runs war direkt vor dem Paste `Safari` die Front-App.
- In 20 von 20 Runs war direkt nach dem Paste weiter `Safari` die Front-App.
- In 20 von 20 Runs wurde der Fokus als `AXTextArea` erkannt.
- In 20 von 20 Runs wurde der Payload exakt in die Fixture uebernommen.
- Der Harness wurde in 0 von 20 Runs frontmost.

### 4. Clipboard-Restore

- Plain-Text-Probe:
  - erfolgreich
  - eingefuegter Text korrekt
  - vor und nach dem Run genau ein Pasteboard-Item
  - Typ blieb `public.utf8-plain-text`
- Nicht-triviale Probe:
  - erfolgreich
  - eingefuegter Text korrekt
  - vor und nach dem Run genau ein Pasteboard-Item
  - Typen vor und nach dem Restore identisch:
    - `public.html`
    - `public.rtf`
    - `public.utf16-external-plain-text`
    - `public.utf8-plain-text`

## Interpretation

- Das Fokusproblem aus 002A trat im fokusstabilen App-Harness nicht mehr auf.
- Der dominante Fehlschlagstreiber aus 002A war damit in diesem Test klar ein Harness-/Fokusproblem und kein grundsaetzlicher Schwachpunkt des Paste-Ansatzes.
- Der Pfad `Pasteboard -> synthetisches Cmd+V` war in beiden Pflichtkontexten unter fokusstabilen Bedingungen voll reproduzierbar.
- Clipboard-Restore blieb auch fuer einen realistischeren, mehrformatigen Clipboard-Inhalt stabil.

## MVP-Einordnung

**Tragfaehig als erster MVP-Pfad.**

Begruendung:

- 40 von 40 Pflicht-Runs waren erfolgreich.
- Es trat kein beobachteter Fokusverlust durch den nativen Harness auf.
- TextEdit und Browser-Textarea verhalten sich im getesteten Scope stabil.
- Clipboard-Restore funktioniert fuer einfachen Plain Text und fuer einen mehrformatigen Inhalt.

Die verbleibenden Einschraenkungen liegen primär bei macOS-Rechten und sauberem Lifecycle des konkreten App-Bundles, nicht beim Paste-Pfad selbst.

## Konkrete Folgeempfehlung

### Folgeauftrag 002C

Ueberfuehre denselben Paste-Pfad in einen minimalen produktnahen Hintergrund-Agent fuer PushWrite v0.1.0 mit folgendem engen Scope:

1. expliziter Accessibility-Preflight mit klarer Nutzerfuehrung
2. reuse des fokusstabilen Agent-App-Musters ohne sichtbares Hauptfenster
3. derselbe Insert-Pfad: Plain-Text-Pasteboard plus synthetisches `Cmd+V`
4. definierte Regeln, dass der Agent selbst keinen Fokus uebernimmt
5. ein kleiner Regressionstest fuer TextEdit und Browser-Textarea auf Basis des 002B-Harness

## Offene Punkte

- Validiert wurden nur TextEdit und eine Safari-Textarea-Fixture.
- Nicht validiert wurden Passwortfelder, geschuetzte Eingaben, Terminale, Canvas-Editoren oder Remote-Sessions.
- Die Accessibility-Freigabe haengt an der konkreten App-Datei. Ein Rebuild derselben `.app` kann in der Praxis eine erneute Freigabe noetig machen.
