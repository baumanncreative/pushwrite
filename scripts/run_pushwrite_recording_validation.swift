#!/usr/bin/env swift

import AppKit
import Foundation

struct Options {
    var productOutputDir = ""
    var productAppPath: String?
    var successRuntimeDir = ""
    var blockedRuntimeDir = ""
    var deniedRuntimeDir = ""
    var noMicrophoneRuntimeDir = ""
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

enum TranscriptionStatus: String, Codable {
    case succeeded
    case failed
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
    let frontmostBundleAfterTrigger: String?
    let artifactFileExists: Bool
    let artifactMetadataExists: Bool
    let success: Bool
    let skipped: Bool
    let skipReason: String?
    let failureReasons: [String]
    let notes: [String]
}

struct PromptValidationSummary: Codable {
    let launchMicrophonePermissionStatus: MicrophonePermissionStatus
    let launchCreatedRecordingArtifacts: Bool
    let launchCreatedHotKeyResponse: Bool
    let firstPromptObservedInThisRun: Bool
    let notes: [String]
}

struct ValidationSummary: Codable {
    let timestamp: String
    let productAppPath: String
    let successRuntimeDir: String
    let blockedRuntimeDir: String
    let deniedRuntimeDir: String
    let noMicrophoneRuntimeDir: String
    let inferenceFailureRuntimeDir: String
    let holdDurationMs: Int
    let promptValidation: PromptValidationSummary
    let success: ScenarioSummary
    let inferenceFailure: ScenarioSummary
    let blockedAccessibility: ScenarioSummary
    let microphoneDenied: ScenarioSummary
    let noMicrophone: ScenarioSummary
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
        case "--product-output-dir":
            options.productOutputDir = try requireValue(for: argument)
        case "--product-app-path":
            options.productAppPath = try requireValue(for: argument)
        case "--success-runtime-dir":
            options.successRuntimeDir = try requireValue(for: argument)
        case "--blocked-runtime-dir":
            options.blockedRuntimeDir = try requireValue(for: argument)
        case "--denied-runtime-dir":
            options.deniedRuntimeDir = try requireValue(for: argument)
        case "--no-microphone-runtime-dir":
            options.noMicrophoneRuntimeDir = try requireValue(for: argument)
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
    forceAccessibilityTrusted: Bool,
    forceMicrophoneDenied: Bool,
    forceNoMicrophoneDevice: Bool
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
    if forceMicrophoneDenied {
        arguments.append("--force-microphone-denied")
    }
    if forceNoMicrophoneDevice {
        arguments.append("--force-no-microphone-device")
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

func frontmostBundleID() -> String? {
    NSWorkspace.shared.frontmostApplication?.bundleIdentifier
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

func launchArtifactExists(runtimeDir: String) -> Bool {
    let recordingDir = "\(runtimeDir)/recordings"
    guard let entries = try? FileManager.default.contentsOfDirectory(atPath: recordingDir) else {
        return false
    }
    return !entries.isEmpty
}

func runScenario(
    name: String,
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
    forceMicrophoneDenied: Bool,
    forceNoMicrophoneDevice: Bool,
    expectedTerminalState: String,
    expectedStatus: String,
    expectedBlockedReason: String? = nil,
    expectedErrorContains: String? = nil,
    expectedTranscriptionStatus: TranscriptionStatus? = nil,
    expectedTranscriptionErrorContains: String? = nil,
    expectRecordingArtifact: Bool,
    expectNonEmptyTranscriptText: Bool = false
) throws -> ScenarioSummary {
    try? FileManager.default.removeItem(atPath: runtimeDir)

    let launchState = try launchProduct(
        productAppPath: productAppPath,
        runtimeDir: runtimeDir,
        whisperCLIPath: whisperCLIPath,
        whisperModelPath: whisperModelPath,
        whisperLanguage: whisperLanguage,
        transcriptionFixtureWAVPath: transcriptionFixtureWAVPath,
        forceAccessibilityBlocked: forceAccessibilityBlocked,
        forceAccessibilityTrusted: forceAccessibilityTrusted,
        forceMicrophoneDenied: forceMicrophoneDenied,
        forceNoMicrophoneDevice: forceNoMicrophoneDevice
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
    let finalState = try? readState(runtimeDir: runtimeDir)

    let artifactFileExists = hotKeyResponse.recordingArtifact.map { FileManager.default.fileExists(atPath: $0.filePath) } ?? false
    let artifactMetadataExists = hotKeyResponse.recordingArtifact.map { FileManager.default.fileExists(atPath: $0.metadataPath) } ?? false
    let transcriptionArtifactFileExists = hotKeyResponse.transcriptionArtifact.map {
        FileManager.default.fileExists(atPath: $0.artifactPath)
    } ?? false
    let transcriptionTextFileExists = hotKeyResponse.transcriptionArtifact.map {
        FileManager.default.fileExists(atPath: $0.textFilePath)
    } ?? false
    let transcriptionRawJSONFileExists = hotKeyResponse.transcriptionArtifact.map {
        FileManager.default.fileExists(atPath: $0.rawOutputJSONPath)
    } ?? false
    let frontmostAfterTrigger = frontmostBundleID()

    var failureReasons: [String] = []
    if hotKeyResponse.kind != "recordAudio" {
        failureReasons.append("unexpected-kind-\(hotKeyResponse.kind)")
    }
    if hotKeyResponse.status != expectedStatus {
        failureReasons.append("unexpected-status-\(hotKeyResponse.status)")
    }
    if let expectedBlockedReason, hotKeyResponse.blockedReason != expectedBlockedReason {
        failureReasons.append("unexpected-blocked-reason")
    }
    if let expectedErrorContains {
        if hotKeyResponse.error?.contains(expectedErrorContains) != true {
            failureReasons.append("unexpected-error")
        }
    } else if hotKeyResponse.error != nil {
        failureReasons.append("unexpected-error-present")
    }
    if let expectedTranscriptionStatus, hotKeyResponse.transcriptionArtifact?.status != expectedTranscriptionStatus {
        failureReasons.append("unexpected-transcription-status")
    }
    if let expectedTranscriptionErrorContains {
        if hotKeyResponse.transcriptionArtifact?.error?.contains(expectedTranscriptionErrorContains) != true {
            failureReasons.append("unexpected-transcription-error")
        }
    }
    if expectRecordingArtifact {
        if hotKeyResponse.microphonePermissionStatus != .granted {
            failureReasons.append("microphone-permission-not-granted")
        }
        if hotKeyResponse.hotKeyInteractionModel != "pressAndHold" {
            failureReasons.append("unexpected-hotkey-interaction-model")
        }
        if hotKeyResponse.recordingArtifact == nil {
            failureReasons.append("missing-recording-artifact")
        }
        if !artifactFileExists {
            failureReasons.append("missing-recording-file")
        }
        if !artifactMetadataExists {
            failureReasons.append("missing-recording-metadata")
        }
        if hotKeyResponse.recordingArtifact?.durationMs ?? 0 <= 0 {
            failureReasons.append("non-positive-recording-duration")
        }
        if hotKeyResponse.transcribingPlaceholder {
            failureReasons.append("unexpected-transcribing-placeholder")
        }
        if hotKeyResponse.syntheticPastePosted {
            failureReasons.append("synthetic-paste-posted-during-recording-stage")
        }
        if let expectedTranscriptionStatus {
            if hotKeyResponse.transcriptionArtifact == nil {
                failureReasons.append("missing-transcription-artifact")
            }
            if !transcriptionArtifactFileExists {
                failureReasons.append("missing-transcription-artifact-file")
            }
            if expectedTranscriptionStatus == .succeeded {
                if !transcriptionTextFileExists {
                    failureReasons.append("missing-transcription-text-file")
                }
                if !transcriptionRawJSONFileExists {
                    failureReasons.append("missing-transcription-raw-json")
                }
            }
            if expectNonEmptyTranscriptText, (hotKeyResponse.transcriptionArtifact?.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false) {
                failureReasons.append("empty-transcription-text")
            }
        } else if hotKeyResponse.transcriptionArtifact != nil {
            failureReasons.append("unexpected-transcription-artifact")
        }
        failureReasons.append(contentsOf: missingFlowReasons(
            flowStates: flowStates,
            expectedStates: ["triggered", "recording", "transcribing", expectedTerminalState]
        ))
        if finalState?.activeRecordingID != nil {
            failureReasons.append("active-recording-left-open")
        }
        if finalState?.lastRecording?.id != hotKeyResponse.id {
            failureReasons.append("state-last-recording-mismatch")
        }
        if let expectedTranscriptionStatus {
            if finalState?.lastTranscription?.id != hotKeyResponse.id {
                failureReasons.append("state-last-transcription-mismatch")
            }
            if finalState?.lastTranscription?.status != expectedTranscriptionStatus {
                failureReasons.append("state-last-transcription-status-mismatch")
            }
        }
    } else {
        if hotKeyResponse.recordingArtifact != nil {
            failureReasons.append("unexpected-recording-artifact")
        }
        if artifactFileExists || artifactMetadataExists {
            failureReasons.append("unexpected-recording-files")
        }
        if hotKeyResponse.transcriptionArtifact != nil {
            failureReasons.append("unexpected-transcription-artifact")
        }
        failureReasons.append(contentsOf: missingFlowReasons(
            flowStates: flowStates,
            expectedStates: ["triggered", expectedTerminalState]
        ))
    }

    if let finalState, finalState.flow.state != expectedTerminalState {
        failureReasons.append("unexpected-final-state-\(finalState.flow.state)")
    }

    return ScenarioSummary(
        name: name,
        runtimeDir: runtimeDir,
        launchState: launchState,
        finalState: finalState,
        hotKeyResponse: hotKeyResponse,
        flowStates: flowStates,
        frontmostBundleAfterTrigger: frontmostAfterTrigger,
        artifactFileExists: artifactFileExists,
        artifactMetadataExists: artifactMetadataExists,
        success: failureReasons.isEmpty,
        skipped: false,
        skipReason: nil,
        failureReasons: failureReasons,
        notes: []
    )
}

func skippedScenario(name: String, runtimeDir: String, launchState: ProductState, reason: String) -> ScenarioSummary {
    ScenarioSummary(
        name: name,
        runtimeDir: runtimeDir,
        launchState: launchState,
        finalState: nil,
        hotKeyResponse: nil,
        flowStates: [],
        frontmostBundleAfterTrigger: nil,
        artifactFileExists: false,
        artifactMetadataExists: false,
        success: false,
        skipped: true,
        skipReason: reason,
        failureReasons: [],
        notes: [reason]
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
        options.successRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-002j-transcription-success"
    }
    if options.blockedRuntimeDir.isEmpty {
        options.blockedRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-002j-transcription-blocked"
    }
    if options.deniedRuntimeDir.isEmpty {
        options.deniedRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-002j-transcription-denied"
    }
    if options.noMicrophoneRuntimeDir.isEmpty {
        options.noMicrophoneRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-002j-transcription-no-mic"
    }
    if options.inferenceFailureRuntimeDir.isEmpty {
        options.inferenceFailureRuntimeDir = "\(repoRoot)/build/pushwrite-product/runtime-002j-transcription-inference-failure"
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
    let inferenceFailureModelPath = "\(repoRoot)/models/ggml-tiny-missing-002j.bin"

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

    let accessibilityBlockedReason = "Accessibility access is required before PushWrite can insert text with synthetic Cmd+V."
    let microphoneDeniedReason = "Microphone access is required before PushWrite can start recording."
    let noMicrophoneReason = "No audio input device is available for PushWrite recording."

    let promptLaunchState: ProductState
    do {
        try? FileManager.default.removeItem(atPath: options.successRuntimeDir)
        promptLaunchState = try launchProduct(
            productAppPath: productAppURL.path,
            runtimeDir: options.successRuntimeDir,
            whisperCLIPath: whisperCLIPath,
            whisperModelPath: whisperModelPath,
            whisperLanguage: options.whisperLanguage,
            transcriptionFixtureWAVPath: nil,
            forceAccessibilityBlocked: false,
            forceAccessibilityTrusted: true,
            forceMicrophoneDenied: false,
            forceNoMicrophoneDevice: false
        )
    } catch {
        fputs("Prompt baseline launch failed: \(error)\n", stderr)
        return 1
    }

    let promptValidation = PromptValidationSummary(
        launchMicrophonePermissionStatus: promptLaunchState.microphonePermissionStatus,
        launchCreatedRecordingArtifacts: launchArtifactExists(runtimeDir: options.successRuntimeDir),
        launchCreatedHotKeyResponse: (try? readLastHotKeyResponse(runtimeDir: options.successRuntimeDir)) != nil,
        firstPromptObservedInThisRun: false,
        notes: promptLaunchState.microphonePermissionStatus == .granted
            ? [
                "The workstation already had microphone permission granted for PushWrite before 002J validation.",
                "No TCC reset was performed, so the OS first-prompt could not be re-observed in this run.",
                "Launch created neither recording artifacts nor a hotkey response before the first hotkey press."
            ]
            : [
                "Launch created neither recording artifacts nor a hotkey response before the first hotkey press.",
                "A real first-prompt was not re-driven in this run."
            ]
    )

    stopProduct(repoRoot: repoRoot, productAppPath: productAppURL.path, runtimeDir: options.successRuntimeDir)

    let successScenario: ScenarioSummary
    do {
        successScenario = try runScenario(
            name: "success",
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.successRuntimeDir,
            holdDurationMs: options.holdDurationMs,
            whisperCLIPath: whisperCLIPath,
            whisperModelPath: whisperModelPath,
            whisperLanguage: options.whisperLanguage,
            transcriptionFixtureWAVPath: transcriptionFixtureWAVPath,
            forceAccessibilityBlocked: false,
            forceAccessibilityTrusted: true,
            forceMicrophoneDenied: false,
            forceNoMicrophoneDevice: false,
            expectedTerminalState: "done",
            expectedStatus: "succeeded",
            expectedTranscriptionStatus: .succeeded,
            expectRecordingArtifact: true,
            expectNonEmptyTranscriptText: true
        )
    } catch {
        fputs("Success recording validation failed: \(error)\n", stderr)
        return 1
    }

    let inferenceFailureScenario: ScenarioSummary
    do {
        inferenceFailureScenario = try runScenario(
            name: "inference_failure",
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.inferenceFailureRuntimeDir,
            holdDurationMs: options.holdDurationMs,
            whisperCLIPath: whisperCLIPath,
            whisperModelPath: inferenceFailureModelPath,
            whisperLanguage: options.whisperLanguage,
            transcriptionFixtureWAVPath: transcriptionFixtureWAVPath,
            forceAccessibilityBlocked: false,
            forceAccessibilityTrusted: true,
            forceMicrophoneDenied: false,
            forceNoMicrophoneDevice: false,
            expectedTerminalState: "error",
            expectedStatus: "failed",
            expectedErrorContains: "whisper.cpp model is missing",
            expectedTranscriptionStatus: .failed,
            expectedTranscriptionErrorContains: "whisper.cpp model is missing",
            expectRecordingArtifact: true
        )
    } catch {
        fputs("Inference failure validation failed: \(error)\n", stderr)
        return 1
    }

    let blockedScenario: ScenarioSummary
    do {
        blockedScenario = try runScenario(
            name: "blocked_accessibility",
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.blockedRuntimeDir,
            holdDurationMs: 120,
            whisperCLIPath: whisperCLIPath,
            whisperModelPath: whisperModelPath,
            whisperLanguage: options.whisperLanguage,
            transcriptionFixtureWAVPath: nil,
            forceAccessibilityBlocked: true,
            forceAccessibilityTrusted: false,
            forceMicrophoneDenied: false,
            forceNoMicrophoneDevice: false,
            expectedTerminalState: "blocked",
            expectedStatus: "blocked",
            expectedBlockedReason: accessibilityBlockedReason,
            expectRecordingArtifact: false
        )
    } catch {
        fputs("Accessibility blocked validation failed: \(error)\n", stderr)
        return 1
    }

    let deniedScenario: ScenarioSummary
    do {
        deniedScenario = try runScenario(
            name: "microphone_denied",
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.deniedRuntimeDir,
            holdDurationMs: 120,
            whisperCLIPath: whisperCLIPath,
            whisperModelPath: whisperModelPath,
            whisperLanguage: options.whisperLanguage,
            transcriptionFixtureWAVPath: nil,
            forceAccessibilityBlocked: false,
            forceAccessibilityTrusted: true,
            forceMicrophoneDenied: true,
            forceNoMicrophoneDevice: false,
            expectedTerminalState: "blocked",
            expectedStatus: "blocked",
            expectedBlockedReason: microphoneDeniedReason,
            expectRecordingArtifact: false
        )
    } catch {
        fputs("Microphone denied validation failed: \(error)\n", stderr)
        return 1
    }

    let noMicrophoneScenario: ScenarioSummary
    do {
        noMicrophoneScenario = try runScenario(
            name: "no_microphone",
            repoRoot: repoRoot,
            productAppPath: productAppURL.path,
            runtimeDir: options.noMicrophoneRuntimeDir,
            holdDurationMs: 120,
            whisperCLIPath: whisperCLIPath,
            whisperModelPath: whisperModelPath,
            whisperLanguage: options.whisperLanguage,
            transcriptionFixtureWAVPath: nil,
            forceAccessibilityBlocked: false,
            forceAccessibilityTrusted: true,
            forceMicrophoneDenied: false,
            forceNoMicrophoneDevice: true,
            expectedTerminalState: "error",
            expectedStatus: "failed",
            expectedErrorContains: noMicrophoneReason,
            expectRecordingArtifact: false
        )
    } catch {
        fputs("No-microphone validation failed: \(error)\n", stderr)
        return 1
    }

    let summary = ValidationSummary(
        timestamp: isoTimestamp(),
        productAppPath: productAppURL.path,
        successRuntimeDir: options.successRuntimeDir,
        blockedRuntimeDir: options.blockedRuntimeDir,
        deniedRuntimeDir: options.deniedRuntimeDir,
        noMicrophoneRuntimeDir: options.noMicrophoneRuntimeDir,
        inferenceFailureRuntimeDir: options.inferenceFailureRuntimeDir,
        holdDurationMs: options.holdDurationMs,
        promptValidation: promptValidation,
        success: successScenario,
        inferenceFailure: inferenceFailureScenario,
        blockedAccessibility: blockedScenario,
        microphoneDenied: deniedScenario,
        noMicrophone: noMicrophoneScenario
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

    return 0
}

exit(main())
