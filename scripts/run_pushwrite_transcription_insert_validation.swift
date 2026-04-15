#!/usr/bin/env swift

import AppKit
import ApplicationServices
import Foundation

struct Options {
    var scenario = "all"
    var productOutputDir = ""
    var productAppPath: String?
    var successRuntimeDir = ""
    var gatedEmptyRuntimeDir = ""
    var gatedTooShortRuntimeDir = ""
    var blockedRuntimeDir = ""
    var inferenceFailureRuntimeDir = ""
    var whisperCLIPath: String?
    var whisperModelPath: String?
    var whisperLanguage = "en"
    var transcriptionFixtureWAVPath: String?
    var resultsFile: String?
    var holdDurationMs = 900
    var skipBuild = false
}

enum MicrophonePermissionStatus: String, Codable {
    case notDetermined
    case granted
    case denied
    case restricted
}

enum TranscriptionStatus: String, Codable {
    case succeeded
    case failed
}

enum TranscriptionInsertGate: String, Codable {
    case passed
    case empty
    case tooShort
}

enum GatedTranscriptionFeedback: String, Codable {
    case systemBeep
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
    let transcriptionInsertGate: TranscriptionInsertGate?
    let gatedTranscriptionFeedback: GatedTranscriptionFeedback?
    let blockedReason: String?
    let error: String?
    let recordingDurationMs: Int?
    let recordingFilePath: String?
}

struct RecordingArtifact: Codable {
    let id: String
    let filePath: String
    let metadataPath: String
    let format: String
    let sampleRateHz: Double
    let channelCount: Int
    let durationMs: Int
    let fileSizeBytes: UInt64
    let createdAt: String
}

struct TranscriptionArtifact: Codable {
    let id: String
    let recordingID: String
    let recordingFilePath: String
    let artifactPath: String
    let textFilePath: String
    let rawOutputJSONPath: String
    let cliPath: String
    let modelPath: String
    let modelName: String
    let language: String
    let status: TranscriptionStatus
    let text: String
    let textLength: Int
    let startedAt: String
    let completedAt: String
    let durationMs: Int
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
    let lastTranscriptionInsertGate: TranscriptionInsertGate?
    let lastGatedTranscriptionFeedback: GatedTranscriptionFeedback?
    let lastBlockedReason: String?
    let lastError: String?
    let microphonePermissionStatus: MicrophonePermissionStatus
    let hotKeyInteractionModel: String
    let activeRecordingID: String?
    let lastRecording: RecordingArtifact?
    let lastTranscription: TranscriptionArtifact?
    let hotKey: HotKeyStateSnapshot
    let flow: ProductFlowSnapshot
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

struct ProductResponse: Codable {
    let id: String
    let kind: String
    let timestamp: String
    let productBundleID: String?
    let productPID: Int32
    let status: String
    let accessibilityTrusted: Bool
    let microphonePermissionStatus: MicrophonePermissionStatus
    let requestedMicrophonePermission: Bool
    let promptAccessibility: Bool
    let blockedReason: String?
    let settleDelayMs: UInt32
    let pasteDelayMs: UInt32
    let restoreClipboard: Bool
    let restoreDelayMs: UInt32
    let textLength: Int
    let transcriptionInsertGate: TranscriptionInsertGate?
    let gatedTranscriptionFeedback: GatedTranscriptionFeedback?
    let hotKeyInteractionModel: String?
    let insertRoute: String?
    let insertSource: String?
    let focusAtReceipt: FocusSnapshot?
    let focusBeforePaste: FocusSnapshot?
    let focusAfterPaste: FocusSnapshot?
    let focusAtStop: FocusSnapshot?
    let productFrontmostAtReceipt: Bool
    let productFrontmostBeforePaste: Bool
    let productFrontmostAfterPaste: Bool
    let originalPasteboard: PasteboardMetadata?
    let syntheticPastePosted: Bool
    let clipboardRestored: Bool
    let recordingStartedAt: String?
    let recordingStoppedAt: String?
    let recordingArtifact: RecordingArtifact?
    let transcriptionArtifact: TranscriptionArtifact?
    let transcribingPlaceholder: Bool
    let error: String?
}

struct ProductFlowEvent: Codable {
    let id: String
    let state: String
    let trigger: String
    let timestamp: String
    let textLength: Int
    let transcriptionInsertGate: TranscriptionInsertGate?
    let blockedReason: String?
    let error: String?
    let recordingDurationMs: Int?
    let recordingFilePath: String?
}

struct ScenarioSummary: Codable {
    let name: String
    let runtimeDir: String
    let launchState: ProductState
    let finalState: ProductState?
    let hotKeyResponse: ProductResponse?
    let flowStates: [String]
    let observedText: String
    let frontmostBundleAfterTrigger: String?
    let success: Bool
    let failureReasons: [String]
    let notes: [String]
}

struct ValidationSummary: Codable {
    let timestamp: String
    let productAppPath: String
    let holdDurationMs: Int
    let successRuntimeDir: String
    let gatedEmptyRuntimeDir: String
    let gatedTooShortRuntimeDir: String
    let blockedRuntimeDir: String
    let inferenceFailureRuntimeDir: String
    let success: ScenarioSummary
    let gatedEmpty: ScenarioSummary
    let gatedTooShort: ScenarioSummary
    let blockedAccessibility: ScenarioSummary
    let inferenceFailure: ScenarioSummary
}

struct ScenarioObservation {
    let launchState: ProductState
    let finalState: ProductState?
    let hotKeyResponse: ProductResponse
    let flowStates: [String]
    let observedText: String
    let frontmostBundleAfterTrigger: String?
}

enum ValidationError: Error, CustomStringConvertible {
    case invalidInteger(flag: String, value: String)
    case missingValue(flag: String)
    case unknownArgument(String)
    case buildFailed(String)
    case controlFailed(String)
    case appleScriptFailed(String)
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
        case "--scenario":
            options.scenario = try requireValue(for: argument)
        case "--product-output-dir":
            options.productOutputDir = try requireValue(for: argument)
        case "--product-app-path":
            options.productAppPath = try requireValue(for: argument)
        case "--success-runtime-dir":
            options.successRuntimeDir = try requireValue(for: argument)
        case "--gated-empty-runtime-dir":
            options.gatedEmptyRuntimeDir = try requireValue(for: argument)
        case "--gated-too-short-runtime-dir":
            options.gatedTooShortRuntimeDir = try requireValue(for: argument)
        case "--blocked-runtime-dir":
            options.blockedRuntimeDir = try requireValue(for: argument)
        case "--inference-failure-runtime-dir":
            options.inferenceFailureRuntimeDir = try requireValue(for: argument)
        case "--whisper-cli-path":
            options.whisperCLIPath = try requireValue(for: argument)
        case "--whisper-model-path":
            options.whisperModelPath = try requireValue(for: argument)
        case "--whisper-language":
            options.whisperLanguage = try requireValue(for: argument)
        case "--transcription-fixture-wav":
            options.transcriptionFixtureWAVPath = try requireValue(for: argument)
        case "--results-file":
            options.resultsFile = try requireValue(for: argument)
        case "--hold-duration-ms":
            let value = try requireValue(for: argument)
            guard let parsed = Int(value) else {
                throw ValidationError.invalidInteger(flag: argument, value: value)
            }
            options.holdDurationMs = parsed
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

@discardableResult
func runProcess(
    _ executable: String,
    arguments: [String],
    currentDirectory: String? = nil
) throws -> String {
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

    let stdoutString = String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    let stderrString = String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)

    guard process.terminationStatus == 0 else {
        let failureOutput = stderrString.isEmpty ? stdoutString : stderrString
        throw ValidationError.controlFailed(failureOutput)
    }

    return stdoutString
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

func stableProductAppPath(repoRoot: String) -> String {
    "\(repoRoot)/build/pushwrite-product/PushWrite.app"
}

func candidateProductOutputDir(repoRoot: String) -> String {
    "\(repoRoot)/build/pushwrite-product-candidate"
}

func defaultWhisperCLIPath(repoRoot: String) -> String {
    "\(repoRoot)/build/whispercpp/build/bin/whisper-cli"
}

func defaultWhisperModelPath(repoRoot: String) -> String {
    "\(repoRoot)/models/ggml-tiny.bin"
}

func defaultTranscriptionFixtureWAVPath(repoRoot: String) -> String {
    "\(repoRoot)/build/whispercpp/micro-machines-16k-mono.wav"
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

    let stableURL = URL(fileURLWithPath: stableProductAppPath(repoRoot: repoRoot))
    if FileManager.default.fileExists(atPath: stableURL.path) {
        return stableURL
    }

    if options.skipBuild {
        throw ValidationError.controlFailed("Missing stable product app at \(stableURL.path)")
    }

    let outputDir = options.productOutputDir.isEmpty ? candidateProductOutputDir(repoRoot: repoRoot) : options.productOutputDir
    return try buildProduct(repoRoot: repoRoot, outputDir: outputDir)
}

func launchProduct(
    productAppPath: String,
    runtimeDir: String,
    whisperCLIPath: String?,
    whisperModelPath: String?,
    whisperLanguage: String?,
    transcriptionFixtureWAVPath: String?,
    forceAccessibilityBlocked: Bool,
    forceAccessibilityTrusted: Bool
) throws -> ProductState {
    let appURL = URL(fileURLWithPath: productAppPath)
    let executableURL = appURL
        .appendingPathComponent("Contents", isDirectory: true)
        .appendingPathComponent("MacOS", isDirectory: true)
        .appendingPathComponent("PushWrite", isDirectory: false)
    guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
        throw ValidationError.controlFailed("Missing PushWrite executable at \(executableURL.path)")
    }

    var arguments = ["--runtime-dir", runtimeDir]
    if let whisperCLIPath, !whisperCLIPath.isEmpty {
        arguments.append(contentsOf: ["--whisper-cli-path", whisperCLIPath])
    }
    if let whisperModelPath, !whisperModelPath.isEmpty {
        arguments.append(contentsOf: ["--whisper-model-path", whisperModelPath])
    }
    if let whisperLanguage, !whisperLanguage.isEmpty {
        arguments.append(contentsOf: ["--whisper-language", whisperLanguage])
    }
    if let transcriptionFixtureWAVPath, !transcriptionFixtureWAVPath.isEmpty {
        arguments.append(contentsOf: ["--transcription-fixture-wav", transcriptionFixtureWAVPath])
    }
    if forceAccessibilityBlocked {
        arguments.append("--force-accessibility-blocked")
    }
    if forceAccessibilityTrusted {
        arguments.append("--force-accessibility-trusted")
    }

    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments
    process.standardOutput = Pipe()
    process.standardError = Pipe()
    try process.run()

    try waitUntil(timeoutSeconds: 20) {
        guard let state = try? readState(runtimeDir: runtimeDir) else {
            return false
        }
        return state.running
    }

    return try readState(runtimeDir: runtimeDir)
}

func readState(runtimeDir: String) throws -> ProductState {
    let path = "\(runtimeDir)/product-state.json"
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    return try JSONDecoder().decode(ProductState.self, from: data)
}

func stopProduct(repoRoot: String, productAppPath: String, runtimeDir: String) {
    let scriptPath = "\(repoRoot)/scripts/control_pushwrite_product.sh"
    _ = try? runProcess(
        "/bin/zsh",
        arguments: [scriptPath, "stop", "--timeout-ms", "5000", "--product-app", productAppPath, "--runtime-dir", runtimeDir],
        currentDirectory: repoRoot
    )
}

func cleanupRunningProductProcesses(productAppPath: String) {
    guard
        let output = try? runProcess("/bin/ps", arguments: ["-Ao", "pid=,args="]),
        !output.isEmpty
    else {
        return
    }

    let executablePath = "\(productAppPath)/Contents/MacOS/PushWrite"
    let pids = output
        .split(whereSeparator: \.isNewline)
        .compactMap { line -> Int32? in
            let text = String(line)
            guard text.contains(executablePath) else {
                return nil
            }
            let parts = text.split(maxSplits: 1, whereSeparator: \.isWhitespace)
            guard let pidText = parts.first, let pid = Int32(pidText) else {
                return nil
            }
            return pid
        }

    for pid in pids {
        _ = kill(pid, SIGTERM)
    }

    if !pids.isEmpty {
        Thread.sleep(forTimeInterval: 0.5)
    }
}

func resetRuntimeDirectory(_ runtimeDir: String) throws {
    if FileManager.default.fileExists(atPath: runtimeDir) {
        try FileManager.default.removeItem(atPath: runtimeDir)
    }
    try FileManager.default.createDirectory(atPath: runtimeDir, withIntermediateDirectories: true, attributes: nil)
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

func ensureTextEditReady() throws {
    _ = try runAppleScript("""
    tell application "TextEdit"
      activate
      if not (exists document 1) then
        make new document
      end if
      set text of document 1 to ""
    end tell
    """)
    Thread.sleep(forTimeInterval: 0.35)
}

func readTextEditValue() throws -> String {
    let result = try runAppleScript("""
    tell application "TextEdit"
      if not (exists document 1) then
        return ""
      end if
      return text of document 1
    end tell
    """)
    return result.stringValue ?? ""
}

func frontmostBundleID() -> String? {
    NSWorkspace.shared.frontmostApplication?.bundleIdentifier
}

func currentBundleID(_ focus: FocusSnapshot?) -> String? {
    focus?.app?.bundleID
}

func pressGlobalHotKey() throws {
    guard let source = CGEventSource(stateID: .combinedSessionState) else {
        throw ValidationError.controlFailed("Could not create a CGEventSource for hotkey validation.")
    }

    let hotKeyFlags: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand]
    guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 35, keyDown: true) else {
        throw ValidationError.controlFailed("Could not create a synthetic hotkey keyDown event.")
    }

    keyDown.flags = hotKeyFlags
    keyDown.post(tap: .cghidEventTap)
}

func releaseGlobalHotKey() throws {
    guard let source = CGEventSource(stateID: .combinedSessionState) else {
        throw ValidationError.controlFailed("Could not create a CGEventSource for hotkey validation.")
    }

    let hotKeyFlags: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand]
    guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 35, keyDown: false) else {
        throw ValidationError.controlFailed("Could not create a synthetic hotkey keyUp event.")
    }

    keyUp.flags = hotKeyFlags
    keyUp.post(tap: .cghidEventTap)
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
        .replacingOccurrences(of: "}{", with: "}\n{")
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

func missingFlowReasons(flowStates: [String], expectedStates: [String]) -> [String] {
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

func meaningfulCharacterCount(_ text: String) -> Int {
    text.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.count
}

func createFakeWhisperCLI(directory: String, transcriptText: String) throws -> String {
    try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
    let path = "\(directory)/fake-whisper-cli.sh"
    let script = """
    #!/bin/zsh
    set -euo pipefail

    output_base=""
    language="en"

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -of)
          output_base="$2"
          shift 2
          ;;
        -l)
          language="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done

    if [[ -z "$output_base" ]]; then
      echo "missing -of output base" >&2
      exit 64
    fi

    cat <<'PUSHWRITE_TRANSCRIPT' > "${output_base}.txt"
    \(transcriptText)
    PUSHWRITE_TRANSCRIPT

    cat <<EOF_JSON > "${output_base}.json"
    {"result":{"language":"${language}"}}
    EOF_JSON
    """
    try script.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
    return path
}

func runHotKeyScenario(
    repoRoot: String,
    productAppPath: String,
    runtimeDir: String,
    holdDurationMs: Int,
    whisperCLIPath: String?,
    whisperModelPath: String?,
    whisperLanguage: String?,
    transcriptionFixtureWAVPath: String?,
    forceAccessibilityBlocked: Bool,
    forceAccessibilityTrusted: Bool,
    expectedTerminalState: String
) throws -> ScenarioObservation {
    try resetRuntimeDirectory(runtimeDir)

    let launchState = try launchProduct(
        productAppPath: productAppPath,
        runtimeDir: runtimeDir,
        whisperCLIPath: whisperCLIPath,
        whisperModelPath: whisperModelPath,
        whisperLanguage: whisperLanguage,
        transcriptionFixtureWAVPath: transcriptionFixtureWAVPath,
        forceAccessibilityBlocked: forceAccessibilityBlocked,
        forceAccessibilityTrusted: forceAccessibilityTrusted
    )

    defer {
        stopProduct(repoRoot: repoRoot, productAppPath: productAppPath, runtimeDir: runtimeDir)
    }

    try ensureTextEditReady()

    let previousResponseID = try readLastHotKeyResponse(runtimeDir: runtimeDir)?.id
    try pressGlobalHotKey()
    Thread.sleep(forTimeInterval: Double(holdDurationMs) / 1_000.0)
    try releaseGlobalHotKey()

    let hotKeyResponse = try waitForNewHotKeyResponse(runtimeDir: runtimeDir, previousID: previousResponseID)
    let flowStates = try waitForFlowStates(runtimeDir: runtimeDir, responseID: hotKeyResponse.id, terminalState: expectedTerminalState)
    Thread.sleep(forTimeInterval: 0.25)

    return ScenarioObservation(
        launchState: launchState,
        finalState: try? readState(runtimeDir: runtimeDir),
        hotKeyResponse: hotKeyResponse,
        flowStates: flowStates,
        observedText: try readTextEditValue(),
        frontmostBundleAfterTrigger: frontmostBundleID()
    )
}

func runSuccessScenario(
    repoRoot: String,
    productAppPath: String,
    runtimeDir: String,
    holdDurationMs: Int,
    whisperCLIPath: String,
    whisperModelPath: String,
    whisperLanguage: String,
    transcriptionFixtureWAVPath: String
) throws -> ScenarioSummary {
    let observation = try runHotKeyScenario(
        repoRoot: repoRoot,
        productAppPath: productAppPath,
        runtimeDir: runtimeDir,
        holdDurationMs: holdDurationMs,
        whisperCLIPath: whisperCLIPath,
        whisperModelPath: whisperModelPath,
        whisperLanguage: whisperLanguage,
        transcriptionFixtureWAVPath: transcriptionFixtureWAVPath,
        forceAccessibilityBlocked: false,
        forceAccessibilityTrusted: true,
        expectedTerminalState: "done"
    )

    let response = observation.hotKeyResponse
    var failureReasons: [String] = []

    if response.kind != "insertTranscription" {
        failureReasons.append("unexpected-kind-\(response.kind)")
    }
    if response.status != "succeeded" {
        failureReasons.append("unexpected-status-\(response.status)")
    }
    if response.transcriptionInsertGate != .passed {
        failureReasons.append("unexpected-transcription-insert-gate")
    }
    if response.gatedTranscriptionFeedback != nil {
        failureReasons.append("unexpected-gated-feedback")
    }
    if response.insertRoute != "pasteboardCommandV" {
        failureReasons.append("unexpected-insert-route")
    }
    if response.insertSource != "transcription" {
        failureReasons.append("unexpected-insert-source")
    }
    if !response.syntheticPastePosted {
        failureReasons.append("synthetic-paste-not-posted")
    }
    if response.error != nil {
        failureReasons.append("unexpected-error-present")
    }
    if response.transcriptionArtifact?.status != .succeeded {
        failureReasons.append("unexpected-transcription-status")
    }
    if response.transcriptionArtifact?.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
        failureReasons.append("empty-transcription-text")
    }
    if observation.observedText != response.transcriptionArtifact?.text {
        failureReasons.append("observed-text-mismatch")
    }
    if currentBundleID(response.focusAtReceipt) != "com.apple.TextEdit" {
        failureReasons.append("focus-at-receipt-not-textedit")
    }
    if currentBundleID(response.focusBeforePaste) != "com.apple.TextEdit" {
        failureReasons.append("focus-before-not-textedit")
    }
    if currentBundleID(response.focusAfterPaste) != "com.apple.TextEdit" {
        failureReasons.append("focus-after-not-textedit")
    }
    if response.productFrontmostAtReceipt {
        failureReasons.append("product-frontmost-at-receipt")
    }
    if response.productFrontmostBeforePaste {
        failureReasons.append("product-frontmost-before-paste")
    }
    if response.productFrontmostAfterPaste {
        failureReasons.append("product-frontmost-after-paste")
    }
    if observation.frontmostBundleAfterTrigger != "com.apple.TextEdit" {
        failureReasons.append("frontmost-after-trigger-not-textedit")
    }
    if response.recordingArtifact == nil {
        failureReasons.append("missing-recording-artifact")
    }
    if response.transcriptionArtifact == nil {
        failureReasons.append("missing-transcription-artifact")
    }
    failureReasons.append(contentsOf: missingFlowReasons(
        flowStates: observation.flowStates,
        expectedStates: ["triggered", "recording", "transcribing", "inserting", "done"]
    ))

    if observation.finalState?.flow.state != "done" {
        failureReasons.append("unexpected-final-state")
    }
    if observation.finalState?.flow.transcriptionInsertGate != .passed {
        failureReasons.append("unexpected-final-flow-gate")
    }
    if observation.finalState?.flow.gatedTranscriptionFeedback != nil {
        failureReasons.append("unexpected-final-flow-feedback")
    }
    if observation.finalState?.lastTranscriptionInsertGate != .passed {
        failureReasons.append("unexpected-last-gate")
    }
    if observation.finalState?.lastGatedTranscriptionFeedback != nil {
        failureReasons.append("unexpected-last-feedback")
    }

    return ScenarioSummary(
        name: "success",
        runtimeDir: runtimeDir,
        launchState: observation.launchState,
        finalState: observation.finalState,
        hotKeyResponse: response,
        flowStates: observation.flowStates,
        observedText: observation.observedText,
        frontmostBundleAfterTrigger: observation.frontmostBundleAfterTrigger,
        success: failureReasons.isEmpty,
        failureReasons: failureReasons,
        notes: []
    )
}

func runGatedScenario(
    name: String,
    repoRoot: String,
    productAppPath: String,
    runtimeDir: String,
    holdDurationMs: Int,
    whisperModelPath: String,
    whisperLanguage: String,
    transcriptText: String,
    expectedGate: TranscriptionInsertGate
) throws -> ScenarioSummary {
    let fakeCLIDir = "/tmp/pushwrite-product-tools/\(name)"
    let fakeCLIPath = try createFakeWhisperCLI(directory: fakeCLIDir, transcriptText: transcriptText)

    let observation = try runHotKeyScenario(
        repoRoot: repoRoot,
        productAppPath: productAppPath,
        runtimeDir: runtimeDir,
        holdDurationMs: holdDurationMs,
        whisperCLIPath: fakeCLIPath,
        whisperModelPath: whisperModelPath,
        whisperLanguage: whisperLanguage,
        transcriptionFixtureWAVPath: nil,
        forceAccessibilityBlocked: false,
        forceAccessibilityTrusted: true,
        expectedTerminalState: "done"
    )

    let response = observation.hotKeyResponse
    var failureReasons: [String] = []

    if response.kind != "insertTranscription" {
        failureReasons.append("unexpected-kind-\(response.kind)")
    }
    if response.status != "succeeded" {
        failureReasons.append("unexpected-status-\(response.status)")
    }
    if response.transcriptionInsertGate != expectedGate {
        failureReasons.append("unexpected-transcription-insert-gate")
    }
    if response.gatedTranscriptionFeedback != .systemBeep {
        failureReasons.append("missing-gated-feedback")
    }
    if response.insertSource != "transcription" {
        failureReasons.append("unexpected-insert-source")
    }
    if response.insertRoute != nil {
        failureReasons.append("unexpected-insert-route")
    }
    if response.syntheticPastePosted {
        failureReasons.append("synthetic-paste-posted")
    }
    if response.error != nil {
        failureReasons.append("unexpected-error-present")
    }
    if response.transcriptionArtifact?.status != .succeeded {
        failureReasons.append("unexpected-transcription-status")
    }
    if observation.observedText != "" {
        failureReasons.append("unexpected-textedit-change")
    }
    if observation.frontmostBundleAfterTrigger != "com.apple.TextEdit" {
        failureReasons.append("frontmost-after-trigger-not-textedit")
    }
    if response.recordingArtifact == nil {
        failureReasons.append("missing-recording-artifact")
    }
    if response.transcriptionArtifact == nil {
        failureReasons.append("missing-transcription-artifact")
    }

    switch expectedGate {
    case .empty:
        if response.transcriptionArtifact?.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != true {
            failureReasons.append("expected-empty-text")
        }
    case .tooShort:
        let text = response.transcriptionArtifact?.text ?? ""
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            failureReasons.append("unexpected-empty-text")
        }
        if meaningfulCharacterCount(text) >= 2 {
            failureReasons.append("expected-too-short-text")
        }
    case .passed:
        failureReasons.append("invalid-expected-gate")
    }

    failureReasons.append(contentsOf: missingFlowReasons(
        flowStates: observation.flowStates,
        expectedStates: ["triggered", "recording", "transcribing", "done"]
    ))
    if observation.flowStates.contains("inserting") {
        failureReasons.append("unexpected-inserting-state")
    }
    if observation.finalState?.flow.state != "done" {
        failureReasons.append("unexpected-final-state")
    }
    if observation.finalState?.flow.transcriptionInsertGate != expectedGate {
        failureReasons.append("unexpected-final-flow-gate")
    }
    if observation.finalState?.flow.gatedTranscriptionFeedback != .systemBeep {
        failureReasons.append("unexpected-final-flow-feedback")
    }
    if observation.finalState?.lastTranscriptionInsertGate != expectedGate {
        failureReasons.append("unexpected-last-gate")
    }
    if observation.finalState?.lastGatedTranscriptionFeedback != .systemBeep {
        failureReasons.append("unexpected-last-feedback")
    }

    return ScenarioSummary(
        name: name,
        runtimeDir: runtimeDir,
        launchState: observation.launchState,
        finalState: observation.finalState,
        hotKeyResponse: response,
        flowStates: observation.flowStates,
        observedText: observation.observedText,
        frontmostBundleAfterTrigger: observation.frontmostBundleAfterTrigger,
        success: failureReasons.isEmpty,
        failureReasons: failureReasons,
        notes: [
            "fake_whisper_cli=\(fakeCLIPath)",
            "gated_transcription_feedback=systemBeep"
        ]
    )
}

func runBlockedScenario(
    repoRoot: String,
    productAppPath: String,
    runtimeDir: String,
    holdDurationMs: Int
) throws -> ScenarioSummary {
    let observation = try runHotKeyScenario(
        repoRoot: repoRoot,
        productAppPath: productAppPath,
        runtimeDir: runtimeDir,
        holdDurationMs: holdDurationMs,
        whisperCLIPath: nil,
        whisperModelPath: nil,
        whisperLanguage: nil,
        transcriptionFixtureWAVPath: nil,
        forceAccessibilityBlocked: true,
        forceAccessibilityTrusted: false,
        expectedTerminalState: "blocked"
    )

    let response = observation.hotKeyResponse
    let expectedBlockedReason = "Accessibility access is required before PushWrite can insert text with synthetic Cmd+V."
    var failureReasons: [String] = []

    if response.kind != "recordAudio" {
        failureReasons.append("unexpected-kind-\(response.kind)")
    }
    if response.status != "blocked" {
        failureReasons.append("unexpected-status-\(response.status)")
    }
    if response.blockedReason != expectedBlockedReason {
        failureReasons.append("unexpected-blocked-reason")
    }
    if response.transcriptionInsertGate != nil {
        failureReasons.append("unexpected-transcription-insert-gate")
    }
    if response.gatedTranscriptionFeedback != nil {
        failureReasons.append("unexpected-gated-feedback")
    }
    if response.syntheticPastePosted {
        failureReasons.append("synthetic-paste-posted")
    }
    if observation.observedText != "" {
        failureReasons.append("unexpected-textedit-change")
    }
    if response.recordingArtifact != nil || response.transcriptionArtifact != nil {
        failureReasons.append("unexpected-artifacts")
    }
    failureReasons.append(contentsOf: missingFlowReasons(
        flowStates: observation.flowStates,
        expectedStates: ["triggered", "blocked"]
    ))
    if observation.finalState?.flow.state != "blocked" {
        failureReasons.append("unexpected-final-state")
    }

    return ScenarioSummary(
        name: "blocked_accessibility",
        runtimeDir: runtimeDir,
        launchState: observation.launchState,
        finalState: observation.finalState,
        hotKeyResponse: response,
        flowStates: observation.flowStates,
        observedText: observation.observedText,
        frontmostBundleAfterTrigger: observation.frontmostBundleAfterTrigger,
        success: failureReasons.isEmpty,
        failureReasons: failureReasons,
        notes: []
    )
}

func runInferenceFailureScenario(
    repoRoot: String,
    productAppPath: String,
    runtimeDir: String,
    holdDurationMs: Int,
    whisperCLIPath: String,
    missingModelPath: String,
    whisperLanguage: String,
    transcriptionFixtureWAVPath: String
) throws -> ScenarioSummary {
    let observation = try runHotKeyScenario(
        repoRoot: repoRoot,
        productAppPath: productAppPath,
        runtimeDir: runtimeDir,
        holdDurationMs: holdDurationMs,
        whisperCLIPath: whisperCLIPath,
        whisperModelPath: missingModelPath,
        whisperLanguage: whisperLanguage,
        transcriptionFixtureWAVPath: transcriptionFixtureWAVPath,
        forceAccessibilityBlocked: false,
        forceAccessibilityTrusted: true,
        expectedTerminalState: "error"
    )

    let response = observation.hotKeyResponse
    var failureReasons: [String] = []

    if response.kind != "recordAudio" {
        failureReasons.append("unexpected-kind-\(response.kind)")
    }
    if response.status != "failed" {
        failureReasons.append("unexpected-status-\(response.status)")
    }
    if response.transcriptionInsertGate != nil {
        failureReasons.append("unexpected-transcription-insert-gate")
    }
    if response.gatedTranscriptionFeedback != nil {
        failureReasons.append("unexpected-gated-feedback")
    }
    if response.error?.contains("whisper.cpp model is missing") != true {
        failureReasons.append("unexpected-error")
    }
    if response.transcriptionArtifact?.status != .failed {
        failureReasons.append("unexpected-transcription-status")
    }
    if observation.observedText != "" {
        failureReasons.append("unexpected-textedit-change")
    }
    failureReasons.append(contentsOf: missingFlowReasons(
        flowStates: observation.flowStates,
        expectedStates: ["triggered", "recording", "transcribing", "error"]
    ))
    if observation.finalState?.flow.state != "error" {
        failureReasons.append("unexpected-final-state")
    }

    return ScenarioSummary(
        name: "inference_failure",
        runtimeDir: runtimeDir,
        launchState: observation.launchState,
        finalState: observation.finalState,
        hotKeyResponse: response,
        flowStates: observation.flowStates,
        observedText: observation.observedText,
        frontmostBundleAfterTrigger: observation.frontmostBundleAfterTrigger,
        success: failureReasons.isEmpty,
        failureReasons: failureReasons,
        notes: []
    )
}

func main() -> Int32 {
    let repoRoot = FileManager.default.currentDirectoryPath
    var options: Options
    do {
        options = try parseOptions(arguments: Array(CommandLine.arguments.dropFirst()))
    } catch {
        fputs("\(error)\n", stderr)
        return 64
    }

    if options.successRuntimeDir.isEmpty {
        options.successRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-002k-success"
    }
    if options.gatedEmptyRuntimeDir.isEmpty {
        options.gatedEmptyRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-002k-gated-empty"
    }
    if options.gatedTooShortRuntimeDir.isEmpty {
        options.gatedTooShortRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-002k-gated-too-short"
    }
    if options.blockedRuntimeDir.isEmpty {
        options.blockedRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-002k-blocked"
    }
    if options.inferenceFailureRuntimeDir.isEmpty {
        options.inferenceFailureRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-002k-inference-failure"
    }

    let productAppURL: URL
    do {
        productAppURL = try resolveProductApp(repoRoot: repoRoot, options: options)
    } catch {
        fputs("\(error)\n", stderr)
        return 1
    }

    let whisperCLIPath = options.whisperCLIPath ?? defaultWhisperCLIPath(repoRoot: repoRoot)
    let whisperModelPath = options.whisperModelPath ?? defaultWhisperModelPath(repoRoot: repoRoot)
    let transcriptionFixtureWAVPath = options.transcriptionFixtureWAVPath ?? defaultTranscriptionFixtureWAVPath(repoRoot: repoRoot)
    let inferenceFailureModelPath = "\(repoRoot)/models/ggml-tiny-missing-002k.bin"

    guard FileManager.default.isExecutableFile(atPath: whisperCLIPath) else {
        fputs("Missing whisper-cli at \(whisperCLIPath)\n", stderr)
        return 1
    }
    guard FileManager.default.fileExists(atPath: whisperModelPath) else {
        fputs("Missing whisper model at \(whisperModelPath)\n", stderr)
        return 1
    }
    guard FileManager.default.fileExists(atPath: transcriptionFixtureWAVPath) else {
        fputs("Missing transcription fixture WAV at \(transcriptionFixtureWAVPath)\n", stderr)
        return 1
    }

    func emitSingleScenario(_ scenario: ScenarioSummary) -> Int32 {
        if let resultsFile = options.resultsFile {
            do {
                try writeSummary(scenario, to: resultsFile)
            } catch {
                fputs("Could not write results file: \(error)\n", stderr)
                return 1
            }
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(scenario)
            if let string = String(data: data, encoding: .utf8) {
                print(string)
            }
        } catch {
            fputs("Could not encode scenario summary: \(error)\n", stderr)
            return 1
        }

        return scenario.success ? 0 : 1
    }

    switch options.scenario {
    case "success":
        do {
            fputs("[002K] running success scenario\n", stderr)
            return emitSingleScenario(try runSuccessScenario(
                repoRoot: repoRoot,
                productAppPath: productAppURL.path,
                runtimeDir: options.successRuntimeDir,
                holdDurationMs: options.holdDurationMs,
                whisperCLIPath: whisperCLIPath,
                whisperModelPath: whisperModelPath,
                whisperLanguage: options.whisperLanguage,
                transcriptionFixtureWAVPath: transcriptionFixtureWAVPath
            ))
        } catch {
            fputs("Success validation failed: \(error)\n", stderr)
            return 1
        }
    case "gated_empty":
        do {
            fputs("[002K] running gated_empty scenario\n", stderr)
            return emitSingleScenario(try runGatedScenario(
                name: "gated_empty",
                repoRoot: repoRoot,
                productAppPath: productAppURL.path,
                runtimeDir: options.gatedEmptyRuntimeDir,
                holdDurationMs: options.holdDurationMs,
                whisperModelPath: whisperModelPath,
                whisperLanguage: options.whisperLanguage,
                transcriptText: "   ",
                expectedGate: .empty
            ))
        } catch {
            fputs("Empty gate validation failed: \(error)\n", stderr)
            return 1
        }
    case "gated_too_short":
        do {
            fputs("[002K] running gated_too_short scenario\n", stderr)
            return emitSingleScenario(try runGatedScenario(
                name: "gated_too_short",
                repoRoot: repoRoot,
                productAppPath: productAppURL.path,
                runtimeDir: options.gatedTooShortRuntimeDir,
                holdDurationMs: options.holdDurationMs,
                whisperModelPath: whisperModelPath,
                whisperLanguage: options.whisperLanguage,
                transcriptText: "x",
                expectedGate: .tooShort
            ))
        } catch {
            fputs("Too-short gate validation failed: \(error)\n", stderr)
            return 1
        }
    case "blocked_accessibility":
        do {
            fputs("[002K] running blocked_accessibility scenario\n", stderr)
            return emitSingleScenario(try runBlockedScenario(
                repoRoot: repoRoot,
                productAppPath: productAppURL.path,
                runtimeDir: options.blockedRuntimeDir,
                holdDurationMs: 120
            ))
        } catch {
            fputs("Blocked validation failed: \(error)\n", stderr)
            return 1
        }
    case "inference_failure":
        do {
            fputs("[002K] running inference_failure scenario\n", stderr)
            return emitSingleScenario(try runInferenceFailureScenario(
                repoRoot: repoRoot,
                productAppPath: productAppURL.path,
                runtimeDir: options.inferenceFailureRuntimeDir,
                holdDurationMs: options.holdDurationMs,
                whisperCLIPath: whisperCLIPath,
                missingModelPath: inferenceFailureModelPath,
                whisperLanguage: options.whisperLanguage,
                transcriptionFixtureWAVPath: transcriptionFixtureWAVPath
            ))
        } catch {
            fputs("Inference failure validation failed: \(error)\n", stderr)
            return 1
        }
    case "all":
        break
    default:
        fputs("Unknown scenario: \(options.scenario)\n", stderr)
        return 64
    }

    let successScenario: ScenarioSummary
    do {
        fputs("[002K] running success scenario\n", stderr)
        successScenario = try runSuccessScenario(
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.successRuntimeDir,
            holdDurationMs: options.holdDurationMs,
            whisperCLIPath: whisperCLIPath,
            whisperModelPath: whisperModelPath,
            whisperLanguage: options.whisperLanguage,
            transcriptionFixtureWAVPath: transcriptionFixtureWAVPath
        )
    } catch {
        fputs("Success validation failed: \(error)\n", stderr)
        return 1
    }

    let gatedEmptyScenario: ScenarioSummary
    do {
        fputs("[002K] running gated_empty scenario\n", stderr)
        gatedEmptyScenario = try runGatedScenario(
            name: "gated_empty",
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.gatedEmptyRuntimeDir,
            holdDurationMs: options.holdDurationMs,
            whisperModelPath: whisperModelPath,
            whisperLanguage: options.whisperLanguage,
            transcriptText: "   ",
            expectedGate: .empty
        )
    } catch {
        fputs("Empty gate validation failed: \(error)\n", stderr)
        return 1
    }

    let gatedTooShortScenario: ScenarioSummary
    do {
        fputs("[002K] running gated_too_short scenario\n", stderr)
        gatedTooShortScenario = try runGatedScenario(
            name: "gated_too_short",
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.gatedTooShortRuntimeDir,
            holdDurationMs: options.holdDurationMs,
            whisperModelPath: whisperModelPath,
            whisperLanguage: options.whisperLanguage,
            transcriptText: "x",
            expectedGate: .tooShort
        )
    } catch {
        fputs("Too-short gate validation failed: \(error)\n", stderr)
        return 1
    }

    let blockedScenario: ScenarioSummary
    do {
        fputs("[002K] running blocked_accessibility scenario\n", stderr)
        blockedScenario = try runBlockedScenario(
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.blockedRuntimeDir,
            holdDurationMs: 120
        )
    } catch {
        fputs("Blocked validation failed: \(error)\n", stderr)
        return 1
    }

    let inferenceFailureScenario: ScenarioSummary
    do {
        fputs("[002K] running inference_failure scenario\n", stderr)
        inferenceFailureScenario = try runInferenceFailureScenario(
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.inferenceFailureRuntimeDir,
            holdDurationMs: options.holdDurationMs,
            whisperCLIPath: whisperCLIPath,
            missingModelPath: inferenceFailureModelPath,
            whisperLanguage: options.whisperLanguage,
            transcriptionFixtureWAVPath: transcriptionFixtureWAVPath
        )
    } catch {
        fputs("Inference failure validation failed: \(error)\n", stderr)
        return 1
    }

    let summary = ValidationSummary(
        timestamp: isoTimestamp(),
        productAppPath: productAppURL.path,
        holdDurationMs: options.holdDurationMs,
        successRuntimeDir: options.successRuntimeDir,
        gatedEmptyRuntimeDir: options.gatedEmptyRuntimeDir,
        gatedTooShortRuntimeDir: options.gatedTooShortRuntimeDir,
        blockedRuntimeDir: options.blockedRuntimeDir,
        inferenceFailureRuntimeDir: options.inferenceFailureRuntimeDir,
        success: successScenario,
        gatedEmpty: gatedEmptyScenario,
        gatedTooShort: gatedTooShortScenario,
        blockedAccessibility: blockedScenario,
        inferenceFailure: inferenceFailureScenario
    )

    if let resultsFile = options.resultsFile {
        do {
            try writeSummary(summary, to: resultsFile)
        } catch {
            fputs("Could not write results file: \(error)\n", stderr)
            return 1
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
        return 1
    }

    let failures = [
        successScenario.success,
        gatedEmptyScenario.success,
        gatedTooShortScenario.success,
        blockedScenario.success,
        inferenceFailureScenario.success
    ]

    return failures.allSatisfy { $0 } ? 0 : 1
}

exit(main())
