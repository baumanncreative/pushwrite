# PushWrite RC v0.1.0-rc1: Externe Erstinstallations-Checkliste (macOS)

Diese Checkliste ist fuer externe Tester ohne Repo-Kontext.

## 1) Was erhalte ich?
- Datei: `PushWrite-v0.1.0-rc1-macos.zip`
- Inhalt nach Entpacken: `PushWrite.app`
- RC-Name: `PushWrite-v0.1.0-rc1`

## 2) Wie entpacke ich die App?
1. ZIP lokal speichern.
2. ZIP per Doppelklick entpacken.
3. Pruefen, dass `PushWrite.app` sichtbar ist.

## 3) Wo lege ich die App ab?
1. `PushWrite.app` nach `/Applications` verschieben.
2. Danach nur noch diese App an diesem Ort starten (kein Start aus temporaeren Entpackordnern).

## 4) Wie starte ich sie beim ersten Mal?
1. In `/Applications` auf `PushWrite.app` rechtsklicken und `Oeffnen` waehlen.
2. Falls macOS wegen nicht notarisiertem RC warnt: Start explizit bestaetigen.
3. Die App ist eine Menueleisten-/Hintergrund-App; es erscheint kein klassisches Hauptfenster.

## 5) Welche Berechtigungen sind relevant?
- Mikrofon: erforderlich fuer Aufnahme.
- Bedienungshilfen (Accessibility): erforderlich fuer synthetisches Cmd+V und Einfuegen am Cursor.

Hinweis:
- Ohne Accessibility bleibt der Insert-Pfad blockiert.

## 6) Erfolgsfall in 1-2 Minuten testen
1. TextEdit oeffnen und Cursor in ein Dokument setzen.
2. In macOS pruefen, dass PushWrite Mikrofon- und Accessibility-Zugriff hat.
3. Hotkey `Control+Option+Command+P` gedrueckt halten, kurz sprechen, loslassen.
4. Erwartung:
   - gesprochener Text wird in TextEdit eingefuegt
   - kein blockierter Hinweis auf fehlende Accessibility

## 7) Negativfall in 1-2 Minuten testen
1. In macOS fuer PushWrite Accessibility voruebergehend deaktivieren.
2. In TextEdit erneut den Hotkey `Control+Option+Command+P` ausfuehren.
3. Erwartung:
   - kein Einfuegen
   - Lauf ist wegen fehlender Accessibility blockiert

## 8) Welche Informationen bei Fehlern zurueckmelden?
Bitte diese Punkte gesammelt senden:
- macOS-Version
- RC-Name: `PushWrite-v0.1.0-rc1`
- Konnte ZIP entpackt werden? (ja/nein)
- Konnte `PushWrite.app` gestartet werden? (ja/nein)
- Mikrofonberechtigung gesetzt? (ja/nein/unbekannt)
- Accessibility-Berechtigung gesetzt? (ja/nein/unbekannt)
- Beobachteter Fall: Erfolgsfall oder Fehlerfall, inkl. kurzer Beschreibung
- Falls vorhanden: relevante Datei(en) aus
  - `~/Library/Application Support/PushWrite/runtime/product-state.json`
  - `~/Library/Application Support/PushWrite/runtime/logs/last-hotkey-response.json`
  - `~/Library/Application Support/PushWrite/runtime/logs/events.jsonl`
- Screenshot nur, wenn er den Befund klar zeigt

## 9) Bekannte Grenzen dieses RC-Stands
- Kein notarisiertes Distributionsprodukt
- Kein finaler Installer (`.pkg`)
- Kein DMG-Installationsdesign
- Kein Auto-Update
- Dieser Stand ist fuer kontrollierte externe RC-Tests, nicht fuer breite Endnutzerverteilung
