import AppKit
import Foundation

enum LanguageSettingsCatalog {
    static let inputTitles = [
        "Automatisch erkennen",
        "Deutsch (Deutschland)",
        "Deutsch (Österreich)",
        "Deutsch (Schweiz / Schweizerdeutsch)",
        "Englisch",
        "Spanisch",
        "Französisch",
    ]
    static let inputValues = ["auto", "de-DE", "de-AT", "de-CH", "en", "es", "fr"]
    static let outputTitles = ["System", "Deutsch", "Englisch", "Spanisch", "Französisch"]
    static let outputValues = ["system", "de", "en", "es", "fr"]
}

enum MenuBarPresentationState {
    case ready
    case recording
    case processing
    case attention
}

struct MenuBarSnapshot {
    let state: MenuBarPresentationState
    let statusText: String
    let hotKeyText: String
    let accessibilityGranted: Bool
    let microphoneStatusText: String
    let versionText: String
}

final class PushWriteMenuBarController: NSObject, NSMenuDelegate {
    var onRefreshSnapshot: (() -> MenuBarSnapshot?)?
    var onOpenAccessibilitySettings: (() -> Void)?
    var onMicrophoneAction: (() -> Void)?
    var onShowSettings: (() -> Void)?
    var onShowAbout: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let statusMenuItem = NSMenuItem(title: "Bereit", action: nil, keyEquivalent: "")
    private let hotKeyMenuItem = NSMenuItem(title: "Tastenkombination", action: nil, keyEquivalent: "")
    private let accessibilityMenuItem = NSMenuItem(title: "Bedienungshilfen", action: nil, keyEquivalent: "")
    private let microphoneMenuItem = NSMenuItem(title: "Mikrofon", action: nil, keyEquivalent: "")
    private let translationMenuItem = NSMenuItem(title: "Lokale Übersetzung", action: nil, keyEquivalent: "")
    private var snapshot: MenuBarSnapshot

    init(initialSnapshot: MenuBarSnapshot) {
        self.snapshot = initialSnapshot
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureMenu()
        update(initialSnapshot)
    }

    private func configureMenu() {
        menu.delegate = self
        statusMenuItem.isEnabled = false
        hotKeyMenuItem.isEnabled = false
        translationMenuItem.isEnabled = false

        accessibilityMenuItem.target = self
        accessibilityMenuItem.action = #selector(openAccessibilitySettings)
        microphoneMenuItem.target = self
        microphoneMenuItem.action = #selector(handleMicrophoneAction)

        let settingsItem = NSMenuItem(title: "Einstellungen …", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.setAccessibilityLabel("PushWrite-Einstellungen öffnen")

        let aboutItem = NSMenuItem(title: "Über PushWrite", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self

        let quitItem = NSMenuItem(title: "PushWrite beenden", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self

        menu.items = [
            statusMenuItem,
            hotKeyMenuItem,
            .separator(),
            accessibilityMenuItem,
            microphoneMenuItem,
            .separator(),
            translationMenuItem,
            settingsItem,
            aboutItem,
            .separator(),
            quitItem,
        ]
        statusItem.menu = menu
        statusItem.button?.setAccessibilityLabel("PushWrite")
        statusItem.button?.setAccessibilityHelp("Zeigt Status, Berechtigungen und Einstellungen von PushWrite")
    }

    func update(_ snapshot: MenuBarSnapshot) {
        self.snapshot = snapshot
        statusMenuItem.title = "Status: \(snapshot.statusText)"
        hotKeyMenuItem.title = "Halten zum Sprechen: \(snapshot.hotKeyText)"
        accessibilityMenuItem.title = snapshot.accessibilityGranted
            ? "Bedienungshilfen: Erlaubt"
            : "Bedienungshilfen: Öffnen …"
        microphoneMenuItem.title = "Mikrofon: \(snapshot.microphoneStatusText)"
        translationMenuItem.title = "Lokale Textverarbeitung: Aktiv (offline)"

        let image = statusImage(for: snapshot.state)
        statusItem.button?.image = image
        statusItem.button?.toolTip = "PushWrite – \(snapshot.statusText)"
        statusItem.button?.setAccessibilityValue(snapshot.statusText)
    }

    func menuWillOpen(_ menu: NSMenu) {
        guard let refreshedSnapshot = onRefreshSnapshot?() else {
            return
        }
        update(refreshedSnapshot)
    }

    private func statusImage(for state: MenuBarPresentationState) -> NSImage? {
        let symbolName: String
        switch state {
        case .ready:
            if let resourceURL = Bundle.main.url(forResource: "PushWriteMenuBarTemplate", withExtension: "svg"),
               let image = NSImage(contentsOf: resourceURL) {
                image.isTemplate = true
                image.size = NSSize(width: 18, height: 18)
                return image
            }
            symbolName = "waveform"
        case .recording:
            symbolName = "record.circle.fill"
        case .processing:
            symbolName = "ellipsis.circle"
        case .attention:
            symbolName = "exclamationmark.circle"
        }
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: snapshot.statusText)
        image?.isTemplate = true
        return image
    }

    @objc private func openAccessibilitySettings() {
        onOpenAccessibilitySettings?()
    }

    @objc private func handleMicrophoneAction() {
        onMicrophoneAction?()
    }

    @objc private func showSettings() {
        onShowSettings?()
    }

    @objc private func showAbout() {
        onShowAbout?()
    }

    @objc private func quit() {
        onQuit?()
    }
}

final class PushWriteSettingsWindowController: NSWindowController {
    private let permissionLabel = NSTextField(wrappingLabelWithString: "")
    private let inputLanguagePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let outputLanguagePopup = NSPopUpButton(frame: .zero, pullsDown: false)

    var onInputLanguageChanged: ((String) -> Void)?
    var onOutputLanguageChanged: ((String) -> Void)?

    func updatePermissions(accessibilityGranted: Bool, microphoneStatus: String) {
        permissionLabel.stringValue = "Bedienungshilfen: \(accessibilityGranted ? "Erlaubt" : "Nicht erlaubt")\nMikrofon: \(microphoneStatus)"
    }

    init(
        hotKeyText: String,
        accessibilityGranted: Bool,
        microphoneStatus: String,
        selectedInputLanguage: String,
        selectedOutputLanguage: String
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 440),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "PushWrite-Einstellungen"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        configureContent(
            hotKeyText: hotKeyText,
            accessibilityGranted: accessibilityGranted,
            microphoneStatus: microphoneStatus,
            selectedInputLanguage: selectedInputLanguage,
            selectedOutputLanguage: selectedOutputLanguage
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureContent(
        hotKeyText: String,
        accessibilityGranted: Bool,
        microphoneStatus: String,
        selectedInputLanguage: String,
        selectedOutputLanguage: String
    ) {
        guard let contentView = window?.contentView else {
            return
        }

        let title = NSTextField(labelWithString: "PushWrite")
        title.font = .systemFont(ofSize: 22, weight: .semibold)
        let claim = NSTextField(labelWithString: "Local voice input for macOS")
        claim.textColor = .secondaryLabelColor
        let hotKey = NSTextField(labelWithString: "Halten zum Sprechen: \(hotKeyText)")
        hotKey.font = .monospacedSystemFont(ofSize: 13, weight: .medium)

        permissionLabel.stringValue = "Bedienungshilfen: \(accessibilityGranted ? "Erlaubt" : "Nicht erlaubt")\nMikrofon: \(microphoneStatus)"
        permissionLabel.setAccessibilityLabel("Berechtigungsstatus")

        let inputLanguageLabel = NSTextField(labelWithString: "Gesprochene Sprache")
        inputLanguagePopup.addItems(withTitles: LanguageSettingsCatalog.inputTitles)
        inputLanguagePopup.selectItem(
            at: LanguageSettingsCatalog.inputValues.firstIndex(of: selectedInputLanguage) ?? 0
        )
        inputLanguagePopup.target = self
        inputLanguagePopup.action = #selector(inputLanguageChanged)
        inputLanguagePopup.setAccessibilityLabel("Gesprochene Sprache")

        let outputLanguageLabel = NSTextField(labelWithString: "Ausgabesprache")
        outputLanguagePopup.addItems(withTitles: LanguageSettingsCatalog.outputTitles)
        let migratedOutputLanguage = selectedOutputLanguage == "auto" ? "system" : selectedOutputLanguage
        outputLanguagePopup.selectItem(
            at: LanguageSettingsCatalog.outputValues.firstIndex(of: migratedOutputLanguage) ?? 0
        )
        outputLanguagePopup.target = self
        outputLanguagePopup.action = #selector(outputLanguageChanged)
        outputLanguagePopup.setAccessibilityLabel("Ausgabesprache")

        let translationTitle = NSTextField(labelWithString: "Lokale Sprachverarbeitung")
        translationTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        let translationNote = NSTextField(wrappingLabelWithString: "Erkennung, Schweizerdeutsch-Normalisierung und Übersetzung laufen vollständig lokal. Audio und Text werden nicht übertragen; nach der Installation ist keine Netzwerkverbindung erforderlich.")
        translationNote.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [
            title,
            claim,
            hotKey,
            permissionLabel,
            inputLanguageLabel,
            inputLanguagePopup,
            outputLanguageLabel,
            outputLanguagePopup,
            translationTitle,
            translationNote,
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),
            inputLanguagePopup.widthAnchor.constraint(equalToConstant: 310),
            outputLanguagePopup.widthAnchor.constraint(equalToConstant: 220),
        ])
    }

    @objc private func inputLanguageChanged() {
        let index = max(
            0,
            min(inputLanguagePopup.indexOfSelectedItem, LanguageSettingsCatalog.inputValues.count - 1)
        )
        onInputLanguageChanged?(LanguageSettingsCatalog.inputValues[index])
    }

    @objc private func outputLanguageChanged() {
        let index = max(
            0,
            min(outputLanguagePopup.indexOfSelectedItem, LanguageSettingsCatalog.outputValues.count - 1)
        )
        onOutputLanguageChanged?(LanguageSettingsCatalog.outputValues[index])
    }
}
