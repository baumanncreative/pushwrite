import AppKit
import Foundation

@main
enum PushWriteProductUIPreview {
    private static var controller: PushWriteMenuBarController?

    static func main() {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.accessory)

        let snapshot = MenuBarSnapshot(
            state: .recording,
            statusText: "Aufnahme läuft",
            hotKeyText: "Control+Option+Command+P",
            accessibilityGranted: true,
            microphoneStatusText: "Erlaubt",
            versionText: "0.3.2",
            recordingElapsed: 18,
            audioLevel: 0.72,
            inputLanguageText: "Deutsch (Schweiz / Schweizerdeutsch)",
            outputLanguageText: "System",
            workflowStage: .recording
        )
        controller = PushWriteMenuBarController(initialSnapshot: snapshot)
        controller?.onRefreshSnapshot = { snapshot }
        controller?.onQuit = { NSApp.terminate(nil) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            controller?.showPopover()
        }
        NSApp.run()
    }
}
