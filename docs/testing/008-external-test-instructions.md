# PushWrite RC v0.1.0-rc1: Externe Testanleitung (macOS)

## Was du erhaeltst
- ZIP-Artefakt:
  - `PushWrite-v0.1.0-rc1-macos.zip`
- Nach Entpacken:
  - `PushWrite.app`

## Entpacken
1. ZIP in einen lokalen Ordner kopieren.
2. ZIP entpacken (Doppelklick im Finder oder `ditto -x -k <zip> <zielordner>`).
3. Pruefen, dass `PushWrite.app` vorhanden ist.

## App starten
1. `PushWrite.app` starten.
2. Falls macOS Sicherheitsdialoge zeigt, Start explizit erlauben.
3. App laeuft als menuleiste-/hintergrundnahe Utility-App (`LSUIElement=true`), es oeffnet sich kein klassisches Hauptfenster.

## Erwartete Berechtigungen
- Accessibility (fuer synthetisches Cmd+V / Texteinfuegung)
- Mikrofon (fuer Aufnahme aus dem globalen Hotkey-Pfad)

Ohne Accessibility bleibt Einfuegen blockiert.

## Kurzer Erfolgsfall
1. Accessibility fuer `PushWrite.app` erlauben.
2. Fokus in ein Textfeld setzen (z. B. Notizen/TextEdit).
3. Ueber den QA-Pfad eine `insert-transcription`-Anfrage ausloesen (oder den bekannten Hotkey-Pfad verwenden).
4. Erwartung:
   - Response `status=succeeded`
   - `insertRoute=pasteboardCommandV`

## Kurzer negativer Fall
1. Accessibility verweigern oder blockierten Zustand simulieren.
2. `preflight` ausfuehren.
3. Erwartung:
   - Response `status=blocked`
   - `blockedReason` enthaelt den Accessibility-Hinweis.

## Wichtige Artefakte bei Problemen
- `product-state.json`
- `logs/events.jsonl`
- `logs/last-hotkey-response.json` (falls Hotkey-Pfad getestet wurde)
- `validation-success-response.json` / `validation-blocked-response.json` (falls Validierungsskript genutzt wurde)

## Scope-Hinweis
Dieser RC validiert MVP-0.1.0-Packaging und Installationsfaehigkeit fuer externe Tests.
Nicht enthalten: Notarisierung, DMG-Design, Auto-Update, Mehrmodell-Management.
