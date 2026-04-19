# 006A Results: Stable-Bundle-/LaunchServices-Revalidierung fuer 006

## Status
- umgesetzt
- QA-Revalidierung fuer 006 im primaeren Pfad erreicht (Stable-Bundle + LaunchServices + CDHash)
- zusaetzlicher Befund: `open`-CLI auf demselben Bundle bleibt mit `kLSNoExecutableErr` (`Code=-10827`) fehlerhaft

## Kurzfassung
- Der Stable-Bundle-Istzustand wurde neu aufgenommen (Bundle/Executable/Info.plist/Codesign/CDHash).
- Der dokumentierte Fehler wurde reproduziert: `open -n <PushWrite.app> --args ...` liefert weiterhin `kLSNoExecutableErr` (`Code=-10827`).
- Der LaunchServices-Start wurde alternativ ueber die LaunchServices-API (`NSWorkspace.openApplication`) auf demselben Stable-Bundle erfolgreich ausgefuehrt.
- Ueber diesen gueltigen LS-Startpfad wurden zwei 006-relevante Produktfaelle nachgewiesen:
  - Erfolgsfall: `transcriptionInsertGate=passed`, `insert-succeeded`, kein `local-feedback-triggered`.
  - Negativer Fall (Gate): `transcriptionInsertGate=transcriptionSkipped`, `localUserFeedback=blockedPanel`, `local-feedback-triggered` vorhanden.
- Keine Produktlogik, kein Bundle-Inhalt und kein Packaging-Code wurden geaendert.

## Geaenderte Dateien
- `/Users/michel/Code/pushwrite/docs/execution/006A-results-stable-bundle-launchservices-revalidation.md`

## Stable-Bundle-Befund (Ist-Zustand)
- Stable-Bundle-Pfad:
  - `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
- Executable im Bundle:
  - `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app/Contents/MacOS/PushWrite`
- Relevante Bundle-Keys:
  - `CFBundleExecutable=PushWrite`
  - `CFBundleIdentifier=ch.baumanncreative.pushwrite`
  - `LSUIElement=true`
- Codesign/CDHash:
  - `CDHash=00b1aaa0b4a2017a9bb9892df95a2a1417956f20`
  - `Signature=adhoc`
  - `codesign --verify --deep --strict --verbose=4` meldete: `valid on disk`, `satisfies its Designated Requirement`

## LaunchServices-Revalidierung

### Primaer (gueltig): Stable-Bundle + LaunchServices + CDHash
- Bundle: `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
- CDHash: `00b1aaa0b4a2017a9bb9892df95a2a1417956f20`
- LaunchServices-Start (API-basiert, erfolgreich):
  - `swift -e '... NSWorkspace.shared.openApplication(at: appURL, configuration: cfg) ...'`
  - Konfiguration enthielt u.a.:
    - `--runtime-dir <runtime>`
    - `--force-accessibility-trusted`
    - `--force-microphone-permission-status granted`
    - `--force-microphone-request-result granted`
    - `--simulated-transcription-text <text>`
- Ergebnis:
  - Launch erfolgreich (`ok`), `product-state.json` mit `running=true`, `hotKey.registered=true`.

### Zusaetzlicher LaunchServices-Befund (weiterhin fehlerhaft)
- Exakter `open`-Befehl:
  - `open -n /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --args --runtime-dir /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-006A-ls-open-attempt --force-accessibility-trusted --force-microphone-permission-status granted --force-microphone-request-result granted --simulated-transcription-text 'PushWrite 006A LS open attempt.'`
- Ergebnis:
  - Fehler unveraendert: `Error Domain=NSOSStatusErrorDomain Code=-10827 "kLSNoExecutableErr: The executable is missing"`
- Eingrenzung:
  - Bundle und Executable sind vorhanden und ausfuehrbar.
  - CDHash/Codesign-Befund ist konsistent.
  - Der Fehler ist in dieser Session auf den `open`-CLI-Pfad reproduzierbar; der LS-API-Pfad startet dasselbe Bundle erfolgreich.

## 006-Faelle ueber gueltigen Pfad bewertet

### Fall A: Erfolgsfall (Insert gelingt, stumm)
- Runtime:
  - `/Users/michel/Code/pushwrite/build/pushwrite-product/runtime-006A-ls-success`
- Flow-ID:
  - `631C88FA-B285-4E4D-9308-A29C172B6251`
- Befund (Artefakte):
  - `logs/last-hotkey-response.json`:
    - `status=succeeded`
    - `transcriptionInsertGate=passed`
    - `textLength=14`
    - kein `localUserFeedback`-Feld gesetzt
  - `logs/last-insert-result.json`:
    - `status=succeeded`
    - `gate=passed`
    - `insertAttempted=true`
    - `insertedTextLength=14`
  - `logs/hotkey-recording-prototype.jsonl`:
    - `recording-stopped` mit `durationMs=833`
    - `transcription-succeeded`
    - `insert-succeeded`
    - `local-feedback-evaluated` mit `feedbackCase=none`
    - kein `local-feedback-triggered` fuer diese Flow-ID

### Fall B: Negativer Fall (Gate: too short)
- Runtime:
  - `/Users/michel/Code/pushwrite/build/pushwrite-product/runtime-006A-ls-gate-short`
- Flow-ID:
  - `CD8B3C8F-27B4-4160-815C-54B59E9FDDFC`
- Befund (Artefakte):
  - `logs/last-hotkey-response.json`:
    - `status=succeeded`
    - `transcriptionInsertGate=transcriptionSkipped`
    - `localUserFeedback=blockedPanel`
    - `textLength=0`
  - `logs/last-insert-result.json`:
    - `status=gated`
    - `gate=transcriptionSkipped`
    - `insertAttempted=false`
  - `logs/hotkey-recording-prototype.jsonl`:
    - `recording-stopped` mit `durationMs=39`
    - `transcription-skipped` (`reason=tooShortRecording`)
    - `local-feedback-evaluated` (`feedbackCase=tooShortRecording`)
    - `local-feedback-triggered` (`channel=blockedPanel`)

## Primaer vs. Sekundaer

### Primaer (gueltig)
- Stable-Bundle: `/Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
- LaunchServices: erfolgreich ueber `NSWorkspace.openApplication`
- CDHash dokumentiert: `00b1aaa0b4a2017a9bb9892df95a2a1417956f20`
- 006-Faelle (Erfolg + negativer Gate-Fall) ueber diesen Pfad bewertet

### Sekundaer (Debug)
- Reproduktion des dokumentierten `open`-CLI-Fehlers `-10827`
- Keine Direkt-/Control-Starts als Ersatz fuer den gueltigen Primarbefund verwendet

## Nicht umgesetzt
- Keine Aenderung an Produktlogik (Hotkey/Insert/Feedback)
- Keine neue UI/Architektur
- Keine Bundle-/Packaging-Codeaenderung
- Kein broad Refactor

## Bekannte Risiken / Annahmen
- Der `open`-CLI-Pfad ist weiterhin fehlerhaft (`kLSNoExecutableErr`), obwohl derselbe Bundle-Stand ueber die LS-API startet.
- Die Revalidierung stuetzt sich deshalb auf den erfolgreichen LaunchServices-API-Pfad als primaeren gueltigen LS-Nachweis.
- Ursache fuer die `open`-CLI-inkonsistenz ist eingegrenzt, aber in 006A bewusst nicht per groesserem Umbau adressiert.

## Testhinweise
1. Bundle-/Signatur-Check:
   - `plutil -p /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app/Contents/Info.plist`
   - `/usr/bin/codesign -dv --verbose=4 /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app`
2. `open`-Fehler reproduzieren:
   - `open -n /Users/michel/Code/pushwrite/build/pushwrite-product/PushWrite.app --args --runtime-dir /Users/michel/Code/pushwrite/build/pushwrite-product/runtime-006A-ls-open-attempt --force-accessibility-trusted --force-microphone-permission-status granted --force-microphone-request-result granted --simulated-transcription-text 'PushWrite 006A LS open attempt.'`
3. Gueltiger LS-Start (API) und 006-Faelle:
   - LS-Start ueber `NSWorkspace.openApplication` mit `--runtime-dir` und den oben dokumentierten Args.
   - Erfolgsfall-Artefakte: `runtime-006A-ls-success/logs/*`
   - Negativfall-Artefakte: `runtime-006A-ls-gate-short/logs/*`

## Rollback
- Reine Doku-Aenderung:
  - `git restore /Users/michel/Code/pushwrite/docs/execution/006A-results-stable-bundle-launchservices-revalidation.md`
