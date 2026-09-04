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
            versionText: "0.3.2",
            recordingElapsed: 0,
            audioLevel: 0,
            inputLanguageText: "Automatisch erkennen",
            outputLanguageText: "System",
            workflowStage: .attention
        )
        let refreshed = MenuBarSnapshot(
            state: .ready,
            statusText: "Bereit",
            hotKeyText: "Control+Option+Command+P",
            accessibilityGranted: true,
            microphoneStatusText: "Erlaubt",
            versionText: "0.3.2",
            recordingElapsed: 18,
            audioLevel: 0.7,
            inputLanguageText: "Deutsch (Schweiz / Schweizerdeutsch)",
            outputLanguageText: "Deutsch",
            workflowStage: .recording
        )

        let controller = PushWriteMenuBarController(initialSnapshot: initial)
        var refreshCount = 0
        controller.onRefreshSnapshot = {
            refreshCount += 1
            return refreshed
        }

        controller.refreshSnapshotForTesting()

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
        guard LanguageSettingsCatalog.inputTitles[4] == "Englisch (USA)",
              LanguageSettingsCatalog.outputTitles[2] == "Englisch (USA)" else {
            fputs("English must be labeled with its United States locale in both settings.\n", stderr)
            exit(1)
        }

        guard controller.settingsActionCountForTesting == 1 else {
            fputs("Settings must have exactly one action in the popover.\n", stderr)
            exit(1)
        }

        guard controller.quitActionCountForTesting == 1 else {
            fputs("The popover must have exactly one quit action.\n", stderr)
            exit(1)
        }

        guard controller.workflowStepCountForTesting == 4 else {
            fputs("The 0.3.2 workflow must expose four visual stages.\n", stderr)
            exit(1)
        }

        guard LanguageSettingsCatalog.inputTitle(for: "de-CH") == "Deutsch (Schweiz / Schweizerdeutsch)",
              LanguageSettingsCatalog.outputTitle(for: "auto") == "System" else {
            fputs("Language values must resolve to their user-facing labels.\n", stderr)
            exit(1)
        }

        print("PushWriteProductUITests: 7 passed")
    }
}
