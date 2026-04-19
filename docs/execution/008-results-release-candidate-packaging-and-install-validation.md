# 008 Results: Release-Candidate-Packaging und Installationsvalidierung

## Status
- umgesetzt
- Release-Candidate-Build, Release-Artefakt und minimale Installationsvalidierung liegen vor

## Kurzfassung
- Fuer MVP `0.1.0` wurde ein reproduzierbarer RC-Stand `PushWrite-v0.1.0-rc1` gebaut und als ZIP-Artefakt verpackt.
- Das RC-Bundle enthaelt den erwarteten Executable, gebundeltes `whisper-cli` und gebundeltes Minimalmodell `ggml-tiny.bin`.
- Installationsvalidierung wurde am entpackten Artefakt durchgefuehrt: Bundle-/Ressourcenpruefung, LS-Startprobe, ein Erfolgsfall, ein negativer Fall.
- Primaerer Startpfad bleibt klar getrennt dokumentiert: LaunchServices-API (`NSWorkspace.openApplication`) fuer Produktstartnachweis.

## Geaenderte Dateien
- `/Users/michel/Code/pushwrite/scripts/build_pushwrite_release_candidate.sh`
- `/Users/michel/Code/pushwrite/scripts/validate_pushwrite_release_candidate_install.sh`
- `/Users/michel/Code/pushwrite/scripts/run_pushwrite_hotkey_validation.swift`
- `/Users/michel/Code/pushwrite/docs/execution/008-results-release-candidate-packaging-and-install-validation.md`
- `/Users/michel/Code/pushwrite/docs/testing/008-external-test-instructions.md`

## Release-Candidate-Artefakte
- RC-Name:
  - `PushWrite-v0.1.0-rc1`
- RC-Bundle:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite.app`
- Weitergebbares Artefakt:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-macos.zip`
- Installations-Entpackpfad (validiert):
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/install-qa/PushWrite.app`
- Artefaktgroesse:
  - `70381938` Bytes
- Artefakt-SHA256:
  - `a4ee2c79e8106280f91fa04e2270c8051541fe580c36b6bf71fb14e2bde782ee`

## Bundle- und Ressourcenpruefung
- Bundle-Identifier:
  - `ch.baumanncreative.pushwrite`
- Bundle-Executable:
  - `PushWrite`
- Executable-Pfad:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite.app/Contents/MacOS/PushWrite`
- Gebundeltes CLI:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite.app/Contents/Resources/whisper/bin/whisper-cli`
- Gebundeltes Modell:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite.app/Contents/Resources/whisper/models/ggml-tiny.bin`
- Codesign-/CDHash-Befund:
  - `CDHash=a1cb07ec18b4383f7dd83d5ed6be68b0ebf37043`
  - `codesign --verify --deep --strict --verbose=4`: `valid on disk`, `satisfies its Designated Requirement`
- Identity-Report:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-identity.txt`

## Primaer vs. Sekundaer

### Primaer (gueltig)
- LaunchServices-API-Startpfad:
  - `NSWorkspace.openApplication` (ausgefuehrt ueber `/Users/michel/Code/pushwrite/scripts/run_pushwrite_hotkey_validation.sh`)
- Probe:
  - Exit-Code `0`
  - State-Datei vorhanden: `/private/tmp/pushwrite-008-rc1-validation/ls-probe/product-state.json`
  - Bundle-ID im State: `ch.baumanncreative.pushwrite`

### Sekundaer (Debug/Steuerung)
- Produkt-Control fuer deterministische Fallpruefung:
  - `/Users/michel/Code/pushwrite/scripts/control_pushwrite_product.sh`
- Eingesetzt fuer dokumentierten Erfolgs- und Negativfall auf dem installierten RC-Bundle
- Kein Ersatz fuer den primaeren LS-Startnachweis

## Installationsvalidierung (durchgefuehrt)
- Validierungsskript:
  - `/Users/michel/Code/pushwrite/scripts/validate_pushwrite_release_candidate_install.sh`
- Zusammenfassung:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-install-validation.txt`

### Validierter Erfolgsfall
- App:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/install-qa/PushWrite.app`
- Runtime:
  - `/private/tmp/pushwrite-008-rc1-validation/success`
- Anfrage:
  - `insert-transcription`
- Ergebnisdatei:
  - `/private/tmp/pushwrite-008-rc1-validation/success/validation-success-response.json`
- Befund:
  - `status=succeeded`
  - `insertRoute=pasteboardCommandV`
  - `insertSource=transcription`
  - `syntheticPastePosted=true`

### Validierter negativer Fall
- App:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/install-qa/PushWrite.app`
- Runtime:
  - `/private/tmp/pushwrite-008-rc1-validation/blocked`
- Anfrage:
  - `preflight` unter `--force-accessibility-blocked`
- Ergebnisdatei:
  - `/private/tmp/pushwrite-008-rc1-validation/blocked/validation-blocked-response.json`
- Befund:
  - `status=blocked`
  - `blockedReason=Accessibility access is required before PushWrite can insert text with synthetic Cmd+V.`

## Externe Testanleitung
- `/Users/michel/Code/pushwrite/docs/testing/008-external-test-instructions.md`

## Nicht umgesetzt (bewusst)
- DMG-Design
- `.pkg`-Installer
- Notarisierung / App-Store / Vertriebsarchitektur
- Auto-Update / Sparkle
- GitHub-Release-Automatisierung
- neue Produktlogik (Transkription, Insert, Feedback, Mehrmodell)

## Bekannte Risiken / Annahmen
- Die LS-Probe lief in dieser Session mit produktiver GUI-Ausfuehrung ausserhalb der Sandbox stabil.
- Accessibility-Zustand ist weiterhin maschinen- und bundle-pfadabhaengig.
- Der RC-Installationsnachweis deckt MVP-Packaging und Mindestfunktion ab, nicht Distribution-Hardening (Notarisierung/Gatekeeper-Distribution).

## Testhinweise
1. RC bauen und verpacken:
   - `./scripts/build_pushwrite_release_candidate.sh --rc rc1`
2. Metadaten lesen:
   - `cat /Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-metadata.txt`
3. Installationsvalidierung:
   - `./scripts/validate_pushwrite_release_candidate_install.sh --artifact-zip /Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-macos.zip --install-root /Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/install-qa --runtime-root /tmp/pushwrite-008-rc1-validation --results-file /Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-install-validation.txt`
4. LS-Probe-Details:
   - `/private/tmp/pushwrite-008-rc1-validation/ls-probe-summary.json`
5. Erfolgsfall-Response:
   - `/private/tmp/pushwrite-008-rc1-validation/success/validation-success-response.json`
6. Negativfall-Response:
   - `/private/tmp/pushwrite-008-rc1-validation/blocked/validation-blocked-response.json`

## Rollback
- Skript-/Doku-Rollback auf Git-Ebene:
  - `git restore /Users/michel/Code/pushwrite/scripts/build_pushwrite_release_candidate.sh /Users/michel/Code/pushwrite/scripts/validate_pushwrite_release_candidate_install.sh /Users/michel/Code/pushwrite/scripts/run_pushwrite_hotkey_validation.swift /Users/michel/Code/pushwrite/docs/execution/008-results-release-candidate-packaging-and-install-validation.md /Users/michel/Code/pushwrite/docs/testing/008-external-test-instructions.md`
- Build-Artefakte entfernen:
  - `rm -rf /Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1`
- Runtime-Artefakte entfernen:
  - `rm -rf /private/tmp/pushwrite-008-rc1-validation`
