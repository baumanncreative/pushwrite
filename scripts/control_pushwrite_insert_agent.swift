#!/usr/bin/env swift

import AppKit
import Darwin
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

enum Command {
    case launch
    case status
    case preflight
    case insert
    case stop
}

struct Options {
    let command: Command
    let agentAppPath: String
    let runtimeDir: String
    let text: String?
    let restoreClipboard: Bool
    let promptAccessibility: Bool
    let settleDelayMs: UInt32?
    let pasteDelayMs: UInt32?
    let restoreDelayMs: UInt32?
    let timeoutMs: Int
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
    case agentNotRunning(String)
    case timeout(String)

    var description: String {
        switch self {
        case .missingCommand:
            return "Missing command. Use one of: launch, status, preflight, insert, stop."
        case let .missingValue(flag):
            return "Missing value for \(flag)."
        case let .unknownArgument(argument):
            return "Unknown argument: \(argument)"
        case let .invalidInteger(flag, value):
            return "Invalid integer for \(flag): \(value)"
        case .missingText:
            return "Insert requests require --text."
        case let .agentNotRunning(message):
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
    case "stop":
        command = .stop
    default:
        throw ControlError.unknownArgument(first)
    }

    var agentAppPath = ProcessInfo.processInfo.environment["PUSHWRITE_AGENT_APP_PATH"]
        ?? "/tmp/pushwrite-insert-agent-build/PushWriteInsertAgent.app"
    var runtimeDir = ProcessInfo.processInfo.environment["PUSHWRITE_AGENT_RUNTIME_DIR"] ?? "/tmp/pushwrite-insert-agent"
    var text: String?
    var restoreClipboard = false
    var promptAccessibility = false
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
        case "--agent-app":
            agentAppPath = try requireValue(for: argument)
        case "--runtime-dir":
            runtimeDir = try requireValue(for: argument)
        case "--text":
            text = try requireValue(for: argument)
        case "--restore-clipboard":
            restoreClipboard = true
        case "--prompt-accessibility":
            promptAccessibility = true
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

    if command == .insert, text == nil {
        throw ControlError.missingText
    }

    return Options(
        command: command,
        agentAppPath: agentAppPath,
        runtimeDir: runtimeDir,
        text: text,
        restoreClipboard: restoreClipboard,
        promptAccessibility: promptAccessibility,
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

func readState(from runtimeDir: String) -> AgentState? {
    let path = "\(runtimeDir)/agent-state.json"
    guard FileManager.default.fileExists(atPath: path) else {
        return nil
    }

    guard
        let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
        let state = try? JSONDecoder().decode(AgentState.self, from: data)
    else {
        return nil
    }

    return state
}

func readResponse(from path: String) throws -> AgentResponse {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    return try JSONDecoder().decode(AgentResponse.self, from: data)
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

func ensureAgentRunning(options: Options) throws -> AgentState {
    if let state = readState(from: options.runtimeDir), state.running, isProcessAlive(pid: state.pid) {
        return state
    }
    throw ControlError.agentNotRunning(
        "PushWriteInsertAgent is not running for runtime dir \(options.runtimeDir). Start it first with scripts/control_pushwrite_insert_agent.sh launch."
    )
}

func sendRequest(options: Options, kind: AgentRequestKind) throws -> AgentResponse {
    _ = try ensureAgentRunning(options: options)

    let requestID = UUID().uuidString
    let request = AgentRequest(
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
        let state = try ensureAgentRunning(options: options)
        try printJSON(state)
    case .status:
        if let state = readState(from: options.runtimeDir) {
            try printJSON(state)
        } else {
            let placeholder = AgentState(
                timestamp: ISO8601DateFormatter().string(from: Date()),
                runtimeDir: options.runtimeDir,
                bundleID: nil,
                pid: 0,
                running: false,
                accessibilityTrusted: false,
                blockedReason: "Agent not running.",
                queuedRequestCount: 0,
                isProcessing: false,
                lastRequestID: nil,
                lastResponseStatus: nil,
                lastBlockedReason: nil
            )
            try printJSON(placeholder)
        }
    case .preflight:
        let response = try sendRequest(options: options, kind: .preflight)
        try printJSON(response)
    case .insert:
        let response = try sendRequest(options: options, kind: .insert)
        try printJSON(response)
    case .stop:
        let response = try sendRequest(options: options, kind: .shutdown)
        try printJSON(response)
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
