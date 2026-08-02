import AppKit
import Foundation

@main
enum PushWriteProductUITests {
    static func main() {
        _ = NSApplication.shared

        let initial = MenuBarSnapshot(
            state: .attention,
            statusText: "Berechtigung prüfen",
            hotKeyText: "Control+Option+Command+P",
            accessibilityGranted: true,
            microphoneStatusText: "Noch nicht angefragt",
            versionText: "0.2.0-alpha.2"
        )
        let refreshed = MenuBarSnapshot(
            state: .ready,
            statusText: "Bereit",
            hotKeyText: "Control+Option+Command+P",
            accessibilityGranted: true,
            microphoneStatusText: "Erlaubt",
            versionText: "0.2.0-alpha.2"
        )

        let controller = PushWriteMenuBarController(initialSnapshot: initial)
        var refreshCount = 0
        controller.onRefreshSnapshot = {
            refreshCount += 1
            return refreshed
        }

        controller.menuWillOpen(NSMenu())

        guard refreshCount == 1 else {
            fputs("Expected the menu to refresh its permission snapshot exactly once.\n", stderr)
            exit(1)
        }

        print("PushWriteProductUITests: 1 passed")
    }
}
