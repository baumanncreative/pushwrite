# 009 Results: Externe Distribution und Erstinstallationshaertung

## Status
- umgesetzt
- externer Erstinstallationsschnitt fuer RC `PushWrite-v0.1.0-rc1` dokumentiert und mit frischer 009-Validierung belegt

## Kurzfassung
- Die externe Erstinstallationsfuehrung wurde als kurze, direkt weitergebbare Checkliste neu angelegt.
- Die distributionsnahe RC-Info (Name, Artefakt, Bundle-ID, Version, CDHash, SHA256, gebundelte Whisper-Ressourcen, primaerer Startpfad, Distributionsgrenzen) ist fuer 009 eindeutig dokumentiert.
- Eine schlanke technische Erstinstallationsvalidierung wurde mit bestehendem Validierungsskript erneut durchgefuehrt (entpacktes ZIP, `.app`, Bundle-/Ressourcenvollstaendigkeit, produktnaher Erststart, Erfolgsfall, Negativfall).
- Primaerer Produktpfad und sekundaere Debugpfade sind fuer externe Tests klar getrennt.

## Geaenderte Dateien
- `/Users/michel/Code/pushwrite/docs/execution/009-results-external-distribution-and-first-install-hardening.md`
- `/Users/michel/Code/pushwrite/docs/testing/009-external-first-install-checklist.md`

## Kleine Release-/Distributions-Info (RC Snapshot)
- RC-Name:
  - `PushWrite-v0.1.0-rc1`
- Artefaktname:
  - `PushWrite-v0.1.0-rc1-macos.zip`
- RC-Bundle:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite.app`
- ZIP-Artefakt:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-macos.zip`
- Bundle-Identifier:
  - `ch.baumanncreative.pushwrite`
- Version / RC-Kennung:
  - `0.1.0 / rc1`
- CDHash:
  - `a1cb07ec18b4383f7dd83d5ed6be68b0ebf37043`
- SHA256 (ZIP):
  - `a4ee2c79e8106280f91fa04e2270c8051541fe580c36b6bf71fb14e2bde782ee`
- Gebundeltes Modell:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite.app/Contents/Resources/whisper/models/ggml-tiny.bin`
- Gebundelter whisper-CLI-Pfad:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite.app/Contents/Resources/whisper/bin/whisper-cli`
- Primaerer gueltiger Produktstartpfad:
  - LaunchServices-API `NSWorkspace.openApplication`
  - Technisch ausgefuehrt ueber `/Users/michel/Code/pushwrite/scripts/run_pushwrite_hotkey_validation.sh`
  - 009-Probe auf installiertem RC-App-Pfad: `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/install-qa-009/PushWrite.app`
- Referenzdatei des RC-Snapshots:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-metadata.txt`

## Externe Erstinstallations-Checkliste
- `/Users/michel/Code/pushwrite/docs/testing/009-external-first-install-checklist.md`

## Technische Erstinstallationsvalidierung (009)
- Validierungsskript (bestehend, wiederverwendet):
  - `/Users/michel/Code/pushwrite/scripts/validate_pushwrite_release_candidate_install.sh`
- 009-Validierungsergebnisdatei:
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-first-install-validation-009.txt`
- Installations-Entpackpfad (009):
  - `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/install-qa-009/PushWrite.app`
- Runtime-Root (009):
  - `/private/tmp/pushwrite-009-rc1-validation`

### Validierter Erfolgsfall
- Runtime:
  - `/private/tmp/pushwrite-009-rc1-validation/success`
- Response-Datei:
  - `/private/tmp/pushwrite-009-rc1-validation/success/validation-success-response.json`
- Befund:
  - `status=succeeded`
  - `insertRoute=pasteboardCommandV`
  - `insertSource=transcription`
  - `syntheticPastePosted=true`

### Validierter Negativfall
- Runtime:
  - `/private/tmp/pushwrite-009-rc1-validation/blocked`
- Response-Datei:
  - `/private/tmp/pushwrite-009-rc1-validation/blocked/validation-blocked-response.json`
- Befund:
  - `status=blocked`
  - `blockedReason=Accessibility access is required before PushWrite can insert text with synthetic Cmd+V.`

## Primaer vs. Sekundaer (verbindlich getrennt)

### Primaer (gueltig)
- RC-Bundle und RC-ZIP aus `build/release-candidates/PushWrite-v0.1.0-rc1`
- Produktnaher Start ueber LaunchServices-API (`NSWorkspace.openApplication`)
- Dokumentierter CDHash `a1cb07ec18b4383f7dd83d5ed6be68b0ebf37043`
- Produktnah dokumentierter Erfolgsfall und Negativfall aus 009-Validierung

### Sekundaer (Debug)
- Control-/Direktsteuerung ueber `/Users/michel/Code/pushwrite/scripts/control_pushwrite_product.sh`
- Runtime-Overrides und manuelle Diagnosepfade
- Kein Ersatz fuer den primaeren externen Produktnachweis

## Definierte Problemrueckmeldung fuer externe Tester
Folgende Angaben sind in der Checkliste als Pflicht rueckzumelden:
- macOS-Version
- verwendeter RC-Name (`PushWrite-v0.1.0-rc1`)
- ob ZIP entpackt werden konnte
- ob `PushWrite.app` gestartet werden konnte
- ob Mikrofonberechtigung erteilt wurde
- ob Accessibility-Berechtigung erteilt wurde
- beobachteter Erfolgs- oder Fehlerfall
- relevante Runtime-Datei(en)/Pfade, falls vorhanden
  - `~/Library/Application Support/PushWrite/runtime/product-state.json`
  - `~/Library/Application Support/PushWrite/runtime/logs/last-hotkey-response.json`
  - `~/Library/Application Support/PushWrite/runtime/logs/events.jsonl`
- Screenshot nur bei echtem Erklaerungswert

## Dokumentierte Distributionsgrenzen
- kein notarisiertes Distributionsprodukt
- kein finaler Installer (`.pkg`)
- kein DMG-Installationsdesign
- kein Auto-Update
- RC fuer kontrollierte externe Tests, nicht fuer breite Endnutzerverteilung

## Nicht umgesetzt (bewusst)
- neue Produktlogik (Transkription, Insert, Feedback)
- neue Accessibility-Architektur
- Notarisierung
- `.pkg`-Installer
- DMG-Design
- GitHub-Release-Automatisierung
- Auto-Update
- neue UI-Flaechen
- Mehrmodell-Management
- Datei-Transkription
- Multiplattform-Unterstuetzung

## Bekannte Risiken / Annahmen
- Der 009-Nachweis basiert auf einer produktnahen lokalen macOS-Validierung; fremde Mac-Konfigurationen koennen Gatekeeper-/TCC-Interaktionen unterschiedlich anzeigen.
- Accessibility- und Mikrofonzustand sind geraete- und bundle-spezifisch.
- Ohne Notarisierung bleibt der Erststart fuer externe Tester ein kontrollierter RC-Prozess, kein final gehaerteter Massenvertriebspfad.

## Testhinweise
1. RC-Metadaten lesen:
   - `cat /Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-metadata.txt`
2. 009-Erstinstallationsvalidierung reproduzieren:
   - `./scripts/validate_pushwrite_release_candidate_install.sh --artifact-zip /Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-macos.zip --install-root /Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/install-qa-009 --runtime-root /tmp/pushwrite-009-rc1-validation --success-text "PushWrite 009 external first-install validation success." --results-file /Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-first-install-validation-009.txt`
3. 009-Erfolgsfall pruefen:
   - `cat /private/tmp/pushwrite-009-rc1-validation/success/validation-success-response.json`
4. 009-Negativfall pruefen:
   - `cat /private/tmp/pushwrite-009-rc1-validation/blocked/validation-blocked-response.json`

## Rollback
- Repo-Dateien ruecksetzen:
  - `git restore /Users/michel/Code/pushwrite/docs/execution/009-results-external-distribution-and-first-install-hardening.md /Users/michel/Code/pushwrite/docs/testing/009-external-first-install-checklist.md`
- 009-Validierungsartefakte entfernen:
  - `rm -rf /Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/install-qa-009`
  - `rm -f /Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-first-install-validation-009.txt`
  - `rm -rf /private/tmp/pushwrite-009-rc1-validation`
