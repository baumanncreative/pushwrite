#!/usr/bin/env swift

import AppKit
import Foundation

struct Options {
    var simulatedText = "PushWrite 002E simulated transcription."
    var textEditRuns = 5
    var safariRuns = 5
    var productOutputDir = ""
    var successRuntimeDir = ""
    var blockedRuntimeDir = ""
    var productAppPath: String?
    var resultsFile: String?
    var skipBuild = false
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

struct ProductFlowEvent: Codable {
    let id: String
    let state: String
    let trigger: String
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
    let lastResponseStatus: String?
    let lastBlockedReason: String?
    let hotKey: HotKeyStateSnapshot
    let flow: ProductFlowSnapshot
}

struct PasteboardMetadata: Codable {
    let changeCount: Int
    let itemCount: Int
}

struct ProductResponse: Codable {
    let id: String
    let kind: String
    let timestamp: String
    let productBundleID: String?
    let productPID: Int32
    let status: String
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

struct ContextRunRecord: Codable {
    let iteration: Int
    let success: Bool
    let targetValue: String
    let frontmostBundleAfterTrigger: String?
    let hotKeyResponse: ProductResponse
    let flowStates: [String]
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
    let productFrontmostAtReceiptCount: Int
    let productFrontmostBeforePasteCount: Int
    let productFrontmostAfterPasteCount: Int
    let frontmostAfterTriggerTargetAppCount: Int
    let records: [ContextRunRecord]
}

struct HotKeyPreflightSummary: Codable {
    let accessibilityTrusted: Bool
    let blockedReason: String?
    let hotKeyDescriptor: String
    let hotKeyRegistered: Bool
    let hotKeyRegistrationError: String?
    let launchFlowState: String
    let launchFlowTrigger: String?
    let forceAccessibilityTrusted: Bool
}

struct BlockedHotKeySummary: Codable {
    let launchState: ProductState
    let hotKeyResponse: ProductResponse
    let textEditValueAfterTrigger: String
    let frontmostBundleAfterTrigger: String?
    let flowStates: [String]
    let failureReasons: [String]
}

struct ValidationSummary: Codable {
    let timestamp: String
    let simulatedText: String
    let productAppPath: String
    let successRuntimeDir: String
    let blockedRuntimeDir: String
    let manualLaunchCommand: String
    let preflight: HotKeyPreflightSummary
    let textEdit: ContextSummary
    let safari: ContextSummary
    let blocked: BlockedHotKeySummary
    let successFlowEventsLogFile: String
    let blockedFlowEventsLogFile: String
    let lastHotKeyResponseFile: String
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
    case invalidState(String)

    var description: String {
        switch self {
        case let .invalidInteger(flag, value):
            return "Invalid integer for \(flag): \(value)"
        case let .missingValue(flag):
            return "Missing value for \(flag)"
        case let .unknownArgument(argument):
            return "Unknown argument: \(argument)"
        case let .buildFailed(message):
            return "Product build failed: \(message)"
        case let .controlFailed(message):
            return "Product control failed: \(message)"
        case let .appleScriptFailed(message):
            return "AppleScript failed: \(message)"
        case let .missingApplication(bundleID):
            return "Missing application for bundle identifier \(bundleID)"
        case let .timeout(message):
            return "Timed out: \(message)"
        case let .invalidState(message):
            return "Invalid state: \(message)"
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
        case "--simulated-text":
            options.simulatedText = try requireValue(for: argument)
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
        case "--product-output-dir":
            options.productOutputDir = try requireValue(for: argument)
        case "--success-runtime-dir":
            options.successRuntimeDir = try requireValue(for: argument)
        case "--blocked-runtime-dir":
            options.blockedRuntimeDir = try requireValue(for: argument)
        case "--product-app-path":
            options.productAppPath = try requireValue(for: argument)
        case "--results-file":
            options.resultsFile = try requireValue(for: argument)
        case "--skip-build":
            options.skipBuild = true
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

func shellEscape(_ value: String) -> String {
    "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

@discardableResult
func runProcess(
    _ executable: String,
    arguments: [String],
    currentDirectory: String? = nil,
    environment: [String: String] = [:]
) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    if let currentDirectory {
        process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory)
    }
    if !environment.isEmpty {
        var merged = ProcessInfo.processInfo.environment
        for (key, value) in environment {
            merged[key] = value
        }
        process.environment = merged
    }

    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr

    try process.run()
    process.waitUntilExit()

    let stdoutString = String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    let stderrString = String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)

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

func writeSummary<T: Encodable>(_ value: T, to path: String) throws {
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(value).write(to: url, options: .atomic)
}

func buildProduct(repoRoot: String, outputDir: String) throws -> URL {
    let scriptPath = "\(repoRoot)/scripts/build_pushwrite_product.sh"
    let output = try runProcess("/bin/zsh", arguments: [scriptPath, outputDir], currentDirectory: repoRoot)
    let appPath = output.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !appPath.isEmpty else {
        throw ValidationError.buildFailed("Build script did not return an app path.")
    }
    return URL(fileURLWithPath: appPath)
}

func resolveProductApp(repoRoot: String, options: Options) throws -> URL {
    if let productAppPath = options.productAppPath {
        let url = URL(fileURLWithPath: productAppPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError.controlFailed("Missing product app at \(url.path)")
        }
        return url
    }

    if options.skipBuild {
        let defaultPath = "\(repoRoot)/build/pushwrite-product/PushWrite.app"
        let url = URL(fileURLWithPath: defaultPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError.controlFailed("Missing product app at \(url.path)")
        }
        return url
    }

    let outputDir = options.productOutputDir.isEmpty ? "\(repoRoot)/build/pushwrite-product" : options.productOutputDir
    let existingBundleURL = URL(fileURLWithPath: "\(outputDir)/PushWrite.app")
    if FileManager.default.fileExists(atPath: existingBundleURL.path) {
        return existingBundleURL
    }

    return try buildProduct(repoRoot: repoRoot, outputDir: outputDir)
}

func launchCommand(productAppPath: String, runtimeDir: String, simulatedText: String? = nil, forceAccessibilityBlocked: Bool = false, forceAccessibilityTrusted: Bool = false) -> String {
    var parts = [
        "open",
        "-n",
        shellEscape(productAppPath),
        "--args",
        "--runtime-dir",
        shellEscape(runtimeDir)
    ]
    if let simulatedText, !simulatedText.isEmpty {
        parts.append("--simulated-transcription-text")
        parts.append(shellEscape(simulatedText))
    }
    if forceAccessibilityBlocked {
        parts.append("--force-accessibility-blocked")
    }
    if forceAccessibilityTrusted {
        parts.append("--force-accessibility-trusted")
    }
    return parts.joined(separator: " ")
}

func runControl(
    repoRoot: String,
    productAppPath: String,
    runtimeDir: String,
    arguments: [String],
    environment: [String: String] = [:]
) throws -> String {
    let scriptPath = "\(repoRoot)/scripts/control_pushwrite_product.sh"
    return try runProcess(
        "/bin/zsh",
        arguments: [scriptPath] + arguments + ["--product-app", productAppPath, "--runtime-dir", runtimeDir],
        currentDirectory: repoRoot,
        environment: environment
    )
}

func launchProduct(
    repoRoot: String,
    productAppPath: String,
    runtimeDir: String,
    simulatedText: String,
    forceAccessibilityBlocked: Bool,
    forceAccessibilityTrusted: Bool
) throws -> ProductState {
    var arguments = [
        "launch",
        "--timeout-ms",
        "20000",
        "--simulated-text",
        simulatedText
    ]
    if forceAccessibilityBlocked {
        arguments.append("--force-accessibility-blocked")
    }
    if forceAccessibilityTrusted {
        arguments.append("--force-accessibility-trusted")
    }
    let output = try runControl(
        repoRoot: repoRoot,
        productAppPath: productAppPath,
        runtimeDir: runtimeDir,
        arguments: arguments
    )
    return try JSONDecoder().decode(ProductState.self, from: Data(output.utf8))
}

func stopProduct(repoRoot: String, productAppPath: String, runtimeDir: String) {
    _ = try? runControl(
        repoRoot: repoRoot,
        productAppPath: productAppPath,
        runtimeDir: runtimeDir,
        arguments: ["stop", "--timeout-ms", "5000"]
    )
}

func currentBundleID(_ focus: FocusSnapshot?) -> String? {
    focus?.app?.bundleID
}

func frontmostBundleID() -> String? {
    NSWorkspace.shared.frontmostApplication?.bundleIdentifier
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
    try waitUntil(timeoutSeconds: 10) {
        try readTextEditValue().isEmpty
    }
    Thread.sleep(forTimeInterval: 0.25)
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
    _ = semaphore.wait(timeout: .now() + 20)
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

    try waitUntil(timeoutSeconds: 20) {
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

func safariFixtureReady() throws -> Bool {
    let tabName = try readAppleScriptString("""
    tell application id "com.apple.Safari"
      return name of current tab of front window
    end tell
    """)
    return tabName.contains("PushWrite 002A Browser Fixture len=0")
}

func triggerGlobalHotKey() throws {
    _ = try runAppleScript("""
    tell application "System Events"
      key code 35 using {control down, option down, command down}
    end tell
    """)
}

func readLastHotKeyResponse(runtimeDir: String) throws -> ProductResponse? {
    let path = "\(runtimeDir)/logs/last-hotkey-response.json"
    guard FileManager.default.fileExists(atPath: path) else {
        return nil
    }
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    return try JSONDecoder().decode(ProductResponse.self, from: data)
}

func readFlowEvents(runtimeDir: String) throws -> [ProductFlowEvent] {
    let path = "\(runtimeDir)/logs/flow-events.jsonl"
    guard FileManager.default.fileExists(atPath: path) else {
        return []
    }

    let content = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
    let decoder = JSONDecoder()
    return content
        .split(whereSeparator: \.isNewline)
        .compactMap { line in
            try? decoder.decode(ProductFlowEvent.self, from: Data(line.utf8))
        }
}

func waitForNewHotKeyResponse(runtimeDir: String, previousID: String?) throws -> ProductResponse {
    var response: ProductResponse?
    try waitUntil(timeoutSeconds: 10) {
        response = try readLastHotKeyResponse(runtimeDir: runtimeDir)
        guard let response else {
            return false
        }
        return response.id != previousID
    }
    guard let response else {
        throw ValidationError.timeout("Hotkey response did not arrive.")
    }
    return response
}

func waitForFlowStates(runtimeDir: String, responseID: String, terminalState: String) throws -> [String] {
    var states: [String] = []
    try waitUntil(timeoutSeconds: 10) {
        states = try readFlowEvents(runtimeDir: runtimeDir)
            .filter { $0.id == responseID }
            .map(\.state)
        return states.contains(terminalState)
    }
    return states
}

func missingFlowReasons(flowStates: [String], terminalState: String) -> [String] {
    let expectedStates = ["triggered", "inserting", terminalState]
    var reasons: [String] = []
    var searchStart = 0

    for expectedState in expectedStates {
        guard let foundIndex = flowStates[searchStart...].firstIndex(of: expectedState) else {
            reasons.append("missing-flow-\(expectedState)")
            continue
        }
        searchStart = foundIndex + 1
    }

    return reasons
}

func runHotKeySeries(
    name: String,
    runCount: Int,
    expectedText: String,
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
    var productFrontmostAtReceiptCount = 0
    var productFrontmostBeforePasteCount = 0
    var productFrontmostAfterPasteCount = 0
    var frontmostAfterTriggerTargetAppCount = 0

    for iteration in 1...runCount {
        try prepare()

        var reasons: [String] = []
        if let verifyTargetIsReady, try !verifyTargetIsReady() {
            reasons.append("target-not-ready-before-run")
        }

        let previousResponseID = try readLastHotKeyResponse(runtimeDir: runtimeDir)?.id
        try triggerGlobalHotKey()

        let hotKeyResponse = try waitForNewHotKeyResponse(runtimeDir: runtimeDir, previousID: previousResponseID)
        let flowStates = try waitForFlowStates(runtimeDir: runtimeDir, responseID: hotKeyResponse.id, terminalState: "done")

        Thread.sleep(forTimeInterval: 0.25)
        let targetValue = try readValue()
        let frontmostAfterTrigger = frontmostBundleID()

        if targetValue != expectedText {
            reasons.append("target-value-mismatch")
        }
        if hotKeyResponse.status != "succeeded" {
            reasons.append("product-status-\(hotKeyResponse.status)")
        }
        if hotKeyResponse.kind != "insertTranscription" {
            reasons.append("unexpected-kind-\(hotKeyResponse.kind)")
        }
        if hotKeyResponse.insertRoute != "pasteboardCommandV" {
            reasons.append("unexpected-insert-route")
        }
        if hotKeyResponse.insertSource != "transcription" {
            reasons.append("unexpected-insert-source")
        }
        if !hotKeyResponse.syntheticPastePosted {
            reasons.append("synthetic-paste-not-posted")
        }
        if hotKeyResponse.error != nil {
            reasons.append("product-error")
        }

        if currentBundleID(hotKeyResponse.focusAtReceipt) == targetBundleID(for: name) {
            focusAtReceiptTargetAppCount += 1
        } else {
            reasons.append("focus-at-receipt-not-target")
        }

        if currentBundleID(hotKeyResponse.focusBeforePaste) == targetBundleID(for: name) {
            focusBeforeTargetAppCount += 1
        } else {
            reasons.append("focus-before-not-target")
        }

        if currentBundleID(hotKeyResponse.focusAfterPaste) == targetBundleID(for: name) {
            focusAfterTargetAppCount += 1
        } else {
            reasons.append("focus-after-not-target")
        }

        if frontmostAfterTrigger == targetBundleID(for: name) {
            frontmostAfterTriggerTargetAppCount += 1
        } else {
            reasons.append("frontmost-after-trigger-not-target")
        }

        if hotKeyResponse.productFrontmostAtReceipt {
            productFrontmostAtReceiptCount += 1
            reasons.append("product-frontmost-at-receipt")
        }

        if hotKeyResponse.productFrontmostBeforePaste {
            productFrontmostBeforePasteCount += 1
            reasons.append("product-frontmost-before-paste")
        }

        if hotKeyResponse.productFrontmostAfterPaste {
            productFrontmostAfterPasteCount += 1
            reasons.append("product-frontmost-after-paste")
        }

        reasons.append(contentsOf: missingFlowReasons(flowStates: flowStates, terminalState: "done"))

        for reason in reasons {
            failureReasons[reason, default: 0] += 1
        }

        records.append(
            ContextRunRecord(
                iteration: iteration,
                success: reasons.isEmpty,
                targetValue: targetValue,
                frontmostBundleAfterTrigger: frontmostAfterTrigger,
                hotKeyResponse: hotKeyResponse,
                flowStates: flowStates,
                failureReasons: reasons
            )
        )
    }

    return ContextSummary(
        name: name,
        runCount: runCount,
        successCount: records.filter(\.success).count,
        failureReasons: failureReasons,
        focusAtReceiptTargetAppCount: focusAtReceiptTargetAppCount,
        focusBeforeTargetAppCount: focusBeforeTargetAppCount,
        focusAfterTargetAppCount: focusAfterTargetAppCount,
        productFrontmostAtReceiptCount: productFrontmostAtReceiptCount,
        productFrontmostBeforePasteCount: productFrontmostBeforePasteCount,
        productFrontmostAfterPasteCount: productFrontmostAfterPasteCount,
        frontmostAfterTriggerTargetAppCount: frontmostAfterTriggerTargetAppCount,
        records: records
    )
}

func runBlockedHotKeyValidation(
    launchState: ProductState,
    runtimeDir: String
) throws -> BlockedHotKeySummary {
    try ensureTextEditReady()
    let previousResponseID = try readLastHotKeyResponse(runtimeDir: runtimeDir)?.id
    try triggerGlobalHotKey()

    let hotKeyResponse = try waitForNewHotKeyResponse(runtimeDir: runtimeDir, previousID: previousResponseID)
    let flowStates = try waitForFlowStates(runtimeDir: runtimeDir, responseID: hotKeyResponse.id, terminalState: "blocked")

    Thread.sleep(forTimeInterval: 0.25)
    let textEditValue = try readTextEditValue()
    let frontmostAfterTrigger = frontmostBundleID()

    var reasons: [String] = []
    if hotKeyResponse.status != "blocked" {
        reasons.append("product-status-\(hotKeyResponse.status)")
    }
    if hotKeyResponse.blockedReason != "Accessibility access is required before PushWrite can insert text with synthetic Cmd+V." {
        reasons.append("unexpected-blocked-reason")
    }
    if hotKeyResponse.syntheticPastePosted {
        reasons.append("synthetic-paste-posted-while-blocked")
    }
    if hotKeyResponse.clipboardRestored {
        reasons.append("clipboard-restored-while-blocked")
    }
    if textEditValue != "" {
        reasons.append("text-edit-changed-while-blocked")
    }
    if currentBundleID(hotKeyResponse.focusAtReceipt) != "com.apple.TextEdit" {
        reasons.append("blocked-focus-at-receipt-not-target")
    }
    if currentBundleID(hotKeyResponse.focusBeforePaste) != "com.apple.TextEdit" {
        reasons.append("blocked-focus-before-not-target")
    }
    if currentBundleID(hotKeyResponse.focusAfterPaste) != "com.apple.TextEdit" {
        reasons.append("blocked-focus-after-not-target")
    }
    if hotKeyResponse.productFrontmostAtReceipt || hotKeyResponse.productFrontmostBeforePaste || hotKeyResponse.productFrontmostAfterPaste {
        reasons.append("product-became-frontmost-while-blocked")
    }
    if frontmostAfterTrigger != "com.apple.TextEdit" {
        reasons.append("frontmost-after-blocked-trigger-not-textedit")
    }
    reasons.append(contentsOf: missingFlowReasons(flowStates: flowStates, terminalState: "blocked"))

    return BlockedHotKeySummary(
        launchState: launchState,
        hotKeyResponse: hotKeyResponse,
        textEditValueAfterTrigger: textEditValue,
        frontmostBundleAfterTrigger: frontmostAfterTrigger,
        flowStates: flowStates,
        failureReasons: reasons
    )
}

let repoRoot = FileManager.default.currentDirectoryPath
var options: Options
do {
    options = try parseOptions(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
    fputs("\(error)\n", stderr)
    exit(64)
}

if options.productOutputDir.isEmpty {
    options.productOutputDir = "\(repoRoot)/build/pushwrite-product"
}
if options.successRuntimeDir.isEmpty {
    options.successRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-hotkey-success"
}
if options.blockedRuntimeDir.isEmpty {
    options.blockedRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-hotkey-blocked"
}

let productAppURL: URL
do {
    productAppURL = try resolveProductApp(repoRoot: repoRoot, options: options)
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}

let fixtureURL = URL(fileURLWithPath: "\(repoRoot)/tests/integration/browser-textarea-fixture.html")

let successLaunchState: ProductState
do {
    try? FileManager.default.removeItem(atPath: options.successRuntimeDir)
    successLaunchState = try launchProduct(
        repoRoot: repoRoot,
        productAppPath: productAppURL.path,
        runtimeDir: options.successRuntimeDir,
        simulatedText: options.simulatedText,
        forceAccessibilityBlocked: false,
        forceAccessibilityTrusted: true
    )
} catch {
    fputs("Product launch failed: \(error)\n", stderr)
    exit(1)
}

defer {
    stopProduct(repoRoot: repoRoot, productAppPath: productAppURL.path, runtimeDir: options.successRuntimeDir)
}

let preflight = HotKeyPreflightSummary(
    accessibilityTrusted: successLaunchState.accessibilityTrusted,
    blockedReason: successLaunchState.blockedReason,
    hotKeyDescriptor: successLaunchState.hotKey.descriptor,
    hotKeyRegistered: successLaunchState.hotKey.registered,
    hotKeyRegistrationError: successLaunchState.hotKey.registrationError,
    launchFlowState: successLaunchState.flow.state,
    launchFlowTrigger: successLaunchState.flow.trigger,
    forceAccessibilityTrusted: true
)

guard preflight.accessibilityTrusted else {
    fputs("Accessibility is not trusted for the success runtime.\n", stderr)
    exit(1)
}

guard preflight.hotKeyRegistered else {
    fputs("Global hotkey did not register: \(preflight.hotKeyRegistrationError ?? "unknown error")\n", stderr)
    exit(1)
}

let textEditSummary: ContextSummary
do {
    textEditSummary = try runHotKeySeries(
        name: "textedit",
        runCount: options.textEditRuns,
        expectedText: options.simulatedText,
        runtimeDir: options.successRuntimeDir,
        prepare: {
            try ensureTextEditReady()
        },
        readValue: {
            try readTextEditValue()
        }
    )
} catch {
    fputs("TextEdit hotkey series failed: \(error)\n", stderr)
    exit(1)
}

let safariSummary: ContextSummary
do {
    safariSummary = try runHotKeySeries(
        name: "safari",
        runCount: options.safariRuns,
        expectedText: options.simulatedText,
        runtimeDir: options.successRuntimeDir,
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
    fputs("Safari hotkey series failed: \(error)\n", stderr)
    exit(1)
}

stopProduct(repoRoot: repoRoot, productAppPath: productAppURL.path, runtimeDir: options.successRuntimeDir)

let blockedLaunchState: ProductState
do {
    try? FileManager.default.removeItem(atPath: options.blockedRuntimeDir)
    blockedLaunchState = try launchProduct(
        repoRoot: repoRoot,
        productAppPath: productAppURL.path,
        runtimeDir: options.blockedRuntimeDir,
        simulatedText: options.simulatedText,
        forceAccessibilityBlocked: true,
        forceAccessibilityTrusted: false
    )
} catch {
    fputs("Blocked runtime launch failed: \(error)\n", stderr)
    exit(1)
}

defer {
    stopProduct(repoRoot: repoRoot, productAppPath: productAppURL.path, runtimeDir: options.blockedRuntimeDir)
}

let blockedSummary: BlockedHotKeySummary
do {
    blockedSummary = try runBlockedHotKeyValidation(
        launchState: blockedLaunchState,
        runtimeDir: options.blockedRuntimeDir
    )
} catch {
    fputs("Blocked hotkey validation failed: \(error)\n", stderr)
    exit(1)
}

let summary = ValidationSummary(
    timestamp: isoTimestamp(),
    simulatedText: options.simulatedText,
    productAppPath: productAppURL.path,
    successRuntimeDir: options.successRuntimeDir,
    blockedRuntimeDir: options.blockedRuntimeDir,
    manualLaunchCommand: launchCommand(
        productAppPath: productAppURL.path,
        runtimeDir: options.successRuntimeDir,
        simulatedText: options.simulatedText
    ),
    preflight: preflight,
    textEdit: textEditSummary,
    safari: safariSummary,
    blocked: blockedSummary,
    successFlowEventsLogFile: "\(options.successRuntimeDir)/logs/flow-events.jsonl",
    blockedFlowEventsLogFile: "\(options.blockedRuntimeDir)/logs/flow-events.jsonl",
    lastHotKeyResponseFile: "\(options.successRuntimeDir)/logs/last-hotkey-response.json"
)

if let resultsFile = options.resultsFile {
    do {
        try writeSummary(summary, to: resultsFile)
    } catch {
        fputs("Could not write results file: \(error)\n", stderr)
        exit(1)
    }
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
do {
    let data = try encoder.encode(summary)
    if let string = String(data: data, encoding: .utf8) {
        print(string)
    }
} catch {
    fputs("Could not encode summary: \(error)\n", stderr)
    exit(1)
}
