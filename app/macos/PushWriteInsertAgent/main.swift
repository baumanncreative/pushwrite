import AppKit
import ApplicationServices
import Foundation

enum AgentRequestKind: String, Codable {
    case preflight
    case insert
    case shutdown
}

enum AgentResponseStatus: String, Codable {
    case ready
    case succeeded
    case blocked
    case failed
    case invalidRequest
    case stopped
}

struct LaunchOptions {
    let runtimeDir: String
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

struct AgentRequest: Codable {
    let id: String
    let kind: AgentRequestKind
    let text: String?
    let restoreClipboard: Bool
    let promptAccessibility: Bool
    let settleDelayMs: UInt32?
    let pasteDelayMs: UInt32?
    let restoreDelayMs: UInt32?
}

struct AgentResponse: Codable {
    let id: String
    let kind: AgentRequestKind
    let timestamp: String
    let agentBundleID: String?
    let agentPID: Int32
    let status: AgentResponseStatus
    let accessibilityTrusted: Bool
    let promptAccessibility: Bool
    let blockedReason: String?
    let settleDelayMs: UInt32
    let pasteDelayMs: UInt32
    let restoreClipboard: Bool
    let restoreDelayMs: UInt32
    let textLength: Int
    let focusAtReceipt: FocusSnapshot?
    let focusBeforePaste: FocusSnapshot?
    let focusAfterPaste: FocusSnapshot?
    let agentFrontmostAtReceipt: Bool
    let agentFrontmostBeforePaste: Bool
    let agentFrontmostAfterPaste: Bool
    let originalPasteboard: PasteboardMetadata?
    let syntheticPastePosted: Bool
    let clipboardRestored: Bool
    let error: String?
}

struct AgentState: Codable {
    let timestamp: String
    let runtimeDir: String
    let bundleID: String?
    let pid: Int32
    let running: Bool
    let accessibilityTrusted: Bool
    let blockedReason: String?
    let queuedRequestCount: Int
    let isProcessing: Bool
    let lastRequestID: String?
    let lastResponseStatus: AgentResponseStatus?
    let lastBlockedReason: String?
}

struct AgentPaths {
    let runtimeDir: String
    let requestsDir: String
    let responsesDir: String
    let logsDir: String
    let stateFile: String
    let eventsLogFile: String

    init(runtimeDir: String) {
        self.runtimeDir = runtimeDir
        self.requestsDir = "\(runtimeDir)/requests"
        self.responsesDir = "\(runtimeDir)/responses"
        self.logsDir = "\(runtimeDir)/logs"
        self.stateFile = "\(runtimeDir)/agent-state.json"
        self.eventsLogFile = "\(runtimeDir)/logs/events.jsonl"
    }

    func requestFile(for id: String) -> String {
        "\(requestsDir)/\(id).json"
    }

    func responseFile(for id: String) -> String {
        "\(responsesDir)/\(id).json"
    }
}

enum AgentRuntimeError: Error, CustomStringConvertible {
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
            return "Accessibility access is required before PushWriteInsertAgent can post synthetic Cmd+V events."
        case .eventSourceUnavailable:
            return "Could not create a CGEventSource for keyboard events."
        case .eventCreationFailed:
            return "Could not create one or more keyboard events for Cmd+V."
        }
    }
}

func parseLaunchOptions(arguments: [String]) throws -> LaunchOptions {
    var runtimeDir = ProcessInfo.processInfo.environment["PUSHWRITE_AGENT_RUNTIME_DIR"] ?? "/tmp/pushwrite-insert-agent"
    var index = 0

    func requireValue(for flag: String) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < arguments.count else {
            throw AgentRuntimeError.missingValue(flag: flag)
        }
        index = valueIndex
        return arguments[valueIndex]
    }

    while index < arguments.count {
        let argument = arguments[index]
        switch argument {
        case "--runtime-dir":
            runtimeDir = try requireValue(for: argument)
        default:
            throw AgentRuntimeError.unknownArgument(argument)
        }
        index += 1
    }

    return LaunchOptions(runtimeDir: runtimeDir)
}

func sleepMs(_ value: UInt32) {
    usleep(value * 1_000)
}

func isoTimestamp() -> String {
    ISO8601DateFormatter().string(from: Date())
}

func currentFrontmostApp() -> NSRunningApplication? {
    NSWorkspace.shared.frontmostApplication
}

func isAccessibilityTrusted(prompt: Bool) -> Bool {
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
        throw AgentRuntimeError.eventSourceUnavailable
    }

    let keyCodeV: CGKeyCode = 9
    guard
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: true),
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: false)
    else {
        throw AgentRuntimeError.eventCreationFailed
    }

    keyDown.flags = .maskCommand
    keyUp.flags = .maskCommand

    keyDown.post(tap: .cghidEventTap)
    usleep(15_000)
    keyUp.post(tap: .cghidEventTap)
}

func isAgentFrontmost(_ focus: FocusSnapshot?) -> Bool {
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

func readRequest(at path: String) throws -> AgentRequest {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else {
        throw AgentRuntimeError.invalidRequestFile(path)
    }

    var lastError: Error?
    for attempt in 0..<5 {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(AgentRequest.self, from: data)
        } catch {
            lastError = error
            if attempt < 4 {
                usleep(50_000)
            }
        }
    }

    throw lastError ?? AgentRuntimeError.invalidRequestFile(path)
}

final class AgentDelegate: NSObject, NSApplicationDelegate {
    private let launchOptions: LaunchOptions
    private let paths: AgentPaths
    private let defaults = (settle: UInt32(150), paste: UInt32(120), restore: UInt32(350))
    private let workerQueue = DispatchQueue(label: "ch.baumanncreative.pushwrite.insert-agent.worker")
    private var queuedRequestIDs: [String] = []
    private var activeRequestID: String?
    private var isProcessing = false
    private var lastRequestID: String?
    private var lastResponseStatus: AgentResponseStatus?
    private var lastBlockedReason: String?
    private var pollTimer: Timer?

    init(launchOptions: LaunchOptions) {
        self.launchOptions = launchOptions
        self.paths = AgentPaths(runtimeDir: launchOptions.runtimeDir)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            try prepareRuntime()
            try writeState(running: true)
        } catch {
            fputs("Agent startup failed: \(error)\n", stderr)
            NSApp.terminate(nil)
            return
        }

        // Polling the request spool keeps the agent launch/trigger path local and avoids
        // cross-process notification constraints while the process stays background-only.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.pollRequestsDirectory()
        }
        pollRequestsDirectory()
    }

    func applicationWillTerminate(_ notification: Notification) {
        pollTimer?.invalidate()
        try? writeState(running: false)
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
        let state = AgentState(
            timestamp: isoTimestamp(),
            runtimeDir: paths.runtimeDir,
            bundleID: Bundle.main.bundleIdentifier,
            pid: ProcessInfo.processInfo.processIdentifier,
            running: running,
            accessibilityTrusted: accessibilityTrusted,
            blockedReason: accessibilityTrusted ? lastBlockedReason : AgentRuntimeError.accessibilityDenied.description,
            queuedRequestCount: queuedRequestIDs.count,
            isProcessing: isProcessing,
            lastRequestID: lastRequestID,
            lastResponseStatus: lastResponseStatus,
            lastBlockedReason: lastBlockedReason
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

    private func performRequest(withID requestID: String) -> AgentResponse {
        let requestPath = paths.requestFile(for: requestID)

        do {
            let request = try readRequest(at: requestPath)
            switch request.kind {
            case .preflight:
                return performPreflight(request)
            case .insert:
                return try performInsert(request)
            case .shutdown:
                return performShutdown(request)
            }
        } catch {
            return AgentResponse(
                id: requestID,
                kind: .preflight,
                timestamp: isoTimestamp(),
                agentBundleID: Bundle.main.bundleIdentifier,
                agentPID: ProcessInfo.processInfo.processIdentifier,
                status: .invalidRequest,
                accessibilityTrusted: isAccessibilityTrusted(prompt: false),
                promptAccessibility: false,
                blockedReason: nil,
                settleDelayMs: defaults.settle,
                pasteDelayMs: defaults.paste,
                restoreClipboard: false,
                restoreDelayMs: defaults.restore,
                textLength: 0,
                focusAtReceipt: captureFocusSnapshot(isTrusted: false),
                focusBeforePaste: nil,
                focusAfterPaste: nil,
                agentFrontmostAtReceipt: false,
                agentFrontmostBeforePaste: false,
                agentFrontmostAfterPaste: false,
                originalPasteboard: nil,
                syntheticPastePosted: false,
                clipboardRestored: false,
                error: "\(error)"
            )
        }
    }

    private func performPreflight(_ request: AgentRequest) -> AgentResponse {
        let accessibilityTrusted = isAccessibilityTrusted(prompt: request.promptAccessibility)
        let focusAtReceipt = captureFocusSnapshot(isTrusted: accessibilityTrusted)
        let blockedReason = accessibilityTrusted ? nil : AgentRuntimeError.accessibilityDenied.description

        return AgentResponse(
            id: request.id,
            kind: request.kind,
            timestamp: isoTimestamp(),
            agentBundleID: Bundle.main.bundleIdentifier,
            agentPID: ProcessInfo.processInfo.processIdentifier,
            status: accessibilityTrusted ? .ready : .blocked,
            accessibilityTrusted: accessibilityTrusted,
            promptAccessibility: request.promptAccessibility,
            blockedReason: blockedReason,
            settleDelayMs: request.settleDelayMs ?? defaults.settle,
            pasteDelayMs: request.pasteDelayMs ?? defaults.paste,
            restoreClipboard: request.restoreClipboard,
            restoreDelayMs: request.restoreDelayMs ?? defaults.restore,
            textLength: request.text?.count ?? 0,
            focusAtReceipt: focusAtReceipt,
            focusBeforePaste: focusAtReceipt,
            focusAfterPaste: focusAtReceipt,
            agentFrontmostAtReceipt: isAgentFrontmost(focusAtReceipt),
            agentFrontmostBeforePaste: isAgentFrontmost(focusAtReceipt),
            agentFrontmostAfterPaste: isAgentFrontmost(focusAtReceipt),
            originalPasteboard: nil,
            syntheticPastePosted: false,
            clipboardRestored: false,
            error: nil
        )
    }

    private func performInsert(_ request: AgentRequest) throws -> AgentResponse {
        let settleDelayMs = request.settleDelayMs ?? defaults.settle
        let pasteDelayMs = request.pasteDelayMs ?? defaults.paste
        let restoreDelayMs = request.restoreDelayMs ?? defaults.restore
        let accessibilityTrusted = isAccessibilityTrusted(prompt: request.promptAccessibility)
        let focusAtReceipt = captureFocusSnapshot(isTrusted: accessibilityTrusted)

        guard accessibilityTrusted else {
            return AgentResponse(
                id: request.id,
                kind: request.kind,
                timestamp: isoTimestamp(),
                agentBundleID: Bundle.main.bundleIdentifier,
                agentPID: ProcessInfo.processInfo.processIdentifier,
                status: .blocked,
                accessibilityTrusted: false,
                promptAccessibility: request.promptAccessibility,
                blockedReason: AgentRuntimeError.accessibilityDenied.description,
                settleDelayMs: settleDelayMs,
                pasteDelayMs: pasteDelayMs,
                restoreClipboard: request.restoreClipboard,
                restoreDelayMs: restoreDelayMs,
                textLength: request.text?.count ?? 0,
                focusAtReceipt: focusAtReceipt,
                focusBeforePaste: focusAtReceipt,
                focusAfterPaste: focusAtReceipt,
                agentFrontmostAtReceipt: isAgentFrontmost(focusAtReceipt),
                agentFrontmostBeforePaste: isAgentFrontmost(focusAtReceipt),
                agentFrontmostAfterPaste: isAgentFrontmost(focusAtReceipt),
                originalPasteboard: nil,
                syntheticPastePosted: false,
                clipboardRestored: false,
                error: nil
            )
        }

        guard let text = request.text, !text.isEmpty else {
            throw AgentRuntimeError.invalidRequest("Insert requests require a non-empty text payload.")
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
            return AgentResponse(
                id: request.id,
                kind: request.kind,
                timestamp: isoTimestamp(),
                agentBundleID: Bundle.main.bundleIdentifier,
                agentPID: ProcessInfo.processInfo.processIdentifier,
                status: .failed,
                accessibilityTrusted: true,
                promptAccessibility: request.promptAccessibility,
                blockedReason: nil,
                settleDelayMs: settleDelayMs,
                pasteDelayMs: pasteDelayMs,
                restoreClipboard: request.restoreClipboard,
                restoreDelayMs: restoreDelayMs,
                textLength: text.count,
                focusAtReceipt: focusAtReceipt,
                focusBeforePaste: focusBeforePaste,
                focusAfterPaste: captureFocusSnapshot(isTrusted: true),
                agentFrontmostAtReceipt: isAgentFrontmost(focusAtReceipt),
                agentFrontmostBeforePaste: isAgentFrontmost(focusBeforePaste),
                agentFrontmostAfterPaste: isAgentFrontmost(captureFocusSnapshot(isTrusted: true)),
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

        return AgentResponse(
            id: request.id,
            kind: request.kind,
            timestamp: isoTimestamp(),
            agentBundleID: Bundle.main.bundleIdentifier,
            agentPID: ProcessInfo.processInfo.processIdentifier,
            status: .succeeded,
            accessibilityTrusted: true,
            promptAccessibility: request.promptAccessibility,
            blockedReason: nil,
            settleDelayMs: settleDelayMs,
            pasteDelayMs: pasteDelayMs,
            restoreClipboard: request.restoreClipboard,
            restoreDelayMs: restoreDelayMs,
            textLength: text.count,
            focusAtReceipt: focusAtReceipt,
            focusBeforePaste: focusBeforePaste,
            focusAfterPaste: focusAfterPaste,
            agentFrontmostAtReceipt: isAgentFrontmost(focusAtReceipt),
            agentFrontmostBeforePaste: isAgentFrontmost(focusBeforePaste),
            agentFrontmostAfterPaste: isAgentFrontmost(focusAfterPaste),
            originalPasteboard: originalPasteboardMetadata,
            syntheticPastePosted: true,
            clipboardRestored: originalPasteboardSnapshot != nil,
            error: nil
        )
    }

    private func performShutdown(_ request: AgentRequest) -> AgentResponse {
        let accessibilityTrusted = isAccessibilityTrusted(prompt: false)
        let focus = captureFocusSnapshot(isTrusted: accessibilityTrusted)

        return AgentResponse(
            id: request.id,
            kind: request.kind,
            timestamp: isoTimestamp(),
            agentBundleID: Bundle.main.bundleIdentifier,
            agentPID: ProcessInfo.processInfo.processIdentifier,
            status: .stopped,
            accessibilityTrusted: accessibilityTrusted,
            promptAccessibility: request.promptAccessibility,
            blockedReason: nil,
            settleDelayMs: request.settleDelayMs ?? defaults.settle,
            pasteDelayMs: request.pasteDelayMs ?? defaults.paste,
            restoreClipboard: request.restoreClipboard,
            restoreDelayMs: request.restoreDelayMs ?? defaults.restore,
            textLength: 0,
            focusAtReceipt: focus,
            focusBeforePaste: focus,
            focusAfterPaste: focus,
            agentFrontmostAtReceipt: isAgentFrontmost(focus),
            agentFrontmostBeforePaste: isAgentFrontmost(focus),
            agentFrontmostAfterPaste: isAgentFrontmost(focus),
            originalPasteboard: nil,
            syntheticPastePosted: false,
            clipboardRestored: false,
            error: nil
        )
    }

    private func completeRequest(withID requestID: String, response: AgentResponse) {
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
        try? writeState(running: true)

        if response.kind == .shutdown {
            NSApp.terminate(nil)
            return
        }

        processNextRequestIfNeeded()
    }
}

let launchOptions: LaunchOptions
do {
    launchOptions = try parseLaunchOptions(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
    fputs("\(error)\n", stderr)
    exit(64)
}

let app = NSApplication.shared
let delegate = AgentDelegate(launchOptions: launchOptions)
app.delegate = delegate
app.run()
