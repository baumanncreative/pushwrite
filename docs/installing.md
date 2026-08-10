# Installing PushWrite 0.3.1

## GitHub direct-download release

1. Verify that GitHub marks release `v0.3.1` as **Immutable**. For command-line verification, run `gh release verify-asset v0.3.1 DOWNLOADED_FILE -R baumanncreative/pushwrite` and `gh attestation verify DOWNLOADED_FILE -R baumanncreative/pushwrite --signer-workflow baumanncreative/pushwrite/.github/workflows/release.yml --source-ref refs/heads/main`.
2. Open `PushWrite-0.3.1-macos-arm64-unsigned.dmg` and read `INSTALLIEREN.txt`.
3. Drag `PushWrite.app` to the `Applications` link.
4. Try to start `/Applications/PushWrite.app` once. The first warning contains only **Move to Trash** and **Done**; choose **Done**.
5. Open System Settings → Privacy & Security, scroll down, choose **Open Anyway** for PushWrite and confirm **Open**. Apple exposes this button for about one hour after the blocked launch attempt.
6. Trigger the hotkey once or click the microphone row in the menu and grant microphone permission.
7. Grant PushWrite in System Settings → Privacy & Security → Accessibility.
8. Restart PushWrite if macOS requests it.

The GitHub 0.3.1 direct-download artifact is ad-hoc signed for bundle integrity, but it has no Apple Developer ID and is not notarized. GitHub Actions builds it from the exact release commit and publishes a Sigstore-backed provenance attestation; GitHub release immutability prevents later tag or asset replacement. The filename, release metadata and installation instructions state this explicitly. A Developer-ID-signed and notarized artifact can be produced later without changing the application version.

Apple documents this manual exception path in [Safely open apps on your Mac](https://support.apple.com/en-us/102445).

## Authenticated Developer ID release

When a notarized artifact is available:

1. Open `PushWrite-0.3.1-macos-arm64.dmg`.
2. Drag `PushWrite.app` to the `Applications` link.
3. Start `/Applications/PushWrite.app`.
4. Confirm that macOS identifies the app as notarized software from baumanncreative gmbh. Do not bypass Gatekeeper for a stable release.
5. Trigger the hotkey once or click the microphone row in the menu and grant microphone permission.
6. Grant PushWrite in System Settings → Privacy & Security → Accessibility.
7. Restart PushWrite if macOS requests it.

Authenticated artifacts are Developer-ID signed, notarized by Apple and stapled. `SHA256SUMS.txt` remains available for an additional download-integrity check. Raw ad-hoc output from `build_pushwrite_product.sh` remains development-only; only the explicit unsigned release workflow may publish an ad-hoc bundle.

## Use

- Hold `Control + Option + Command + P` while speaking.
- Release the keys to stop and transcribe.
- Keep the intended editable field focused until insertion finishes.
- In Settings, choose the spoken language independently from the output language. `System` follows the first supported macOS preferred language and falls back to German.
- Swiss German input with German output produces Hochdeutsch.
- Permission labels are refreshed whenever the menu opens and when PushWrite becomes active again after System Settings.

## Remove

Quit PushWrite, move `/Applications/PushWrite.app` to Trash, then optionally remove `~/Library/Application Support/PushWrite`. Removing the runtime directory deletes only PushWrite's local QA/state/log data. macOS permission decisions can be removed in System Settings.
