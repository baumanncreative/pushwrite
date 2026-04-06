#!/usr/bin/env swift

import AppKit
import Foundation

struct Options {
    var payload = "PushWrite 002C test aeoeue ss EUR."
    var textEditRuns = 20
    var safariRuns = 20
    var agentOutputDir = "/tmp/pushwrite-insert-agent-build"
    var agentRuntimeDir = "/tmp/pushwrite-insert-agent-runtime"
    var agentAppPath: String?
    var resultsFile: String?
    var promptAccessibilityOnPreflight = false
    var skipLaunch = false
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
    let lastResponseStatus: String?
    let lastBlockedReason: String?
}

struct AgentResponse: Codable {
    let id: String
    let kind: String
    let timestamp: String
    let agentBundleID: String?
    let agentPID: Int32
    let status: String
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

struct PasteboardTypeSnapshot: Codable, Equatable {
    let type: String
    let dataBase64: String
}

struct PasteboardItemSnapshot: Codable, Equatable {
    let entries: [PasteboardTypeSnapshot]
}

struct PasteboardSnapshot: Codable, Equatable {
    let itemCount: Int
    let items: [PasteboardItemSnapshot]
}

struct ClipboardTestResult: Codable {
    let name: String
    let success: Bool
    let insertedTextMatches: Bool
    let beforeSnapshot: PasteboardSnapshot
    let afterSnapshot: PasteboardSnapshot
    let agentResponse: AgentResponse
    let error: String?
}

struct ContextRunRecord: Codable {
    let iteration: Int
    let success: Bool
    let targetValue: String
    let agentResponse: AgentResponse
    let failureReasons: [String]
}

struct ContextSummary: Codable {
    let name: String
    let runCount: Int
    let successCount: Int
    let failureReasons: [String: Int]
    let focusAtReceiptTargetAppCount: Int
    let focusBeforeTargetAppCount: Int
    let focusAfterTargetAppCount: Int
    let agentFrontmostAtReceiptCount: Int
    let agentFrontmostBeforePasteCount: Int
    let agentFrontmostAfterPasteCount: Int
    let records: [ContextRunRecord]
}

struct PreflightSummary: Codable {
    let agentRunning: Bool
    let agentAccessibilityTrusted: Bool
    let agentBlockedReason: String?
    let agentFrontmostAtReceipt: Bool
    let agentFrontmostBeforePaste: Bool
    let textEditAutomationReady: Bool
    let safariAutomationReady: Bool
    let notes: [String]
}

struct ValidationSummary: Codable {
    let timestamp: String
    let payload: String
    let agentAppPath: String
    let agentRuntimeDir: String
    let launchState: AgentState
    let preflight: PreflightSummary
    let textEdit: ContextSummary
    let safari: ContextSummary
    let clipboardRestore: [ClipboardTestResult]
    let eventsLogFile: String
}

enum ValidationError: Error, CustomStringConvertible {
    case invalidInteger(flag: String, value: String)
    case missingValue(flag: String)
    case unknownArgument(String)
    case buildFailed(String)
    case controlFailed(String)
    case appleScriptFailed(String)
    case missingApplication(String)
    case timeout(String)

    var description: String {
        switch self {
        case let .invalidInteger(flag, value):
            return "Invalid integer for \(flag): \(value)"
        case let .missingValue(flag):
            return "Missing value for \(flag)"
        case let .unknownArgument(argument):
            return "Unknown argument: \(argument)"
        case let .buildFailed(message):
            return "Agent build failed: \(message)"
        case let .controlFailed(message):
            return "Agent control failed: \(message)"
        case let .appleScriptFailed(message):
            return "AppleScript failed: \(message)"
        case let .missingApplication(bundleID):
            return "Missing application for bundle identifier \(bundleID)"
        case let .timeout(message):
            return "Timed out: \(message)"
        }
    }
}

func parseOptions(arguments: [String]) throws -> Options {
    var options = Options()
    var index = 0

    func requireValue(for flag: String) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < arguments.count else {
            throw ValidationError.missingValue(flag: flag)
        }
        index = valueIndex
        return arguments[valueIndex]
    }

    while index < arguments.count {
        let argument = arguments[index]
        switch argument {
        case "--payload":
            options.payload = try requireValue(for: argument)
        case "--textedit-runs":
            let value = try requireValue(for: argument)
            guard let parsed = Int(value) else {
                throw ValidationError.invalidInteger(flag: argument, value: value)
            }
            options.textEditRuns = parsed
        case "--safari-runs":
            let value = try requireValue(for: argument)
            guard let parsed = Int(value) else {
                throw ValidationError.invalidInteger(flag: argument, value: value)
            }
            options.safariRuns = parsed
        case "--agent-output-dir":
            options.agentOutputDir = try requireValue(for: argument)
        case "--agent-runtime-dir":
            options.agentRuntimeDir = try requireValue(for: argument)
        case "--agent-app-path":
            options.agentAppPath = try requireValue(for: argument)
        case "--results-file":
            options.resultsFile = try requireValue(for: argument)
        case "--prompt-accessibility-on-preflight":
            options.promptAccessibilityOnPreflight = true
        case "--skip-launch":
            options.skipLaunch = true
        default:
            throw ValidationError.unknownArgument(argument)
        }
        index += 1
    }

    return options
}

func isoTimestamp() -> String {
    ISO8601DateFormatter().string(from: Date())
}

func escapeAppleScriptString(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
}

@discardableResult
func runProcess(_ executable: String, arguments: [String], currentDirectory: String? = nil) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    if let currentDirectory {
        process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory)
    }

    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr

    try process.run()
    process.waitUntilExit()

    let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
    let stdoutString = String(decoding: stdoutData, as: UTF8.self)
    let stderrString = String(decoding: stderrData, as: UTF8.self)

    guard process.terminationStatus == 0 else {
        let failureOutput = stderrString.isEmpty ? stdoutString : stderrString
        throw ValidationError.controlFailed(failureOutput)
    }

    return stdoutString
}

func runAppleScript(_ source: String) throws -> NSAppleEventDescriptor {
    guard let script = NSAppleScript(source: source) else {
        throw ValidationError.appleScriptFailed("Could not compile script.")
    }

    var error: NSDictionary?
    let result = script.executeAndReturnError(&error)
    if let error {
        throw ValidationError.appleScriptFailed(error.description)
    }
    return result
}

func readAppleScriptString(_ source: String) throws -> String {
    let result = try runAppleScript(source)
    return result.stringValue ?? ""
}

func buildAgent(repoRoot: String, outputDir: String) throws -> URL {
    let scriptPath = "\(repoRoot)/scripts/build_pushwrite_insert_agent.sh"
    let output = try runProcess("/bin/zsh", arguments: [scriptPath, outputDir], currentDirectory: repoRoot)
    let appPath = output.trimmingCharacters(in: .whitespacesAndNewlines)
    return URL(fileURLWithPath: appPath)
}

func resolveAgentApp(repoRoot: String, options: Options) throws -> URL {
    if let agentAppPath = options.agentAppPath {
        let url = URL(fileURLWithPath: agentAppPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError.controlFailed("Missing agent app at \(url.path)")
        }
        return url
    }

    return try buildAgent(repoRoot: repoRoot, outputDir: options.agentOutputDir)
}

func runControl(repoRoot: String, agentAppPath: String, runtimeDir: String, arguments: [String]) throws -> String {
    let scriptPath = "\(repoRoot)/scripts/control_pushwrite_insert_agent.sh"
    let output = try runProcess(
        "/bin/zsh",
        arguments: [scriptPath] + arguments + ["--agent-app", agentAppPath, "--runtime-dir", runtimeDir],
        currentDirectory: repoRoot
    )
    return output
}

func launchAgent(repoRoot: String, agentAppPath: String, runtimeDir: String) throws -> AgentState {
    let output = try runControl(
        repoRoot: repoRoot,
        agentAppPath: agentAppPath,
        runtimeDir: runtimeDir,
        arguments: ["launch", "--timeout-ms", "15000"]
    )
    let data = Data(output.utf8)
    return try JSONDecoder().decode(AgentState.self, from: data)
}

func readLaunchState(runtimeDir: String) throws -> AgentState {
    let path = "\(runtimeDir)/agent-state.json"
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else {
        throw ValidationError.controlFailed("Missing agent state file at \(path)")
    }
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(AgentState.self, from: data)
}

func runPreflight(repoRoot: String, agentAppPath: String, runtimeDir: String, prompt: Bool) throws -> AgentResponse {
    var arguments = ["preflight", "--timeout-ms", "15000"]
    if prompt {
        arguments.append("--prompt-accessibility")
    }
    let output = try runControl(repoRoot: repoRoot, agentAppPath: agentAppPath, runtimeDir: runtimeDir, arguments: arguments)
    return try JSONDecoder().decode(AgentResponse.self, from: Data(output.utf8))
}

func runInsert(
    repoRoot: String,
    agentAppPath: String,
    runtimeDir: String,
    text: String,
    restoreClipboard: Bool
) throws -> AgentResponse {
    var arguments = [
        "insert",
        "--text", text,
        "--timeout-ms", "15000"
    ]
    if restoreClipboard {
        arguments.append("--restore-clipboard")
    }

    let output = try runControl(repoRoot: repoRoot, agentAppPath: agentAppPath, runtimeDir: runtimeDir, arguments: arguments)
    return try JSONDecoder().decode(AgentResponse.self, from: Data(output.utf8))
}

func stopAgent(repoRoot: String, agentAppPath: String, runtimeDir: String) {
    _ = try? runControl(
        repoRoot: repoRoot,
        agentAppPath: agentAppPath,
        runtimeDir: runtimeDir,
        arguments: ["stop", "--timeout-ms", "5000"]
    )
}

func waitUntil(timeoutSeconds: Double, pollIntervalSeconds: Double = 0.1, condition: () throws -> Bool) throws {
    let deadline = Date().addingTimeInterval(timeoutSeconds)
    while Date() < deadline {
        if try condition() {
            return
        }
        Thread.sleep(forTimeInterval: pollIntervalSeconds)
    }
    throw ValidationError.timeout("Condition not met within \(timeoutSeconds) seconds.")
}

func currentBundleID(_ focus: FocusSnapshot?) -> String? {
    focus?.app?.bundleID
}

func snapshotGeneralPasteboard() -> PasteboardSnapshot {
    let pasteboard = NSPasteboard.general
    let items = pasteboard.pasteboardItems ?? []
    let snapshots = items.map { item in
        let entries = item.types.sorted { $0.rawValue < $1.rawValue }.compactMap { type -> PasteboardTypeSnapshot? in
            guard let data = item.data(forType: type) else {
                return nil
            }
            return PasteboardTypeSnapshot(type: type.rawValue, dataBase64: data.base64EncodedString())
        }
        return PasteboardItemSnapshot(entries: entries)
    }

    return PasteboardSnapshot(itemCount: items.count, items: snapshots)
}

func clearAndWriteStringToPasteboard(_ value: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(value, forType: .string)
}

func clearAndWriteRichClipboardProbe() throws {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    let attributed = NSAttributedString(
        string: "PushWrite 002C rich clipboard probe\nLine two with emphasis.",
        attributes: [
            .font: NSFont.boldSystemFont(ofSize: 14)
        ]
    )
    let fullRange = NSRange(location: 0, length: attributed.length)
    let rtfData = try attributed.data(
        from: fullRange,
        documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
    )
    let htmlData = """
    <p><strong>PushWrite 002C rich clipboard probe</strong></p>
    <p>Line two with emphasis.</p>
    """.data(using: .utf8)!

    let item = NSPasteboardItem()
    item.setString("PushWrite 002C rich clipboard probe\nLine two with emphasis.", forType: .string)
    item.setData(rtfData, forType: .rtf)
    item.setData(htmlData, forType: .html)
    pasteboard.writeObjects([item])
}

func ensureTextEditReady() throws {
    let script = """
    tell application id "com.apple.TextEdit"
      activate
      if not (exists document 1) then
        make new document
      end if
      set text of document 1 to ""
    end tell
    """
    _ = try runAppleScript(script)
    Thread.sleep(forTimeInterval: 0.4)
}

func readTextEditValue() throws -> String {
    let script = """
    tell application id "com.apple.TextEdit"
      if not (exists document 1) then
        return ""
      end if
      return text of document 1
    end tell
    """
    return try readAppleScriptString(script)
}

func openSafariFixture(fixtureURL: URL) throws {
    guard let safariAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") else {
        throw ValidationError.missingApplication("com.apple.Safari")
    }

    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = true

    let semaphore = DispatchSemaphore(value: 0)
    var openError: Error?
    NSWorkspace.shared.open([fixtureURL], withApplicationAt: safariAppURL, configuration: configuration) { _, error in
        openError = error
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .now() + 10)
    if let openError {
        throw openError
    }
}

func ensureSafariFixtureReady(fixtureURL: URL) throws {
    try openSafariFixture(fixtureURL: fixtureURL)
    Thread.sleep(forTimeInterval: 1.0)

    let fixtureURLString = escapeAppleScriptString(fixtureURL.absoluteString)
    let script = """
    tell application id "com.apple.Safari"
      activate
      if (count of windows) is 0 then
        make new document
      end if
      set URL of current tab of front window to "\(fixtureURLString)"
    end tell
    """
    _ = try runAppleScript(script)

    try waitUntil(timeoutSeconds: 10) {
        let currentURL = try readAppleScriptString("""
        tell application id "com.apple.Safari"
          return URL of current tab of front window
        end tell
        """)
        return currentURL == fixtureURL.absoluteString
    }
    Thread.sleep(forTimeInterval: 0.5)
}

func readSafariTextareaValue() throws -> String {
    let currentURL = try readAppleScriptString("""
    tell application id "com.apple.Safari"
      return URL of current tab of front window
    end tell
    """)

    guard let components = URLComponents(string: currentURL) else {
        return ""
    }

    return components.percentEncodedFragment?.removingPercentEncoding ?? ""
}

func safariActiveElementID() throws -> String {
    try readAppleScriptString("""
    tell application id "com.apple.Safari"
      return name of current tab of front window
    end tell
    """)
}

func safariFixtureReady() throws -> Bool {
    let tabName = try safariActiveElementID()
    return tabName.contains("PushWrite 002A Browser Fixture len=0")
}

func validateAutomationReadiness() -> (textEdit: Bool, safari: Bool, notes: [String]) {
    var notes: [String] = []

    let textEditReady: Bool
    do {
        _ = try readAppleScriptString("""
        tell application id "com.apple.TextEdit"
          return "ok"
        end tell
        """)
        textEditReady = true
    } catch {
        notes.append("TextEdit automation check failed: \(error)")
        textEditReady = false
    }

    let safariReady: Bool
    do {
        _ = try readAppleScriptString("""
        tell application id "com.apple.Safari"
          return "ok"
        end tell
        """)
        safariReady = true
    } catch {
        notes.append("Safari automation check failed: \(error)")
        safariReady = false
    }

    return (textEditReady, safariReady, notes)
}

func runContextSeries(
    name: String,
    runCount: Int,
    payload: String,
    repoRoot: String,
    agentAppPath: String,
    runtimeDir: String,
    prepare: () throws -> Void,
    readValue: () throws -> String,
    verifyTargetIsReady: (() throws -> Bool)? = nil
) throws -> ContextSummary {
    var records: [ContextRunRecord] = []
    var failureReasons: [String: Int] = [:]
    var focusAtReceiptTargetAppCount = 0
    var focusBeforeTargetAppCount = 0
    var focusAfterTargetAppCount = 0
    var agentFrontmostAtReceiptCount = 0
    var agentFrontmostBeforePasteCount = 0
    var agentFrontmostAfterPasteCount = 0

    for iteration in 1...runCount {
        try prepare()
        var reasons: [String] = []
        if let verifyTargetIsReady {
            let ready = try verifyTargetIsReady()
            if !ready {
                reasons.append("target-not-ready-before-run")
            }
        }

        let agentResponse = try runInsert(
            repoRoot: repoRoot,
            agentAppPath: agentAppPath,
            runtimeDir: runtimeDir,
            text: payload,
            restoreClipboard: false
        )

        Thread.sleep(forTimeInterval: 0.25)
        let targetValue = try readValue()

        if targetValue != payload {
            reasons.append("target-value-mismatch")
        }

        if agentResponse.status != "succeeded" {
            reasons.append("agent-status-\(agentResponse.status)")
        }

        if !agentResponse.syntheticPastePosted {
            reasons.append("synthetic-paste-not-posted")
        }

        if agentResponse.error != nil {
            reasons.append("agent-error")
        }

        if currentBundleID(agentResponse.focusAtReceipt) == targetBundleID(for: name) {
            focusAtReceiptTargetAppCount += 1
        } else {
            reasons.append("focus-at-receipt-not-target")
        }

        if currentBundleID(agentResponse.focusBeforePaste) == targetBundleID(for: name) {
            focusBeforeTargetAppCount += 1
        } else {
            reasons.append("focus-before-not-target")
        }

        if currentBundleID(agentResponse.focusAfterPaste) == targetBundleID(for: name) {
            focusAfterTargetAppCount += 1
        } else {
            reasons.append("focus-after-not-target")
        }

        if agentResponse.agentFrontmostAtReceipt {
            agentFrontmostAtReceiptCount += 1
            reasons.append("agent-frontmost-at-receipt")
        }

        if agentResponse.agentFrontmostBeforePaste {
            agentFrontmostBeforePasteCount += 1
            reasons.append("agent-frontmost-before-paste")
        }

        if agentResponse.agentFrontmostAfterPaste {
            agentFrontmostAfterPasteCount += 1
            reasons.append("agent-frontmost-after-paste")
        }

        for reason in reasons {
            failureReasons[reason, default: 0] += 1
        }

        let success = reasons.isEmpty
        records.append(
            ContextRunRecord(
                iteration: iteration,
                success: success,
                targetValue: targetValue,
                agentResponse: agentResponse,
                failureReasons: reasons
            )
        )
    }

    let successCount = records.filter(\.success).count
    return ContextSummary(
        name: name,
        runCount: runCount,
        successCount: successCount,
        failureReasons: failureReasons,
        focusAtReceiptTargetAppCount: focusAtReceiptTargetAppCount,
        focusBeforeTargetAppCount: focusBeforeTargetAppCount,
        focusAfterTargetAppCount: focusAfterTargetAppCount,
        agentFrontmostAtReceiptCount: agentFrontmostAtReceiptCount,
        agentFrontmostBeforePasteCount: agentFrontmostBeforePasteCount,
        agentFrontmostAfterPasteCount: agentFrontmostAfterPasteCount,
        records: records
    )
}

func targetBundleID(for name: String) -> String {
    switch name {
    case "textedit":
        return "com.apple.TextEdit"
    case "safari":
        return "com.apple.Safari"
    default:
        return ""
    }
}

func runClipboardRestoreProbe(
    name: String,
    payload: String,
    repoRoot: String,
    agentAppPath: String,
    runtimeDir: String,
    seedClipboard: () throws -> Void
) throws -> ClipboardTestResult {
    try ensureTextEditReady()
    try seedClipboard()
    let beforeSnapshot = snapshotGeneralPasteboard()

    let agentResponse = try runInsert(
        repoRoot: repoRoot,
        agentAppPath: agentAppPath,
        runtimeDir: runtimeDir,
        text: payload,
        restoreClipboard: true
    )

    Thread.sleep(forTimeInterval: 0.6)
    let afterSnapshot = snapshotGeneralPasteboard()
    let insertedText = try readTextEditValue()

    var error: String?
    if beforeSnapshot != afterSnapshot {
        error = "clipboard-snapshot-mismatch"
    }

    if insertedText != payload {
        error = [error, "inserted-text-mismatch"].compactMap { $0 }.joined(separator: ",")
    }

    return ClipboardTestResult(
        name: name,
        success: beforeSnapshot == afterSnapshot && insertedText == payload,
        insertedTextMatches: insertedText == payload,
        beforeSnapshot: beforeSnapshot,
        afterSnapshot: afterSnapshot,
        agentResponse: agentResponse,
        error: error
    )
}

func writeSummary(_ summary: ValidationSummary, to path: String) throws {
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(summary).write(to: url, options: .atomic)
}

let repoRoot = FileManager.default.currentDirectoryPath
let options: Options
do {
    options = try parseOptions(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
    fputs("\(error)\n", stderr)
    exit(64)
}

let agentAppURL: URL
do {
    agentAppURL = try resolveAgentApp(repoRoot: repoRoot, options: options)
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}

let launchState: AgentState
do {
    if options.skipLaunch {
        launchState = try readLaunchState(runtimeDir: options.agentRuntimeDir)
    } else {
        try? FileManager.default.removeItem(atPath: options.agentRuntimeDir)
        launchState = try launchAgent(
            repoRoot: repoRoot,
            agentAppPath: agentAppURL.path,
            runtimeDir: options.agentRuntimeDir
        )
    }
} catch {
    fputs("Agent launch failed: \(error)\n", stderr)
    exit(1)
}

defer {
    stopAgent(repoRoot: repoRoot, agentAppPath: agentAppURL.path, runtimeDir: options.agentRuntimeDir)
}

let fixtureURL = URL(fileURLWithPath: "\(repoRoot)/tests/integration/browser-textarea-fixture.html")

var preflightResponse: AgentResponse
do {
    preflightResponse = try runPreflight(
        repoRoot: repoRoot,
        agentAppPath: agentAppURL.path,
        runtimeDir: options.agentRuntimeDir,
        prompt: options.promptAccessibilityOnPreflight
    )
} catch {
    fputs("Preflight failed: \(error)\n", stderr)
    exit(1)
}

if !preflightResponse.accessibilityTrusted && options.promptAccessibilityOnPreflight {
    let deadline = Date().addingTimeInterval(45)
    while Date() < deadline && !preflightResponse.accessibilityTrusted {
        Thread.sleep(forTimeInterval: 2.0)
        do {
            preflightResponse = try runPreflight(
                repoRoot: repoRoot,
                agentAppPath: agentAppURL.path,
                runtimeDir: options.agentRuntimeDir,
                prompt: false
            )
        } catch {
            fputs("Preflight recheck failed: \(error)\n", stderr)
            exit(1)
        }
    }
}

let automationReady = validateAutomationReadiness()
let preflight = PreflightSummary(
    agentRunning: launchState.running,
    agentAccessibilityTrusted: preflightResponse.accessibilityTrusted,
    agentBlockedReason: preflightResponse.blockedReason,
    agentFrontmostAtReceipt: preflightResponse.agentFrontmostAtReceipt,
    agentFrontmostBeforePaste: preflightResponse.agentFrontmostBeforePaste,
    textEditAutomationReady: automationReady.textEdit,
    safariAutomationReady: automationReady.safari,
    notes: automationReady.notes
)

guard preflight.agentAccessibilityTrusted else {
    fputs("Accessibility is not trusted for the agent app.\n", stderr)
    exit(1)
}

guard preflight.textEditAutomationReady, preflight.safariAutomationReady else {
    fputs("Automation preflight failed.\n", stderr)
    exit(1)
}

let textEditSummary: ContextSummary
do {
    textEditSummary = try runContextSeries(
        name: "textedit",
        runCount: options.textEditRuns,
        payload: options.payload,
        repoRoot: repoRoot,
        agentAppPath: agentAppURL.path,
        runtimeDir: options.agentRuntimeDir,
        prepare: {
            try ensureTextEditReady()
        },
        readValue: {
            try readTextEditValue()
        }
    )
} catch {
    fputs("TextEdit series failed: \(error)\n", stderr)
    exit(1)
}

let safariSummary: ContextSummary
do {
    safariSummary = try runContextSeries(
        name: "safari",
        runCount: options.safariRuns,
        payload: options.payload,
        repoRoot: repoRoot,
        agentAppPath: agentAppURL.path,
        runtimeDir: options.agentRuntimeDir,
        prepare: {
            try ensureSafariFixtureReady(fixtureURL: fixtureURL)
        },
        readValue: {
            try readSafariTextareaValue()
        },
        verifyTargetIsReady: {
            try safariFixtureReady()
        }
    )
} catch {
    fputs("Safari series failed: \(error)\n", stderr)
    exit(1)
}

let plainClipboardResult: ClipboardTestResult
let richClipboardResult: ClipboardTestResult
do {
    plainClipboardResult = try runClipboardRestoreProbe(
        name: "plain",
        payload: options.payload,
        repoRoot: repoRoot,
        agentAppPath: agentAppURL.path,
        runtimeDir: options.agentRuntimeDir,
        seedClipboard: {
            clearAndWriteStringToPasteboard("ORIGINAL_CLIPBOARD_002C")
        }
    )

    richClipboardResult = try runClipboardRestoreProbe(
        name: "rich",
        payload: options.payload,
        repoRoot: repoRoot,
        agentAppPath: agentAppURL.path,
        runtimeDir: options.agentRuntimeDir,
        seedClipboard: {
            try clearAndWriteRichClipboardProbe()
        }
    )
} catch {
    fputs("Clipboard restore probe failed: \(error)\n", stderr)
    exit(1)
}

let summary = ValidationSummary(
    timestamp: isoTimestamp(),
    payload: options.payload,
    agentAppPath: agentAppURL.path,
    agentRuntimeDir: options.agentRuntimeDir,
    launchState: launchState,
    preflight: preflight,
    textEdit: textEditSummary,
    safari: safariSummary,
    clipboardRestore: [plainClipboardResult, richClipboardResult],
    eventsLogFile: "\(options.agentRuntimeDir)/logs/events.jsonl"
)

if let resultsFile = options.resultsFile {
    do {
        try writeSummary(summary, to: resultsFile)
    } catch {
        fputs("Could not write results file: \(error)\n", stderr)
        exit(1)
    }
}

func printContextSummary(_ summary: ContextSummary) {
    print("[002C] context=\(summary.name) success=\(summary.successCount)/\(summary.runCount)")
    print("[002C] context=\(summary.name) focusReceiptTarget=\(summary.focusAtReceiptTargetAppCount) focusBeforeTarget=\(summary.focusBeforeTargetAppCount) focusAfterTarget=\(summary.focusAfterTargetAppCount)")
    print("[002C] context=\(summary.name) agentFrontmostReceipt=\(summary.agentFrontmostAtReceiptCount) agentFrontmostBefore=\(summary.agentFrontmostBeforePasteCount) agentFrontmostAfter=\(summary.agentFrontmostAfterPasteCount)")
    if !summary.failureReasons.isEmpty {
        let fragments = summary.failureReasons.keys.sorted().map { "\($0)=\(summary.failureReasons[$0] ?? 0)" }
        print("[002C] context=\(summary.name) failures=\(fragments.joined(separator: ","))")
    }
}

print("[002C] agentAppPath=\(summary.agentAppPath)")
print("[002C] runtimeDir=\(summary.agentRuntimeDir)")
print("[002C] preflight accessibilityTrusted=\(summary.preflight.agentAccessibilityTrusted) running=\(summary.preflight.agentRunning) blockedReason=\(summary.preflight.agentBlockedReason ?? "none")")
if !summary.preflight.notes.isEmpty {
    print("[002C] preflight notes=\(summary.preflight.notes.joined(separator: " | "))")
}
printContextSummary(summary.textEdit)
printContextSummary(summary.safari)
for clipboard in summary.clipboardRestore {
    print("[002C] clipboard=\(clipboard.name) success=\(clipboard.success) insertedTextMatches=\(clipboard.insertedTextMatches) error=\(clipboard.error ?? "none")")
}
