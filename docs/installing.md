# Installing the 0.2.0-alpha.2 build

## Ad-hoc internal Alpha

1. Open `PushWrite-0.2.0-alpha.2-macos-arm64.dmg`.
2. Drag `PushWrite.app` to the `Applications` link.
3. Start `/Applications/PushWrite.app`.
4. If Gatekeeper blocks the ad-hoc build, use System Settings → Privacy & Security only after verifying the published SHA-256 checksum.
5. Trigger the hotkey once or click the microphone row in the menu and grant microphone permission.
6. Grant PushWrite in System Settings → Privacy & Security → Accessibility.
7. Restart PushWrite if macOS requests it.

Do not distribute the ad-hoc artifact as a public trusted release. It has a valid structural ad-hoc signature but no Developer ID identity or notarization ticket.

## Use

- Hold `Control + Option + Command + P` while speaking.
- Release the keys to stop and transcribe.
- Keep the intended editable field focused until insertion finishes.
- Use the menu-bar icon to inspect permissions, choose automatic/German/English transcription, open settings or quit.
- Permission labels are refreshed whenever the menu opens and when PushWrite becomes active again after System Settings.

## Remove

Quit PushWrite, move `/Applications/PushWrite.app` to Trash, then optionally remove `~/Library/Application Support/PushWrite`. Removing the runtime directory deletes only PushWrite's local QA/state/log data. macOS permission decisions can be removed in System Settings.
