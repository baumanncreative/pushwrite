import AppKit
import ApplicationServices
import AVFoundation
import Carbon
import Foundation

enum ProductRequestKind: String, Codable {
    case preflight
    case insert
    case insertTranscription
    case recordAudio
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
    case recording
    case processing
    case transcribing
    case inserting
    case done
    case error
}

enum FlowTriggerSource: String, Codable {
    case globalHotKey
}

enum MicrophonePermissionStatus: String, Codable {
    case notDetermined
    case granted
    case denied
    case restricted
}

enum HotKeyInteractionModel: String, Codable {
    case pressAndHold
}

enum LocalUserFeedback: String, Codable {
    case systemBeep
    case blockedPanel
}

enum HotKeyTerminalFeedbackCase: String, Codable {
    case tooShortRecording
    case transcriptionFailed
    case noUsableText
    case insertFailed
}

var runtimeAccessibilityBlockedOverride = false
var runtimeAccessibilityTrustedOverride = false
var runtimeMicrophoneDeniedOverride = false
var runtimeNoMicrophoneDeviceOverride = false
var runtimeMicrophoneRecorderStartFailureOverride = false
var runtimeSyntheticPasteFailureOverride = false
var runtimeForcedMicrophonePermissionStatus: MicrophonePermissionStatus?
var runtimeForcedMicrophonePermissionRequestResult: MicrophonePermissionStatus?
var runtimeCurrentMicrophonePermissionStatusOverride: MicrophonePermissionStatus?

struct LaunchOptions {
    let runtimeDir: String
    let simulatedTranscriptionText: String
    let whisperCLIPath: String?
    let whisperModelPath: String?
    let whisperLanguage: String
    let transcriptionFixtureWAVPath: String?
    let forceAccessibilityBlocked: Bool
    let forceAccessibilityTrusted: Bool
    let forceMicrophoneDenied: Bool
    let forceNoMicrophoneDevice: Bool
    let forceMicrophoneRecorderStartFailure: Bool
    let forceSyntheticPasteFailure: Bool
    let forcedMicrophonePermissionStatus: MicrophonePermissionStatus?
    let forcedMicrophonePermissionRequestResult: MicrophonePermissionStatus?
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
    let transcriptionInsertGate: TranscriptionInsertGate?
    let gatedTranscriptionFeedback: GatedTranscriptionFeedback?
    let blockedReason: String?
    let error: String?
    let recordingDurationMs: Int?
    let recordingFilePath: String?
    let microphonePermissionStatus: MicrophonePermissionStatus?
    let requestedMicrophonePermission: Bool
    let localUserFeedback: LocalUserFeedback?
}

struct ProductFlowEvent: Codable {
    let id: String
    let state: ProductFlowState
    let trigger: FlowTriggerSource
    let timestamp: String
    let textLength: Int
    let transcriptionInsertGate: TranscriptionInsertGate?
    let gatedTranscriptionFeedback: GatedTranscriptionFeedback?
    let blockedReason: String?
    let error: String?
    let recordingDurationMs: Int?
    let recordingFilePath: String?
    let microphonePermissionStatus: MicrophonePermissionStatus?
    let requestedMicrophonePermission: Bool
    let localUserFeedback: LocalUserFeedback?
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

enum RecordingUsability: String, Codable {
    case usable
    case empty
    case tooShort
}

struct AudioProcessingHandoff: Codable {
    let id: String
    let recordingArtifact: RecordingArtifact
    let usability: RecordingUsability
    let heuristic: String
    let startedAt: String
}

struct HotKeyRecordingLogEvent: Codable {
    let timestamp: String
    let flowID: String?
    let event: String
    let state: ProductFlowState?
    let detail: String?
}

enum TranscriptionStatus: String, Codable {
    case succeeded
    case failed
}

enum TranscriptionResultStatus: String, Codable {
    case succeeded
    case failed
    case skipped
}

enum TranscriptionSkipReason: String, Codable {
    case emptyRecording
    case tooShortRecording
}

enum TranscriptionInsertGate: String, Codable {
    case passed
    case transcriptionSkipped
    case transcriptionFailed
    case emptyTranscriptionText
    case whitespaceOnlyTranscriptionText
    case empty
    case tooShort
}

enum InsertResultStatus: String, Codable {
    case gated
    case succeeded
    case failed
}

struct InsertResult: Codable {
    let id: String
    let flowID: String
    let transcriptionResultID: String
    let transcriptionResultStatus: TranscriptionResultStatus
    let transcriptionAttempted: Bool
    let transcriptionTextLength: Int
    let insertAttempted: Bool
    let status: InsertResultStatus
    let gate: TranscriptionInsertGate
    let gateReason: String?
    let error: String?
    let insertedTextLength: Int
    let insertRoute: InsertRoute?
    let insertSource: InsertSource
    let startedAt: String
    let completedAt: String
    let durationMs: Int
}

enum TranscriptionInsertGateEvaluation {
    case passed(text: String)
    case gated(reason: TranscriptionInsertGate)
}

func evaluateTranscriptionInsertGate(for result: TranscriptionResult) -> TranscriptionInsertGateEvaluation {
    guard result.status == .succeeded else {
        return result.status == .skipped
            ? .gated(reason: .transcriptionSkipped)
            : .gated(reason: .transcriptionFailed)
    }
    guard result.transcriptionAttempted else {
        return .gated(reason: .transcriptionSkipped)
    }
    guard let text = result.text else {
        return .gated(reason: .emptyTranscriptionText)
    }
    guard !text.isEmpty else {
        return .gated(reason: .emptyTranscriptionText)
    }
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return .gated(reason: .whitespaceOnlyTranscriptionText)
    }
    return .passed(text: text)
}

enum GatedTranscriptionFeedback: String, Codable {
    case systemBeep
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

struct TranscriptionResult: Codable {
    let id: String
    let recordingID: String
    let recordingFilePath: String
    let recordingUsability: RecordingUsability
    let transcriptionAttempted: Bool
    let succeeded: Bool
    let status: TranscriptionResultStatus
    let text: String?
    let textLength: Int
    let skipReason: TranscriptionSkipReason?
    let error: String?
    let startedAt: String
    let completedAt: String
    let durationMs: Int
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
    let hotKeyInteractionModel: HotKeyInteractionModel?
    let insertRoute: InsertRoute?
    let insertSource: InsertSource?
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
    let localUserFeedback: LocalUserFeedback?
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
    let lastTranscriptionInsertGate: TranscriptionInsertGate?
    let lastGatedTranscriptionFeedback: GatedTranscriptionFeedback?
    let lastRequestedMicrophonePermission: Bool?
    let lastLocalUserFeedback: LocalUserFeedback?
    let lastBlockedReason: String?
    let lastError: String?
    let microphonePermissionStatus: MicrophonePermissionStatus
    let hotKeyInteractionModel: HotKeyInteractionModel
    let activeRecordingID: String?
    let lastRecording: RecordingArtifact?
    let lastTranscription: TranscriptionArtifact?
    let hotKey: HotKeyStateSnapshot
    let flow: ProductFlowSnapshot
}

struct ProductPaths {
    let runtimeDir: String
    let requestsDir: String
    let responsesDir: String
    let logsDir: String
    let recordingsDir: String
    let stateFile: String
    let eventsLogFile: String
    let flowEventsLogFile: String
    let hotKeyResponsesLogFile: String
    let lastHotKeyResponseFile: String
    let recordingPrototypeLogFile: String
    let audioProcessingHandoffLogFile: String
    let lastAudioProcessingHandoffFile: String
    let transcriptionResultsLogFile: String
    let lastTranscriptionResultFile: String
    let insertResultsLogFile: String
    let lastInsertResultFile: String

    init(runtimeDir: String) {
        self.runtimeDir = runtimeDir
        self.requestsDir = "\(runtimeDir)/requests"
        self.responsesDir = "\(runtimeDir)/responses"
        self.logsDir = "\(runtimeDir)/logs"
        self.recordingsDir = "\(runtimeDir)/recordings"
        self.stateFile = "\(runtimeDir)/product-state.json"
        self.eventsLogFile = "\(runtimeDir)/logs/events.jsonl"
        self.flowEventsLogFile = "\(runtimeDir)/logs/flow-events.jsonl"
        self.hotKeyResponsesLogFile = "\(runtimeDir)/logs/hotkey-responses.jsonl"
        self.lastHotKeyResponseFile = "\(runtimeDir)/logs/last-hotkey-response.json"
        self.recordingPrototypeLogFile = "\(runtimeDir)/logs/hotkey-recording-prototype.jsonl"
        self.audioProcessingHandoffLogFile = "\(runtimeDir)/logs/audio-processing-handoffs.jsonl"
        self.lastAudioProcessingHandoffFile = "\(runtimeDir)/logs/last-audio-processing-handoff.json"
        self.transcriptionResultsLogFile = "\(runtimeDir)/logs/transcription-results.jsonl"
        self.lastTranscriptionResultFile = "\(runtimeDir)/logs/last-transcription-result.json"
        self.insertResultsLogFile = "\(runtimeDir)/logs/insert-results.jsonl"
        self.lastInsertResultFile = "\(runtimeDir)/logs/last-insert-result.json"
    }

    func requestFile(for id: String) -> String {
        "\(requestsDir)/\(id).json"
    }

    func responseFile(for id: String) -> String {
        "\(responsesDir)/\(id).json"
    }

    func recordingAudioFile(for id: String) -> String {
        "\(recordingsDir)/\(id).wav"
    }

    func recordingMetadataFile(for id: String) -> String {
        "\(recordingsDir)/\(id).json"
    }

    func transcriptionOutputBase(for id: String) -> String {
        "\(recordingsDir)/\(id).transcription"
    }

    func transcriptionTextFile(for id: String) -> String {
        "\(transcriptionOutputBase(for: id)).txt"
    }

    func transcriptionRawJSONFile(for id: String) -> String {
        "\(transcriptionOutputBase(for: id)).json"
    }

    func transcriptionArtifactFile(for id: String) -> String {
        "\(transcriptionOutputBase(for: id)).artifact.json"
    }
}

enum ProductRuntimeError: Error, CustomStringConvertible {
    case missingValue(flag: String)
    case unknownArgument(String)
    case invalidRequestFile(String)
    case invalidRequest(String)
    case accessibilityDenied
    case noMicrophoneDevice
    case microphoneRecorderCreationFailed(String)
    case microphoneRecordingStartFailed
    case eventSourceUnavailable
    case eventCreationFailed
    case missingWhisperCLI(String)
    case missingWhisperModel(String)
    case missingTranscriptionFixture(String)
    case failedToInspectRecording(String)
    case failedToReplaceRecordingArtifact(String)
    case transcriptionLaunchFailed(String)
    case transcriptionProcessFailed(String)
    case missingTranscriptionOutput(String)
    case emptyTranscriptionOutput
    case forcedSyntheticPasteFailure

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
        case .noMicrophoneDevice:
            return "No audio input device is available for PushWrite recording."
        case let .microphoneRecorderCreationFailed(message):
            return "PushWrite could not create a microphone recorder: \(message)"
        case .microphoneRecordingStartFailed:
            return "PushWrite could not start microphone recording."
        case .eventSourceUnavailable:
            return "Could not create a CGEventSource for keyboard events."
        case .eventCreationFailed:
            return "Could not create one or more keyboard events for Cmd+V."
        case let .missingWhisperCLI(path):
            return "whisper.cpp CLI is missing at \(path)."
        case let .missingWhisperModel(path):
            return "whisper.cpp model is missing at \(path)."
        case let .missingTranscriptionFixture(path):
            return "Transcription fixture WAV is missing at \(path)."
        case let .failedToInspectRecording(message):
            return "PushWrite could not inspect the recording artifact: \(message)"
        case let .failedToReplaceRecordingArtifact(message):
            return "PushWrite could not prepare the recording artifact for transcription: \(message)"
        case let .transcriptionLaunchFailed(message):
            return "PushWrite could not start whisper.cpp inference: \(message)"
        case let .transcriptionProcessFailed(message):
            return "whisper.cpp inference failed: \(message)"
        case let .missingTranscriptionOutput(path):
            return "whisper.cpp did not produce the expected transcription output at \(path)."
        case .emptyTranscriptionOutput:
            return "whisper.cpp returned an empty transcription result."
        case .forcedSyntheticPasteFailure:
            return "Synthetic Cmd+V paste was forced to fail for runtime validation."
        }
    }
}

final class ActiveRecordingSession {
    let flowID: String
    let fileURL: URL
    let metadataURL: URL
    let startedAt: Date
    let startedAtTimestamp: String
    let focusAtStart: FocusSnapshot?
    let recorder: AVAudioRecorder
    let requestedMicrophonePermission: Bool

    init(
        flowID: String,
        fileURL: URL,
        metadataURL: URL,
        startedAt: Date,
        startedAtTimestamp: String,
        focusAtStart: FocusSnapshot?,
        recorder: AVAudioRecorder,
        requestedMicrophonePermission: Bool
    ) {
        self.flowID = flowID
        self.fileURL = fileURL
        self.metadataURL = metadataURL
        self.startedAt = startedAt
        self.startedAtTimestamp = startedAtTimestamp
        self.focusAtStart = focusAtStart
        self.recorder = recorder
        self.requestedMicrophonePermission = requestedMicrophonePermission
    }
}

func parseLaunchOptions(arguments: [String]) throws -> LaunchOptions {
    var runtimeDir = ProcessInfo.processInfo.environment["PUSHWRITE_PRODUCT_RUNTIME_DIR"] ?? ""
    var simulatedTranscriptionText = defaultSimulatedTranscriptionText()
    var whisperCLIPath = ProcessInfo.processInfo.environment["PUSHWRITE_WHISPER_CLI_PATH"]
    var whisperModelPath = ProcessInfo.processInfo.environment["PUSHWRITE_WHISPER_MODEL_PATH"]
    var whisperLanguage = ProcessInfo.processInfo.environment["PUSHWRITE_WHISPER_LANGUAGE"] ?? "auto"
    var transcriptionFixtureWAVPath = ProcessInfo.processInfo.environment["PUSHWRITE_TRANSCRIPTION_FIXTURE_WAV"]
    var forceAccessibilityBlocked = accessibilityBlockedOverrideEnabled()
    var forceAccessibilityTrusted = ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_ACCESSIBILITY_TRUSTED"] == "1"
    var forceMicrophoneDenied = ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_MICROPHONE_DENIED"] == "1"
    var forceNoMicrophoneDevice = ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_NO_MICROPHONE_DEVICE"] == "1"
    var forceMicrophoneRecorderStartFailure =
        ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_MICROPHONE_RECORDER_START_FAILURE"] == "1"
    var forceSyntheticPasteFailure =
        ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_SYNTHETIC_PASTE_FAILURE"] == "1"
    var forcedMicrophonePermissionStatus = parseMicrophonePermissionStatusOverride(
        ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_MICROPHONE_PERMISSION_STATUS"]
    )
    var forcedMicrophonePermissionRequestResult = parseMicrophonePermissionStatusOverride(
        ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_MICROPHONE_REQUEST_RESULT"]
    )
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
        case "--whisper-cli-path":
            whisperCLIPath = try requireValue(for: argument)
        case "--whisper-model-path":
            whisperModelPath = try requireValue(for: argument)
        case "--whisper-language":
            whisperLanguage = try requireValue(for: argument)
        case "--transcription-fixture-wav":
            transcriptionFixtureWAVPath = try requireValue(for: argument)
        case "--force-accessibility-blocked":
            forceAccessibilityBlocked = true
        case "--force-accessibility-trusted":
            forceAccessibilityTrusted = true
        case "--force-microphone-denied":
            forceMicrophoneDenied = true
        case "--force-no-microphone-device":
            forceNoMicrophoneDevice = true
        case "--force-microphone-recorder-start-failure":
            forceMicrophoneRecorderStartFailure = true
        case "--force-synthetic-paste-failure":
            forceSyntheticPasteFailure = true
        case "--force-microphone-permission-status":
            forcedMicrophonePermissionStatus = try requireMicrophonePermissionStatus(
                parseMicrophonePermissionStatusOverride(try requireValue(for: argument)),
                flag: argument
            )
        case "--force-microphone-request-result":
            forcedMicrophonePermissionRequestResult = try requireMicrophonePermissionStatus(
                parseMicrophonePermissionStatusOverride(try requireValue(for: argument)),
                flag: argument
            )
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
        whisperCLIPath: whisperCLIPath,
        whisperModelPath: whisperModelPath,
        whisperLanguage: whisperLanguage,
        transcriptionFixtureWAVPath: transcriptionFixtureWAVPath,
        forceAccessibilityBlocked: forceAccessibilityBlocked,
        forceAccessibilityTrusted: forceAccessibilityTrusted,
        forceMicrophoneDenied: forceMicrophoneDenied,
        forceNoMicrophoneDevice: forceNoMicrophoneDevice,
        forceMicrophoneRecorderStartFailure: forceMicrophoneRecorderStartFailure,
        forceSyntheticPasteFailure: forceSyntheticPasteFailure,
        forcedMicrophonePermissionStatus: forcedMicrophonePermissionStatus,
        forcedMicrophonePermissionRequestResult: forcedMicrophonePermissionRequestResult
    )
}

func parseMicrophonePermissionStatusOverride(_ value: String?) -> MicrophonePermissionStatus? {
    guard let value else {
        return nil
    }

    switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "notdetermined", "not_determined", "not-determined":
        return .notDetermined
    case "granted", "authorized", "authorised":
        return .granted
    case "denied":
        return .denied
    case "restricted":
        return .restricted
    default:
        return nil
    }
}

func requireMicrophonePermissionStatus(
    _ status: MicrophonePermissionStatus?,
    flag: String
) throws -> MicrophonePermissionStatus {
    guard let status else {
        throw ProductRuntimeError.invalidRequest(
            "\(flag) requires one of: notDetermined, granted, denied, restricted."
        )
    }
    return status
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

struct RecordingFileDetails {
    let format: String
    let sampleRateHz: Double
    let channelCount: Int
    let durationMs: Int
    let fileSizeBytes: UInt64
}

func defaultWhisperCLIPath() -> String {
    Bundle.main.bundleURL
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("build", isDirectory: true)
        .appendingPathComponent("whispercpp", isDirectory: true)
        .appendingPathComponent("build", isDirectory: true)
        .appendingPathComponent("bin", isDirectory: true)
        .appendingPathComponent("whisper-cli", isDirectory: false)
        .path
}

func defaultWhisperModelPath() -> String {
    Bundle.main.bundleURL
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("models", isDirectory: true)
        .appendingPathComponent("ggml-tiny.bin", isDirectory: false)
        .path
}

func resolveWhisperCLIPath(launchOptions: LaunchOptions) throws -> String {
    let explicitPath = launchOptions.whisperCLIPath?.trimmingCharacters(in: .whitespacesAndNewlines)
    let path = (explicitPath?.isEmpty == false ? explicitPath : defaultWhisperCLIPath()) ?? defaultWhisperCLIPath()
    guard FileManager.default.isExecutableFile(atPath: path) else {
        throw ProductRuntimeError.missingWhisperCLI(path)
    }
    return path
}

func resolveWhisperModelPath(launchOptions: LaunchOptions) throws -> String {
    let explicitPath = launchOptions.whisperModelPath?.trimmingCharacters(in: .whitespacesAndNewlines)
    let path = (explicitPath?.isEmpty == false ? explicitPath : defaultWhisperModelPath()) ?? defaultWhisperModelPath()
    guard FileManager.default.fileExists(atPath: path) else {
        throw ProductRuntimeError.missingWhisperModel(path)
    }
    return path
}

func normalizedWhisperLanguage(_ language: String) -> String {
    let trimmed = language.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "auto" : trimmed
}

func optionalNonEmptyTrimmed(_ value: String?) -> String? {
    guard let value else {
        return nil
    }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

func trimmingTrailingLineBreaks(_ text: String) -> String {
    var normalized = text
    while normalized.last == "\n" || normalized.last == "\r" {
        normalized.removeLast()
    }
    return normalized
}

func classifyRecordingUsability(
    durationMs: Int,
    fileSizeBytes: UInt64,
    minimumUsableDurationMs: Int
) -> RecordingUsability {
    if durationMs <= 0 || fileSizeBytes <= 44 {
        return .empty
    }
    if durationMs < minimumUsableDurationMs {
        return .tooShort
    }
    return .usable
}

func inspectRecordingArtifact(at fileURL: URL) throws -> RecordingFileDetails {
    do {
        let audioFile = try AVAudioFile(forReading: fileURL)
        let sampleRateHz = audioFile.fileFormat.sampleRate
        let channelCount = Int(audioFile.fileFormat.channelCount)
        let durationMs = sampleRateHz > 0
            ? max(Int((Double(audioFile.length) / sampleRateHz * 1_000.0).rounded()), 0)
            : 0
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSizeBytes = (attributes[.size] as? NSNumber)?.uint64Value ?? 0

        let normalizedSampleRateHz = Int(sampleRateHz.rounded())
        let format: String
        if fileURL.pathExtension.lowercased() == "wav", normalizedSampleRateHz == 16_000, channelCount == 1 {
            format = "wav-lpcm-16khz-mono"
        } else {
            let channelDescriptor = channelCount == 1 ? "mono" : "\(channelCount)ch"
            format = "\(fileURL.pathExtension.lowercased())-lpcm-\(normalizedSampleRateHz)hz-\(channelDescriptor)"
        }

        return RecordingFileDetails(
            format: format,
            sampleRateHz: sampleRateHz,
            channelCount: channelCount,
            durationMs: durationMs,
            fileSizeBytes: fileSizeBytes
        )
    } catch {
        throw ProductRuntimeError.failedToInspectRecording("\(error)")
    }
}

func hotKeyRegistrationErrorMessage(status: OSStatus) -> String {
    "Global hotkey registration failed with OSStatus \(status)."
}

func microphoneDeniedReason() -> String {
    "Microphone access is required before PushWrite can start recording."
}

func microphoneRestrictedReason() -> String {
    "Microphone access is restricted and PushWrite cannot start recording."
}

func currentMicrophonePermissionStatus() -> MicrophonePermissionStatus {
    if let runtimeCurrentMicrophonePermissionStatusOverride {
        return runtimeCurrentMicrophonePermissionStatusOverride
    }

    if let runtimeForcedMicrophonePermissionStatus {
        return runtimeForcedMicrophonePermissionStatus
    }

    if runtimeMicrophoneDeniedOverride || ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_MICROPHONE_DENIED"] == "1" {
        return .denied
    }

    switch AVCaptureDevice.authorizationStatus(for: .audio) {
    case .authorized:
        return .granted
    case .denied:
        return .denied
    case .restricted:
        return .restricted
    case .notDetermined:
        return .notDetermined
    @unknown default:
        return .restricted
    }
}

func microphoneBlockedReason(for status: MicrophonePermissionStatus) -> String? {
    switch status {
    case .denied:
        return microphoneDeniedReason()
    case .restricted:
        return microphoneRestrictedReason()
    case .granted, .notDetermined:
        return nil
    }
}

func hasAvailableMicrophoneDevice() -> Bool {
    if runtimeNoMicrophoneDeviceOverride || ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_NO_MICROPHONE_DEVICE"] == "1" {
        return false
    }
    let discoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.microphone, .external],
        mediaType: .audio,
        position: .unspecified
    )
    return !discoverySession.devices.isEmpty
}

func requestMicrophoneAccess(completion: @escaping (MicrophonePermissionStatus, Bool) -> Void) {
    let currentStatus = currentMicrophonePermissionStatus()
    guard currentStatus == .notDetermined else {
        completion(currentStatus, false)
        return
    }

    if let runtimeForcedMicrophonePermissionRequestResult {
        runtimeCurrentMicrophonePermissionStatusOverride = runtimeForcedMicrophonePermissionRequestResult
        completion(runtimeForcedMicrophonePermissionRequestResult, true)
        return
    }

    AVCaptureDevice.requestAccess(for: .audio) { granted in
        let resolvedStatus: MicrophonePermissionStatus
        if runtimeMicrophoneDeniedOverride {
            resolvedStatus = .denied
        } else if granted {
            resolvedStatus = .granted
        } else {
            resolvedStatus = currentMicrophonePermissionStatus()
        }
        runtimeCurrentMicrophonePermissionStatusOverride = resolvedStatus
        completion(resolvedStatus, true)
    }
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
    if runtimeSyntheticPasteFailureOverride ||
        ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_SYNTHETIC_PASTE_FAILURE"] == "1" {
        throw ProductRuntimeError.forcedSyntheticPasteFailure
    }

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

final class ProductFeedbackWindowController: NSWindowController, NSWindowDelegate {
    private let onPrimaryAction: (() -> Void)?
    private let onDismiss: () -> Void

    init(
        windowTitle: String,
        title: String,
        message: String,
        primaryButtonTitle: String?,
        dismissButtonTitle: String,
        onPrimaryAction: (() -> Void)?,
        onDismiss: @escaping () -> Void
    ) {
        self.onPrimaryAction = onPrimaryAction
        self.onDismiss = onDismiss

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = windowTitle
        window.center()
        window.isReleasedWhenClosed = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let bodyLabel = NSTextField(wrappingLabelWithString: message)
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        let primaryButton = primaryButtonTitle.map { title in
            let button = NSButton(title: title, target: nil, action: nil)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.keyEquivalent = "\r"
            return button
        }

        let dismissButton = NSButton(title: dismissButtonTitle, target: nil, action: nil)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        if let primaryButton {
            contentView.addSubview(primaryButton)
        }
        contentView.addSubview(dismissButton)

        var constraints = [
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),

            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),

            dismissButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            dismissButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ]

        if let primaryButton {
            constraints.append(primaryButton.trailingAnchor.constraint(equalTo: dismissButton.leadingAnchor, constant: -12))
            constraints.append(primaryButton.bottomAnchor.constraint(equalTo: dismissButton.bottomAnchor))
        }

        NSLayoutConstraint.activate(constraints)

        super.init(window: window)
        window.delegate = self
        primaryButton?.target = self
        primaryButton?.action = #selector(runPrimaryAction)
        dismissButton.target = self
        dismissButton.action = #selector(dismissPanel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func runPrimaryAction() {
        onPrimaryAction?()
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
    private let recordingLogQueue = DispatchQueue(label: "ch.baumanncreative.pushwrite.recording-log")
    private var queuedRequestIDs: [String] = []
    private var activeRequestID: String?
    private var activeHotKeyFlowID: String?
    private var isProcessing = false
    private var lastRequestID: String?
    private var lastResponseStatus: ProductResponseStatus?
    private var lastTranscriptionInsertGate: TranscriptionInsertGate?
    private var lastGatedTranscriptionFeedback: GatedTranscriptionFeedback?
    private var lastRequestedMicrophonePermission: Bool?
    private var lastLocalUserFeedback: LocalUserFeedback?
    private var lastBlockedReason: String?
    private var lastError: String?
    private var lastRecording: RecordingArtifact?
    private var lastTranscription: TranscriptionArtifact?
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyEventHandler: EventHandlerRef?
    private var hotKeyState: HotKeyStateSnapshot
    private var flowSnapshot: ProductFlowSnapshot
    private var pollTimer: Timer?
    private var blockedWindowController: ProductFeedbackWindowController?
    private var launchBlockedUIHasBeenPresented = false
    private var isHotKeyHeld = false
    private var isAwaitingMicrophonePermission = false
    private var pendingStopAfterRecordingStart = false
    private var activeRecordingSession: ActiveRecordingSession?
    private let minimumUsableRecordingDurationMs = 300

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
            transcriptionInsertGate: nil,
            gatedTranscriptionFeedback: nil,
            blockedReason: nil,
            error: nil,
            recordingDurationMs: nil,
            recordingFilePath: nil,
            microphonePermissionStatus: currentMicrophonePermissionStatus(),
            requestedMicrophonePermission: false,
            localUserFeedback: nil
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
        if let activeRecordingSession {
            activeRecordingSession.recorder.stop()
            self.activeRecordingSession = nil
        }
        try? writeState(running: false)
    }

    private func registerGlobalHotKey() {
        let hotKeyUserData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        var eventTypes = [
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            ),
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyReleased)
            )
        ]

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData, let event else {
                    return noErr
                }
                let delegate = Unmanaged<PushWriteAppDelegate>.fromOpaque(userData).takeUnretainedValue()
                return delegate.handleHotKeyEvent(event)
            },
            eventTypes.count,
            &eventTypes,
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

        switch GetEventKind(event) {
        case UInt32(kEventHotKeyPressed):
            handleGlobalHotKeyPressed()
        case UInt32(kEventHotKeyReleased):
            handleGlobalHotKeyReleased()
        default:
            break
        }
        return noErr
    }

    private func handleGlobalHotKeyPressed() {
        let flowID = UUID().uuidString
        isHotKeyHeld = true
        logHotKeyRecordingEvent(flowID: flowID, event: "hotkey-down-detected", detail: nil)

        guard hotKeyState.registered else {
            logHotKeyRecordingEvent(
                flowID: flowID,
                event: "hotkey-down-rejected",
                detail: hotKeyState.registrationError ?? "Global hotkey is not registered."
            )
            transitionFlow(
                to: .idle,
                id: flowID,
                trigger: .globalHotKey,
                textLength: 0,
                error: hotKeyState.registrationError ?? "Global hotkey is not registered.",
                localUserFeedback: .systemBeep
            )
            emitSystemBeep()
            return
        }

        guard !isProcessing else {
            logHotKeyRecordingEvent(
                flowID: activeHotKeyFlowID ?? flowID,
                event: "hotkey-down-ignored",
                detail: busyBlockedReason()
            )
            return
        }

        let receiptObservation = captureReceiptObservation(promptAccessibility: false)
        isProcessing = true
        activeHotKeyFlowID = flowID
        pendingStopAfterRecordingStart = false
        logHotKeyRecordingEvent(flowID: flowID, event: "recording-start-attempt", detail: nil)
        startHotKeyRecordingAttempt(flowID: flowID, receiptObservation: receiptObservation)
    }

    private func handleGlobalHotKeyReleased() {
        isHotKeyHeld = false
        logHotKeyRecordingEvent(flowID: activeHotKeyFlowID, event: "hotkey-up-detected", detail: nil)

        guard isProcessing, let flowID = activeHotKeyFlowID else {
            logHotKeyRecordingEvent(flowID: nil, event: "hotkey-up-ignored", detail: "No active recording flow.")
            return
        }

        if let activeRecordingSession, activeRecordingSession.flowID == flowID {
            stopActiveRecordingSession(activeRecordingSession)
            return
        }

        if isAwaitingMicrophonePermission {
            pendingStopAfterRecordingStart = true
            logHotKeyRecordingEvent(
                flowID: flowID,
                event: "hotkey-up-queued-stop",
                detail: "Recording start still pending microphone permission."
            )
        }
    }

    private func captureReceiptObservation(promptAccessibility: Bool) -> ReceiptObservation {
        let accessibilityTrusted = isAccessibilityTrusted(prompt: promptAccessibility)
        return ReceiptObservation(
            accessibilityTrusted: accessibilityTrusted,
            focusSnapshot: captureFocusSnapshot(isTrusted: accessibilityTrusted)
        )
    }

    private func busyBlockedReason() -> String {
        if flowSnapshot.state == .processing {
            return "PushWrite is still processing the previous recording."
        }
        return "PushWrite is already processing another action."
    }

    private func emitSystemBeep() {
        DispatchQueue.main.async {
            NSSound.beep()
        }
    }

    private func localUserFeedbackForTranscriptionGate(_ gate: TranscriptionInsertGate) -> LocalUserFeedback? {
        switch gate {
        case .transcriptionSkipped, .transcriptionFailed, .emptyTranscriptionText, .whitespaceOnlyTranscriptionText, .empty, .tooShort:
            return .blockedPanel
        case .passed:
            return nil
        }
    }

    private func makeHotKeyTerminalFeedbackDescriptor(for response: ProductResponse) -> (
        feedbackCase: HotKeyTerminalFeedbackCase,
        title: String,
        message: String
    )? {
        guard response.kind == .insertTranscription else {
            return nil
        }

        if response.transcriptionInsertGate == .passed {
            guard response.status != .succeeded else {
                return nil
            }
            return (
                feedbackCase: .insertFailed,
                title: "Text nicht eingefuegt",
                message: "Text konnte nicht eingefuegt werden."
            )
        }

        guard let gate = response.transcriptionInsertGate else {
            return nil
        }

        switch gate {
        case .transcriptionSkipped, .tooShort:
            return (
                feedbackCase: .tooShortRecording,
                title: "Kein Text eingefuegt",
                message: "Kein Text eingefuegt. Aufnahme zu kurz."
            )
        case .transcriptionFailed:
            return (
                feedbackCase: .transcriptionFailed,
                title: "Kein Text eingefuegt",
                message: "Kein Text eingefuegt. Transkription fehlgeschlagen."
            )
        case .emptyTranscriptionText, .whitespaceOnlyTranscriptionText, .empty:
            return (
                feedbackCase: .noUsableText,
                title: "Kein Text eingefuegt",
                message: "Kein Text eingefuegt. Kein brauchbarer Text erkannt."
            )
        case .passed:
            return nil
        }
    }

    private func presentTerminalHotKeyFeedback(title: String, message: String) {
        presentFeedbackPanel(
            windowTitle: "PushWrite",
            title: title,
            message: message,
            primaryButtonTitle: nil,
            dismissButtonTitle: "OK",
            onPrimaryAction: nil
        )
    }

    private func presentMicrophonePermissionBlockedUI(blockedReason: String) {
        let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "PushWrite"
        presentFeedbackPanel(
            windowTitle: "PushWrite setup required",
            title: "Microphone access required",
            message: "\(bundleName) cannot start recording until microphone access is enabled for this app in System Settings > Privacy & Security > Microphone.\n\n\(blockedReason)",
            primaryButtonTitle: "Open System Settings",
            dismissButtonTitle: "Not Now",
            onPrimaryAction: { [weak self] in
                self?.openMicrophoneSettings()
            }
        )
    }

    private func presentRecordingStartFailureUI(error: String) {
        presentFeedbackPanel(
            windowTitle: "PushWrite recording unavailable",
            title: "Recording could not start",
            message: error,
            primaryButtonTitle: nil,
            dismissButtonTitle: "OK",
            onPrimaryAction: nil
        )
    }

    private func startHotKeyRecordingAttempt(flowID: String, receiptObservation: ReceiptObservation) {
        isAwaitingMicrophonePermission = true
        requestMicrophoneAccess { [weak self] permissionStatus, requestedPermission in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                self.isAwaitingMicrophonePermission = false

                guard self.activeHotKeyFlowID == flowID else {
                    return
                }

                if let blockedReason = microphoneBlockedReason(for: permissionStatus) {
                    self.logHotKeyRecordingEvent(
                        flowID: flowID,
                        event: "recording-start-blocked",
                        detail: blockedReason
                    )
                    self.presentMicrophonePermissionBlockedUI(blockedReason: blockedReason)
                    self.completeGlobalHotKeyFlow(
                        flowID: flowID,
                        response: self.makeBlockedHotKeyResponse(
                            flowID: flowID,
                            receiptObservation: receiptObservation,
                            microphonePermissionStatus: permissionStatus,
                            blockedReason: blockedReason,
                            requestedMicrophonePermission: requestedPermission,
                            localUserFeedback: .blockedPanel
                        )
                    )
                    return
                }

                do {
                    let session = try self.startRecordingSession(
                        flowID: flowID,
                        receiptObservation: receiptObservation,
                        requestedMicrophonePermission: requestedPermission
                    )
                    self.activeRecordingSession = session
                    self.transitionFlow(
                        to: .recording,
                        id: flowID,
                        trigger: .globalHotKey,
                        textLength: 0,
                        recordingDurationMs: 0,
                        recordingFilePath: session.fileURL.path,
                        microphonePermissionStatus: permissionStatus,
                        requestedMicrophonePermission: requestedPermission
                    )
                    self.logHotKeyRecordingEvent(flowID: flowID, event: "recording-state-entered", detail: session.fileURL.path)

                    if self.pendingStopAfterRecordingStart || !self.isHotKeyHeld {
                        self.logHotKeyRecordingEvent(
                            flowID: flowID,
                            event: "recording-stop-auto-queued",
                            detail: "Hotkey was already released while recording startup finished."
                        )
                        self.stopActiveRecordingSession(session)
                    }
                } catch {
                    self.logHotKeyRecordingEvent(
                        flowID: flowID,
                        event: "recording-start-failed",
                        detail: "\(error)"
                    )
                    self.presentRecordingStartFailureUI(error: "\(error)")
                    self.completeGlobalHotKeyFlow(
                        flowID: flowID,
                        response: self.makeFailedHotKeyResponse(
                            flowID: flowID,
                            receiptObservation: receiptObservation,
                            microphonePermissionStatus: permissionStatus,
                            requestedMicrophonePermission: requestedPermission,
                            localUserFeedback: .blockedPanel,
                            error: "\(error)"
                        )
                    )
                }
            }
        }
    }

    private func startRecordingSession(
        flowID: String,
        receiptObservation: ReceiptObservation,
        requestedMicrophonePermission: Bool
    ) throws -> ActiveRecordingSession {
        guard hasAvailableMicrophoneDevice() else {
            throw ProductRuntimeError.noMicrophoneDevice
        }

        if runtimeMicrophoneRecorderStartFailureOverride ||
            ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_MICROPHONE_RECORDER_START_FAILURE"] == "1" {
            throw ProductRuntimeError.microphoneRecordingStartFailed
        }

        let fileURL = URL(fileURLWithPath: paths.recordingAudioFile(for: flowID))
        let metadataURL = URL(fileURLWithPath: paths.recordingMetadataFile(for: flowID))
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        do {
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.prepareToRecord()

            guard recorder.record() else {
                throw ProductRuntimeError.microphoneRecordingStartFailed
            }

            let startedAt = Date()
            return ActiveRecordingSession(
                flowID: flowID,
                fileURL: fileURL,
                metadataURL: metadataURL,
                startedAt: startedAt,
                startedAtTimestamp: isoTimestamp(),
                focusAtStart: receiptObservation.focusSnapshot,
                recorder: recorder,
                requestedMicrophonePermission: requestedMicrophonePermission
            )
        } catch let error as ProductRuntimeError {
            throw error
        } catch {
            throw ProductRuntimeError.microphoneRecorderCreationFailed("\(error)")
        }
    }

    private func stopActiveRecordingSession(_ session: ActiveRecordingSession) {
        guard activeRecordingSession?.flowID == session.flowID else {
            return
        }

        logHotKeyRecordingEvent(flowID: session.flowID, event: "recording-stop-started", detail: nil)
        activeRecordingSession = nil
        pendingStopAfterRecordingStart = false

        let measuredDurationMs = max(Int((session.recorder.currentTime * 1_000.0).rounded()), 0)
        let focusAtStop = captureFocusSnapshot(isTrusted: true)
        session.recorder.stop()
        logHotKeyRecordingEvent(
            flowID: session.flowID,
            event: "recording-stopped",
            detail: "durationMs=\(measuredDurationMs)"
        )

        transitionFlow(
            to: .processing,
            id: session.flowID,
            trigger: .globalHotKey,
            textLength: 0,
            recordingDurationMs: measuredDurationMs,
            recordingFilePath: session.fileURL.path,
            microphonePermissionStatus: .granted,
            requestedMicrophonePermission: session.requestedMicrophonePermission
        )
        logHotKeyRecordingEvent(flowID: session.flowID, event: "processing-state-entered", detail: nil)

        workerQueue.async {
            let response = self.finishRecordingSession(
                session,
                measuredDurationMs: measuredDurationMs,
                focusAtStop: focusAtStop
            )
            DispatchQueue.main.async {
                self.completeGlobalHotKeyFlow(flowID: session.flowID, response: response)
            }
        }
    }

    private func finishRecordingSession(
        _ session: ActiveRecordingSession,
        measuredDurationMs: Int,
        focusAtStop: FocusSnapshot?
    ) -> ProductResponse {
        let recordingStoppedAt = isoTimestamp()
        let productFrontmostAtReceipt = isProductFrontmost(session.focusAtStart)
        var recordedArtifact: RecordingArtifact?

        do {
            try replaceRecordingArtifactWithFixtureIfNeeded(session: session)
            let artifact = try makeRecordingArtifact(session: session, measuredDurationMs: measuredDurationMs)
            recordedArtifact = artifact
            logHotKeyRecordingEvent(flowID: session.flowID, event: "audio-handoff-started", detail: artifact.filePath)
            let handoff = try handoffAudioForProcessing(recordingArtifact: artifact)
            logHotKeyRecordingEvent(
                flowID: session.flowID,
                event: "audio-handoff-succeeded",
                detail: "usability=\(handoff.usability.rawValue)"
            )
            let transcriptionOutcome = try processAudioProcessingHandoff(session: session, handoff: handoff)
            let response = completeTranscriptionInsertFlow(
                session: session,
                recordingStoppedAt: recordingStoppedAt,
                focusAtStop: focusAtStop,
                productFrontmostAtReceipt: productFrontmostAtReceipt,
                recordingArtifact: artifact,
                transcriptionResult: transcriptionOutcome.result,
                transcriptionArtifact: transcriptionOutcome.artifact
            )
            logHotKeyRecordingEvent(
                flowID: session.flowID,
                event: "processing-flow-completed",
                detail: "transcriptionStatus=\(transcriptionOutcome.result.status.rawValue),insertStatus=\(response.status.rawValue),insertGate=\(response.transcriptionInsertGate?.rawValue ?? "none")"
            )
            return response
        } catch {
            logHotKeyRecordingEvent(
                flowID: session.flowID,
                event: "audio-handoff-failed",
                detail: "\(error)"
            )
            return ProductResponse(
                id: session.flowID,
                kind: .recordAudio,
                timestamp: isoTimestamp(),
                productBundleID: Bundle.main.bundleIdentifier,
                productPID: ProcessInfo.processInfo.processIdentifier,
                status: .failed,
                accessibilityTrusted: true,
                microphonePermissionStatus: .granted,
                requestedMicrophonePermission: session.requestedMicrophonePermission,
                promptAccessibility: false,
                blockedReason: nil,
                settleDelayMs: defaults.settle,
                pasteDelayMs: defaults.paste,
                restoreClipboard: false,
                restoreDelayMs: defaults.restore,
                textLength: 0,
                transcriptionInsertGate: nil,
                gatedTranscriptionFeedback: nil,
                hotKeyInteractionModel: .pressAndHold,
                insertRoute: nil,
                insertSource: nil,
                focusAtReceipt: session.focusAtStart,
                focusBeforePaste: nil,
                focusAfterPaste: nil,
                focusAtStop: focusAtStop,
                productFrontmostAtReceipt: productFrontmostAtReceipt,
                productFrontmostBeforePaste: false,
                productFrontmostAfterPaste: false,
                originalPasteboard: nil,
                syntheticPastePosted: false,
                clipboardRestored: false,
                recordingStartedAt: session.startedAtTimestamp,
                recordingStoppedAt: recordingStoppedAt,
                recordingArtifact: recordedArtifact,
                transcriptionArtifact: nil,
                transcribingPlaceholder: false,
                localUserFeedback: nil,
                error: "\(error)"
            )
        }
    }

    private func handoffAudioForProcessing(recordingArtifact: RecordingArtifact) throws -> AudioProcessingHandoff {
        let usability = classifyRecordingUsability(
            durationMs: recordingArtifact.durationMs,
            fileSizeBytes: recordingArtifact.fileSizeBytes,
            minimumUsableDurationMs: minimumUsableRecordingDurationMs
        )
        let handoff = AudioProcessingHandoff(
            id: recordingArtifact.id,
            recordingArtifact: recordingArtifact,
            usability: usability,
            heuristic: "empty if durationMs <= 0 or fileSizeBytes <= 44; tooShort if durationMs < \(minimumUsableRecordingDurationMs); otherwise usable",
            startedAt: isoTimestamp()
        )
        try writeJSON(handoff, to: paths.lastAudioProcessingHandoffFile)
        try appendJSONLine(handoff, to: paths.audioProcessingHandoffLogFile)
        return handoff
    }

    private func processAudioProcessingHandoff(
        session: ActiveRecordingSession,
        handoff: AudioProcessingHandoff
    ) throws -> (result: TranscriptionResult, artifact: TranscriptionArtifact?) {
        logHotKeyRecordingEvent(
            flowID: session.flowID,
            event: "transcription-handoff-received",
            detail: "usability=\(handoff.usability.rawValue)"
        )

        switch handoff.usability {
        case .empty:
            let result = makeSkippedTranscriptionResult(
                handoff: handoff,
                skipReason: .emptyRecording
            )
            try persistTranscriptionResult(result)
            logHotKeyRecordingEvent(
                flowID: session.flowID,
                event: "transcription-skipped",
                detail: "reason=\(TranscriptionSkipReason.emptyRecording.rawValue)"
            )
            return (result, nil)
        case .tooShort:
            let result = makeSkippedTranscriptionResult(
                handoff: handoff,
                skipReason: .tooShortRecording
            )
            try persistTranscriptionResult(result)
            logHotKeyRecordingEvent(
                flowID: session.flowID,
                event: "transcription-skipped",
                detail: "reason=\(TranscriptionSkipReason.tooShortRecording.rawValue)"
            )
            return (result, nil)
        case .usable:
            logHotKeyRecordingEvent(flowID: session.flowID, event: "transcription-started", detail: nil)
            let transcriptionArtifact = transcribeRecording(
                session: session,
                recordingArtifact: handoff.recordingArtifact
            )
            if transcriptionArtifact.status == .succeeded {
                let result = TranscriptionResult(
                    id: handoff.id,
                    recordingID: handoff.recordingArtifact.id,
                    recordingFilePath: handoff.recordingArtifact.filePath,
                    recordingUsability: handoff.usability,
                    transcriptionAttempted: true,
                    succeeded: true,
                    status: .succeeded,
                    text: transcriptionArtifact.text,
                    textLength: transcriptionArtifact.textLength,
                    skipReason: nil,
                    error: nil,
                    startedAt: transcriptionArtifact.startedAt,
                    completedAt: transcriptionArtifact.completedAt,
                    durationMs: transcriptionArtifact.durationMs
                )
                try persistTranscriptionResult(result)
                logHotKeyRecordingEvent(
                    flowID: session.flowID,
                    event: "transcription-succeeded",
                    detail: "textLength=\(transcriptionArtifact.textLength)"
                )
                return (result, transcriptionArtifact)
            }

            let fallbackError = "whisper.cpp transcription failed without an explicit error message."
            let result = TranscriptionResult(
                id: handoff.id,
                recordingID: handoff.recordingArtifact.id,
                recordingFilePath: handoff.recordingArtifact.filePath,
                recordingUsability: handoff.usability,
                transcriptionAttempted: true,
                succeeded: false,
                status: .failed,
                text: nil,
                textLength: transcriptionArtifact.textLength,
                skipReason: nil,
                error: transcriptionArtifact.error ?? fallbackError,
                startedAt: transcriptionArtifact.startedAt,
                completedAt: transcriptionArtifact.completedAt,
                durationMs: transcriptionArtifact.durationMs
            )
            try persistTranscriptionResult(result)
            logHotKeyRecordingEvent(
                flowID: session.flowID,
                event: "transcription-failed",
                detail: result.error
            )
            return (result, transcriptionArtifact)
        }
    }

    private func makeSkippedTranscriptionResult(
        handoff: AudioProcessingHandoff,
        skipReason: TranscriptionSkipReason
    ) -> TranscriptionResult {
        let timestamp = isoTimestamp()
        return TranscriptionResult(
            id: handoff.id,
            recordingID: handoff.recordingArtifact.id,
            recordingFilePath: handoff.recordingArtifact.filePath,
            recordingUsability: handoff.usability,
            transcriptionAttempted: false,
            succeeded: false,
            status: .skipped,
            text: nil,
            textLength: 0,
            skipReason: skipReason,
            error: nil,
            startedAt: timestamp,
            completedAt: timestamp,
            durationMs: 0
        )
    }

    private func completeTranscriptionInsertFlow(
        session: ActiveRecordingSession,
        recordingStoppedAt: String,
        focusAtStop: FocusSnapshot?,
        productFrontmostAtReceipt: Bool,
        recordingArtifact: RecordingArtifact,
        transcriptionResult: TranscriptionResult,
        transcriptionArtifact: TranscriptionArtifact?
    ) -> ProductResponse {
        let evaluationStartedAt = Date()
        let evaluationStartedAtTimestamp = isoTimestamp()
        let gateEvaluation = evaluateTranscriptionInsertGate(for: transcriptionResult)
        let gate: TranscriptionInsertGate

        switch gateEvaluation {
        case .passed:
            gate = .passed
        case let .gated(reason):
            gate = reason
        }

        logHotKeyRecordingEvent(
            flowID: session.flowID,
            event: "insert-gate-evaluated",
            detail: "gate=\(gate.rawValue),transcriptionStatus=\(transcriptionResult.status.rawValue),transcriptionAttempted=\(transcriptionResult.transcriptionAttempted),textLength=\(transcriptionResult.textLength)"
        )

        switch gateEvaluation {
        case let .gated(reason):
            logHotKeyRecordingEvent(
                flowID: session.flowID,
                event: "insert-gated",
                detail: "gate=\(reason.rawValue)"
            )
            let response = makeGatedHotKeyTranscriptionResponse(
                session: session,
                recordingStoppedAt: recordingStoppedAt,
                productFrontmostAtReceipt: productFrontmostAtReceipt,
                focusAtStop: focusAtStop,
                recordingArtifact: recordingArtifact,
                transcriptionArtifact: transcriptionArtifact,
                transcriptionResult: transcriptionResult,
                transcriptionInsertGate: reason,
                gatedTranscriptionFeedback: nil,
                localUserFeedback: localUserFeedbackForTranscriptionGate(reason)
            )
            let insertResult = InsertResult(
                id: session.flowID,
                flowID: session.flowID,
                transcriptionResultID: transcriptionResult.id,
                transcriptionResultStatus: transcriptionResult.status,
                transcriptionAttempted: transcriptionResult.transcriptionAttempted,
                transcriptionTextLength: transcriptionResult.textLength,
                insertAttempted: false,
                status: .gated,
                gate: reason,
                gateReason: reason.rawValue,
                error: response.error,
                insertedTextLength: 0,
                insertRoute: nil,
                insertSource: .transcription,
                startedAt: evaluationStartedAtTimestamp,
                completedAt: isoTimestamp(),
                durationMs: max(Int(Date().timeIntervalSince(evaluationStartedAt) * 1_000.0), 0)
            )
            try? persistInsertResult(insertResult)
            return response
        case let .passed(text):
            logHotKeyRecordingEvent(
                flowID: session.flowID,
                event: "insert-started",
                detail: "textLength=\(text.count)"
            )

            let receiptObservation = ReceiptObservation(
                accessibilityTrusted: true,
                focusSnapshot: session.focusAtStart
            )
            let insertResponse: ProductResponse
            do {
                insertResponse = try insertTranscription(
                    text: text,
                    requestID: session.flowID,
                    presentsBlockedUI: false,
                    receiptObservation: receiptObservation
                )
            } catch {
                insertResponse = makeHotKeyInsertAttemptFailedResponse(
                    flowID: session.flowID,
                    error: "\(error)",
                    receiptObservation: receiptObservation
                )
            }

            let insertFailed = insertResponse.status != .succeeded
            if insertFailed {
                logHotKeyRecordingEvent(
                    flowID: session.flowID,
                    event: "insert-failed",
                    detail: insertResponse.error ?? insertResponse.blockedReason ?? "status=\(insertResponse.status.rawValue)"
                )
            } else {
                logHotKeyRecordingEvent(
                    flowID: session.flowID,
                    event: "insert-succeeded",
                    detail: "insertRoute=\(insertResponse.insertRoute?.rawValue ?? "none"),textLength=\(text.count)"
                )
            }

            let insertResult = InsertResult(
                id: session.flowID,
                flowID: session.flowID,
                transcriptionResultID: transcriptionResult.id,
                transcriptionResultStatus: transcriptionResult.status,
                transcriptionAttempted: transcriptionResult.transcriptionAttempted,
                transcriptionTextLength: transcriptionResult.textLength,
                insertAttempted: true,
                status: insertFailed ? .failed : .succeeded,
                gate: .passed,
                gateReason: nil,
                error: insertResponse.error ?? insertResponse.blockedReason,
                insertedTextLength: insertFailed ? 0 : text.count,
                insertRoute: insertResponse.insertRoute,
                insertSource: .transcription,
                startedAt: evaluationStartedAtTimestamp,
                completedAt: isoTimestamp(),
                durationMs: max(Int(Date().timeIntervalSince(evaluationStartedAt) * 1_000.0), 0)
            )
            try? persistInsertResult(insertResult)

            return makeCompletedHotKeyInsertResponse(
                insertResponse: insertResponse,
                session: session,
                recordingStoppedAt: recordingStoppedAt,
                focusAtStop: focusAtStop,
                recordingArtifact: recordingArtifact,
                transcriptionArtifact: transcriptionArtifact,
                transcriptionInsertGate: .passed
            )
        }
    }

    private func makeHotKeyInsertAttemptFailedResponse(
        flowID: String,
        error: String,
        receiptObservation: ReceiptObservation
    ) -> ProductResponse {
        ProductResponse(
            id: flowID,
            kind: .insertTranscription,
            timestamp: isoTimestamp(),
            productBundleID: Bundle.main.bundleIdentifier,
            productPID: ProcessInfo.processInfo.processIdentifier,
            status: .failed,
            accessibilityTrusted: receiptObservation.accessibilityTrusted,
            microphonePermissionStatus: .granted,
            requestedMicrophonePermission: false,
            promptAccessibility: false,
            blockedReason: nil,
            settleDelayMs: defaults.settle,
            pasteDelayMs: defaults.paste,
            restoreClipboard: false,
            restoreDelayMs: defaults.restore,
            textLength: 0,
            transcriptionInsertGate: nil,
            gatedTranscriptionFeedback: nil,
            hotKeyInteractionModel: .pressAndHold,
            insertRoute: nil,
            insertSource: .transcription,
            focusAtReceipt: receiptObservation.focusSnapshot,
            focusBeforePaste: nil,
            focusAfterPaste: nil,
            focusAtStop: nil,
            productFrontmostAtReceipt: isProductFrontmost(receiptObservation.focusSnapshot),
            productFrontmostBeforePaste: false,
            productFrontmostAfterPaste: false,
            originalPasteboard: nil,
            syntheticPastePosted: false,
            clipboardRestored: false,
            recordingStartedAt: nil,
            recordingStoppedAt: nil,
            recordingArtifact: nil,
            transcriptionArtifact: nil,
            transcribingPlaceholder: false,
            localUserFeedback: nil,
            error: error
        )
    }

    private func makeCompletedHotKeyInsertResponse(
        insertResponse: ProductResponse,
        session: ActiveRecordingSession,
        recordingStoppedAt: String,
        focusAtStop: FocusSnapshot?,
        recordingArtifact: RecordingArtifact,
        transcriptionArtifact: TranscriptionArtifact?,
        transcriptionInsertGate: TranscriptionInsertGate
    ) -> ProductResponse {
        let localUserFeedback: LocalUserFeedback? = insertResponse.status == .succeeded
            ? insertResponse.localUserFeedback
            : .blockedPanel
        return ProductResponse(
            id: insertResponse.id,
            kind: .insertTranscription,
            timestamp: insertResponse.timestamp,
            productBundleID: insertResponse.productBundleID,
            productPID: insertResponse.productPID,
            status: insertResponse.status,
            accessibilityTrusted: insertResponse.accessibilityTrusted,
            microphonePermissionStatus: .granted,
            requestedMicrophonePermission: session.requestedMicrophonePermission,
            promptAccessibility: false,
            blockedReason: insertResponse.blockedReason,
            settleDelayMs: insertResponse.settleDelayMs,
            pasteDelayMs: insertResponse.pasteDelayMs,
            restoreClipboard: insertResponse.restoreClipboard,
            restoreDelayMs: insertResponse.restoreDelayMs,
            textLength: transcriptionArtifact?.textLength ?? insertResponse.textLength,
            transcriptionInsertGate: transcriptionInsertGate,
            gatedTranscriptionFeedback: nil,
            hotKeyInteractionModel: .pressAndHold,
            insertRoute: insertResponse.insertRoute,
            insertSource: insertResponse.insertSource,
            focusAtReceipt: insertResponse.focusAtReceipt,
            focusBeforePaste: insertResponse.focusBeforePaste,
            focusAfterPaste: insertResponse.focusAfterPaste,
            focusAtStop: focusAtStop,
            productFrontmostAtReceipt: insertResponse.productFrontmostAtReceipt,
            productFrontmostBeforePaste: insertResponse.productFrontmostBeforePaste,
            productFrontmostAfterPaste: insertResponse.productFrontmostAfterPaste,
            originalPasteboard: insertResponse.originalPasteboard,
            syntheticPastePosted: insertResponse.syntheticPastePosted,
            clipboardRestored: insertResponse.clipboardRestored,
            recordingStartedAt: session.startedAtTimestamp,
            recordingStoppedAt: recordingStoppedAt,
            recordingArtifact: recordingArtifact,
            transcriptionArtifact: transcriptionArtifact,
            transcribingPlaceholder: false,
            localUserFeedback: localUserFeedback,
            error: insertResponse.error
        )
    }

    private func makeGatedHotKeyTranscriptionResponse(
        session: ActiveRecordingSession,
        recordingStoppedAt: String,
        productFrontmostAtReceipt: Bool,
        focusAtStop: FocusSnapshot?,
        recordingArtifact: RecordingArtifact,
        transcriptionArtifact: TranscriptionArtifact?,
        transcriptionResult: TranscriptionResult,
        transcriptionInsertGate: TranscriptionInsertGate,
        gatedTranscriptionFeedback: GatedTranscriptionFeedback?,
        localUserFeedback: LocalUserFeedback?
    ) -> ProductResponse {
        let status: ProductResponseStatus = transcriptionResult.status == .failed ? .failed : .succeeded
        let error = transcriptionResult.status == .failed ? transcriptionResult.error : nil
        return ProductResponse(
            id: session.flowID,
            kind: .insertTranscription,
            timestamp: isoTimestamp(),
            productBundleID: Bundle.main.bundleIdentifier,
            productPID: ProcessInfo.processInfo.processIdentifier,
            status: status,
            accessibilityTrusted: isAccessibilityTrusted(prompt: false),
            microphonePermissionStatus: .granted,
            requestedMicrophonePermission: session.requestedMicrophonePermission,
            promptAccessibility: false,
            blockedReason: nil,
            settleDelayMs: defaults.settle,
            pasteDelayMs: defaults.paste,
            restoreClipboard: false,
            restoreDelayMs: defaults.restore,
            textLength: transcriptionResult.textLength,
            transcriptionInsertGate: transcriptionInsertGate,
            gatedTranscriptionFeedback: gatedTranscriptionFeedback,
            hotKeyInteractionModel: .pressAndHold,
            insertRoute: nil,
            insertSource: .transcription,
            focusAtReceipt: session.focusAtStart,
            focusBeforePaste: nil,
            focusAfterPaste: nil,
            focusAtStop: focusAtStop,
            productFrontmostAtReceipt: productFrontmostAtReceipt,
            productFrontmostBeforePaste: false,
            productFrontmostAfterPaste: false,
            originalPasteboard: nil,
            syntheticPastePosted: false,
            clipboardRestored: false,
            recordingStartedAt: session.startedAtTimestamp,
            recordingStoppedAt: recordingStoppedAt,
            recordingArtifact: recordingArtifact,
            transcriptionArtifact: transcriptionArtifact,
            transcribingPlaceholder: false,
            localUserFeedback: localUserFeedback,
            error: error
        )
    }

    private func replaceRecordingArtifactWithFixtureIfNeeded(session: ActiveRecordingSession) throws {
        guard
            let fixturePath = launchOptions.transcriptionFixtureWAVPath?.trimmingCharacters(in: .whitespacesAndNewlines),
            !fixturePath.isEmpty
        else {
            return
        }

        guard FileManager.default.fileExists(atPath: fixturePath) else {
            throw ProductRuntimeError.missingTranscriptionFixture(fixturePath)
        }

        do {
            if FileManager.default.fileExists(atPath: session.fileURL.path) {
                try FileManager.default.removeItem(at: session.fileURL)
            }
            try FileManager.default.copyItem(atPath: fixturePath, toPath: session.fileURL.path)
        } catch {
            throw ProductRuntimeError.failedToReplaceRecordingArtifact("\(error)")
        }
    }

    private func transcribeRecording(
        session: ActiveRecordingSession,
        recordingArtifact: RecordingArtifact
    ) -> TranscriptionArtifact {
        let configuredCLIPath = optionalNonEmptyTrimmed(launchOptions.whisperCLIPath) ?? defaultWhisperCLIPath()
        let configuredModelPath = optionalNonEmptyTrimmed(launchOptions.whisperModelPath) ?? defaultWhisperModelPath()
        let configuredLanguage = normalizedWhisperLanguage(launchOptions.whisperLanguage)
        let artifactPath = paths.transcriptionArtifactFile(for: session.flowID)
        let textFilePath = paths.transcriptionTextFile(for: session.flowID)
        let rawOutputJSONPath = paths.transcriptionRawJSONFile(for: session.flowID)
        let startedAt = isoTimestamp()
        let started = Date()

        do {
            let cliPath = try resolveWhisperCLIPath(launchOptions: launchOptions)
            let modelPath = try resolveWhisperModelPath(launchOptions: launchOptions)
            let transcriptText = try runWhisperCLI(
                cliPath: cliPath,
                modelPath: modelPath,
                recordingPath: recordingArtifact.filePath,
                outputBasePath: paths.transcriptionOutputBase(for: session.flowID),
                language: configuredLanguage
            )
            let resolvedLanguage = resolveTranscriptionLanguage(
                rawOutputJSONPath: rawOutputJSONPath,
                fallbackLanguage: configuredLanguage
            )
            let artifact = TranscriptionArtifact(
                id: session.flowID,
                recordingID: recordingArtifact.id,
                recordingFilePath: recordingArtifact.filePath,
                artifactPath: artifactPath,
                textFilePath: textFilePath,
                rawOutputJSONPath: rawOutputJSONPath,
                cliPath: cliPath,
                modelPath: modelPath,
                modelName: URL(fileURLWithPath: modelPath).lastPathComponent,
                language: resolvedLanguage,
                status: .succeeded,
                text: transcriptText,
                textLength: transcriptText.count,
                startedAt: startedAt,
                completedAt: isoTimestamp(),
                durationMs: max(Int(Date().timeIntervalSince(started) * 1_000.0), 0),
                error: nil
            )
            persistTranscriptionArtifact(artifact)
            return artifact
        } catch {
            let artifact = TranscriptionArtifact(
                id: session.flowID,
                recordingID: recordingArtifact.id,
                recordingFilePath: recordingArtifact.filePath,
                artifactPath: artifactPath,
                textFilePath: textFilePath,
                rawOutputJSONPath: rawOutputJSONPath,
                cliPath: configuredCLIPath,
                modelPath: configuredModelPath,
                modelName: URL(fileURLWithPath: configuredModelPath).lastPathComponent,
                language: configuredLanguage,
                status: .failed,
                text: "",
                textLength: 0,
                startedAt: startedAt,
                completedAt: isoTimestamp(),
                durationMs: max(Int(Date().timeIntervalSince(started) * 1_000.0), 0),
                error: "\(error)"
            )
            persistTranscriptionArtifact(artifact)
            return artifact
        }
    }

    private func runWhisperCLI(
        cliPath: String,
        modelPath: String,
        recordingPath: String,
        outputBasePath: String,
        language: String
    ) throws -> String {
        let textOutputPath = "\(outputBasePath).txt"
        let rawJSONOutputPath = "\(outputBasePath).json"
        try? FileManager.default.removeItem(atPath: textOutputPath)
        try? FileManager.default.removeItem(atPath: rawJSONOutputPath)

        var arguments = [
            "-m", modelPath,
            "-f", recordingPath,
            "-nt",
            "-ng",
            "-otxt",
            "-oj",
            "-of", outputBasePath
        ]
        if language != "auto" {
            arguments.append(contentsOf: ["-l", language])
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw ProductRuntimeError.transcriptionLaunchFailed("\(error)")
        }

        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let processOutput = ([stdout, stderr].joined(separator: "\n"))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard process.terminationStatus == 0 else {
            let message = processOutput.isEmpty
                ? "exit status \(process.terminationStatus)"
                : "exit status \(process.terminationStatus): \(processOutput)"
            throw ProductRuntimeError.transcriptionProcessFailed(message)
        }

        guard FileManager.default.fileExists(atPath: textOutputPath) else {
            throw ProductRuntimeError.missingTranscriptionOutput(textOutputPath)
        }
        guard FileManager.default.fileExists(atPath: rawJSONOutputPath) else {
            throw ProductRuntimeError.missingTranscriptionOutput(rawJSONOutputPath)
        }

        return trimmingTrailingLineBreaks(
            try String(contentsOf: URL(fileURLWithPath: textOutputPath), encoding: .utf8)
        )
    }

    private func resolveTranscriptionLanguage(rawOutputJSONPath: String, fallbackLanguage: String) -> String {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: rawOutputJSONPath)) else {
            return fallbackLanguage
        }
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = object["result"] as? [String: Any],
            let language = result["language"] as? String,
            !language.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return fallbackLanguage
        }
        return language
    }

    private func persistTranscriptionArtifact(_ artifact: TranscriptionArtifact) {
        do {
            try writeJSON(artifact, to: artifact.artifactPath)
        } catch {
            fputs("Could not persist transcription artifact for \(artifact.id): \(error)\n", stderr)
        }
    }

    private func persistTranscriptionResult(_ result: TranscriptionResult) throws {
        try writeJSON(result, to: paths.lastTranscriptionResultFile)
        try appendJSONLine(result, to: paths.transcriptionResultsLogFile)
    }

    private func persistInsertResult(_ result: InsertResult) throws {
        try writeJSON(result, to: paths.lastInsertResultFile)
        try appendJSONLine(result, to: paths.insertResultsLogFile)
    }

    private func makeRecordingArtifact(session: ActiveRecordingSession, measuredDurationMs: Int) throws -> RecordingArtifact {
        let details = try inspectRecordingArtifact(at: session.fileURL)
        let artifact = RecordingArtifact(
            id: session.flowID,
            filePath: session.fileURL.path,
            metadataPath: session.metadataURL.path,
            format: details.format,
            sampleRateHz: details.sampleRateHz,
            channelCount: details.channelCount,
            durationMs: details.durationMs > 0 ? details.durationMs : measuredDurationMs,
            fileSizeBytes: details.fileSizeBytes,
            createdAt: session.startedAtTimestamp
        )
        try writeJSON(artifact, to: session.metadataURL.path)
        return artifact
    }

    private func makeBlockedHotKeyResponse(
        flowID: String,
        receiptObservation: ReceiptObservation,
        microphonePermissionStatus: MicrophonePermissionStatus,
        blockedReason: String,
        requestedMicrophonePermission: Bool,
        localUserFeedback: LocalUserFeedback?
    ) -> ProductResponse {
        ProductResponse(
            id: flowID,
            kind: .recordAudio,
            timestamp: isoTimestamp(),
            productBundleID: Bundle.main.bundleIdentifier,
            productPID: ProcessInfo.processInfo.processIdentifier,
            status: .blocked,
            accessibilityTrusted: receiptObservation.accessibilityTrusted,
            microphonePermissionStatus: microphonePermissionStatus,
            requestedMicrophonePermission: requestedMicrophonePermission,
            promptAccessibility: false,
            blockedReason: blockedReason,
            settleDelayMs: defaults.settle,
            pasteDelayMs: defaults.paste,
            restoreClipboard: false,
            restoreDelayMs: defaults.restore,
            textLength: 0,
            transcriptionInsertGate: nil,
            gatedTranscriptionFeedback: nil,
            hotKeyInteractionModel: .pressAndHold,
            insertRoute: nil,
            insertSource: nil,
            focusAtReceipt: receiptObservation.focusSnapshot,
            focusBeforePaste: nil,
            focusAfterPaste: nil,
            focusAtStop: receiptObservation.focusSnapshot,
            productFrontmostAtReceipt: isProductFrontmost(receiptObservation.focusSnapshot),
            productFrontmostBeforePaste: false,
            productFrontmostAfterPaste: false,
            originalPasteboard: nil,
            syntheticPastePosted: false,
            clipboardRestored: false,
            recordingStartedAt: nil,
            recordingStoppedAt: nil,
            recordingArtifact: nil,
            transcriptionArtifact: nil,
            transcribingPlaceholder: false,
            localUserFeedback: localUserFeedback,
            error: nil
        )
    }

    private func makeFailedHotKeyResponse(
        flowID: String,
        receiptObservation: ReceiptObservation,
        microphonePermissionStatus: MicrophonePermissionStatus,
        requestedMicrophonePermission: Bool,
        localUserFeedback: LocalUserFeedback?,
        error: String
    ) -> ProductResponse {
        ProductResponse(
            id: flowID,
            kind: .recordAudio,
            timestamp: isoTimestamp(),
            productBundleID: Bundle.main.bundleIdentifier,
            productPID: ProcessInfo.processInfo.processIdentifier,
            status: .failed,
            accessibilityTrusted: receiptObservation.accessibilityTrusted,
            microphonePermissionStatus: microphonePermissionStatus,
            requestedMicrophonePermission: requestedMicrophonePermission,
            promptAccessibility: false,
            blockedReason: nil,
            settleDelayMs: defaults.settle,
            pasteDelayMs: defaults.paste,
            restoreClipboard: false,
            restoreDelayMs: defaults.restore,
            textLength: 0,
            transcriptionInsertGate: nil,
            gatedTranscriptionFeedback: nil,
            hotKeyInteractionModel: .pressAndHold,
            insertRoute: nil,
            insertSource: nil,
            focusAtReceipt: receiptObservation.focusSnapshot,
            focusBeforePaste: nil,
            focusAfterPaste: nil,
            focusAtStop: receiptObservation.focusSnapshot,
            productFrontmostAtReceipt: isProductFrontmost(receiptObservation.focusSnapshot),
            productFrontmostBeforePaste: false,
            productFrontmostAfterPaste: false,
            originalPasteboard: nil,
            syntheticPastePosted: false,
            clipboardRestored: false,
            recordingStartedAt: nil,
            recordingStoppedAt: nil,
            recordingArtifact: nil,
            transcriptionArtifact: nil,
            transcribingPlaceholder: false,
            localUserFeedback: localUserFeedback,
            error: error
        )
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
        isAwaitingMicrophonePermission = false
        pendingStopAfterRecordingStart = false
        lastRequestID = response.id
        lastResponseStatus = response.status
        lastTranscriptionInsertGate = response.transcriptionInsertGate
        lastGatedTranscriptionFeedback = response.gatedTranscriptionFeedback
        lastRequestedMicrophonePermission = response.requestedMicrophonePermission
        lastLocalUserFeedback = response.localUserFeedback
        lastBlockedReason = response.blockedReason
        lastError = response.error
        lastRecording = response.recordingArtifact
        lastTranscription = response.transcriptionArtifact

        let completionEvent: String
        switch response.status {
        case .succeeded:
            completionEvent = "flow-completed-succeeded"
        case .blocked:
            completionEvent = "flow-completed-blocked"
        case .failed, .invalidRequest:
            completionEvent = "flow-completed-failed"
        case .ready, .stopped:
            completionEvent = "flow-completed-unexpected-status"
        }
        logHotKeyRecordingEvent(flowID: flowID, event: completionEvent, detail: response.error ?? response.blockedReason)

        transitionFlow(
            to: .idle,
            id: flowID,
            trigger: .globalHotKey,
            textLength: response.textLength,
            transcriptionInsertGate: response.transcriptionInsertGate,
            gatedTranscriptionFeedback: response.gatedTranscriptionFeedback,
            blockedReason: response.blockedReason,
            error: response.error,
            recordingDurationMs: response.recordingArtifact?.durationMs,
            recordingFilePath: response.recordingArtifact?.filePath,
            microphonePermissionStatus: response.microphonePermissionStatus,
            requestedMicrophonePermission: response.requestedMicrophonePermission,
            localUserFeedback: response.localUserFeedback
        )
        logHotKeyRecordingEvent(flowID: flowID, event: "flow-returned-idle", detail: nil)

        if response.kind == .insertTranscription {
            let terminalFeedback = makeHotKeyTerminalFeedbackDescriptor(for: response)
            logHotKeyRecordingEvent(
                flowID: flowID,
                event: "local-feedback-evaluated",
                detail: "feedbackCase=\(terminalFeedback?.feedbackCase.rawValue ?? "none"),insertStatus=\(response.status.rawValue),insertGate=\(response.transcriptionInsertGate?.rawValue ?? "none")"
            )
            if let terminalFeedback {
                presentTerminalHotKeyFeedback(
                    title: terminalFeedback.title,
                    message: terminalFeedback.message
                )
                logHotKeyRecordingEvent(
                    flowID: flowID,
                    event: "local-feedback-triggered",
                    detail: "feedbackCase=\(terminalFeedback.feedbackCase.rawValue),channel=\(response.localUserFeedback?.rawValue ?? "none")"
                )
            }
        }

        processNextRequestIfNeeded()
    }

    private func transitionFlow(
        to state: ProductFlowState,
        id: String? = nil,
        trigger: FlowTriggerSource? = nil,
        textLength: Int = 0,
        transcriptionInsertGate: TranscriptionInsertGate? = nil,
        gatedTranscriptionFeedback: GatedTranscriptionFeedback? = nil,
        blockedReason: String? = nil,
        error: String? = nil,
        recordingDurationMs: Int? = nil,
        recordingFilePath: String? = nil,
        microphonePermissionStatus: MicrophonePermissionStatus? = nil,
        requestedMicrophonePermission: Bool = false,
        localUserFeedback: LocalUserFeedback? = nil
    ) {
        let snapshot = ProductFlowSnapshot(
            id: id,
            state: state,
            trigger: trigger,
            timestamp: isoTimestamp(),
            textLength: textLength,
            transcriptionInsertGate: transcriptionInsertGate,
            gatedTranscriptionFeedback: gatedTranscriptionFeedback,
            blockedReason: blockedReason,
            error: error,
            recordingDurationMs: recordingDurationMs,
            recordingFilePath: recordingFilePath,
            microphonePermissionStatus: microphonePermissionStatus ?? currentMicrophonePermissionStatus(),
            requestedMicrophonePermission: requestedMicrophonePermission,
            localUserFeedback: localUserFeedback
        )
        flowSnapshot = snapshot

        if let id, let trigger {
            let event = ProductFlowEvent(
                id: id,
                state: state,
                trigger: trigger,
                timestamp: snapshot.timestamp,
                textLength: textLength,
                transcriptionInsertGate: transcriptionInsertGate,
                gatedTranscriptionFeedback: gatedTranscriptionFeedback,
                blockedReason: blockedReason,
                error: error,
                recordingDurationMs: recordingDurationMs,
                recordingFilePath: recordingFilePath,
                microphonePermissionStatus: snapshot.microphonePermissionStatus,
                requestedMicrophonePermission: requestedMicrophonePermission,
                localUserFeedback: localUserFeedback
            )
            try? appendJSONLine(event, to: paths.flowEventsLogFile)
        }

        try? writeState(running: true)
    }

    private func logHotKeyRecordingEvent(
        flowID: String?,
        event: String,
        state: ProductFlowState? = nil,
        detail: String?
    ) {
        let resolvedState = state ?? flowSnapshot.state
        let record = HotKeyRecordingLogEvent(
            timestamp: isoTimestamp(),
            flowID: flowID,
            event: event,
            state: resolvedState,
            detail: detail
        )
        recordingLogQueue.sync {
            try? appendJSONLine(record, to: paths.recordingPrototypeLogFile)
        }
    }

    private func prepareRuntime() throws {
        try ensureDirectory(paths.runtimeDir)
        try ensureDirectory(paths.requestsDir)
        try ensureDirectory(paths.responsesDir)
        try ensureDirectory(paths.logsDir)
        try ensureDirectory(paths.recordingsDir)
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
            lastTranscriptionInsertGate: lastTranscriptionInsertGate,
            lastGatedTranscriptionFeedback: lastGatedTranscriptionFeedback,
            lastRequestedMicrophonePermission: lastRequestedMicrophonePermission,
            lastLocalUserFeedback: lastLocalUserFeedback,
            lastBlockedReason: lastBlockedReason,
            lastError: lastError,
            microphonePermissionStatus: currentMicrophonePermissionStatus(),
            hotKeyInteractionModel: .pressAndHold,
            activeRecordingID: activeRecordingSession?.flowID,
            lastRecording: lastRecording,
            lastTranscription: lastTranscription,
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
            case .recordAudio:
                throw ProductRuntimeError.invalidRequest("recordAudio is reserved for the global hotkey flow.")
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
                microphonePermissionStatus: currentMicrophonePermissionStatus(),
                requestedMicrophonePermission: false,
                promptAccessibility: false,
                blockedReason: nil,
                settleDelayMs: defaults.settle,
                pasteDelayMs: defaults.paste,
                restoreClipboard: false,
                restoreDelayMs: defaults.restore,
                textLength: 0,
                transcriptionInsertGate: nil,
                gatedTranscriptionFeedback: nil,
                hotKeyInteractionModel: nil,
                insertRoute: nil,
                insertSource: nil,
                focusAtReceipt: captureFocusSnapshot(isTrusted: false),
                focusBeforePaste: nil,
                focusAfterPaste: nil,
                focusAtStop: nil,
                productFrontmostAtReceipt: false,
                productFrontmostBeforePaste: false,
                productFrontmostAfterPaste: false,
                originalPasteboard: nil,
                syntheticPastePosted: false,
                clipboardRestored: false,
                recordingStartedAt: nil,
                recordingStoppedAt: nil,
                recordingArtifact: nil,
                transcriptionArtifact: nil,
                transcribingPlaceholder: false,
                localUserFeedback: nil,
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
            microphonePermissionStatus: currentMicrophonePermissionStatus(),
            requestedMicrophonePermission: false,
            promptAccessibility: request.promptAccessibility,
            blockedReason: blockedReason,
            settleDelayMs: request.settleDelayMs ?? defaults.settle,
            pasteDelayMs: request.pasteDelayMs ?? defaults.paste,
            restoreClipboard: request.restoreClipboard,
            restoreDelayMs: request.restoreDelayMs ?? defaults.restore,
            textLength: request.text?.count ?? 0,
            transcriptionInsertGate: nil,
            gatedTranscriptionFeedback: nil,
            hotKeyInteractionModel: .pressAndHold,
            insertRoute: nil,
            insertSource: nil,
            focusAtReceipt: focusAtReceipt,
            focusBeforePaste: focusAtReceipt,
            focusAfterPaste: focusAtReceipt,
            focusAtStop: nil,
            productFrontmostAtReceipt: isProductFrontmost(focusAtReceipt),
            productFrontmostBeforePaste: isProductFrontmost(focusAtReceipt),
            productFrontmostAfterPaste: isProductFrontmost(focusAtReceipt),
            originalPasteboard: nil,
            syntheticPastePosted: false,
            clipboardRestored: false,
            recordingStartedAt: nil,
            recordingStoppedAt: nil,
            recordingArtifact: nil,
            transcriptionArtifact: nil,
            transcribingPlaceholder: false,
            localUserFeedback: nil,
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
                microphonePermissionStatus: currentMicrophonePermissionStatus(),
                requestedMicrophonePermission: false,
                promptAccessibility: request.promptAccessibility,
                blockedReason: ProductRuntimeError.accessibilityDenied.description,
                settleDelayMs: settleDelayMs,
                pasteDelayMs: pasteDelayMs,
                restoreClipboard: request.restoreClipboard,
                restoreDelayMs: restoreDelayMs,
                textLength: text?.count ?? 0,
                transcriptionInsertGate: nil,
                gatedTranscriptionFeedback: nil,
                hotKeyInteractionModel: nil,
                insertRoute: .pasteboardCommandV,
                insertSource: source,
                focusAtReceipt: focusAtReceipt,
                focusBeforePaste: focusAtReceipt,
                focusAfterPaste: focusAtReceipt,
                focusAtStop: nil,
                productFrontmostAtReceipt: isProductFrontmost(focusAtReceipt),
                productFrontmostBeforePaste: isProductFrontmost(focusAtReceipt),
                productFrontmostAfterPaste: isProductFrontmost(focusAtReceipt),
                originalPasteboard: nil,
                syntheticPastePosted: false,
                clipboardRestored: false,
                recordingStartedAt: nil,
                recordingStoppedAt: nil,
                recordingArtifact: nil,
                transcriptionArtifact: nil,
                transcribingPlaceholder: false,
                localUserFeedback: presentsBlockedUI ? .blockedPanel : .systemBeep,
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
                microphonePermissionStatus: currentMicrophonePermissionStatus(),
                requestedMicrophonePermission: false,
                promptAccessibility: request.promptAccessibility,
                blockedReason: nil,
                settleDelayMs: settleDelayMs,
                pasteDelayMs: pasteDelayMs,
                restoreClipboard: request.restoreClipboard,
                restoreDelayMs: restoreDelayMs,
                textLength: text.count,
                transcriptionInsertGate: nil,
                gatedTranscriptionFeedback: nil,
                hotKeyInteractionModel: nil,
                insertRoute: .pasteboardCommandV,
                insertSource: source,
                focusAtReceipt: focusAtReceipt,
                focusBeforePaste: focusBeforePaste,
                focusAfterPaste: focusAfterFailure,
                focusAtStop: nil,
                productFrontmostAtReceipt: isProductFrontmost(focusAtReceipt),
                productFrontmostBeforePaste: isProductFrontmost(focusBeforePaste),
                productFrontmostAfterPaste: isProductFrontmost(focusAfterFailure),
                originalPasteboard: originalPasteboardMetadata,
                syntheticPastePosted: false,
                clipboardRestored: false,
                recordingStartedAt: nil,
                recordingStoppedAt: nil,
                recordingArtifact: nil,
                transcriptionArtifact: nil,
                transcribingPlaceholder: false,
                localUserFeedback: nil,
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
            microphonePermissionStatus: currentMicrophonePermissionStatus(),
            requestedMicrophonePermission: false,
            promptAccessibility: request.promptAccessibility,
            blockedReason: nil,
            settleDelayMs: settleDelayMs,
            pasteDelayMs: pasteDelayMs,
            restoreClipboard: request.restoreClipboard,
            restoreDelayMs: restoreDelayMs,
            textLength: text.count,
            transcriptionInsertGate: nil,
            gatedTranscriptionFeedback: nil,
            hotKeyInteractionModel: nil,
            insertRoute: .pasteboardCommandV,
            insertSource: source,
            focusAtReceipt: focusAtReceipt,
            focusBeforePaste: focusBeforePaste,
            focusAfterPaste: focusAfterPaste,
            focusAtStop: nil,
            productFrontmostAtReceipt: isProductFrontmost(focusAtReceipt),
            productFrontmostBeforePaste: isProductFrontmost(focusBeforePaste),
            productFrontmostAfterPaste: isProductFrontmost(focusAfterPaste),
            originalPasteboard: originalPasteboardMetadata,
            syntheticPastePosted: true,
            clipboardRestored: originalPasteboardSnapshot != nil,
            recordingStartedAt: nil,
            recordingStoppedAt: nil,
            recordingArtifact: nil,
            transcriptionArtifact: nil,
            transcribingPlaceholder: false,
            localUserFeedback: nil,
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
            microphonePermissionStatus: currentMicrophonePermissionStatus(),
            requestedMicrophonePermission: false,
            promptAccessibility: request.promptAccessibility,
            blockedReason: nil,
            settleDelayMs: request.settleDelayMs ?? defaults.settle,
            pasteDelayMs: request.pasteDelayMs ?? defaults.paste,
            restoreClipboard: request.restoreClipboard,
            restoreDelayMs: request.restoreDelayMs ?? defaults.restore,
            textLength: 0,
            transcriptionInsertGate: nil,
            gatedTranscriptionFeedback: nil,
            hotKeyInteractionModel: nil,
            insertRoute: nil,
            insertSource: nil,
            focusAtReceipt: focus,
            focusBeforePaste: focus,
            focusAfterPaste: focus,
            focusAtStop: focus,
            productFrontmostAtReceipt: isProductFrontmost(focus),
            productFrontmostBeforePaste: isProductFrontmost(focus),
            productFrontmostAfterPaste: isProductFrontmost(focus),
            originalPasteboard: nil,
            syntheticPastePosted: false,
            clipboardRestored: false,
            recordingStartedAt: nil,
            recordingStoppedAt: nil,
            recordingArtifact: nil,
            transcriptionArtifact: nil,
            transcribingPlaceholder: false,
            localUserFeedback: nil,
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
        lastTranscriptionInsertGate = response.transcriptionInsertGate
        lastGatedTranscriptionFeedback = response.gatedTranscriptionFeedback
        lastRequestedMicrophonePermission = response.requestedMicrophonePermission
        lastLocalUserFeedback = response.localUserFeedback
        lastBlockedReason = response.blockedReason
        lastError = response.error
        if let recordingArtifact = response.recordingArtifact {
            lastRecording = recordingArtifact
        }
        if let transcriptionArtifact = response.transcriptionArtifact {
            lastTranscription = transcriptionArtifact
        }

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
            let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "PushWrite"
            self.presentFeedbackPanel(
                windowTitle: "PushWrite setup required",
                title: "Accessibility access required",
                message: "\(bundleName) cannot insert text until Accessibility is enabled for this app in System Settings > Privacy & Security > Accessibility.\n\n\(ProductRuntimeError.accessibilityDenied.description)",
                primaryButtonTitle: "Open System Settings",
                dismissButtonTitle: "Not Now",
                onPrimaryAction: { [weak self] in
                    self?.openAccessibilitySettings()
                }
            )
        }
    }

    private func presentFeedbackPanel(
        windowTitle: String,
        title: String,
        message: String,
        primaryButtonTitle: String?,
        dismissButtonTitle: String,
        onPrimaryAction: (() -> Void)?
    ) {
        DispatchQueue.main.async {
            if self.blockedWindowController != nil {
                return
            }

            NSApp.setActivationPolicy(.accessory)
            let controller = ProductFeedbackWindowController(
                windowTitle: windowTitle,
                title: title,
                message: message,
                primaryButtonTitle: primaryButtonTitle,
                dismissButtonTitle: dismissButtonTitle,
                onPrimaryAction: onPrimaryAction,
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
            try? self.writeState(running: true)
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

    private func openMicrophoneSettings() {
        guard let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") else {
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
runtimeMicrophoneDeniedOverride = launchOptions.forceMicrophoneDenied
runtimeNoMicrophoneDeviceOverride = launchOptions.forceNoMicrophoneDevice
runtimeMicrophoneRecorderStartFailureOverride = launchOptions.forceMicrophoneRecorderStartFailure
runtimeSyntheticPasteFailureOverride = launchOptions.forceSyntheticPasteFailure
runtimeForcedMicrophonePermissionStatus = launchOptions.forcedMicrophonePermissionStatus
runtimeForcedMicrophonePermissionRequestResult = launchOptions.forcedMicrophonePermissionRequestResult
runtimeCurrentMicrophonePermissionStatusOverride = launchOptions.forcedMicrophonePermissionStatus

let app = NSApplication.shared
let delegate = PushWriteAppDelegate(launchOptions: launchOptions)
app.delegate = delegate
app.run()
