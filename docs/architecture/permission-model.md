# Permission model

## Microphone

PushWrite checks `AVCaptureDevice.authorizationStatus(for: .audio)` when recording is requested. A first-use request is issued only at recording intent. Denied or restricted states produce local guidance and do not start a recorder. The bundle contains `NSMicrophoneUsageDescription`.

Apple requires explicit capture permission and a purpose string for microphone use: [Requesting authorization to capture and save media](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media).

## Accessibility

Accessibility trust is checked before focus inspection and insertion. If it is absent, PushWrite opens a local explanation with a link to the relevant System Settings pane. Focus metadata is read only to establish the target process, role, editability and protected-content status. Focused text values are not read or stored.

## Protected input

Targets with secure-text subroles or protected-content metadata are rejected. Non-editable targets and a target-app change between capture and insertion are also rejected. These guards apply before both Accessibility and Unicode-event insertion.

## Clipboard

Dictation never reads or writes transcript text through `NSPasteboard.general`. Apple states that the general pasteboard automatically participates in Universal Clipboard and provides no macOS API to control that feature: [NSPasteboard](https://developer.apple.com/documentation/appkit/nspasteboard). Avoiding the pasteboard prevents accidental cross-device propagation of dictated text.

Clipboard translation is off, cannot be enabled in this build and performs no clipboard access.

## Entitlements

The direct-distribution build requests no code-signing entitlements. It uses a microphone purpose string and the normal TCC prompt. The hardened runtime is enabled during signing. No JIT, unsigned executable memory, library-validation exception, network, automation or sandbox exception is added.
