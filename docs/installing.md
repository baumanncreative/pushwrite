# Installing PushWrite 0.3.0

## Authenticated release artifact

1. Open `PushWrite-0.3.0-macos-arm64.dmg`.
2. Drag `PushWrite.app` to the `Applications` link.
3. Start `/Applications/PushWrite.app`.
4. Confirm that macOS identifies the app as notarized software from baumanncreative gmbh. Do not bypass Gatekeeper for a stable release.
5. Trigger the hotkey once or click the microphone row in the menu and grant microphone permission.
6. Grant PushWrite in System Settings → Privacy & Security → Accessibility.
7. Restart PushWrite if macOS requests it.

Stable artifacts are Developer-ID signed, notarized by Apple and stapled. `SHA256SUMS.txt` remains available for an additional download-integrity check. Ad-hoc output from `build_pushwrite_product.sh` is development-only and must not be published.

## Use

- Hold `Control + Option + Command + P` while speaking.
- Release the keys to stop and transcribe.
- Keep the intended editable field focused until insertion finishes.
- In Settings, choose the spoken language independently from the output language. `System` follows the first supported macOS preferred language and falls back to German.
- Swiss German input with German output produces Hochdeutsch.
- Permission labels are refreshed whenever the menu opens and when PushWrite becomes active again after System Settings.

## Remove

Quit PushWrite, move `/Applications/PushWrite.app` to Trash, then optionally remove `~/Library/Application Support/PushWrite`. Removing the runtime directory deletes only PushWrite's local QA/state/log data. macOS permission decisions can be removed in System Settings.
