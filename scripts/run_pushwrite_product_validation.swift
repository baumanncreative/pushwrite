#!/usr/bin/env swift

import AppKit
import Foundation

struct Options {
    var payload = "PushWrite 002D test aeoeue ss EUR."
    var textEditRuns = 20
    var safariRuns = 20
    var productOutputDir = ""
    var productRuntimeDir = ""
    var productAppPath: String?
    var resultsFile: String?
    var promptAccessibilityOnPreflight = false
    var skipBuild = false
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

struct SuccessCriteria: Codable {
    let rule: String
    let notes: [String]
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
    let productResponse: ProductResponse
    let error: String?
}

struct ContextRunRecord: Codable {
    let iteration: Int
    let success: Bool
    let productResponseSucceeded: Bool
    let observedTargetValueMatches: Bool
    let targetValue: String
    let productResponse: ProductResponse
    let failureReasons: [String]
}

struct ContextSummary: Codable {
    let name: String
    let runCount: Int
    let successCount: Int
    let strictSuccessRule: String
    let productResponseSucceededCount: Int
    let observedTargetValueMatchesCount: Int
    let failureReasons: [String: Int]
    let focusAtReceiptTargetAppCount: Int
    let focusBeforeTargetAppCount: Int
    let focusAfterTargetAppCount: Int
    let productFrontmostAtReceiptCount: Int
    let productFrontmostBeforePasteCount: Int
    let productFrontmostAfterPasteCount: Int
    let records: [ContextRunRecord]
}

struct BlockedFlowSummary: Codable {
    let launchStateAccessibilityTrusted: Bool
    let launchStateBlockedReason: String?
    let preflightWithoutPrompt: ProductResponse
    let promptAttempted: Bool
    let preflightAfterPrompt: ProductResponse?
}

struct PreflightSummary: Codable {
    let productRunning: Bool
    let productAccessibilityTrusted: Bool
    let productBlockedReason: String?
    let preflightKind: String
    let preflightInsertRoute: String?
    let preflightInsertSource: String?
    let productFrontmostAtReceipt: Bool
    let productFrontmostBeforePaste: Bool
    let textEditAutomationReady: Bool
    let safariAutomationReady: Bool
    let notes: [String]
}

struct ValidationSummary: Codable {
    let timestamp: String
    let payload: String
    let productAppPath: String
    let productRuntimeDir: String
    let manualLaunchCommand: String
    let successCriteria: SuccessCriteria
    let launchState: ProductState
    let blockedFlow: BlockedFlowSummary
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
            return "Product build failed: \(message)"
        case let .controlFailed(message):
            return "Product control failed: \(message)"
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
        case "--product-output-dir":
            options.productOutputDir = try requireValue(for: argument)
        case "--product-runtime-dir":
            options.productRuntimeDir = try requireValue(for: argument)
        case "--product-app-path":
            options.productAppPath = try requireValue(for: argument)
        case "--results-file":
            options.resultsFile = try requireValue(for: argument)
        case "--prompt-accessibility-on-preflight":
            options.promptAccessibilityOnPreflight = true
        case "--skip-build":
            options.skipBuild = true
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

func shellEscape(_ value: String) -> String {
    "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

func strictObservedInsertionSuccessRule() -> String {
    "Success requires observed target value == expected text and product response invariants to hold; product status=succeeded alone is insufficient."
}

func productValidationSuccessCriteria() -> SuccessCriteria {
    SuccessCriteria(
        rule: strictObservedInsertionSuccessRule(),
        notes: [
            "A run is only successful when the target context value actually matches the payload.",
            "A product response with status=succeeded does not count as success when observed target content stays unchanged."
        ]
    )
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

func buildProduct(repoRoot: String, outputDir: String) throws -> URL {
    let scriptPath = "\(repoRoot)/scripts/build_pushwrite_product.sh"
    let output = try runProcess("/bin/zsh", arguments: [scriptPath, outputDir], currentDirectory: repoRoot)
    let appPath = output.trimmingCharacters(in: .whitespacesAndNewlines)
    return URL(fileURLWithPath: appPath)
}

func stableProductAppPath(repoRoot: String) -> String {
    "\(repoRoot)/build/pushwrite-product/PushWrite.app"
}

func candidateProductOutputDir(repoRoot: String) -> String {
    "\(repoRoot)/build/pushwrite-product-candidate"
}

func resolveProductApp(repoRoot: String, options: Options) throws -> URL {
    if let productAppPath = options.productAppPath {
        let url = URL(fileURLWithPath: productAppPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError.controlFailed("Missing product app at \(url.path)")
        }
        return url
    }

    let stableURL = URL(fileURLWithPath: stableProductAppPath(repoRoot: repoRoot))
    if FileManager.default.fileExists(atPath: stableURL.path) {
        return stableURL
    }

    if options.skipBuild {
        throw ValidationError.controlFailed(
            "Missing stable product app at \(stableURL.path). Build a candidate bundle with scripts/build_pushwrite_product.sh, promote it explicitly, or pass --product-app-path to validate a non-stable bundle."
        )
    }

    let outputDir = options.productOutputDir.isEmpty ? candidateProductOutputDir(repoRoot: repoRoot) : options.productOutputDir
    let existingBundleURL = URL(fileURLWithPath: "\(outputDir)/PushWrite.app")
    if FileManager.default.fileExists(atPath: existingBundleURL.path) {
        return existingBundleURL
    }

    return try buildProduct(repoRoot: repoRoot, outputDir: outputDir)
}

func launchCommand(repoRoot: String, productAppPath: String, runtimeDir: String) -> String {
    [
        shellEscape("\(repoRoot)/scripts/control_pushwrite_product.sh"),
        "launch",
        "--product-app",
        shellEscape(productAppPath),
        "--runtime-dir",
        shellEscape(runtimeDir)
    ].joined(separator: " ")
}

func runControl(repoRoot: String, productAppPath: String, runtimeDir: String, arguments: [String]) throws -> String {
    let scriptPath = "\(repoRoot)/scripts/control_pushwrite_product.sh"
    return try runProcess(
        "/bin/zsh",
        arguments: [scriptPath] + arguments + ["--product-app", productAppPath, "--runtime-dir", runtimeDir],
        currentDirectory: repoRoot
    )
}

func launchProduct(repoRoot: String, productAppPath: String, runtimeDir: String) throws -> ProductState {
    let appURL = URL(fileURLWithPath: productAppPath)
    guard FileManager.default.fileExists(atPath: appURL.path) else {
        throw ValidationError.controlFailed("Missing product app at \(appURL.path)")
    }

    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = false
    configuration.createsNewApplicationInstance = true
    configuration.arguments = ["--runtime-dir", runtimeDir]

    _ = NSApplication.shared
    let deadline = Date().addingTimeInterval(15)
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
        throw ValidationError.controlFailed("PushWrite launch failed: \(launchError)")
    }
    if !launchCompleted {
        throw ValidationError.timeout("launch completion did not return within 15 seconds")
    }

    try waitUntil(timeoutSeconds: 15) {
        guard let state = try? readLaunchState(runtimeDir: runtimeDir) else {
            return false
        }
        return state.running
    }

    return try readLaunchState(runtimeDir: runtimeDir)
}

func readLaunchState(runtimeDir: String) throws -> ProductState {
    let path = "\(runtimeDir)/product-state.json"
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else {
        throw ValidationError.controlFailed("Missing product state file at \(path)")
    }
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(ProductState.self, from: data)
}

func runPreflight(repoRoot: String, productAppPath: String, runtimeDir: String, prompt: Bool) throws -> ProductResponse {
    var arguments = ["preflight", "--timeout-ms", "15000"]
    if prompt {
        arguments.append("--prompt-accessibility")
    }
    let output = try runControl(repoRoot: repoRoot, productAppPath: productAppPath, runtimeDir: runtimeDir, arguments: arguments)
    return try JSONDecoder().decode(ProductResponse.self, from: Data(output.utf8))
}

func runInsertTranscription(
    repoRoot: String,
    productAppPath: String,
    runtimeDir: String,
    text: String,
    restoreClipboard: Bool
) throws -> ProductResponse {
    var arguments = [
        "insert-transcription",
        "--text", text,
        "--timeout-ms", "15000"
    ]
    if restoreClipboard {
        arguments.append("--restore-clipboard")
    }

    let output = try runControl(repoRoot: repoRoot, productAppPath: productAppPath, runtimeDir: runtimeDir, arguments: arguments)
    return try JSONDecoder().decode(ProductResponse.self, from: Data(output.utf8))
}

func stopProduct(repoRoot: String, productAppPath: String, runtimeDir: String) {
    _ = try? runControl(
        repoRoot: repoRoot,
        productAppPath: productAppPath,
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
        string: "PushWrite 002D rich clipboard probe\nLine two with emphasis.",
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
    <p><strong>PushWrite 002D rich clipboard probe</strong></p>
    <p>Line two with emphasis.</p>
    """.data(using: .utf8)!

    let item = NSPasteboardItem()
    item.setString("PushWrite 002D rich clipboard probe\nLine two with emphasis.", forType: .string)
    item.setData(rtfData, forType: .rtf)
    item.setData(htmlData, forType: .html)
    pasteboard.writeObjects([item])
}

func ensureTextEditReady() throws {
    let script = """
    tell application "TextEdit"
      activate
      if not (exists document 1) then
        make new document
      end if
      set text of document 1 to ""
    end tell
    """
    _ = try runAppleScript(script)
    try waitUntil(timeoutSeconds: 10) {
        let value = try readTextEditValue()
        return value.isEmpty
    }
    Thread.sleep(forTimeInterval: 0.25)
}

func readTextEditValue() throws -> String {
    let script = """
    tell application "TextEdit"
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
    tell application "Safari"
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
        tell application "Safari"
          return URL of current tab of front window
        end tell
        """)
        return currentURL == fixtureURL.absoluteString
    }
    Thread.sleep(forTimeInterval: 0.5)
}

func readSafariTextareaValue() throws -> String {
    let currentURL = try readAppleScriptString("""
    tell application "Safari"
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
    tell application "Safari"
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
        tell application "TextEdit"
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
        tell application "Safari"
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
    productAppPath: String,
    runtimeDir: String,
    prepare: () throws -> Void,
    readValue: () throws -> String,
    verifyTargetIsReady: (() throws -> Bool)? = nil
) throws -> ContextSummary {
    guard runCount > 0 else {
        return ContextSummary(
            name: name,
            runCount: 0,
            successCount: 0,
            strictSuccessRule: strictObservedInsertionSuccessRule(),
            productResponseSucceededCount: 0,
            observedTargetValueMatchesCount: 0,
            failureReasons: [:],
            focusAtReceiptTargetAppCount: 0,
            focusBeforeTargetAppCount: 0,
            focusAfterTargetAppCount: 0,
            productFrontmostAtReceiptCount: 0,
            productFrontmostBeforePasteCount: 0,
            productFrontmostAfterPasteCount: 0,
            records: []
        )
    }

    var records: [ContextRunRecord] = []
    var failureReasons: [String: Int] = [:]
    var productResponseSucceededCount = 0
    var observedTargetValueMatchesCount = 0
    var focusAtReceiptTargetAppCount = 0
    var focusBeforeTargetAppCount = 0
    var focusAfterTargetAppCount = 0
    var productFrontmostAtReceiptCount = 0
    var productFrontmostBeforePasteCount = 0
    var productFrontmostAfterPasteCount = 0

    for iteration in 1...runCount {
        try prepare()
        var reasons: [String] = []
        if let verifyTargetIsReady {
            let ready = try verifyTargetIsReady()
            if !ready {
                reasons.append("target-not-ready-before-run")
            }
        }

        let productResponse = try runInsertTranscription(
            repoRoot: repoRoot,
            productAppPath: productAppPath,
            runtimeDir: runtimeDir,
            text: payload,
            restoreClipboard: false
        )

        Thread.sleep(forTimeInterval: 0.25)
        let targetValue = try readValue()
        let observedTargetValueMatches = targetValue == payload
        let productResponseSucceeded = productResponse.status == "succeeded"

        if observedTargetValueMatches {
            observedTargetValueMatchesCount += 1
        } else {
            reasons.append("target-value-mismatch")
        }

        if productResponseSucceeded {
            productResponseSucceededCount += 1
        } else {
            reasons.append("product-status-\(productResponse.status)")
        }

        if productResponse.kind != "insertTranscription" {
            reasons.append("unexpected-kind-\(productResponse.kind)")
        }

        if productResponse.insertRoute != "pasteboardCommandV" {
            reasons.append("unexpected-insert-route")
        }

        if productResponse.insertSource != "transcription" {
            reasons.append("unexpected-insert-source")
        }

        if !productResponse.syntheticPastePosted {
            reasons.append("synthetic-paste-not-posted")
        }

        if productResponse.error != nil {
            reasons.append("product-error")
        }

        if currentBundleID(productResponse.focusAtReceipt) == targetBundleID(for: name) {
            focusAtReceiptTargetAppCount += 1
        } else {
            reasons.append("focus-at-receipt-not-target")
        }

        if currentBundleID(productResponse.focusBeforePaste) == targetBundleID(for: name) {
            focusBeforeTargetAppCount += 1
        } else {
            reasons.append("focus-before-not-target")
        }

        if currentBundleID(productResponse.focusAfterPaste) == targetBundleID(for: name) {
            focusAfterTargetAppCount += 1
        } else {
            reasons.append("focus-after-not-target")
        }

        if productResponse.productFrontmostAtReceipt {
            productFrontmostAtReceiptCount += 1
            reasons.append("product-frontmost-at-receipt")
        }

        if productResponse.productFrontmostBeforePaste {
            productFrontmostBeforePasteCount += 1
            reasons.append("product-frontmost-before-paste")
        }

        if productResponse.productFrontmostAfterPaste {
            productFrontmostAfterPasteCount += 1
            reasons.append("product-frontmost-after-paste")
        }

        for reason in reasons {
            failureReasons[reason, default: 0] += 1
        }

        let success = reasons.isEmpty
        records.append(
            ContextRunRecord(
                iteration: iteration,
                success: success,
                productResponseSucceeded: productResponseSucceeded,
                observedTargetValueMatches: observedTargetValueMatches,
                targetValue: targetValue,
                productResponse: productResponse,
                failureReasons: reasons
            )
        )
    }

    let successCount = records.filter(\.success).count
    return ContextSummary(
        name: name,
        runCount: runCount,
        successCount: successCount,
        strictSuccessRule: strictObservedInsertionSuccessRule(),
        productResponseSucceededCount: productResponseSucceededCount,
        observedTargetValueMatchesCount: observedTargetValueMatchesCount,
        failureReasons: failureReasons,
        focusAtReceiptTargetAppCount: focusAtReceiptTargetAppCount,
        focusBeforeTargetAppCount: focusBeforeTargetAppCount,
        focusAfterTargetAppCount: focusAfterTargetAppCount,
        productFrontmostAtReceiptCount: productFrontmostAtReceiptCount,
        productFrontmostBeforePasteCount: productFrontmostBeforePasteCount,
        productFrontmostAfterPasteCount: productFrontmostAfterPasteCount,
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
    productAppPath: String,
    runtimeDir: String,
    seedClipboard: () throws -> Void
) throws -> ClipboardTestResult {
    try ensureTextEditReady()
    try seedClipboard()
    let beforeSnapshot = snapshotGeneralPasteboard()

    let productResponse = try runInsertTranscription(
        repoRoot: repoRoot,
        productAppPath: productAppPath,
        runtimeDir: runtimeDir,
        text: payload,
        restoreClipboard: true
    )

    Thread.sleep(forTimeInterval: 0.6)
    let afterSnapshot = snapshotGeneralPasteboard()
    let insertedText = try readTextEditValue()

    var failures: [String] = []
    if beforeSnapshot != afterSnapshot {
        failures.append("clipboard-snapshot-mismatch")
    }
    if insertedText != payload {
        failures.append("inserted-text-mismatch")
    }
    if productResponse.kind != "insertTranscription" {
        failures.append("unexpected-kind-\(productResponse.kind)")
    }
    if productResponse.insertRoute != "pasteboardCommandV" {
        failures.append("unexpected-insert-route")
    }
    if productResponse.insertSource != "transcription" {
        failures.append("unexpected-insert-source")
    }

    return ClipboardTestResult(
        name: name,
        success: failures.isEmpty,
        insertedTextMatches: insertedText == payload,
        beforeSnapshot: beforeSnapshot,
        afterSnapshot: afterSnapshot,
        productResponse: productResponse,
        error: failures.isEmpty ? nil : failures.joined(separator: ",")
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
var options: Options
do {
    options = try parseOptions(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
    fputs("\(error)\n", stderr)
    exit(64)
}

if options.productOutputDir.isEmpty {
    options.productOutputDir = candidateProductOutputDir(repoRoot: repoRoot)
}
if options.productRuntimeDir.isEmpty {
    options.productRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime"
}

let productAppURL: URL
do {
    productAppURL = try resolveProductApp(repoRoot: repoRoot, options: options)
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}

let launchState: ProductState
do {
    if options.skipLaunch {
        launchState = try readLaunchState(runtimeDir: options.productRuntimeDir)
    } else {
        try? FileManager.default.removeItem(atPath: options.productRuntimeDir)
        launchState = try launchProduct(
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.productRuntimeDir
        )
    }
} catch {
    fputs("Product launch failed: \(error)\n", stderr)
    exit(1)
}

defer {
    stopProduct(repoRoot: repoRoot, productAppPath: productAppURL.path, runtimeDir: options.productRuntimeDir)
}

let fixtureURL = URL(fileURLWithPath: "\(repoRoot)/tests/integration/browser-textarea-fixture.html")

let preflightWithoutPrompt: ProductResponse
do {
    preflightWithoutPrompt = try runPreflight(
        repoRoot: repoRoot,
        productAppPath: productAppURL.path,
        runtimeDir: options.productRuntimeDir,
        prompt: false
    )
} catch {
    fputs("Preflight without prompt failed: \(error)\n", stderr)
    exit(1)
}

var preflightAfterPrompt: ProductResponse?
if options.promptAccessibilityOnPreflight && !preflightWithoutPrompt.accessibilityTrusted {
    do {
        preflightAfterPrompt = try runPreflight(
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.productRuntimeDir,
            prompt: true
        )
    } catch {
        fputs("Preflight with prompt failed: \(error)\n", stderr)
        exit(1)
    }

    let deadline = Date().addingTimeInterval(60)
    while Date() < deadline, let response = preflightAfterPrompt, !response.accessibilityTrusted {
        Thread.sleep(forTimeInterval: 2.0)
        do {
            preflightAfterPrompt = try runPreflight(
                repoRoot: repoRoot,
                productAppPath: productAppURL.path,
                runtimeDir: options.productRuntimeDir,
                prompt: false
            )
        } catch {
            fputs("Preflight recheck failed: \(error)\n", stderr)
            exit(1)
        }
    }
}

let finalPreflight = preflightAfterPrompt ?? preflightWithoutPrompt
let blockedFlow = BlockedFlowSummary(
    launchStateAccessibilityTrusted: launchState.accessibilityTrusted,
    launchStateBlockedReason: launchState.blockedReason,
    preflightWithoutPrompt: preflightWithoutPrompt,
    promptAttempted: options.promptAccessibilityOnPreflight,
    preflightAfterPrompt: preflightAfterPrompt
)

let automationReady = validateAutomationReadiness()
let preflight = PreflightSummary(
    productRunning: launchState.running,
    productAccessibilityTrusted: finalPreflight.accessibilityTrusted,
    productBlockedReason: finalPreflight.blockedReason,
    preflightKind: finalPreflight.kind,
    preflightInsertRoute: finalPreflight.insertRoute,
    preflightInsertSource: finalPreflight.insertSource,
    productFrontmostAtReceipt: finalPreflight.productFrontmostAtReceipt,
    productFrontmostBeforePaste: finalPreflight.productFrontmostBeforePaste,
    textEditAutomationReady: automationReady.textEdit,
    safariAutomationReady: automationReady.safari,
    notes: automationReady.notes
)

guard preflight.productAccessibilityTrusted else {
    if let resultsFile = options.resultsFile {
        let placeholderSummary = ValidationSummary(
            timestamp: isoTimestamp(),
            payload: options.payload,
            productAppPath: productAppURL.path,
            productRuntimeDir: options.productRuntimeDir,
            manualLaunchCommand: launchCommand(repoRoot: repoRoot, productAppPath: productAppURL.path, runtimeDir: options.productRuntimeDir),
            successCriteria: productValidationSuccessCriteria(),
            launchState: launchState,
            blockedFlow: blockedFlow,
            preflight: preflight,
            textEdit: ContextSummary(name: "textedit", runCount: 0, successCount: 0, strictSuccessRule: strictObservedInsertionSuccessRule(), productResponseSucceededCount: 0, observedTargetValueMatchesCount: 0, failureReasons: [:], focusAtReceiptTargetAppCount: 0, focusBeforeTargetAppCount: 0, focusAfterTargetAppCount: 0, productFrontmostAtReceiptCount: 0, productFrontmostBeforePasteCount: 0, productFrontmostAfterPasteCount: 0, records: []),
            safari: ContextSummary(name: "safari", runCount: 0, successCount: 0, strictSuccessRule: strictObservedInsertionSuccessRule(), productResponseSucceededCount: 0, observedTargetValueMatchesCount: 0, failureReasons: [:], focusAtReceiptTargetAppCount: 0, focusBeforeTargetAppCount: 0, focusAfterTargetAppCount: 0, productFrontmostAtReceiptCount: 0, productFrontmostBeforePasteCount: 0, productFrontmostAfterPasteCount: 0, records: []),
            clipboardRestore: [],
            eventsLogFile: "\(options.productRuntimeDir)/logs/events.jsonl"
        )
        try? writeSummary(placeholderSummary, to: resultsFile)
    }
    fputs("Accessibility is not trusted for the PushWrite product app.\n", stderr)
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
        productAppPath: productAppURL.path,
        runtimeDir: options.productRuntimeDir,
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
        productAppPath: productAppURL.path,
        runtimeDir: options.productRuntimeDir,
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
        productAppPath: productAppURL.path,
        runtimeDir: options.productRuntimeDir,
        seedClipboard: {
            clearAndWriteStringToPasteboard("ORIGINAL_CLIPBOARD_002D")
        }
    )

    richClipboardResult = try runClipboardRestoreProbe(
        name: "rich",
        payload: options.payload,
        repoRoot: repoRoot,
        productAppPath: productAppURL.path,
        runtimeDir: options.productRuntimeDir,
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
    productAppPath: productAppURL.path,
    productRuntimeDir: options.productRuntimeDir,
    manualLaunchCommand: launchCommand(repoRoot: repoRoot, productAppPath: productAppURL.path, runtimeDir: options.productRuntimeDir),
    successCriteria: productValidationSuccessCriteria(),
    launchState: launchState,
    blockedFlow: blockedFlow,
    preflight: preflight,
    textEdit: textEditSummary,
    safari: safariSummary,
    clipboardRestore: [plainClipboardResult, richClipboardResult],
    eventsLogFile: "\(options.productRuntimeDir)/logs/events.jsonl"
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
    print("[002D] context=\(summary.name) success=\(summary.successCount)/\(summary.runCount)")
    print("[002D] context=\(summary.name) productStatusSucceeded=\(summary.productResponseSucceededCount)/\(summary.runCount) observedTargetMatch=\(summary.observedTargetValueMatchesCount)/\(summary.runCount)")
    print("[002D] context=\(summary.name) focusReceiptTarget=\(summary.focusAtReceiptTargetAppCount) focusBeforeTarget=\(summary.focusBeforeTargetAppCount) focusAfterTarget=\(summary.focusAfterTargetAppCount)")
    print("[002D] context=\(summary.name) productFrontmostReceipt=\(summary.productFrontmostAtReceiptCount) productFrontmostBefore=\(summary.productFrontmostBeforePasteCount) productFrontmostAfter=\(summary.productFrontmostAfterPasteCount)")
    if !summary.failureReasons.isEmpty {
        let fragments = summary.failureReasons.keys.sorted().map { "\($0)=\(summary.failureReasons[$0] ?? 0)" }
        print("[002D] context=\(summary.name) failures=\(fragments.joined(separator: ","))")
    }
}

print("[002D] productAppPath=\(summary.productAppPath)")
print("[002D] runtimeDir=\(summary.productRuntimeDir)")
print("[002D] successRule=\(summary.successCriteria.rule)")
print("[002D] blockedPreflight accessibilityTrusted=\(summary.blockedFlow.preflightWithoutPrompt.accessibilityTrusted) blockedReason=\(summary.blockedFlow.preflightWithoutPrompt.blockedReason ?? "none")")
if let promptResponse = summary.blockedFlow.preflightAfterPrompt {
    print("[002D] promptedPreflight accessibilityTrusted=\(promptResponse.accessibilityTrusted) blockedReason=\(promptResponse.blockedReason ?? "none")")
}
print("[002D] preflight accessibilityTrusted=\(summary.preflight.productAccessibilityTrusted) running=\(summary.preflight.productRunning) blockedReason=\(summary.preflight.productBlockedReason ?? "none")")
if !summary.preflight.notes.isEmpty {
    print("[002D] preflight notes=\(summary.preflight.notes.joined(separator: " | "))")
}
printContextSummary(summary.textEdit)
printContextSummary(summary.safari)
for clipboard in summary.clipboardRestore {
    print("[002D] clipboard=\(clipboard.name) success=\(clipboard.success) insertedTextMatches=\(clipboard.insertedTextMatches) error=\(clipboard.error ?? "none")")
}
