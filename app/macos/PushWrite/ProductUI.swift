import AppKit
import Foundation

enum LanguageSettingsCatalog {
    static let inputTitles = [
        "Automatisch erkennen",
        "Deutsch (Deutschland)",
        "Deutsch (Österreich)",
        "Deutsch (Schweiz / Schweizerdeutsch)",
        "Englisch (USA)",
        "Spanisch",
        "Französisch",
    ]
    static let inputValues = ["auto", "de-DE", "de-AT", "de-CH", "en", "es", "fr"]
    static let outputTitles = ["System", "Deutsch", "Englisch (USA)", "Spanisch", "Französisch"]
    static let outputValues = ["system", "de", "en", "es", "fr"]

    static func inputTitle(for value: String) -> String {
        guard let index = inputValues.firstIndex(of: value) else { return inputTitles[0] }
        return inputTitles[index]
    }

    static func outputTitle(for value: String) -> String {
        let migratedValue = value == "auto" ? "system" : value
        guard let index = outputValues.firstIndex(of: migratedValue) else { return outputTitles[0] }
        return outputTitles[index]
    }
}

enum MenuBarPresentationState {
    case ready
    case recording
    case processing
    case attention
}

enum WorkflowPresentationStage {
    case ready
    case recording
    case transcribing
    case transforming
    case inserting
    case attention
}

struct MenuBarSnapshot {
    let state: MenuBarPresentationState
    let statusText: String
    let hotKeyText: String
    let accessibilityGranted: Bool
    let microphoneStatusText: String
    let versionText: String
    let recordingElapsed: TimeInterval
    let audioLevel: Double
    let inputLanguageText: String
    let outputLanguageText: String
    let workflowStage: WorkflowPresentationStage
}

private enum BrandStyle {
    static let accent = NSColor(deviceRed: 192 / 255, green: 0, blue: 0, alpha: 1)
    static let background = NSColor(deviceWhite: 16 / 255, alpha: 1)
    static let surface = NSColor(deviceWhite: 28 / 255, alpha: 1)
    static let surfaceRaised = NSColor(deviceWhite: 39 / 255, alpha: 1)
    static let primaryText = NSColor(deviceWhite: 244 / 255, alpha: 1)
    static let secondaryText = NSColor(deviceWhite: 170 / 255, alpha: 1)
    static let mutedText = NSColor(deviceWhite: 244 / 255, alpha: 0.62)
    static let success = NSColor(deviceRed: 93 / 255, green: 174 / 255, blue: 111 / 255, alpha: 1)

    static func headingFont(size: CGFloat) -> NSFont {
        NSFont(name: "Futura-Medium", size: size)
            ?? NSFont(name: "Arial-BoldMT", size: size)
            ?? .systemFont(ofSize: size, weight: .semibold)
    }

    static func bodyFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        if weight == .regular, let font = NSFont(name: "ArialMT", size: size) { return font }
        if weight == .bold, let font = NSFont(name: "Arial-BoldMT", size: size) { return font }
        return .systemFont(ofSize: size, weight: weight)
    }
}

private class SurfaceView: NSView {
    init(color: NSColor, radius: CGFloat) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = color.cgColor
        layer?.cornerRadius = radius
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private func makeLabel(
    _ text: String,
    size: CGFloat,
    color: NSColor = BrandStyle.primaryText,
    weight: NSFont.Weight = .regular,
    heading: Bool = false
) -> NSTextField {
    let label = NSTextField(labelWithString: text)
    label.font = heading ? BrandStyle.headingFont(size: size) : BrandStyle.bodyFont(size: size, weight: weight)
    label.textColor = color
    label.maximumNumberOfLines = 0
    return label
}

private func makeSymbolButton(
    symbolName: String,
    accessibilityLabel: String,
    target: AnyObject,
    action: Selector
) -> NSButton {
    let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
    let button = NSButton(image: image ?? NSImage(), target: target, action: action)
    button.isBordered = false
    button.contentTintColor = BrandStyle.primaryText
    button.setAccessibilityLabel(accessibilityLabel)
    return button
}

private final class WorkflowProgressView: SurfaceView {
    private let stepIcons: [NSImageView]
    private let stepLabels: [NSTextField]
    private let stepTitles: [String]

    init() {
        let steps = [
            ("waveform", "Aufnehmen"),
            ("text.bubble", "Transkription"),
            ("wand.and.stars", "Textverarbeitung"),
            ("text.cursor", "Einfügen"),
        ]
        stepIcons = steps.map { _ in NSImageView() }
        stepLabels = steps.map { makeLabel($0.1, size: 11, color: BrandStyle.secondaryText) }
        stepTitles = steps.map(\.1)
        super.init(color: BrandStyle.surface, radius: 10)

        let title = makeLabel("ABLAUF", size: 10, color: BrandStyle.mutedText, weight: .bold)
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)

        var columns: [NSView] = []
        for (index, step) in steps.enumerated() {
            let icon = stepIcons[index]
            icon.image = NSImage(systemSymbolName: step.0, accessibilityDescription: step.1)
            icon.contentTintColor = BrandStyle.mutedText
            icon.setAccessibilityElement(false)
            icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 17, weight: .medium)
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 22).isActive = true
            let column = NSStackView(views: [icon, stepLabels[index]])
            column.orientation = .vertical
            column.alignment = .centerX
            column.spacing = 6
            columns.append(column)
        }
        let stepsStack = NSStackView(views: columns)
        stepsStack.orientation = .horizontal
        stepsStack.distribution = .fillEqually
        stepsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stepsStack)

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            title.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stepsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stepsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stepsStack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            stepsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
        ])
    }

    func update(stage: WorkflowPresentationStage) {
        let activeIndex: Int?
        switch stage {
        case .recording: activeIndex = 0
        case .transcribing: activeIndex = 1
        case .transforming: activeIndex = 2
        case .inserting: activeIndex = 3
        case .ready, .attention: activeIndex = nil
        }
        for index in stepIcons.indices {
            let isActive = index == activeIndex
            stepIcons[index].contentTintColor = isActive ? BrandStyle.accent : BrandStyle.mutedText
            stepLabels[index].textColor = isActive ? BrandStyle.primaryText : BrandStyle.secondaryText
            stepLabels[index].font = BrandStyle.bodyFont(size: 11, weight: isActive ? .bold : .regular)
            stepLabels[index].stringValue = isActive ? "\(stepTitles[index]) · aktiv" : stepTitles[index]
            stepLabels[index].setAccessibilityLabel("Ablaufschritt \(stepTitles[index])")
            stepLabels[index].setAccessibilityValue(isActive ? "Aktiv" : "Nicht aktiv")
        }
    }

    var stepCountForTesting: Int { stepLabels.count }
}

private final class PushWritePopoverViewController: NSViewController {
    var onOpenAccessibilitySettings: (() -> Void)?
    var onMicrophoneAction: (() -> Void)?
    var onShowSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusIcon = NSImageView()
    private let statusTitle = makeLabel("Bereit", size: 17, weight: .bold)
    private let statusDetail = makeLabel("PushWrite ist bereit.", size: 12, color: BrandStyle.secondaryText)
    private let activityTitle = makeLabel("BEREIT", size: 10, color: BrandStyle.mutedText, weight: .bold)
    private let timerLabel = makeLabel("00:00", size: 28, weight: .bold, heading: true)
    private let activityInstruction = makeLabel("Tastenkombination halten, um zu sprechen.", size: 12, color: BrandStyle.secondaryText)
    private let meter = NSLevelIndicator()
    private let shortcutKeys = NSStackView()
    private let inputLanguageValue = makeLabel("Automatisch erkennen", size: 12, weight: .bold)
    private let outputLanguageValue = makeLabel("System", size: 12, weight: .bold)
    private let accessibilityButton = NSButton(title: "", target: nil, action: nil)
    private let microphoneButton = NSButton(title: "", target: nil, action: nil)
    private let workflow = WorkflowProgressView()

    init(initialSnapshot: MenuBarSnapshot) {
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = NSSize(width: 520, height: 630)
        loadView()
        configureView()
        configureShortcut(initialSnapshot.hotKeyText)
        update(initialSnapshot)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        view = SurfaceView(color: BrandStyle.background, radius: 0)
        view.frame = NSRect(origin: .zero, size: preferredContentSize)
    }

    func update(_ snapshot: MenuBarSnapshot) {
        statusTitle.stringValue = snapshot.statusText
        statusIcon.image = NSImage(systemSymbolName: statusSymbol(for: snapshot.state), accessibilityDescription: snapshot.statusText)
        statusIcon.contentTintColor = statusColor(for: snapshot.state)
        statusTitle.textColor = BrandStyle.primaryText
        activityTitle.stringValue = activityHeading(for: snapshot.state)
        timerLabel.stringValue = elapsedText(snapshot.recordingElapsed)
        timerLabel.textColor = BrandStyle.primaryText
        timerLabel.setAccessibilityValue(timerLabel.stringValue)
        activityInstruction.stringValue = activityHelp(for: snapshot.state)
        meter.doubleValue = max(0, min(snapshot.audioLevel, 1))
        meter.fillColor = snapshot.state == .recording ? BrandStyle.primaryText : BrandStyle.mutedText
        meter.setAccessibilityValue("\(Int(meter.doubleValue * 100)) Prozent")
        meter.isHidden = snapshot.state == .ready || snapshot.state == .attention
        inputLanguageValue.stringValue = snapshot.inputLanguageText
        outputLanguageValue.stringValue = snapshot.outputLanguageText
        configurePermissionButton(accessibilityButton, title: snapshot.accessibilityGranted ? "Erlaubt" : "Öffnen", allowed: snapshot.accessibilityGranted)
        configurePermissionButton(microphoneButton, title: snapshot.microphoneStatusText, allowed: snapshot.microphoneStatusText == "Erlaubt")
        workflow.update(stage: snapshot.workflowStage)
        statusDetail.stringValue = statusDescription(for: snapshot)
    }

    private func configureView() {
        let rootStack = NSStackView()
        rootStack.orientation = .vertical
        rootStack.alignment = .leading
        rootStack.spacing = 12
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        [makeHeader(), makeActivityCard(), makeShortcutCard(), workflow, makeContextCard(), makeFooter()].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            rootStack.addArrangedSubview($0)
            $0.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16),
        ])
    }

    private func makeHeader() -> NSView {
        let icon = NSImageView(image: NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "PushWrite") ?? NSImage())
        icon.contentTintColor = BrandStyle.accent
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 27, weight: .medium)
        let title = makeLabel("PushWrite", size: 21, weight: .bold, heading: true)
        let subtitle = makeLabel("Lokale Spracheingabe für macOS", size: 11, color: BrandStyle.secondaryText)
        let text = NSStackView(views: [title, subtitle])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 1
        let spacer = NSView()
        let settings = makeSymbolButton(symbolName: "gearshape.fill", accessibilityLabel: "PushWrite-Einstellungen öffnen", target: self, action: #selector(showSettings))
        settings.identifier = NSUserInterfaceItemIdentifier("pushwrite.settings")
        settings.contentTintColor = BrandStyle.accent
        let header = NSStackView(views: [icon, text, spacer, settings])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 10
        settings.widthAnchor.constraint(equalToConstant: 32).isActive = true
        settings.heightAnchor.constraint(equalToConstant: 32).isActive = true
        return header
    }

    private func makeActivityCard() -> NSView {
        let card = SurfaceView(color: BrandStyle.surfaceRaised, radius: 10)
        statusIcon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        statusIcon.setAccessibilityElement(false)
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        statusIcon.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let statusText = NSStackView(views: [statusTitle, statusDetail])
        statusText.orientation = .vertical
        statusText.alignment = .leading
        statusText.spacing = 1
        let statusRow = NSStackView(views: [statusIcon, statusText])
        statusRow.orientation = .horizontal
        statusRow.alignment = .centerY
        statusRow.spacing = 10
        statusRow.translatesAutoresizingMaskIntoConstraints = false
        activityTitle.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.font = BrandStyle.headingFont(size: 46)
        timerLabel.setAccessibilityLabel("Aufnahmedauer")
        meter.translatesAutoresizingMaskIntoConstraints = false
        meter.levelIndicatorStyle = .continuousCapacity
        meter.setAccessibilityElement(true)
        meter.setAccessibilityLabel("Mikrofonpegel")
        meter.minValue = 0
        meter.maxValue = 1
        meter.warningValue = 1
        meter.criticalValue = 1
        activityInstruction.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(statusRow)
        card.addSubview(activityTitle)
        card.addSubview(timerLabel)
        card.addSubview(meter)
        card.addSubview(activityInstruction)
        NSLayoutConstraint.activate([
            statusRow.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            statusRow.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            activityTitle.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            activityTitle.topAnchor.constraint(equalTo: statusRow.bottomAnchor, constant: 12),
            timerLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: activityTitle.bottomAnchor, constant: 1),
            meter.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            meter.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            meter.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 5),
            meter.heightAnchor.constraint(equalToConstant: 24),
            activityInstruction.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            activityInstruction.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            activityInstruction.topAnchor.constraint(equalTo: meter.bottomAnchor, constant: 12),
            activityInstruction.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -15),
        ])
        return card
    }

    private func makeShortcutCard() -> NSView {
        let card = SurfaceView(color: BrandStyle.surface, radius: 10)
        let title = makeLabel("HALTEN ZUM SPRECHEN", size: 10, color: BrandStyle.mutedText, weight: .bold)
        title.translatesAutoresizingMaskIntoConstraints = false
        shortcutKeys.orientation = .horizontal
        shortcutKeys.spacing = 7
        shortcutKeys.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(title)
        card.addSubview(shortcutKeys)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            title.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            shortcutKeys.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            shortcutKeys.topAnchor.constraint(equalTo: card.topAnchor, constant: 11),
            shortcutKeys.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -11),
        ])
        return card
    }

    private func makeContextCard() -> NSView {
        let card = SurfaceView(color: BrandStyle.surface, radius: 10)
        let languageTitle = makeLabel("SPRACHEN", size: 10, color: BrandStyle.mutedText, weight: .bold)
        let spoken = makeValueRow(label: "Gesprochen", value: inputLanguageValue)
        let output = makeValueRow(label: "Ausgabe", value: outputLanguageValue)
        let permissionTitle = makeLabel("BERECHTIGUNGEN", size: 10, color: BrandStyle.mutedText, weight: .bold)
        accessibilityButton.target = self
        accessibilityButton.action = #selector(openAccessibilitySettings)
        microphoneButton.target = self
        microphoneButton.action = #selector(handleMicrophoneAction)
        let accessibility = makePermissionRow(symbol: "accessibility", label: "Bedienungshilfen", button: accessibilityButton)
        let microphone = makePermissionRow(symbol: "mic", label: "Mikrofon", button: microphoneButton)
        let localProcessing = makeValueRow(
            label: "Lokale Verarbeitung",
            value: makeLabel("✓  Aktiv", size: 12, color: BrandStyle.success, weight: .bold)
        )
        let stack = NSStackView(views: [languageTitle, spoken, output, localProcessing, permissionTitle, accessibility, microphone])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        for row in [spoken, output, localProcessing, accessibility, microphone] {
            row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])
        return card
    }

    private func makeFooter() -> NSView {
        let quitButton = NSButton(title: "PushWrite beenden", target: self, action: #selector(quit))
        quitButton.isBordered = false
        quitButton.font = BrandStyle.bodyFont(size: 12)
        quitButton.contentTintColor = BrandStyle.primaryText
        quitButton.setAccessibilityLabel("PushWrite beenden")
        quitButton.identifier = NSUserInterfaceItemIdentifier("pushwrite.quit")
        quitButton.keyEquivalent = "q"
        let quitShortcut = makeLabel("⌘ Q", size: 11, color: BrandStyle.mutedText)
        let offline = makeLabel("100 % lokal · offline", size: 11, color: BrandStyle.mutedText)
        let spacer = NSView()
        let row = NSStackView(views: [quitButton, quitShortcut, spacer, offline])
        row.orientation = .horizontal
        row.alignment = .centerY
        return row
    }

    private func makeValueRow(label: String, value: NSTextField) -> NSView {
        let labelView = makeLabel(label, size: 12, color: BrandStyle.secondaryText)
        let spacer = NSView()
        let row = NSStackView(views: [labelView, spacer, value])
        row.orientation = .horizontal
        row.alignment = .centerY
        return row
    }

    private func makePermissionRow(symbol: String, label: String, button: NSButton) -> NSView {
        let icon = NSImageView(image: NSImage(systemSymbolName: symbol, accessibilityDescription: label) ?? NSImage())
        icon.contentTintColor = BrandStyle.secondaryText
        let labelView = makeLabel(label, size: 12, color: BrandStyle.secondaryText)
        let spacer = NSView()
        button.isBordered = false
        button.font = BrandStyle.bodyFont(size: 12, weight: .bold)
        let row = NSStackView(views: [icon, labelView, spacer, button])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        return row
    }

    private func configurePermissionButton(_ button: NSButton, title: String, allowed: Bool) {
        button.title = allowed ? "✓  \(title)" : title
        button.contentTintColor = allowed ? BrandStyle.success : BrandStyle.accent
        button.isEnabled = true
    }

    func configureShortcut(_ hotKeyText: String) {
        shortcutKeys.arrangedSubviews.forEach { shortcutKeys.removeArrangedSubview($0); $0.removeFromSuperview() }
        let keyTitles = hotKeyText.split(separator: "+").map(String.init)
        for keyTitle in keyTitles {
            let key = makeLabel(keyTitle, size: 13, color: BrandStyle.primaryText, weight: .bold)
            key.alignment = .center
            key.wantsLayer = true
            key.layer?.backgroundColor = BrandStyle.surfaceRaised.cgColor
            key.layer?.cornerRadius = 6
            key.setAccessibilityLabel("Taste \(keyTitle)")
            key.heightAnchor.constraint(equalToConstant: 25).isActive = true
            key.widthAnchor.constraint(greaterThanOrEqualToConstant: max(key.intrinsicContentSize.width + 18, 34)).isActive = true
            shortcutKeys.addArrangedSubview(key)
        }
    }

    private func statusSymbol(for state: MenuBarPresentationState) -> String {
        switch state {
        case .ready: return "checkmark.circle.fill"
        case .recording: return "record.circle.fill"
        case .processing: return "ellipsis.circle.fill"
        case .attention: return "exclamationmark.circle.fill"
        }
    }

    private func statusColor(for state: MenuBarPresentationState) -> NSColor {
        switch state {
        case .ready: return BrandStyle.success
        case .recording, .attention: return BrandStyle.accent
        case .processing: return BrandStyle.primaryText
        }
    }

    private func statusDescription(for snapshot: MenuBarSnapshot) -> String {
        switch snapshot.state {
        case .ready: return "Bereit für die globale Tastenkombination."
        case .recording: return "Sprache wird ausschliesslich lokal aufgenommen."
        case .processing: return "Transkription und Einfügen laufen lokal."
        case .attention: return "Berechtigungen oder Tastenkombination prüfen."
        }
    }

    private func activityHeading(for state: MenuBarPresentationState) -> String {
        switch state {
        case .ready: return "BEREIT"
        case .recording: return "AUFNAHME"
        case .processing: return "VERARBEITUNG"
        case .attention: return "HANDLUNGSBEDARF"
        }
    }

    private func activityHelp(for state: MenuBarPresentationState) -> String {
        switch state {
        case .ready: return "Tastenkombination halten, um zu sprechen."
        case .recording: return "Taste loslassen, um die Aufnahme zu verarbeiten."
        case .processing: return "Text wird transkribiert und anschliessend eingefügt."
        case .attention: return "Fehlende Berechtigung unten öffnen und danach erneut versuchen."
        }
    }

    private func elapsedText(_ elapsed: TimeInterval) -> String {
        let seconds = max(Int(elapsed.rounded(.down)), 0)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var settingsActionCountForTesting: Int {
        countButtons(identifier: "pushwrite.settings", in: view)
    }

    var quitActionCountForTesting: Int {
        countButtons(identifier: "pushwrite.quit", in: view)
    }

    var workflowStepCountForTesting: Int { workflow.stepCountForTesting }

    private func countButtons(identifier: String, in root: NSView) -> Int {
        let ownCount = (root as? NSButton)?.identifier?.rawValue == identifier ? 1 : 0
        return ownCount + root.subviews.reduce(0) { $0 + countButtons(identifier: identifier, in: $1) }
    }

    @objc private func openAccessibilitySettings() { onOpenAccessibilitySettings?() }
    @objc private func handleMicrophoneAction() { onMicrophoneAction?() }
    @objc private func showSettings() { onShowSettings?() }
    @objc private func quit() { onQuit?() }
}

final class PushWriteMenuBarController: NSObject, NSPopoverDelegate {
    var onRefreshSnapshot: (() -> MenuBarSnapshot?)?
    var onOpenAccessibilitySettings: (() -> Void)? {
        didSet { contentController.onOpenAccessibilitySettings = onOpenAccessibilitySettings }
    }
    var onMicrophoneAction: (() -> Void)? {
        didSet { contentController.onMicrophoneAction = onMicrophoneAction }
    }
    var onShowSettings: (() -> Void)? {
        didSet { contentController.onShowSettings = onShowSettings }
    }
    var onQuit: (() -> Void)? {
        didSet { contentController.onQuit = onQuit }
    }

    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let contentController: PushWritePopoverViewController
    private var snapshot: MenuBarSnapshot
    private var refreshTimer: Timer?

    init(initialSnapshot: MenuBarSnapshot) {
        snapshot = initialSnapshot
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        contentController = PushWritePopoverViewController(initialSnapshot: initialSnapshot)
        super.init()
        configureStatusItem()
        configurePopover()
        update(initialSnapshot)
    }

    deinit { refreshTimer?.invalidate() }

    func update(_ snapshot: MenuBarSnapshot) {
        self.snapshot = snapshot
        contentController.update(snapshot)
        statusItem.button?.image = statusImage(for: snapshot.state)
        statusItem.button?.toolTip = "PushWrite – \(snapshot.statusText)"
        statusItem.button?.setAccessibilityValue(snapshot.statusText)
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        refreshSnapshot()
        if !popover.isShown { popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY) }
        startRefreshTimer()
    }

    func closePopover() { popover.performClose(nil) }
    func refreshSnapshotForTesting() { refreshSnapshot() }
    var settingsActionCountForTesting: Int { contentController.settingsActionCountForTesting }
    var quitActionCountForTesting: Int { contentController.quitActionCountForTesting }
    var workflowStepCountForTesting: Int { contentController.workflowStepCountForTesting }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePopover)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.setAccessibilityLabel("PushWrite")
        button.setAccessibilityHelp("Zeigt Status, Aufnahme, Berechtigungen und Einstellungen")
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self
        popover.contentViewController = contentController
    }

    private func refreshSnapshot() {
        guard let refreshedSnapshot = onRefreshSnapshot?() else { return }
        update(refreshedSnapshot)
    }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            guard let self, self.popover.isShown else {
                self?.refreshTimer?.invalidate()
                self?.refreshTimer = nil
                return
            }
            self.refreshSnapshot()
        }
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
        case .recording: symbolName = "record.circle.fill"
        case .processing: symbolName = "ellipsis.circle"
        case .attention: symbolName = "exclamationmark.circle"
        }
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: snapshot.statusText)
        image?.isTemplate = true
        return image
    }

    @objc private func togglePopover() { popover.isShown ? closePopover() : showPopover() }

    func popoverDidClose(_ notification: Notification) {
        refreshTimer?.invalidate()
        refreshTimer = nil
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
        selectedOutputLanguage: String,
        versionText: String
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "PushWrite-Einstellungen"
        window.center()
        window.isReleasedWhenClosed = false
        window.backgroundColor = BrandStyle.background

        super.init(window: window)
        configureContent(
            hotKeyText: hotKeyText,
            accessibilityGranted: accessibilityGranted,
            microphoneStatus: microphoneStatus,
            selectedInputLanguage: selectedInputLanguage,
            selectedOutputLanguage: selectedOutputLanguage,
            versionText: versionText
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configureContent(
        hotKeyText: String,
        accessibilityGranted: Bool,
        microphoneStatus: String,
        selectedInputLanguage: String,
        selectedOutputLanguage: String,
        versionText: String
    ) {
        guard let contentView = window?.contentView else { return }

        let title = makeLabel("Einstellungen", size: 24, weight: .bold, heading: true)
        let claim = makeLabel("PushWrite \(versionText) · lokale Spracheingabe für macOS", size: 12, color: BrandStyle.secondaryText)
        let hotKey = makeLabel("Halten zum Sprechen: \(hotKeyText)", size: 13, weight: .bold)

        permissionLabel.stringValue = "Bedienungshilfen: \(accessibilityGranted ? "Erlaubt" : "Nicht erlaubt")\nMikrofon: \(microphoneStatus)"
        permissionLabel.font = BrandStyle.bodyFont(size: 12)
        permissionLabel.textColor = BrandStyle.secondaryText
        permissionLabel.setAccessibilityLabel("Berechtigungsstatus")

        let inputLanguageLabel = makeLabel("Gesprochene Sprache", size: 12, color: BrandStyle.secondaryText)
        inputLanguagePopup.addItems(withTitles: LanguageSettingsCatalog.inputTitles)
        inputLanguagePopup.selectItem(at: LanguageSettingsCatalog.inputValues.firstIndex(of: selectedInputLanguage) ?? 0)
        inputLanguagePopup.target = self
        inputLanguagePopup.action = #selector(inputLanguageChanged)
        inputLanguagePopup.setAccessibilityLabel("Gesprochene Sprache")

        let outputLanguageLabel = makeLabel("Ausgabesprache", size: 12, color: BrandStyle.secondaryText)
        outputLanguagePopup.addItems(withTitles: LanguageSettingsCatalog.outputTitles)
        let migratedOutputLanguage = selectedOutputLanguage == "auto" ? "system" : selectedOutputLanguage
        outputLanguagePopup.selectItem(at: LanguageSettingsCatalog.outputValues.firstIndex(of: migratedOutputLanguage) ?? 0)
        outputLanguagePopup.target = self
        outputLanguagePopup.action = #selector(outputLanguageChanged)
        outputLanguagePopup.setAccessibilityLabel("Ausgabesprache")

        let translationTitle = makeLabel("Lokale Sprachverarbeitung", size: 15, weight: .bold, heading: true)
        let translationNote = makeLabel(
            "Erkennung, Schweizerdeutsch-Normalisierung und Übersetzung laufen vollständig lokal. Audio und Text werden nicht übertragen; nach der Installation ist keine Netzwerkverbindung erforderlich.",
            size: 12,
            color: BrandStyle.secondaryText
        )

        let stack = NSStackView(views: [title, claim, hotKey, permissionLabel, inputLanguageLabel, inputLanguagePopup, outputLanguageLabel, outputLanguagePopup, translationTitle, translationNote])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 11
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
        let index = max(0, min(inputLanguagePopup.indexOfSelectedItem, LanguageSettingsCatalog.inputValues.count - 1))
        onInputLanguageChanged?(LanguageSettingsCatalog.inputValues[index])
    }

    @objc private func outputLanguageChanged() {
        let index = max(0, min(outputLanguagePopup.indexOfSelectedItem, LanguageSettingsCatalog.outputValues.count - 1))
        onOutputLanguageChanged?(LanguageSettingsCatalog.outputValues[index])
    }
}
