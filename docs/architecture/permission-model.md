# Permission model

## Microphone

PushWrite checks `AVCaptureDevice.authorizationStatus(for: .audio)` when recording is requested, whenever its menu opens and whenever the app becomes active again. A first-use request is issued at recording intent or when the user clicks the microphone row while the state is `notDetermined`. Denied or restricted states produce local guidance and do not start a recorder. The bundle contains `NSMicrophoneUsageDescription`.

Apple requires explicit capture permission and a purpose string for microphone use: [Requesting authorization to capture and save media](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media).

## Accessibility

Accessibility trust is checked before focus inspection and insertion. If it is absent, PushWrite opens a local explanation with a link to the relevant System Settings pane. Focus metadata is read only to establish the target process, role, editability and protected-content status. Focused text values are not read or stored.

## Protected input

Targets with secure-text subroles or protected-content metadata are rejected. Non-editable targets and a target-app or focused-element change between capture and insertion are also rejected. These guards apply before both Accessibility and Unicode-event insertion. Unicode events are directed to the validated process ID, the target is revalidated between characters, and the resulting value must match. Opaque fields without a verifiable Accessibility value fail closed, including applications that do not expose their compose field through Accessibility.

## Clipboard

Dictation never reads or writes transcript text through `NSPasteboard.general`. Apple states that the general pasteboard automatically participates in Universal Clipboard and provides no macOS API to control that feature: [NSPasteboard](https://developer.apple.com/documentation/appkit/nspasteboard). Avoiding the pasteboard prevents accidental cross-device propagation of dictated text.

Language normalization and translation operate on the in-memory transcript and never monitor or read the clipboard.

## Entitlements

The direct-distribution build requests only `com.apple.security.device.audio-input`, which permits audio input while Hardened Runtime is enabled. It also uses a microphone purpose string and the normal TCC prompt. No JIT, unsigned executable memory, library-validation exception, network, automation or sandbox exception is added. The local text subprocess is additionally wrapped in a macOS sandbox profile with `deny network*`.
