#!/usr/bin/env swift

import AppKit
import Darwin
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

enum Command {
    case launch
    case status
    case preflight
    case insert
    case insertTranscription
    case stop
}

struct Options {
    let command: Command
    let productAppPath: String
    let runtimeDir: String
    let text: String?
    let simulatedText: String?
    let restoreClipboard: Bool
    let promptAccessibility: Bool
    let forceAccessibilityBlocked: Bool
    let forceAccessibilityTrusted: Bool
    let settleDelayMs: UInt32?
    let pasteDelayMs: UInt32?
    let restoreDelayMs: UInt32?
    let timeoutMs: Int
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

struct HotKeyStateSnapshot: Codable {
    let descriptor: String
    let keyCode: UInt32
    let carbonModifiers: UInt32
    let registered: Bool
    let registrationError: String?
}

struct ProductFlowSnapshot: Codable {
    let id: String?
    let state: String
    let trigger: String?
    let timestamp: String
    let textLength: Int
    let blockedReason: String?
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
    let hotKey: HotKeyStateSnapshot?
    let flow: ProductFlowSnapshot?
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
    let insertRoute: String?
    let insertSource: String?
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

struct PasteboardMetadata: Codable {
    let changeCount: Int
    let itemCount: Int
}

enum ControlError: Error, CustomStringConvertible {
    case missingCommand
    case missingValue(flag: String)
    case unknownArgument(String)
    case invalidInteger(flag: String, value: String)
    case missingText
    case productNotRunning(String)
    case timeout(String)

    var description: String {
        switch self {
        case .missingCommand:
            return "Missing command. Use one of: launch, status, preflight, insert, insert-transcription, stop."
        case let .missingValue(flag):
            return "Missing value for \(flag)."
        case let .unknownArgument(argument):
            return "Unknown argument: \(argument)"
        case let .invalidInteger(flag, value):
            return "Invalid integer for \(flag): \(value)"
        case .missingText:
            return "Insert requests require --text."
        case let .productNotRunning(message):
            return message
        case let .timeout(message):
            return "Timed out: \(message)"
        }
    }
}

func parseOptions(arguments: [String]) throws -> Options {
    guard let first = arguments.first else {
        throw ControlError.missingCommand
    }

    let command: Command
    switch first {
    case "launch":
        command = .launch
    case "status":
        command = .status
    case "preflight":
        command = .preflight
    case "insert":
        command = .insert
    case "insert-transcription":
        command = .insertTranscription
    case "stop":
        command = .stop
    default:
        throw ControlError.unknownArgument(first)
    }

    var productAppPath = ProcessInfo.processInfo.environment["PUSHWRITE_PRODUCT_APP_PATH"] ?? ""
    var runtimeDir = ProcessInfo.processInfo.environment["PUSHWRITE_PRODUCT_RUNTIME_DIR"] ?? ""
    var text: String?
    var simulatedText = ProcessInfo.processInfo.environment["PUSHWRITE_SIMULATED_TRANSCRIPTION_TEXT"]
    var restoreClipboard = false
    var promptAccessibility = false
    var forceAccessibilityBlocked = ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_ACCESSIBILITY_BLOCKED"] == "1"
    var forceAccessibilityTrusted = ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_ACCESSIBILITY_TRUSTED"] == "1"
    var settleDelayMs: UInt32?
    var pasteDelayMs: UInt32?
    var restoreDelayMs: UInt32?
    var timeoutMs = 10_000
    var index = 1

    func requireValue(for flag: String) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < arguments.count else {
            throw ControlError.missingValue(flag: flag)
        }
        index = valueIndex
        return arguments[valueIndex]
    }

    func requireUInt32(for flag: String) throws -> UInt32 {
        let value = try requireValue(for: flag)
        guard let parsed = UInt32(value) else {
            throw ControlError.invalidInteger(flag: flag, value: value)
        }
        return parsed
    }

    func requireInt(for flag: String) throws -> Int {
        let value = try requireValue(for: flag)
        guard let parsed = Int(value) else {
            throw ControlError.invalidInteger(flag: flag, value: value)
        }
        return parsed
    }

    while index < arguments.count {
        let argument = arguments[index]
        switch argument {
        case "--product-app":
            productAppPath = try requireValue(for: argument)
        case "--runtime-dir":
            runtimeDir = try requireValue(for: argument)
        case "--text":
            text = try requireValue(for: argument)
        case "--simulated-text":
            simulatedText = try requireValue(for: argument)
        case "--restore-clipboard":
            restoreClipboard = true
        case "--prompt-accessibility":
            promptAccessibility = true
        case "--force-accessibility-blocked":
            forceAccessibilityBlocked = true
        case "--force-accessibility-trusted":
            forceAccessibilityTrusted = true
        case "--settle-delay-ms":
            settleDelayMs = try requireUInt32(for: argument)
        case "--paste-delay-ms":
            pasteDelayMs = try requireUInt32(for: argument)
        case "--restore-delay-ms":
            restoreDelayMs = try requireUInt32(for: argument)
        case "--timeout-ms":
            timeoutMs = try requireInt(for: argument)
        default:
            throw ControlError.unknownArgument(argument)
        }
        index += 1
    }

    if (command == .insert || command == .insertTranscription), text == nil {
        throw ControlError.missingText
    }

    if productAppPath.isEmpty {
        productAppPath = "\(FileManager.default.currentDirectoryPath)/build/pushwrite-product/PushWrite.app"
    }
    if runtimeDir.isEmpty {
        runtimeDir = "\(FileManager.default.currentDirectoryPath)/build/pushwrite-product/runtime"
    }

    return Options(
        command: command,
        productAppPath: productAppPath,
        runtimeDir: runtimeDir,
        text: text,
        simulatedText: simulatedText,
        restoreClipboard: restoreClipboard,
        promptAccessibility: promptAccessibility,
        forceAccessibilityBlocked: forceAccessibilityBlocked,
        forceAccessibilityTrusted: forceAccessibilityTrusted,
        settleDelayMs: settleDelayMs,
        pasteDelayMs: pasteDelayMs,
        restoreDelayMs: restoreDelayMs,
        timeoutMs: timeoutMs
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

func printJSON<T: Encodable>(_ value: T) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    guard let string = String(data: data, encoding: .utf8) else {
        return
    }
    print(string)
}

func readState(from runtimeDir: String) -> ProductState? {
    let path = "\(runtimeDir)/product-state.json"
    guard FileManager.default.fileExists(atPath: path) else {
        return nil
    }

    guard
        let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
        let state = try? JSONDecoder().decode(ProductState.self, from: data)
    else {
        return nil
    }

    if state.running, !isProcessAlive(pid: state.pid) {
        let normalizedState = ProductState(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            runtimeDir: state.runtimeDir,
            appPath: state.appPath,
            bundleID: state.bundleID,
            pid: state.pid,
            running: false,
            accessibilityTrusted: state.accessibilityTrusted,
            blockedReason: state.blockedReason,
            queuedRequestCount: 0,
            isProcessing: false,
            lastRequestID: state.lastRequestID,
            lastResponseStatus: state.lastResponseStatus,
            lastBlockedReason: state.lastBlockedReason,
            hotKey: state.hotKey,
            flow: state.flow
        )
        try? writeJSON(normalizedState, to: path)
        return normalizedState
    }

    return state
}

func readResponse(from path: String) throws -> ProductResponse {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    return try JSONDecoder().decode(ProductResponse.self, from: data)
}

func isProcessAlive(pid: Int32) -> Bool {
    guard pid > 0 else {
        return false
    }
    if kill(pid_t(pid), 0) == 0 {
        return true
    }
    return errno == EPERM
}

func waitUntil(timeoutMs: Int, pollIntervalMs: Int = 100, condition: () throws -> Bool) throws {
    let deadline = Date().addingTimeInterval(Double(timeoutMs) / 1_000.0)
    while Date() < deadline {
        if try condition() {
            return
        }
        Thread.sleep(forTimeInterval: Double(pollIntervalMs) / 1_000.0)
    }
    throw ControlError.timeout("condition not met within \(timeoutMs)ms")
}

func launchProduct(options: Options) throws -> ProductState {
    if let state = readState(from: options.runtimeDir), state.running, isProcessAlive(pid: state.pid) {
        return state
    }

    let appURL = URL(fileURLWithPath: options.productAppPath)
    guard FileManager.default.fileExists(atPath: appURL.path) else {
        throw ControlError.productNotRunning("Missing PushWrite app at \(appURL.path). Build it first.")
    }

    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = false
    configuration.createsNewApplicationInstance = true

    var arguments = ["--runtime-dir", options.runtimeDir]
    if let simulatedText = options.simulatedText, !simulatedText.isEmpty {
        arguments.append(contentsOf: ["--simulated-transcription-text", simulatedText])
    }
    if options.forceAccessibilityBlocked {
        arguments.append("--force-accessibility-blocked")
    }
    if options.forceAccessibilityTrusted {
        arguments.append("--force-accessibility-trusted")
    }
    configuration.arguments = arguments

    _ = NSApplication.shared
    let deadline = Date().addingTimeInterval(Double(max(1, options.timeoutMs)) / 1_000.0)
    var launchError: Error?
    var launchCompleted = false
    DispatchQueue.main.async {
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
            launchError = error
            launchCompleted = true
            CFRunLoopStop(CFRunLoopGetMain())
        }
    }

    while !launchCompleted, Date() < deadline {
        RunLoop.main.run(mode: .default, before: min(deadline, Date().addingTimeInterval(0.1)))
    }

    if let launchError {
        throw ControlError.productNotRunning("PushWrite launch failed: \(launchError)")
    }
    if !launchCompleted {
        throw ControlError.timeout("launch completion did not return within \(options.timeoutMs)ms")
    }

    try waitUntil(timeoutMs: options.timeoutMs) {
        guard let state = readState(from: options.runtimeDir) else {
            return false
        }
        return state.running && isProcessAlive(pid: state.pid)
    }

    guard let state = readState(from: options.runtimeDir) else {
        throw ControlError.timeout("missing product state in \(options.runtimeDir)")
    }
    return state
}

func ensureProductRunning(options: Options) throws -> ProductState {
    if let state = readState(from: options.runtimeDir), state.running, isProcessAlive(pid: state.pid) {
        return state
    }
    throw ControlError.productNotRunning(
        "PushWrite is not running for runtime dir \(options.runtimeDir). Start it first with scripts/control_pushwrite_product.sh launch."
    )
}

func sendRequest(options: Options, kind: ProductRequestKind) throws -> ProductResponse {
    _ = try ensureProductRunning(options: options)

    let requestID = UUID().uuidString
    let request = ProductRequest(
        id: requestID,
        kind: kind,
        text: options.text,
        restoreClipboard: options.restoreClipboard,
        promptAccessibility: options.promptAccessibility,
        settleDelayMs: options.settleDelayMs,
        pasteDelayMs: options.pasteDelayMs,
        restoreDelayMs: options.restoreDelayMs
    )

    let requestPath = "\(options.runtimeDir)/requests/\(requestID).json"
    let responsePath = "\(options.runtimeDir)/responses/\(requestID).json"
    try? FileManager.default.removeItem(atPath: responsePath)
    try writeJSON(request, to: requestPath)

    try waitUntil(timeoutMs: options.timeoutMs) {
        FileManager.default.fileExists(atPath: responsePath)
    }

    return try readResponse(from: responsePath)
}

let options: Options
do {
    options = try parseOptions(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
    fputs("\(error)\n", stderr)
    exit(64)
}

do {
    switch options.command {
    case .launch:
        let state = try launchProduct(options: options)
        try printJSON(state)
    case .status:
        if let state = readState(from: options.runtimeDir) {
            try printJSON(state)
        } else {
            let placeholder = ProductState(
                timestamp: ISO8601DateFormatter().string(from: Date()),
                runtimeDir: options.runtimeDir,
                appPath: options.productAppPath,
                bundleID: nil,
                pid: 0,
                running: false,
                accessibilityTrusted: false,
                blockedReason: "PushWrite is not running.",
                queuedRequestCount: 0,
                isProcessing: false,
                lastRequestID: nil,
                lastResponseStatus: nil,
                lastBlockedReason: nil,
                hotKey: nil,
                flow: nil
            )
            try printJSON(placeholder)
        }
    case .preflight:
        let response = try sendRequest(options: options, kind: .preflight)
        try printJSON(response)
    case .insert:
        let response = try sendRequest(options: options, kind: .insert)
        try printJSON(response)
    case .insertTranscription:
        let response = try sendRequest(options: options, kind: .insertTranscription)
        try printJSON(response)
    case .stop:
        let response = try sendRequest(options: options, kind: .shutdown)
        try waitUntil(timeoutMs: options.timeoutMs) {
            guard let state = readState(from: options.runtimeDir) else {
                return true
            }
            return !isProcessAlive(pid: state.pid)
        }
        _ = readState(from: options.runtimeDir)
        try printJSON(response)
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
