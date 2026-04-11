import AppKit
import ApplicationServices
import Carbon
import Foundation

enum ProductRequestKind: String, Codable {
    case preflight
    case insert
    case insertTranscription
    case shutdown
}

enum ProductResponseStatus: String, Codable {
    case ready
    case succeeded
    case blocked
    case failed
    case invalidRequest
    case stopped
}

enum InsertRoute: String, Codable {
    case pasteboardCommandV
}

enum InsertSource: String, Codable {
    case directRequest
    case transcription
}

enum ProductFlowState: String, Codable {
    case idle
    case triggered
    case blocked
    case inserting
    case done
    case error
}

enum FlowTriggerSource: String, Codable {
    case globalHotKey
}

var runtimeAccessibilityBlockedOverride = false
var runtimeAccessibilityTrustedOverride = false

struct LaunchOptions {
    let runtimeDir: String
    let simulatedTranscriptionText: String
    let forceAccessibilityBlocked: Bool
    let forceAccessibilityTrusted: Bool
}

struct GlobalHotKeyConfiguration {
    let keyCode: UInt32
    let carbonModifiers: UInt32
    let displayString: String
    let signature: OSType
    let identifier: UInt32

    static let `default` = GlobalHotKeyConfiguration(
        keyCode: UInt32(kVK_ANSI_P),
        carbonModifiers: UInt32(controlKey) | UInt32(optionKey) | UInt32(cmdKey),
        displayString: "Control+Option+Command+P",
        signature: fourCharCode("PWHK"),
        identifier: 1
    )
}

struct AppSnapshot: Codable {
    let name: String?
    let bundleID: String?
    let pid: Int32
}

struct FocusSnapshot: Codable {
    let app: AppSnapshot?
    let role: String?
    let subrole: String?
    let title: String?
    let value: String?
}

struct PasteboardItemSnapshot {
    let dataByType: [(NSPasteboard.PasteboardType, Data)]
}

struct PasteboardSnapshot {
    let changeCount: Int
    let items: [PasteboardItemSnapshot]
}

struct PasteboardMetadata: Codable {
    let changeCount: Int
    let itemCount: Int
}

struct HotKeyStateSnapshot: Codable {
    let descriptor: String
    let keyCode: UInt32
    let carbonModifiers: UInt32
    let registered: Bool
    let registrationError: String?
}

struct ReceiptObservation {
    let accessibilityTrusted: Bool
    let focusSnapshot: FocusSnapshot?
}

struct ProductFlowSnapshot: Codable {
    let id: String?
    let state: ProductFlowState
    let trigger: FlowTriggerSource?
    let timestamp: String
    let textLength: Int
    let blockedReason: String?
    let error: String?
}

struct ProductFlowEvent: Codable {
    let id: String
    let state: ProductFlowState
    let trigger: FlowTriggerSource
    let timestamp: String
    let textLength: Int
    let blockedReason: String?
    let error: String?
}

struct ProductRequest: Codable {
    let id: String
    let kind: ProductRequestKind
    let text: String?
    let restoreClipboard: Bool
    let promptAccessibility: Bool
    let settleDelayMs: UInt32?
    let pasteDelayMs: UInt32?
    let restoreDelayMs: UInt32?
}

struct ProductResponse: Codable {
    let id: String
    let kind: ProductRequestKind
    let timestamp: String
    let productBundleID: String?
    let productPID: Int32
    let status: ProductResponseStatus
    let accessibilityTrusted: Bool
    let promptAccessibility: Bool
    let blockedReason: String?
    let settleDelayMs: UInt32
    let pasteDelayMs: UInt32
    let restoreClipboard: Bool
    let restoreDelayMs: UInt32
    let textLength: Int
    let insertRoute: InsertRoute?
    let insertSource: InsertSource?
    let focusAtReceipt: FocusSnapshot?
    let focusBeforePaste: FocusSnapshot?
    let focusAfterPaste: FocusSnapshot?
    let productFrontmostAtReceipt: Bool
    let productFrontmostBeforePaste: Bool
    let productFrontmostAfterPaste: Bool
    let originalPasteboard: PasteboardMetadata?
    let syntheticPastePosted: Bool
    let clipboardRestored: Bool
    let error: String?
}

struct ProductState: Codable {
    let timestamp: String
    let runtimeDir: String
    let appPath: String
    let bundleID: String?
    let pid: Int32
    let running: Bool
    let accessibilityTrusted: Bool
    let blockedReason: String?
    let queuedRequestCount: Int
    let isProcessing: Bool
    let lastRequestID: String?
    let lastResponseStatus: ProductResponseStatus?
    let lastBlockedReason: String?
    let hotKey: HotKeyStateSnapshot
    let flow: ProductFlowSnapshot
}

struct ProductPaths {
    let runtimeDir: String
    let requestsDir: String
    let responsesDir: String
    let logsDir: String
    let stateFile: String
    let eventsLogFile: String
    let flowEventsLogFile: String
    let hotKeyResponsesLogFile: String
    let lastHotKeyResponseFile: String

    init(runtimeDir: String) {
        self.runtimeDir = runtimeDir
        self.requestsDir = "\(runtimeDir)/requests"
        self.responsesDir = "\(runtimeDir)/responses"
        self.logsDir = "\(runtimeDir)/logs"
        self.stateFile = "\(runtimeDir)/product-state.json"
        self.eventsLogFile = "\(runtimeDir)/logs/events.jsonl"
        self.flowEventsLogFile = "\(runtimeDir)/logs/flow-events.jsonl"
        self.hotKeyResponsesLogFile = "\(runtimeDir)/logs/hotkey-responses.jsonl"
        self.lastHotKeyResponseFile = "\(runtimeDir)/logs/last-hotkey-response.json"
    }

    func requestFile(for id: String) -> String {
        "\(requestsDir)/\(id).json"
    }

    func responseFile(for id: String) -> String {
        "\(responsesDir)/\(id).json"
    }
}

enum ProductRuntimeError: Error, CustomStringConvertible {
    case missingValue(flag: String)
    case unknownArgument(String)
    case invalidRequestFile(String)
    case invalidRequest(String)
    case accessibilityDenied
    case eventSourceUnavailable
    case eventCreationFailed

    var description: String {
        switch self {
        case let .missingValue(flag):
            return "Missing value for \(flag)."
        case let .unknownArgument(argument):
            return "Unknown argument: \(argument)"
        case let .invalidRequestFile(path):
            return "Could not load request file at \(path)."
        case let .invalidRequest(message):
            return message
        case .accessibilityDenied:
            return "Accessibility access is required before PushWrite can insert text with synthetic Cmd+V."
        case .eventSourceUnavailable:
            return "Could not create a CGEventSource for keyboard events."
        case .eventCreationFailed:
            return "Could not create one or more keyboard events for Cmd+V."
        }
    }
}

func parseLaunchOptions(arguments: [String]) throws -> LaunchOptions {
    var runtimeDir = ProcessInfo.processInfo.environment["PUSHWRITE_PRODUCT_RUNTIME_DIR"] ?? ""
    var simulatedTranscriptionText = defaultSimulatedTranscriptionText()
    var forceAccessibilityBlocked = accessibilityBlockedOverrideEnabled()
    var forceAccessibilityTrusted = ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_ACCESSIBILITY_TRUSTED"] == "1"
    var index = 0

    func requireValue(for flag: String) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < arguments.count else {
            throw ProductRuntimeError.missingValue(flag: flag)
        }
        index = valueIndex
        return arguments[valueIndex]
    }

    while index < arguments.count {
        let argument = arguments[index]
        switch argument {
        case "--runtime-dir":
            runtimeDir = try requireValue(for: argument)
        case "--simulated-transcription-text":
            simulatedTranscriptionText = try requireValue(for: argument)
        case "--force-accessibility-blocked":
            forceAccessibilityBlocked = true
        case "--force-accessibility-trusted":
            forceAccessibilityTrusted = true
        default:
            throw ProductRuntimeError.unknownArgument(argument)
        }
        index += 1
    }

    if runtimeDir.isEmpty {
        runtimeDir = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Library/Application Support/PushWrite/runtime"
    }

    return LaunchOptions(
        runtimeDir: runtimeDir,
        simulatedTranscriptionText: simulatedTranscriptionText,
        forceAccessibilityBlocked: forceAccessibilityBlocked,
        forceAccessibilityTrusted: forceAccessibilityTrusted
    )
}

func sleepMs(_ value: UInt32) {
    usleep(value * 1_000)
}

func isoTimestamp() -> String {
    ISO8601DateFormatter().string(from: Date())
}

func fourCharCode(_ value: String) -> OSType {
    value.utf8.reduce(0) { partialResult, byte in
        (partialResult << 8) | OSType(byte)
    }
}

func defaultSimulatedTranscriptionText() -> String {
    let override = ProcessInfo.processInfo.environment["PUSHWRITE_SIMULATED_TRANSCRIPTION_TEXT"]?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    if let override, !override.isEmpty {
        return override
    }
    return "PushWrite 002E simulated transcription."
}

func hotKeyRegistrationErrorMessage(status: OSStatus) -> String {
    "Global hotkey registration failed with OSStatus \(status)."
}

func currentFrontmostApp() -> NSRunningApplication? {
    NSWorkspace.shared.frontmostApplication
}

func accessibilityBlockedOverrideEnabled() -> Bool {
    runtimeAccessibilityBlockedOverride || ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_ACCESSIBILITY_BLOCKED"] == "1"
}

func isAccessibilityTrusted(prompt: Bool) -> Bool {
    if runtimeAccessibilityTrustedOverride || ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_ACCESSIBILITY_TRUSTED"] == "1" {
        return true
    }
    if accessibilityBlockedOverrideEnabled() {
        return false
    }
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
}

func copyStringAttribute(_ name: CFString, from element: AXUIElement) -> String? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, name, &value)
    guard result == .success else {
        return nil
    }
    return value as? String
}

func copyFocusedElement(from app: NSRunningApplication) -> AXUIElement? {
    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &value)
    guard result == .success, let focused = value else {
        return nil
    }
    return unsafeBitCast(focused, to: AXUIElement.self)
}

func captureFocusSnapshot(isTrusted: Bool) -> FocusSnapshot? {
    guard let app = currentFrontmostApp() else {
        return nil
    }

    let appSnapshot = AppSnapshot(
        name: app.localizedName,
        bundleID: app.bundleIdentifier,
        pid: app.processIdentifier
    )

    guard isTrusted, let focusedElement = copyFocusedElement(from: app) else {
        return FocusSnapshot(app: appSnapshot, role: nil, subrole: nil, title: nil, value: nil)
    }

    return FocusSnapshot(
        app: appSnapshot,
        role: copyStringAttribute(kAXRoleAttribute as CFString, from: focusedElement),
        subrole: copyStringAttribute(kAXSubroleAttribute as CFString, from: focusedElement),
        title: copyStringAttribute(kAXTitleAttribute as CFString, from: focusedElement),
        value: copyStringAttribute(kAXValueAttribute as CFString, from: focusedElement)
    )
}

func snapshotGeneralPasteboard() -> PasteboardSnapshot {
    let pasteboard = NSPasteboard.general
    let items = pasteboard.pasteboardItems ?? []
    let snapshotItems = items.map { item in
        PasteboardItemSnapshot(
            dataByType: item.types.compactMap { type in
                guard let data = item.data(forType: type) else {
                    return nil
                }
                return (type, data)
            }
        )
    }

    return PasteboardSnapshot(changeCount: pasteboard.changeCount, items: snapshotItems)
}

func restoreGeneralPasteboard(from snapshot: PasteboardSnapshot) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    let restoredItems = snapshot.items.map { itemSnapshot in
        let item = NSPasteboardItem()
        for (type, data) in itemSnapshot.dataByType {
            item.setData(data, forType: type)
        }
        return item
    }

    if !restoredItems.isEmpty {
        pasteboard.writeObjects(restoredItems)
    }
}

func writePlainTextToPasteboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

func postSyntheticPaste() throws {
    guard let source = CGEventSource(stateID: .combinedSessionState) else {
        throw ProductRuntimeError.eventSourceUnavailable
    }

    let keyCodeV: CGKeyCode = 9
    guard
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: true),
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: false)
    else {
        throw ProductRuntimeError.eventCreationFailed
    }

    keyDown.flags = .maskCommand
    keyUp.flags = .maskCommand

    keyDown.post(tap: .cghidEventTap)
    usleep(15_000)
    keyUp.post(tap: .cghidEventTap)
}

func isProductFrontmost(_ focus: FocusSnapshot?) -> Bool {
    focus?.app?.pid == ProcessInfo.processInfo.processIdentifier
}

func ensureDirectory(_ path: String) throws {
    try FileManager.default.createDirectory(
        at: URL(fileURLWithPath: path),
        withIntermediateDirectories: true,
        attributes: nil
    )
}

func writeJSON<T: Encodable>(_ value: T, to path: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    try FileManager.default.createDirectory(
        at: URL(fileURLWithPath: path).deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil
    )
    try data.write(to: URL(fileURLWithPath: path), options: .atomic)
}

func appendJSONLine<T: Encodable>(_ value: T, to path: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    try FileManager.default.createDirectory(
        at: URL(fileURLWithPath: path).deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil
    )

    if !FileManager.default.fileExists(atPath: path) {
        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
    }

    let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
    defer { try? handle.close() }
    try handle.seekToEnd()
    handle.write(data)
    handle.write(Data([0x0A]))
}

func readRequest(at path: String) throws -> ProductRequest {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else {
        throw ProductRuntimeError.invalidRequestFile(path)
    }

    var lastError: Error?
    for attempt in 0..<5 {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(ProductRequest.self, from: data)
        } catch {
            lastError = error
            if attempt < 4 {
                usleep(50_000)
            }
        }
    }

    throw lastError ?? ProductRuntimeError.invalidRequestFile(path)
}

final class AccessibilityBlockedWindowController: NSWindowController, NSWindowDelegate {
    private let onOpenSettings: () -> Void
    private let onDismiss: () -> Void

    init(bundleName: String, blockedReason: String, onOpenSettings: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
        self.onDismiss = onDismiss

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "PushWrite setup required"
        window.center()
        window.isReleasedWhenClosed = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView

        let titleLabel = NSTextField(labelWithString: "Accessibility access required")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let bodyLabel = NSTextField(wrappingLabelWithString: "\(bundleName) cannot insert text until Accessibility is enabled for this app in System Settings > Privacy & Security > Accessibility.\n\n\(blockedReason)")
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        let openButton = NSButton(title: "Open System Settings", target: nil, action: nil)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.keyEquivalent = "\r"

        let dismissButton = NSButton(title: "Not Now", target: nil, action: nil)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(openButton)
        contentView.addSubview(dismissButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),

            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),

            dismissButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            dismissButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            openButton.trailingAnchor.constraint(equalTo: dismissButton.leadingAnchor, constant: -12),
            openButton.bottomAnchor.constraint(equalTo: dismissButton.bottomAnchor)
        ])

        super.init(window: window)
        window.delegate = self
        openButton.target = self
        openButton.action = #selector(openSettings)
        dismissButton.target = self
        dismissButton.action = #selector(dismissPanel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func openSettings() {
        onOpenSettings()
        close()
    }

    @objc private func dismissPanel() {
        close()
    }

    func windowWillClose(_ notification: Notification) {
        onDismiss()
    }
}

final class PushWriteAppDelegate: NSObject, NSApplicationDelegate {
    private let launchOptions: LaunchOptions
    private let paths: ProductPaths
    private let hotKeyConfiguration = GlobalHotKeyConfiguration.default
    private let defaults = (settle: UInt32(150), paste: UInt32(120), restore: UInt32(350))
    private let workerQueue = DispatchQueue(label: "ch.baumanncreative.pushwrite.worker")
    private var queuedRequestIDs: [String] = []
    private var activeRequestID: String?
    private var activeHotKeyFlowID: String?
    private var isProcessing = false
    private var lastRequestID: String?
    private var lastResponseStatus: ProductResponseStatus?
    private var lastBlockedReason: String?
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyEventHandler: EventHandlerRef?
    private var hotKeyState: HotKeyStateSnapshot
    private var flowSnapshot: ProductFlowSnapshot
    private var pollTimer: Timer?
    private var blockedWindowController: AccessibilityBlockedWindowController?
    private var launchBlockedUIHasBeenPresented = false

    init(launchOptions: LaunchOptions) {
        let hotKeyConfiguration = GlobalHotKeyConfiguration.default
        self.launchOptions = launchOptions
        self.paths = ProductPaths(runtimeDir: launchOptions.runtimeDir)
        self.hotKeyState = HotKeyStateSnapshot(
            descriptor: hotKeyConfiguration.displayString,
            keyCode: hotKeyConfiguration.keyCode,
            carbonModifiers: hotKeyConfiguration.carbonModifiers,
            registered: false,
            registrationError: nil
        )
        self.flowSnapshot = ProductFlowSnapshot(
            id: nil,
            state: .idle,
            trigger: nil,
            timestamp: isoTimestamp(),
            textLength: 0,
            blockedReason: nil,
            error: nil
        )
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            try prepareRuntime()
            registerGlobalHotKey()
            try writeState(running: true)
        } catch {
            fputs("Product startup failed: \(error)\n", stderr)
            NSApp.terminate(nil)
            return
        }

        if !isAccessibilityTrusted(prompt: false) {
            presentAccessibilityBlockedUIIfNeeded(triggeredByLaunch: true)
        }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.pollRequestsDirectory()
        }
        pollRequestsDirectory()
    }

    func applicationWillTerminate(_ notification: Notification) {
        pollTimer?.invalidate()
        unregisterGlobalHotKey()
        try? writeState(running: false)
    }

    private func registerGlobalHotKey() {
        let hotKeyUserData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData, let event else {
                    return noErr
                }
                let delegate = Unmanaged<PushWriteAppDelegate>.fromOpaque(userData).takeUnretainedValue()
                return delegate.handleHotKeyEvent(event)
            },
            1,
            &eventType,
            hotKeyUserData,
            &hotKeyEventHandler
        )

        guard handlerStatus == noErr else {
            hotKeyState = HotKeyStateSnapshot(
                descriptor: hotKeyConfiguration.displayString,
                keyCode: hotKeyConfiguration.keyCode,
                carbonModifiers: hotKeyConfiguration.carbonModifiers,
                registered: false,
                registrationError: hotKeyRegistrationErrorMessage(status: handlerStatus)
            )
            fputs("\(hotKeyState.registrationError ?? "Global hotkey registration failed.")\n", stderr)
            return
        }

        let hotKeyID = EventHotKeyID(signature: hotKeyConfiguration.signature, id: hotKeyConfiguration.identifier)
        let registrationStatus = RegisterEventHotKey(
            hotKeyConfiguration.keyCode,
            hotKeyConfiguration.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registrationStatus == noErr else {
            if let hotKeyEventHandler {
                RemoveEventHandler(hotKeyEventHandler)
                self.hotKeyEventHandler = nil
            }
            hotKeyState = HotKeyStateSnapshot(
                descriptor: hotKeyConfiguration.displayString,
                keyCode: hotKeyConfiguration.keyCode,
                carbonModifiers: hotKeyConfiguration.carbonModifiers,
                registered: false,
                registrationError: hotKeyRegistrationErrorMessage(status: registrationStatus)
            )
            fputs("\(hotKeyState.registrationError ?? "Global hotkey registration failed.")\n", stderr)
            return
        }

        hotKeyState = HotKeyStateSnapshot(
            descriptor: hotKeyConfiguration.displayString,
            keyCode: hotKeyConfiguration.keyCode,
            carbonModifiers: hotKeyConfiguration.carbonModifiers,
            registered: true,
            registrationError: nil
        )
    }

    private func unregisterGlobalHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let hotKeyEventHandler {
            RemoveEventHandler(hotKeyEventHandler)
            self.hotKeyEventHandler = nil
        }
    }

    private func handleHotKeyEvent(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else {
            return status
        }

        guard hotKeyID.signature == hotKeyConfiguration.signature, hotKeyID.id == hotKeyConfiguration.identifier else {
            return noErr
        }

        handleGlobalHotKeyPressed()
        return noErr
    }

    private func handleGlobalHotKeyPressed() {
        let flowID = UUID().uuidString
        let text = launchOptions.simulatedTranscriptionText
        let receiptObservation = captureReceiptObservation(promptAccessibility: false)

        guard hotKeyState.registered else {
            transitionFlow(
                to: .error,
                id: flowID,
                trigger: .globalHotKey,
                textLength: text.count,
                error: hotKeyState.registrationError ?? "Global hotkey is not registered."
            )
            DispatchQueue.main.async {
                NSSound.beep()
            }
            return
        }

        guard !isProcessing else {
            transitionFlow(
                to: .blocked,
                id: flowID,
                trigger: .globalHotKey,
                textLength: text.count,
                blockedReason: "PushWrite is already processing another action."
            )
            DispatchQueue.main.async {
                NSSound.beep()
            }
            return
        }

        isProcessing = true
        activeHotKeyFlowID = flowID
        transitionFlow(to: .triggered, id: flowID, trigger: .globalHotKey, textLength: text.count)

        workerQueue.async {
            let response = self.performGlobalHotKeyFlow(
                flowID: flowID,
                text: text,
                receiptObservation: receiptObservation
            )
            DispatchQueue.main.async {
                self.completeGlobalHotKeyFlow(flowID: flowID, response: response)
            }
        }
    }

    private func captureReceiptObservation(promptAccessibility: Bool) -> ReceiptObservation {
        let accessibilityTrusted = isAccessibilityTrusted(prompt: promptAccessibility)
        return ReceiptObservation(
            accessibilityTrusted: accessibilityTrusted,
            focusSnapshot: captureFocusSnapshot(isTrusted: accessibilityTrusted)
        )
    }

    private func performGlobalHotKeyFlow(
        flowID: String,
        text: String,
        receiptObservation: ReceiptObservation
    ) -> ProductResponse {
        DispatchQueue.main.sync {
            self.transitionFlow(to: .inserting, id: flowID, trigger: .globalHotKey, textLength: text.count)
        }

        do {
            return try insertTranscription(
                text: text,
                requestID: flowID,
                presentsBlockedUI: false,
                receiptObservation: receiptObservation
            )
        } catch {
            return ProductResponse(
                id: flowID,
                kind: .insertTranscription,
                timestamp: isoTimestamp(),
                productBundleID: Bundle.main.bundleIdentifier,
                productPID: ProcessInfo.processInfo.processIdentifier,
                status: .failed,
                accessibilityTrusted: receiptObservation.accessibilityTrusted,
                promptAccessibility: false,
                blockedReason: nil,
                settleDelayMs: defaults.settle,
                pasteDelayMs: defaults.paste,
                restoreClipboard: false,
                restoreDelayMs: defaults.restore,
                textLength: text.count,
                insertRoute: .pasteboardCommandV,
                insertSource: .transcription,
                focusAtReceipt: receiptObservation.focusSnapshot,
                focusBeforePaste: nil,
                focusAfterPaste: nil,
                productFrontmostAtReceipt: isProductFrontmost(receiptObservation.focusSnapshot),
                productFrontmostBeforePaste: false,
                productFrontmostAfterPaste: false,
                originalPasteboard: nil,
                syntheticPastePosted: false,
                clipboardRestored: false,
                error: "\(error)"
            )
        }
    }

    private func completeGlobalHotKeyFlow(flowID: String, response: ProductResponse) {
        do {
            try writeJSON(response, to: paths.lastHotKeyResponseFile)
            try appendJSONLine(response, to: paths.hotKeyResponsesLogFile)
        } catch {
            fputs("Could not persist hotkey response for \(flowID): \(error)\n", stderr)
        }

        activeHotKeyFlowID = nil
        isProcessing = false
        lastRequestID = response.id
        lastResponseStatus = response.status
        lastBlockedReason = response.blockedReason

        transitionFlow(
            to: terminalFlowState(for: response),
            id: flowID,
            trigger: .globalHotKey,
            textLength: response.textLength,
            blockedReason: response.blockedReason,
            error: response.error
        )

        processNextRequestIfNeeded()
    }

    private func terminalFlowState(for response: ProductResponse) -> ProductFlowState {
        switch response.status {
        case .succeeded:
            return .done
        case .blocked:
            return .blocked
        case .failed, .invalidRequest:
            return .error
        case .ready, .stopped:
            return .error
        }
    }

    private func transitionFlow(
        to state: ProductFlowState,
        id: String? = nil,
        trigger: FlowTriggerSource? = nil,
        textLength: Int = 0,
        blockedReason: String? = nil,
        error: String? = nil
    ) {
        let snapshot = ProductFlowSnapshot(
            id: id,
            state: state,
            trigger: trigger,
            timestamp: isoTimestamp(),
            textLength: textLength,
            blockedReason: blockedReason,
            error: error
        )
        flowSnapshot = snapshot

        if let id, let trigger {
            let event = ProductFlowEvent(
                id: id,
                state: state,
                trigger: trigger,
                timestamp: snapshot.timestamp,
                textLength: textLength,
                blockedReason: blockedReason,
                error: error
            )
            try? appendJSONLine(event, to: paths.flowEventsLogFile)
        }

        try? writeState(running: true)
    }

    private func prepareRuntime() throws {
        try ensureDirectory(paths.runtimeDir)
        try ensureDirectory(paths.requestsDir)
        try ensureDirectory(paths.responsesDir)
        try ensureDirectory(paths.logsDir)
    }

    private func pollRequestsDirectory() {
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: paths.requestsDir) else {
            return
        }

        let requestIDs = entries
            .filter { $0.hasSuffix(".json") }
            .map { String($0.dropLast(5)) }
            .sorted()

        var addedRequest = false
        for requestID in requestIDs {
            if requestID == activeRequestID || queuedRequestIDs.contains(requestID) {
                continue
            }
            queuedRequestIDs.append(requestID)
            addedRequest = true
        }

        if addedRequest {
            try? writeState(running: true)
            processNextRequestIfNeeded()
        }
    }

    private func writeState(running: Bool) throws {
        let accessibilityTrusted = isAccessibilityTrusted(prompt: false)
        let state = ProductState(
            timestamp: isoTimestamp(),
            runtimeDir: paths.runtimeDir,
            appPath: Bundle.main.bundlePath,
            bundleID: Bundle.main.bundleIdentifier,
            pid: ProcessInfo.processInfo.processIdentifier,
            running: running,
            accessibilityTrusted: accessibilityTrusted,
            blockedReason: accessibilityTrusted ? lastBlockedReason : ProductRuntimeError.accessibilityDenied.description,
            queuedRequestCount: queuedRequestIDs.count,
            isProcessing: isProcessing,
            lastRequestID: lastRequestID,
            lastResponseStatus: lastResponseStatus,
            lastBlockedReason: lastBlockedReason,
            hotKey: hotKeyState,
            flow: flowSnapshot
        )
        try writeJSON(state, to: paths.stateFile)
    }

    private func processNextRequestIfNeeded() {
        guard !isProcessing, let nextRequestID = queuedRequestIDs.first else {
            return
        }

        isProcessing = true
        activeRequestID = nextRequestID
        try? writeState(running: true)

        workerQueue.async {
            let response = self.performRequest(withID: nextRequestID)
            DispatchQueue.main.async {
                self.completeRequest(withID: nextRequestID, response: response)
            }
        }
    }

    private func performRequest(withID requestID: String) -> ProductResponse {
        let requestPath = paths.requestFile(for: requestID)

        do {
            let request = try readRequest(at: requestPath)
            switch request.kind {
            case .preflight:
                return performPreflight(request)
            case .insert:
                return try performDirectInsert(request)
            case .insertTranscription:
                return try insertTranscription(text: request.text, request: request)
            case .shutdown:
                return performShutdown(request)
            }
        } catch {
            return ProductResponse(
                id: requestID,
                kind: .preflight,
                timestamp: isoTimestamp(),
                productBundleID: Bundle.main.bundleIdentifier,
                productPID: ProcessInfo.processInfo.processIdentifier,
                status: .invalidRequest,
                accessibilityTrusted: isAccessibilityTrusted(prompt: false),
                promptAccessibility: false,
                blockedReason: nil,
                settleDelayMs: defaults.settle,
                pasteDelayMs: defaults.paste,
                restoreClipboard: false,
                restoreDelayMs: defaults.restore,
                textLength: 0,
                insertRoute: nil,
                insertSource: nil,
                focusAtReceipt: captureFocusSnapshot(isTrusted: false),
                focusBeforePaste: nil,
                focusAfterPaste: nil,
                productFrontmostAtReceipt: false,
                productFrontmostBeforePaste: false,
                productFrontmostAfterPaste: false,
                originalPasteboard: nil,
                syntheticPastePosted: false,
                clipboardRestored: false,
                error: "\(error)"
            )
        }
    }

    private func performPreflight(_ request: ProductRequest) -> ProductResponse {
        let accessibilityTrusted = isAccessibilityTrusted(prompt: request.promptAccessibility)
        let focusAtReceipt = captureFocusSnapshot(isTrusted: accessibilityTrusted)
        let blockedReason = accessibilityTrusted ? nil : ProductRuntimeError.accessibilityDenied.description

        if !accessibilityTrusted, request.promptAccessibility {
            presentAccessibilityBlockedUIIfNeeded(triggeredByLaunch: false)
        }

        return ProductResponse(
            id: request.id,
            kind: request.kind,
            timestamp: isoTimestamp(),
            productBundleID: Bundle.main.bundleIdentifier,
            productPID: ProcessInfo.processInfo.processIdentifier,
            status: accessibilityTrusted ? .ready : .blocked,
            accessibilityTrusted: accessibilityTrusted,
            promptAccessibility: request.promptAccessibility,
            blockedReason: blockedReason,
            settleDelayMs: request.settleDelayMs ?? defaults.settle,
            pasteDelayMs: request.pasteDelayMs ?? defaults.paste,
            restoreClipboard: request.restoreClipboard,
            restoreDelayMs: request.restoreDelayMs ?? defaults.restore,
            textLength: request.text?.count ?? 0,
            insertRoute: nil,
            insertSource: nil,
            focusAtReceipt: focusAtReceipt,
            focusBeforePaste: focusAtReceipt,
            focusAfterPaste: focusAtReceipt,
            productFrontmostAtReceipt: isProductFrontmost(focusAtReceipt),
            productFrontmostBeforePaste: isProductFrontmost(focusAtReceipt),
            productFrontmostAfterPaste: isProductFrontmost(focusAtReceipt),
            originalPasteboard: nil,
            syntheticPastePosted: false,
            clipboardRestored: false,
            error: nil
        )
    }

    private func performDirectInsert(_ request: ProductRequest) throws -> ProductResponse {
        try performInsert(request: request, text: request.text, source: .directRequest, presentsBlockedUI: request.promptAccessibility)
    }

    private func insertTranscription(text: String?, request: ProductRequest) throws -> ProductResponse {
        try performInsert(request: request, text: text, source: .transcription, presentsBlockedUI: request.promptAccessibility)
    }

    private func insertTranscription(
        text: String?,
        requestID: String = UUID().uuidString,
        presentsBlockedUI: Bool,
        receiptObservation: ReceiptObservation? = nil
    ) throws -> ProductResponse {
        let request = ProductRequest(
            id: requestID,
            kind: .insertTranscription,
            text: text,
            restoreClipboard: false,
            promptAccessibility: false,
            settleDelayMs: nil,
            pasteDelayMs: nil,
            restoreDelayMs: nil
        )
        return try performInsert(
            request: request,
            text: text,
            source: .transcription,
            presentsBlockedUI: presentsBlockedUI,
            receiptObservation: receiptObservation
        )
    }

    private func performInsert(
        request: ProductRequest,
        text: String?,
        source: InsertSource,
        presentsBlockedUI: Bool,
        receiptObservation: ReceiptObservation? = nil
    ) throws -> ProductResponse {
        let settleDelayMs = request.settleDelayMs ?? defaults.settle
        let pasteDelayMs = request.pasteDelayMs ?? defaults.paste
        let restoreDelayMs = request.restoreDelayMs ?? defaults.restore
        let accessibilityTrusted = receiptObservation?.accessibilityTrusted ?? isAccessibilityTrusted(prompt: request.promptAccessibility)
        let focusAtReceipt = receiptObservation?.focusSnapshot ?? captureFocusSnapshot(isTrusted: accessibilityTrusted)

        guard accessibilityTrusted else {
            if presentsBlockedUI {
                presentAccessibilityBlockedUIIfNeeded(triggeredByLaunch: false)
            } else {
                DispatchQueue.main.async {
                    NSSound.beep()
                }
            }
            return ProductResponse(
                id: request.id,
                kind: request.kind,
                timestamp: isoTimestamp(),
                productBundleID: Bundle.main.bundleIdentifier,
                productPID: ProcessInfo.processInfo.processIdentifier,
                status: .blocked,
                accessibilityTrusted: false,
                promptAccessibility: request.promptAccessibility,
                blockedReason: ProductRuntimeError.accessibilityDenied.description,
                settleDelayMs: settleDelayMs,
                pasteDelayMs: pasteDelayMs,
                restoreClipboard: request.restoreClipboard,
                restoreDelayMs: restoreDelayMs,
                textLength: text?.count ?? 0,
                insertRoute: .pasteboardCommandV,
                insertSource: source,
                focusAtReceipt: focusAtReceipt,
                focusBeforePaste: focusAtReceipt,
                focusAfterPaste: focusAtReceipt,
                productFrontmostAtReceipt: isProductFrontmost(focusAtReceipt),
                productFrontmostBeforePaste: isProductFrontmost(focusAtReceipt),
                productFrontmostAfterPaste: isProductFrontmost(focusAtReceipt),
                originalPasteboard: nil,
                syntheticPastePosted: false,
                clipboardRestored: false,
                error: nil
            )
        }

        guard let text, !text.isEmpty else {
            throw ProductRuntimeError.invalidRequest("Insert requests require a non-empty text payload.")
        }

        sleepMs(settleDelayMs)
        let focusBeforePaste = captureFocusSnapshot(isTrusted: true)
        let originalPasteboardSnapshot = request.restoreClipboard ? snapshotGeneralPasteboard() : nil
        let originalPasteboardMetadata = originalPasteboardSnapshot.map {
            PasteboardMetadata(changeCount: $0.changeCount, itemCount: $0.items.count)
        }

        writePlainTextToPasteboard(text)
        sleepMs(pasteDelayMs)

        do {
            try postSyntheticPaste()
        } catch {
            let focusAfterFailure = captureFocusSnapshot(isTrusted: true)
            return ProductResponse(
                id: request.id,
                kind: request.kind,
                timestamp: isoTimestamp(),
                productBundleID: Bundle.main.bundleIdentifier,
                productPID: ProcessInfo.processInfo.processIdentifier,
                status: .failed,
                accessibilityTrusted: true,
                promptAccessibility: request.promptAccessibility,
                blockedReason: nil,
                settleDelayMs: settleDelayMs,
                pasteDelayMs: pasteDelayMs,
                restoreClipboard: request.restoreClipboard,
                restoreDelayMs: restoreDelayMs,
                textLength: text.count,
                insertRoute: .pasteboardCommandV,
                insertSource: source,
                focusAtReceipt: focusAtReceipt,
                focusBeforePaste: focusBeforePaste,
                focusAfterPaste: focusAfterFailure,
                productFrontmostAtReceipt: isProductFrontmost(focusAtReceipt),
                productFrontmostBeforePaste: isProductFrontmost(focusBeforePaste),
                productFrontmostAfterPaste: isProductFrontmost(focusAfterFailure),
                originalPasteboard: originalPasteboardMetadata,
                syntheticPastePosted: false,
                clipboardRestored: false,
                error: "\(error)"
            )
        }

        let focusAfterPaste = captureFocusSnapshot(isTrusted: true)

        if let snapshot = originalPasteboardSnapshot {
            sleepMs(restoreDelayMs)
            restoreGeneralPasteboard(from: snapshot)
        }

        return ProductResponse(
            id: request.id,
            kind: request.kind,
            timestamp: isoTimestamp(),
            productBundleID: Bundle.main.bundleIdentifier,
            productPID: ProcessInfo.processInfo.processIdentifier,
            status: .succeeded,
            accessibilityTrusted: true,
            promptAccessibility: request.promptAccessibility,
            blockedReason: nil,
            settleDelayMs: settleDelayMs,
            pasteDelayMs: pasteDelayMs,
            restoreClipboard: request.restoreClipboard,
            restoreDelayMs: restoreDelayMs,
            textLength: text.count,
            insertRoute: .pasteboardCommandV,
            insertSource: source,
            focusAtReceipt: focusAtReceipt,
            focusBeforePaste: focusBeforePaste,
            focusAfterPaste: focusAfterPaste,
            productFrontmostAtReceipt: isProductFrontmost(focusAtReceipt),
            productFrontmostBeforePaste: isProductFrontmost(focusBeforePaste),
            productFrontmostAfterPaste: isProductFrontmost(focusAfterPaste),
            originalPasteboard: originalPasteboardMetadata,
            syntheticPastePosted: true,
            clipboardRestored: originalPasteboardSnapshot != nil,
            error: nil
        )
    }

    private func performShutdown(_ request: ProductRequest) -> ProductResponse {
        let accessibilityTrusted = isAccessibilityTrusted(prompt: false)
        let focus = captureFocusSnapshot(isTrusted: accessibilityTrusted)

        return ProductResponse(
            id: request.id,
            kind: request.kind,
            timestamp: isoTimestamp(),
            productBundleID: Bundle.main.bundleIdentifier,
            productPID: ProcessInfo.processInfo.processIdentifier,
            status: .stopped,
            accessibilityTrusted: accessibilityTrusted,
            promptAccessibility: request.promptAccessibility,
            blockedReason: nil,
            settleDelayMs: request.settleDelayMs ?? defaults.settle,
            pasteDelayMs: request.pasteDelayMs ?? defaults.paste,
            restoreClipboard: request.restoreClipboard,
            restoreDelayMs: request.restoreDelayMs ?? defaults.restore,
            textLength: 0,
            insertRoute: nil,
            insertSource: nil,
            focusAtReceipt: focus,
            focusBeforePaste: focus,
            focusAfterPaste: focus,
            productFrontmostAtReceipt: isProductFrontmost(focus),
            productFrontmostBeforePaste: isProductFrontmost(focus),
            productFrontmostAfterPaste: isProductFrontmost(focus),
            originalPasteboard: nil,
            syntheticPastePosted: false,
            clipboardRestored: false,
            error: nil
        )
    }

    private func completeRequest(withID requestID: String, response: ProductResponse) {
        do {
            try writeJSON(response, to: paths.responseFile(for: requestID))
            try appendJSONLine(response, to: paths.eventsLogFile)
        } catch {
            fputs("Could not persist response for \(requestID): \(error)\n", stderr)
        }

        try? FileManager.default.removeItem(atPath: paths.requestFile(for: requestID))

        if !queuedRequestIDs.isEmpty, queuedRequestIDs[0] == requestID {
            queuedRequestIDs.removeFirst()
        } else {
            queuedRequestIDs.removeAll { $0 == requestID }
        }

        isProcessing = false
        activeRequestID = nil
        lastRequestID = response.id
        lastResponseStatus = response.status
        lastBlockedReason = response.blockedReason

        if response.kind == .shutdown {
            try? writeState(running: false)
            NSApp.terminate(nil)
            return
        }

        try? writeState(running: true)

        processNextRequestIfNeeded()
    }

    private func presentAccessibilityBlockedUIIfNeeded(triggeredByLaunch: Bool) {
        DispatchQueue.main.async {
            if isAccessibilityTrusted(prompt: false) {
                self.dismissBlockedWindowIfNeeded()
                return
            }

            if triggeredByLaunch && self.launchBlockedUIHasBeenPresented {
                return
            }

            if self.blockedWindowController != nil {
                return
            }

            self.launchBlockedUIHasBeenPresented = self.launchBlockedUIHasBeenPresented || triggeredByLaunch
            NSApp.setActivationPolicy(.accessory)
            let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "PushWrite"
            let controller = AccessibilityBlockedWindowController(
                bundleName: bundleName,
                blockedReason: ProductRuntimeError.accessibilityDenied.description,
                onOpenSettings: { [weak self] in
                    self?.openAccessibilitySettings()
                },
                onDismiss: { [weak self] in
                    self?.blockedWindowController = nil
                    if !isAccessibilityTrusted(prompt: false) {
                        NSApp.setActivationPolicy(.prohibited)
                    }
                    try? self?.writeState(running: true)
                }
            )
            self.blockedWindowController = controller
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func dismissBlockedWindowIfNeeded() {
        if let controller = blockedWindowController {
            controller.close()
            blockedWindowController = nil
        }
        NSApp.setActivationPolicy(.prohibited)
    }

    private func openAccessibilitySettings() {
        guard let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(settingsURL)
    }
}

let launchOptions: LaunchOptions
do {
    launchOptions = try parseLaunchOptions(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
    fputs("\(error)\n", stderr)
    exit(64)
}

runtimeAccessibilityBlockedOverride = launchOptions.forceAccessibilityBlocked
runtimeAccessibilityTrustedOverride = launchOptions.forceAccessibilityTrusted

let app = NSApplication.shared
let delegate = PushWriteAppDelegate(launchOptions: launchOptions)
app.delegate = delegate
app.run()
