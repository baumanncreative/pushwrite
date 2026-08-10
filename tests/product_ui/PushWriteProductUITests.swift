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
            versionText: "0.3.0"
        )
        let refreshed = MenuBarSnapshot(
            state: .ready,
            statusText: "Bereit",
            hotKeyText: "Control+Option+Command+P",
            accessibilityGranted: true,
            microphoneStatusText: "Erlaubt",
            versionText: "0.3.0"
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

        guard LanguageSettingsCatalog.inputValues == ["auto", "de-DE", "de-AT", "de-CH", "en", "es", "fr"] else {
            fputs("Input language settings are incomplete or out of order.\n", stderr)
            exit(1)
        }
        guard LanguageSettingsCatalog.outputValues == ["system", "de", "en", "es", "fr"] else {
            fputs("Output language settings are incomplete or out of order.\n", stderr)
            exit(1)
        }
        guard LanguageSettingsCatalog.outputTitles.first == "System" else {
            fputs("The output language default must be labeled System.\n", stderr)
            exit(1)
        }

        print("PushWriteProductUITests: 2 passed")
    }
}
