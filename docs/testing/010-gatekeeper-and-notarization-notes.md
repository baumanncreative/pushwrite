# PushWrite 010: Gatekeeper- und Notarisierungsnotizen fuer externe Tests

## Aktueller Distributionsstand
- RC: `PushWrite-v0.1.0-rc1`
- Bundle: `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite.app`
- ZIP: `/Users/michel/Code/pushwrite/build/release-candidates/PushWrite-v0.1.0-rc1/PushWrite-v0.1.0-rc1-macos.zip`
- Notarisierungsstatus: aktuell **nicht notarisiert**

## Was externe Tester beim Erststart erwarten duerfen
- Der RC ist fuer kontrollierte Tests gedacht, nicht fuer breite Endnutzerdistribution.
- Bei Erststart auf einem externen Mac koennen Gatekeeper-Hinweise fuer nicht notarisierten Inhalt auftreten.
- Falls Gatekeeper blockiert, gilt der dokumentierte Testfreigabeweg (gezieltes Oeffnen des bekannten RC-Bundles) als erwartbarer RC-Prozess.

## Was aktuell als gueltiger Befund gilt
- RC-ZIP entpackbar und `PushWrite.app` vorhanden.
- Bundle ist lokal signiert und verifizierbar (`codesign --verify --deep --strict` erfolgreich).
- Produktstart und Ersttest folgen weiterhin der 009-Checkliste:
  - `/Users/michel/Code/pushwrite/docs/testing/009-external-first-install-checklist.md`

## Aktuelle Huerden, die normal sind
- Keine Developer-ID-basierte Distribution: aktuelles RC-Bundle ist ad-hoc signiert.
- Keine Notarisierung und kein Stapling fuer diesen Stand.

## Was bewusst noch nicht final gehaertet ist
- keine notarized Distribution
- kein finaler Installer (`.pkg`)
- kein DMG-Installationsdesign
- kein Auto-Update
