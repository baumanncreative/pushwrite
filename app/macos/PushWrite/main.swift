import AppKit
import ApplicationServices
import AVFoundation
import Carbon
import CryptoKit
import Darwin
import Foundation

private extension Notification.Name {
    static let pushWriteShowStatus = Notification.Name("ch.baumanncreative.pushwrite.show-status")
    static let pushWriteInstanceAcknowledged = Notification.Name("ch.baumanncreative.pushwrite.instance-acknowledged")
}

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
    case accessibilitySelectedText
    case accessibilityValueReplacement
    case unicodeKeyboardEvents
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
    let localTextCLIPath: String?
    let localTextModelPath: String?
    let inputLanguage: String
    let outputLanguage: String
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
    let editable: Bool?
    let protectedContent: Bool
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
    let focusElement: AXUIElement?
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
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else {
        return .gated(reason: .whitespaceOnlyTranscriptionText)
    }
    guard trimmedText.unicodeScalars.filter({ !$0.properties.isWhitespace }).count >= 2 else {
        return .gated(reason: .tooShort)
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
    let cliResolutionSource: String
    let modelPath: String
    let modelResolutionSource: String
    let modelName: String
    let language: String
    let configuredInputLanguage: String
    let outputLanguage: String
    let rawTextLength: Int
    let localTransformationApplied: Bool
    let localTransformationRuntime: String?
    let localTransformationModel: String?
    let localTransformationDurationMs: Int?
    let status: TranscriptionStatus
    let text: String
    let textLength: Int
    let startedAt: String
    let completedAt: String
    let durationMs: Int
    let error: String?
}

struct LocalTextTransformationResult {
    let text: String
    let runtimePath: String
    let modelPath: String
    let durationMs: Int
}

struct WhisperCLIResult {
    let text: String
    let language: String?
}

final class ThreadSafeDataBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func store(_ newData: Data) {
        lock.lock()
        data = newData
        lock.unlock()
    }

    func load() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }
}

#if PUSHWRITE_QA_CONTROL_INTERFACE
typealias PushWriteAudioRecorder = AVAudioRecorder

private extension AVAudioRecorder {
    var normalizedLevel: Double {
        updateMeters()
        let decibels = peakPower(forChannel: 0)
        guard decibels.isFinite else { return 0 }
        return max(0, min(1, Double((decibels + 50) / 50)))
    }
}
#else
final class PushWriteAudioRecorder {
    private let engine = AVAudioEngine()
    private let sampleLock = NSLock()
    private var monoSamples: [Float] = []
    private var sourceSampleRate: Double = 0
    private var recordingStartedAt: Date?

    init(url _: URL, settings _: [String: Any]) throws {}

    var currentTime: TimeInterval {
        guard let recordingStartedAt else {
            return 0
        }
        return max(Date().timeIntervalSince(recordingStartedAt), 0)
    }

    var normalizedLevel: Double {
        sampleLock.lock()
        defer { sampleLock.unlock() }
        guard !monoSamples.isEmpty else { return 0 }
        let sampleCount = min(monoSamples.count, 2_048)
        let recentSamples = monoSamples.suffix(sampleCount)
        let meanSquare = recentSamples.reduce(0.0) { partial, sample in
            partial + Double(sample * sample)
        } / Double(sampleCount)
        return max(0, min(sqrt(meanSquare) * 7, 1))
    }

    func prepareToRecord() {}

    func record() -> Bool {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            return false
        }

        sourceSampleRate = format.sampleRate
        input.installTap(onBus: 0, bufferSize: 4_096, format: format) { [weak self] buffer, _ in
            guard
                let self,
                let channels = buffer.floatChannelData,
                buffer.frameLength > 0
            else {
                return
            }
            let frameCount = Int(buffer.frameLength)
            let channelCount = Int(buffer.format.channelCount)
            var captured = [Float]()
            captured.reserveCapacity(frameCount)
            for frame in 0..<frameCount {
                var mixed: Float = 0
                for channel in 0..<channelCount {
                    mixed += channels[channel][frame]
                }
                captured.append(mixed / Float(channelCount))
            }
            self.sampleLock.lock()
            self.monoSamples.append(contentsOf: captured)
            self.sampleLock.unlock()
        }

        do {
            engine.prepare()
            try engine.start()
            recordingStartedAt = Date()
            return true
        } catch {
            input.removeTap(onBus: 0)
            return false
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }

    func wavData() -> Data {
        sampleLock.lock()
        let samples = monoSamples
        let sampleRate = sourceSampleRate
        sampleLock.unlock()

        guard sampleRate > 0, !samples.isEmpty else {
            return Self.wavData(pcm16Samples: [], sampleRate: 16_000)
        }
        let targetRate = 16_000.0
        let outputCount = max(Int((Double(samples.count) * targetRate / sampleRate).rounded()), 0)
        var pcm16 = [Int16]()
        pcm16.reserveCapacity(outputCount)
        for outputIndex in 0..<outputCount {
            let sourcePosition = Double(outputIndex) * sampleRate / targetRate
            let lowerIndex = min(Int(sourcePosition), samples.count - 1)
            let upperIndex = min(lowerIndex + 1, samples.count - 1)
            let fraction = Float(sourcePosition - Double(lowerIndex))
            let interpolated = samples[lowerIndex] + ((samples[upperIndex] - samples[lowerIndex]) * fraction)
            let clamped = max(-1.0, min(1.0, interpolated))
            pcm16.append(Int16((clamped * Float(Int16.max)).rounded()))
        }
        return Self.wavData(pcm16Samples: pcm16, sampleRate: 16_000)
    }

    private static func wavData(pcm16Samples: [Int16], sampleRate: UInt32) -> Data {
        let dataByteCount = UInt32(pcm16Samples.count * MemoryLayout<Int16>.size)
        var data = Data()
        data.append(contentsOf: Array("RIFF".utf8))
        data.appendLittleEndian(UInt32(36) + dataByteCount)
        data.append(contentsOf: Array("WAVEfmt ".utf8))
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(sampleRate)
        data.appendLittleEndian(sampleRate * UInt32(MemoryLayout<Int16>.size))
        data.appendLittleEndian(UInt16(MemoryLayout<Int16>.size))
        data.appendLittleEndian(UInt16(16))
        data.append(contentsOf: Array("data".utf8))
        data.appendLittleEndian(dataByteCount)
        for sample in pcm16Samples {
            data.appendLittleEndian(sample)
        }
        return data
    }
}

private extension Data {
    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { bytes in
            append(contentsOf: bytes)
        }
    }
}
#endif

enum WhisperResourceSource: String {
    case bundledProductResource
    case explicitOverride
    case repoFallback
}

struct ResolvedWhisperPath {
    let path: String
    let source: WhisperResourceSource
}

struct ResolvedWhisperRuntime {
    let cli: ResolvedWhisperPath
    let model: ResolvedWhisperPath
}

let bundledWhisperModelSHA256 = "d75795ecff3f83b5faa89d1900604ad8c780abd5739fae406de19f23ecd98ad1"
let bundledWhisperModelSize: UInt64 = 1_081_140_203
let bundledLocalTextModelSHA256 = "183715c435899236895da3869489cc30ac241476b4971a20285b1a462818a5b4"
let bundledLocalTextModelSize: UInt64 = 986_048_512

struct ResolvedLocalTextRuntime {
    let cli: ResolvedWhisperPath
    let model: ResolvedWhisperPath
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
    case protectedTextField
    case nonEditableTarget
    case textInsertionFailed(String)
    case missingWhisperCLI(String)
    case missingWhisperModel(String)
    case invalidWhisperModel(String)
    case missingLocalTextCLI(String)
    case missingLocalTextModel(String)
    case invalidLocalTextModel(String)
    case localTextTransformationFailed(String)
    case invalidRuntimeDirectory(String)
    case instanceLockFailed(String)
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
            return "PushWrite benötigt Zugriff auf Bedienungshilfen, um Text an der Einfügemarke einzusetzen."
        case .noMicrophoneDevice:
            return "No audio input device is available for PushWrite recording."
        case let .microphoneRecorderCreationFailed(message):
            return "PushWrite could not create a microphone recorder: \(message)"
        case .microphoneRecordingStartFailed:
            return "PushWrite could not start microphone recording."
        case .eventSourceUnavailable:
            return "Could not create a CGEventSource for keyboard events."
        case .eventCreationFailed:
            return "Could not create one or more keyboard events for text insertion."
        case .protectedTextField:
            return "PushWrite does not insert text into password or other protected fields."
        case .nonEditableTarget:
            return "The current target is not an editable text field."
        case let .textInsertionFailed(message):
            return "PushWrite could not insert text at the current cursor position: \(message)"
        case let .missingWhisperCLI(path):
            return "whisper.cpp CLI is missing at \(path)."
        case let .missingWhisperModel(path):
            return "whisper.cpp model is missing at \(path)."
        case let .invalidWhisperModel(message):
            return "The bundled whisper.cpp model failed its integrity check: \(message)"
        case let .missingLocalTextCLI(path):
            return "The local text-processing runtime is missing at \(path)."
        case let .missingLocalTextModel(path):
            return "The local text-processing model is missing at \(path)."
        case let .invalidLocalTextModel(message):
            return "The bundled local text-processing model failed its integrity check: \(message)"
        case let .localTextTransformationFailed(message):
            return "Local transcript normalization or translation failed: \(message)"
        case let .invalidRuntimeDirectory(path):
            return "The configured runtime directory is not an allowed PushWrite runtime location: \(path)"
        case let .instanceLockFailed(message):
            return "PushWrite could not establish its single-instance lock: \(message)"
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
    let focusElementAtStart: AXUIElement?
    let recorder: PushWriteAudioRecorder
    let requestedMicrophonePermission: Bool
    var inMemoryWAVData: Data?

    init(
        flowID: String,
        fileURL: URL,
        metadataURL: URL,
        startedAt: Date,
        startedAtTimestamp: String,
        focusAtStart: FocusSnapshot?,
        focusElementAtStart: AXUIElement?,
        recorder: PushWriteAudioRecorder,
        requestedMicrophonePermission: Bool
    ) {
        self.flowID = flowID
        self.fileURL = fileURL
        self.metadataURL = metadataURL
        self.startedAt = startedAt
        self.startedAtTimestamp = startedAtTimestamp
        self.focusAtStart = focusAtStart
        self.focusElementAtStart = focusElementAtStart
        self.recorder = recorder
        self.requestedMicrophonePermission = requestedMicrophonePermission
    }
}

#if PUSHWRITE_QA_CONTROL_INTERFACE
func parseLaunchOptions(arguments: [String]) throws -> LaunchOptions {
    let controlInterfaceEnabled =
        ProcessInfo.processInfo.environment["PUSHWRITE_ENABLE_CONTROL_INTERFACE"] == "1"
    var runtimeDir = ProcessInfo.processInfo.environment["PUSHWRITE_PRODUCT_RUNTIME_DIR"] ?? ""
    var simulatedTranscriptionText = defaultSimulatedTranscriptionText()
    var whisperCLIPath = ProcessInfo.processInfo.environment["PUSHWRITE_WHISPER_CLI_PATH"]
    var whisperModelPath = ProcessInfo.processInfo.environment["PUSHWRITE_WHISPER_MODEL_PATH"]
    var whisperLanguage = ProcessInfo.processInfo.environment["PUSHWRITE_WHISPER_LANGUAGE"]
        ?? "auto"
    var localTextCLIPath = ProcessInfo.processInfo.environment["PUSHWRITE_LOCAL_TEXT_CLI_PATH"]
    var localTextModelPath = ProcessInfo.processInfo.environment["PUSHWRITE_LOCAL_TEXT_MODEL_PATH"]
    var inputLanguage = ProcessInfo.processInfo.environment["PUSHWRITE_INPUT_LANGUAGE"]
        ?? ProcessInfo.processInfo.environment["PUSHWRITE_WHISPER_LANGUAGE"]
        ?? UserDefaults.standard.string(forKey: "inputLanguage")
        ?? "auto"
    var outputLanguage = ProcessInfo.processInfo.environment["PUSHWRITE_OUTPUT_LANGUAGE"]
        ?? UserDefaults.standard.string(forKey: "outputLanguage")
        ?? UserDefaults.standard.string(forKey: "transcriptionLanguage")
        ?? "system"
    var transcriptionFixtureWAVPath = ProcessInfo.processInfo.environment["PUSHWRITE_TRANSCRIPTION_FIXTURE_WAV"]
    var forceAccessibilityBlocked =
        ProcessInfo.processInfo.environment["PUSHWRITE_FORCE_ACCESSIBILITY_BLOCKED"] == "1"
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
            if inputLanguage == "auto" {
                inputLanguage = whisperLanguage
            }
        case "--local-text-cli-path":
            localTextCLIPath = try requireValue(for: argument)
        case "--local-text-model-path":
            localTextModelPath = try requireValue(for: argument)
        case "--input-language":
            inputLanguage = try requireValue(for: argument)
        case "--output-language":
            outputLanguage = try requireValue(for: argument)
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

    let productionRuntimeDir =
        "\(FileManager.default.homeDirectoryForCurrentUser.path)/Library/Application Support/PushWrite/runtime"
    if runtimeDir.isEmpty {
        runtimeDir = productionRuntimeDir
    } else {
        let canonicalRuntimeDir = canonicalPathResolvingExistingAncestors(runtimeDir)
        let canonicalWorkingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path
        let isSafeControlRuntime =
            canonicalRuntimeDir.hasPrefix("/private/tmp/")
            || canonicalRuntimeDir.hasPrefix("/tmp/")
            || canonicalRuntimeDir.hasPrefix("\(canonicalWorkingDirectory)/build/")
        guard controlInterfaceEnabled && isSafeControlRuntime else {
            throw ProductRuntimeError.invalidRuntimeDirectory(canonicalRuntimeDir)
        }
        runtimeDir = canonicalRuntimeDir
    }

    if !controlInterfaceEnabled {
        simulatedTranscriptionText = "PushWrite 002E simulated transcription."
        transcriptionFixtureWAVPath = nil
        forceAccessibilityBlocked = false
        forceAccessibilityTrusted = false
        forceMicrophoneDenied = false
        forceNoMicrophoneDevice = false
        forceMicrophoneRecorderStartFailure = false
        forceSyntheticPasteFailure = false
        forcedMicrophonePermissionStatus = nil
        forcedMicrophonePermissionRequestResult = nil
    }

    return LaunchOptions(
        runtimeDir: runtimeDir,
        simulatedTranscriptionText: simulatedTranscriptionText,
        whisperCLIPath: whisperCLIPath,
        whisperModelPath: whisperModelPath,
        whisperLanguage: whisperLanguage,
        localTextCLIPath: localTextCLIPath,
        localTextModelPath: localTextModelPath,
        inputLanguage: inputLanguage,
        outputLanguage: outputLanguage,
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
#else
func parseLaunchOptions(arguments: [String]) throws -> LaunchOptions {
    guard arguments.isEmpty else {
        throw ProductRuntimeError.unknownArgument(arguments[0])
    }

    let inputLanguage = UserDefaults.standard.string(forKey: "inputLanguage") ?? "auto"
    let outputLanguage = UserDefaults.standard.string(forKey: "outputLanguage")
        ?? UserDefaults.standard.string(forKey: "transcriptionLanguage")
        ?? "system"
    let runtimeDir =
        "\(FileManager.default.homeDirectoryForCurrentUser.path)/Library/Application Support/PushWrite/runtime"

    return LaunchOptions(
        runtimeDir: runtimeDir,
        simulatedTranscriptionText: "PushWrite simulated transcription.",
        whisperCLIPath: nil,
        whisperModelPath: nil,
        whisperLanguage: inputLanguage,
        localTextCLIPath: nil,
        localTextModelPath: nil,
        inputLanguage: inputLanguage,
        outputLanguage: outputLanguage,
        transcriptionFixtureWAVPath: nil,
        forceAccessibilityBlocked: false,
        forceAccessibilityTrusted: false,
        forceMicrophoneDenied: false,
        forceNoMicrophoneDevice: false,
        forceMicrophoneRecorderStartFailure: false,
        forceSyntheticPasteFailure: false,
        forcedMicrophonePermissionStatus: nil,
        forcedMicrophonePermissionRequestResult: nil
    )
}
#endif

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
#if PUSHWRITE_QA_CONTROL_INTERFACE
    let override = ProcessInfo.processInfo.environment["PUSHWRITE_SIMULATED_TRANSCRIPTION_TEXT"]?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    if let override, !override.isEmpty {
        return override
    }
#endif
    return "PushWrite 002E simulated transcription."
}

struct RecordingFileDetails {
    let format: String
    let sampleRateHz: Double
    let channelCount: Int
    let durationMs: Int
    let fileSizeBytes: UInt64
}

func bundledWhisperCLIPath() -> String {
    guard let resourceURL = Bundle.main.resourceURL else {
        return ""
    }
    return resourceURL
        .appendingPathComponent("whisper", isDirectory: true)
        .appendingPathComponent("bin", isDirectory: true)
        .appendingPathComponent("whisper-cli", isDirectory: false)
        .path
}

func bundledWhisperModelPath() -> String {
    guard let resourceURL = Bundle.main.resourceURL else {
        return ""
    }
    return resourceURL
        .appendingPathComponent("whisper", isDirectory: true)
        .appendingPathComponent("models", isDirectory: true)
        .appendingPathComponent("ggml-large-v3-q5_0.bin", isDirectory: false)
        .path
}

func bundledLocalTextCLIPath() -> String {
    guard let resourceURL = Bundle.main.resourceURL else {
        return ""
    }
    return resourceURL
        .appendingPathComponent("local-text", isDirectory: true)
        .appendingPathComponent("bin", isDirectory: true)
        .appendingPathComponent("llama-completion", isDirectory: false)
        .path
}

func bundledLocalTextModelPath() -> String {
    guard let resourceURL = Bundle.main.resourceURL else {
        return ""
    }
    return resourceURL
        .appendingPathComponent("local-text", isDirectory: true)
        .appendingPathComponent("models", isDirectory: true)
        .appendingPathComponent("qwen2.5-1.5b-instruct-q4_k_m.gguf", isDirectory: false)
        .path
}

func repoFallbackLocalTextCLIPath() -> String {
    Bundle.main.bundleURL
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("build", isDirectory: true)
        .appendingPathComponent("llamacpp", isDirectory: true)
        .appendingPathComponent("build", isDirectory: true)
        .appendingPathComponent("bin", isDirectory: true)
        .appendingPathComponent("llama-completion", isDirectory: false)
        .path
}

func repoFallbackLocalTextModelPath() -> String {
    Bundle.main.bundleURL
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("models", isDirectory: true)
        .appendingPathComponent("qwen2.5-1.5b-instruct-q4_k_m.gguf", isDirectory: false)
        .path
}

func repoFallbackWhisperCLIPath() -> String {
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

func repoFallbackWhisperModelPath() -> String {
    Bundle.main.bundleURL
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("models", isDirectory: true)
        .appendingPathComponent("ggml-large-v3-q5_0.bin", isDirectory: false)
        .path
}

func resolveWhisperCLIPath(launchOptions: LaunchOptions) throws -> ResolvedWhisperPath {
    let allowTestOverride = testRuntimeOverridesEnabled()
    let explicitPath = launchOptions.whisperCLIPath?.trimmingCharacters(in: .whitespacesAndNewlines)
    if allowTestOverride,
       let explicitPath,
       !explicitPath.isEmpty {
        guard FileManager.default.isExecutableFile(atPath: explicitPath) else {
            throw ProductRuntimeError.missingWhisperCLI(explicitPath)
        }
        return ResolvedWhisperPath(path: explicitPath, source: .explicitOverride)
    }

    let bundledPath = bundledWhisperCLIPath()
    if !bundledPath.isEmpty, FileManager.default.fileExists(atPath: bundledPath) {
        guard FileManager.default.isExecutableFile(atPath: bundledPath) else {
            throw ProductRuntimeError.missingWhisperCLI(
                "Bundled whisper-cli exists but is not executable: \(bundledPath)"
            )
        }
        return ResolvedWhisperPath(path: bundledPath, source: .bundledProductResource)
    }

    let repoFallbackPath = repoFallbackWhisperCLIPath()
    if allowTestOverride, qaRepoWhisperFallbackEnabled() {
        if FileManager.default.fileExists(atPath: repoFallbackPath) {
            guard FileManager.default.isExecutableFile(atPath: repoFallbackPath) else {
                throw ProductRuntimeError.missingWhisperCLI(
                    "Repo fallback whisper-cli exists but is not executable: \(repoFallbackPath)"
                )
            }
            return ResolvedWhisperPath(path: repoFallbackPath, source: .repoFallback)
        }
    }

    throw ProductRuntimeError.missingWhisperCLI(
        "Could not resolve whisper-cli at the bundled product path \(bundledPath)."
    )
}

func resolveWhisperModelPath(launchOptions: LaunchOptions) throws -> ResolvedWhisperPath {
    let allowTestOverride = testRuntimeOverridesEnabled()
    let explicitPath = launchOptions.whisperModelPath?.trimmingCharacters(in: .whitespacesAndNewlines)
    if allowTestOverride,
       let explicitPath,
       !explicitPath.isEmpty {
        guard FileManager.default.fileExists(atPath: explicitPath) else {
            throw ProductRuntimeError.missingWhisperModel(explicitPath)
        }
        return ResolvedWhisperPath(path: explicitPath, source: .explicitOverride)
    }

    let bundledPath = bundledWhisperModelPath()
    if !bundledPath.isEmpty, FileManager.default.fileExists(atPath: bundledPath) {
        return ResolvedWhisperPath(path: bundledPath, source: .bundledProductResource)
    }

    let repoFallbackPath = repoFallbackWhisperModelPath()
    if allowTestOverride, qaRepoWhisperFallbackEnabled() {
        if FileManager.default.fileExists(atPath: repoFallbackPath) {
            return ResolvedWhisperPath(path: repoFallbackPath, source: .repoFallback)
        }
    }

    throw ProductRuntimeError.missingWhisperModel(
        "Could not resolve the whisper model at the bundled product path \(bundledPath)."
    )
}

func resolveWhisperRuntime(launchOptions: LaunchOptions) throws -> ResolvedWhisperRuntime {
    let cli = try resolveWhisperCLIPath(launchOptions: launchOptions)
    let model = try resolveWhisperModelPath(launchOptions: launchOptions)
    if model.source == .bundledProductResource {
        try verifyBundledWhisperModel(at: model.path)
    }
    return ResolvedWhisperRuntime(cli: cli, model: model)
}

func verifyBundledWhisperModel(at path: String) throws {
    let attributes = try FileManager.default.attributesOfItem(atPath: path)
    let size = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
    guard size == bundledWhisperModelSize else {
        throw ProductRuntimeError.invalidWhisperModel("unexpected size \(size) bytes")
    }

    let digest = try sha256OfFile(at: path)
    guard digest == bundledWhisperModelSHA256 else {
        throw ProductRuntimeError.invalidWhisperModel("SHA-256 mismatch")
    }
}

func resolveLocalTextRuntime(launchOptions: LaunchOptions) throws -> ResolvedLocalTextRuntime {
    let allowTestOverride = testRuntimeOverridesEnabled()
    let explicitCLI = optionalNonEmptyTrimmed(launchOptions.localTextCLIPath)
    let explicitModel = optionalNonEmptyTrimmed(launchOptions.localTextModelPath)

    let cli: ResolvedWhisperPath
    if allowTestOverride, let explicitCLI {
        guard FileManager.default.isExecutableFile(atPath: explicitCLI) else {
            throw ProductRuntimeError.missingLocalTextCLI(explicitCLI)
        }
        cli = ResolvedWhisperPath(path: explicitCLI, source: .explicitOverride)
    } else if FileManager.default.isExecutableFile(atPath: bundledLocalTextCLIPath()) {
        cli = ResolvedWhisperPath(path: bundledLocalTextCLIPath(), source: .bundledProductResource)
    } else if allowTestOverride,
              qaRepoLocalTextFallbackEnabled(),
              FileManager.default.isExecutableFile(atPath: repoFallbackLocalTextCLIPath()) {
        cli = ResolvedWhisperPath(path: repoFallbackLocalTextCLIPath(), source: .repoFallback)
    } else {
        throw ProductRuntimeError.missingLocalTextCLI(bundledLocalTextCLIPath())
    }

    let model: ResolvedWhisperPath
    if allowTestOverride, let explicitModel {
        guard FileManager.default.fileExists(atPath: explicitModel) else {
            throw ProductRuntimeError.missingLocalTextModel(explicitModel)
        }
        model = ResolvedWhisperPath(path: explicitModel, source: .explicitOverride)
    } else if FileManager.default.fileExists(atPath: bundledLocalTextModelPath()) {
        model = ResolvedWhisperPath(path: bundledLocalTextModelPath(), source: .bundledProductResource)
    } else if allowTestOverride,
              qaRepoLocalTextFallbackEnabled(),
              FileManager.default.fileExists(atPath: repoFallbackLocalTextModelPath()) {
        model = ResolvedWhisperPath(path: repoFallbackLocalTextModelPath(), source: .repoFallback)
    } else {
        throw ProductRuntimeError.missingLocalTextModel(bundledLocalTextModelPath())
    }

    if model.source == .bundledProductResource {
        try verifyBundledLocalTextModel(at: model.path)
    }
    return ResolvedLocalTextRuntime(cli: cli, model: model)
}

func verifyBundledLocalTextModel(at path: String) throws {
    let attributes = try FileManager.default.attributesOfItem(atPath: path)
    let size = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
    guard size == bundledLocalTextModelSize else {
        throw ProductRuntimeError.invalidLocalTextModel("unexpected size \(size) bytes")
    }
    let digest = try sha256OfFile(at: path)
    guard digest == bundledLocalTextModelSHA256 else {
        throw ProductRuntimeError.invalidLocalTextModel("SHA-256 mismatch")
    }
}

func sha256OfFile(at path: String) throws -> String {
    let handle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
    defer { try? handle.close() }
    var hasher = SHA256()
    while true {
        let data = try handle.read(upToCount: 4 * 1_024 * 1_024) ?? Data()
        if data.isEmpty { break }
        hasher.update(data: data)
    }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
}

func verifyBundledExecutable(
    at path: String,
    expectedPath: String,
    expectedSHA256: String
) throws {
    let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
    guard standardizedPath == URL(fileURLWithPath: expectedPath).standardizedFileURL.path else {
        throw ProductRuntimeError.invalidRequest("Bundled runtime path does not match its signed resource location.")
    }
    var info = stat()
    guard lstat(standardizedPath, &info) == 0 else {
        throw ProductRuntimeError.invalidRequest("Bundled runtime executable is missing, linked, or not a regular executable file.")
    }
    let actualSHA256 = try sha256OfFile(at: standardizedPath)
    guard RuntimeExecutableIntegrityPolicy.allowsExecution(
        isRegularFile: (info.st_mode & S_IFMT) == S_IFREG,
        isSymbolicLink: (info.st_mode & S_IFMT) == S_IFLNK,
        isExecutable: FileManager.default.isExecutableFile(atPath: standardizedPath),
        actualSHA256: actualSHA256,
        expectedSHA256: expectedSHA256
    ) else {
        throw ProductRuntimeError.invalidRequest("Bundled runtime executable failed its pinned SHA-256 integrity check.")
    }
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

func sanitizedChildProcessEnvironment() -> [String: String] {
    [
        "HOME": FileManager.default.homeDirectoryForCurrentUser.path,
        "TMPDIR": FileManager.default.temporaryDirectory.path,
        "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
        "LC_ALL": "C",
    ]
}

func testRuntimeOverridesEnabled() -> Bool {
#if PUSHWRITE_QA_CONTROL_INTERFACE
    ProcessInfo.processInfo.environment["PUSHWRITE_ENABLE_CONTROL_INTERFACE"] == "1"
        && ProcessInfo.processInfo.environment["PUSHWRITE_ALLOW_TEST_RUNTIME_OVERRIDE"] == "1"
#else
    false
#endif
}

func qaRepoWhisperFallbackEnabled() -> Bool {
#if PUSHWRITE_QA_CONTROL_INTERFACE
    ProcessInfo.processInfo.environment["PUSHWRITE_ALLOW_REPO_WHISPER_FALLBACK"] == "1"
#else
    false
#endif
}

func qaRepoLocalTextFallbackEnabled() -> Bool {
#if PUSHWRITE_QA_CONTROL_INTERFACE
    ProcessInfo.processInfo.environment["PUSHWRITE_ALLOW_REPO_LOCAL_TEXT_FALLBACK"] == "1"
#else
    false
#endif
}

func qaLocalTextBypassEnabled() -> Bool {
#if PUSHWRITE_QA_CONTROL_INTERFACE
    testRuntimeOverridesEnabled()
        && ProcessInfo.processInfo.environment["PUSHWRITE_BYPASS_LOCAL_TEXT_TRANSFORMATION"] == "1"
#else
    false
#endif
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

    if runtimeMicrophoneDeniedOverride {
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
    if runtimeNoMicrophoneDeviceOverride {
        return false
    }
    if #available(macOS 14.0, *) {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        return !discoverySession.devices.isEmpty
    }
    return AVCaptureDevice.default(for: .audio) != nil
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
        completion(resolvedStatus, true)
    }
}

func currentFrontmostApp() -> NSRunningApplication? {
    NSWorkspace.shared.frontmostApplication
}

func accessibilityBlockedOverrideEnabled() -> Bool {
    runtimeAccessibilityBlockedOverride
}

func isAccessibilityTrusted(prompt: Bool) -> Bool {
    if runtimeAccessibilityTrustedOverride {
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

func copyBooleanAttribute(_ name: CFString, from element: AXUIElement) -> Bool? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, name, &value)
    guard result == .success, let number = value as? NSNumber else {
        return nil
    }
    return number.boolValue
}

func copyFocusedElement(from appElement: AXUIElement) -> AXUIElement? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &value)
    guard result == .success, let focused = value else {
        return nil
    }
    return unsafeBitCast(focused, to: AXUIElement.self)
}

func copyFocusedElement(appPID: pid_t) -> AXUIElement? {
    let appElement = AXUIElementCreateApplication(appPID)
    if let focusedElement = copyFocusedElement(from: appElement) {
        return focusedElement
    }

    // Electron keeps its web accessibility tree dormant until an assistive
    // client requests it. Unsupported applications reject this attribute.
    guard AXUIElementSetAttributeValue(
        appElement,
        "AXManualAccessibility" as CFString,
        kCFBooleanTrue
    ) == .success else {
        return nil
    }
    usleep(30_000)
    return copyFocusedElement(from: appElement)
}

func copyFocusedElement(from app: NSRunningApplication) -> AXUIElement? {
    copyFocusedElement(appPID: app.processIdentifier)
}

struct FocusCapture {
    let snapshot: FocusSnapshot
    let element: AXUIElement?
}

func captureFocus(isTrusted: Bool) -> FocusCapture? {
    guard let app = currentFrontmostApp() else {
        return nil
    }

    let appSnapshot = AppSnapshot(
        name: app.localizedName,
        bundleID: app.bundleIdentifier,
        pid: app.processIdentifier
    )

    guard isTrusted, let focusedElement = copyFocusedElement(from: app) else {
        return FocusCapture(
            snapshot: FocusSnapshot(
                app: appSnapshot,
                role: nil,
                subrole: nil,
                title: nil,
                value: nil,
                editable: nil,
                protectedContent: false
            ),
            element: nil
        )
    }

    let subrole = copyStringAttribute(kAXSubroleAttribute as CFString, from: focusedElement)
    let protectedContent = InsertionTargetPolicy.isProtected(
        secureTextSubrole: subrole == (kAXSecureTextFieldSubrole as String),
        containsProtectedContent: copyBooleanAttribute(
            NSAccessibility.Attribute.containsProtectedContent.rawValue as CFString,
            from: focusedElement
        ) == true
    )

    return FocusCapture(
        snapshot: FocusSnapshot(
            app: appSnapshot,
            role: copyStringAttribute(kAXRoleAttribute as CFString, from: focusedElement),
            subrole: subrole,
            title: copyStringAttribute(kAXTitleAttribute as CFString, from: focusedElement),
            value: nil,
            editable: copyBooleanAttribute("AXEditable" as CFString, from: focusedElement),
            protectedContent: protectedContent
        ),
        element: focusedElement
    )
}

func captureFocusSnapshot(isTrusted: Bool) -> FocusSnapshot? {
    captureFocus(isTrusted: isTrusted)?.snapshot
}

func validateInsertionTarget(_ focus: FocusSnapshot?) throws {
    guard let focus else {
        throw ProductRuntimeError.textInsertionFailed("No focused target was available.")
    }
    let decision = InsertionTargetPolicy.evaluate(
        protectedContent: focus.protectedContent || focus.subrole == (kAXSecureTextFieldSubrole as String),
        editable: focus.editable
    )
    if decision == .rejectProtected {
        throw ProductRuntimeError.protectedTextField
    }
    if decision == .rejectNonEditable {
        throw ProductRuntimeError.nonEditableTarget
    }
}

func requireValidatedFocusedElement(
    _ expectedElement: AXUIElement,
    appPID: pid_t
) throws -> AXUIElement {
    guard currentFrontmostApp()?.processIdentifier == appPID,
          let currentElement = copyFocusedElement(appPID: appPID),
          CFEqual(expectedElement, currentElement) else {
        throw ProductRuntimeError.textInsertionFailed("The focused target changed before insertion.")
    }

    let subrole = copyStringAttribute(kAXSubroleAttribute as CFString, from: currentElement)
    let snapshot = FocusSnapshot(
        app: nil,
        role: copyStringAttribute(kAXRoleAttribute as CFString, from: currentElement),
        subrole: subrole,
        title: nil,
        value: nil,
        editable: copyBooleanAttribute("AXEditable" as CFString, from: currentElement),
        protectedContent: InsertionTargetPolicy.isProtected(
            secureTextSubrole: subrole == (kAXSecureTextFieldSubrole as String),
            containsProtectedContent: copyBooleanAttribute(
                NSAccessibility.Attribute.containsProtectedContent.rawValue as CFString,
                from: currentElement
            ) == true
        )
    )
    try validateInsertionTarget(snapshot)
    return currentElement
}

func copySelectedTextRange(from element: AXUIElement) -> CFRange? {
    var rangeValue: CFTypeRef?
    guard AXUIElementCopyAttributeValue(
        element,
        kAXSelectedTextRangeAttribute as CFString,
        &rangeValue
    ) == .success, let rangeValue, CFGetTypeID(rangeValue) == AXValueGetTypeID() else {
        return nil
    }
    let axValue = unsafeBitCast(rangeValue, to: AXValue.self)
    guard AXValueGetType(axValue) == .cfRange else {
        return nil
    }
    var range = CFRange()
    return AXValueGetValue(axValue, .cfRange, &range) ? range : nil
}

func setSelectedTextRange(_ range: CFRange, on element: AXUIElement) {
    var mutableRange = range
    guard let rangeValue = AXValueCreate(.cfRange, &mutableRange) else {
        return
    }
    AXUIElementSetAttributeValue(
        element,
        kAXSelectedTextRangeAttribute as CFString,
        rangeValue
    )
}

func insertWithAccessibility(
    _ text: String,
    appPID: pid_t,
    expectedElement: AXUIElement,
    allowValueReplacement: Bool
) throws -> InsertRoute? {
    let focusedElement = try requireValidatedFocusedElement(expectedElement, appPID: appPID)
    let valueBefore = copyStringAttribute(kAXValueAttribute as CFString, from: focusedElement)
    let selectedRange = copySelectedTextRange(from: focusedElement)
    let expectedValue: String?
    if let valueBefore, let selectedRange,
       selectedRange.location >= 0, selectedRange.length >= 0,
       selectedRange.location + selectedRange.length <= (valueBefore as NSString).length {
        expectedValue = (valueBefore as NSString).replacingCharacters(
            in: NSRange(location: selectedRange.location, length: selectedRange.length),
            with: text
        )
    } else {
        expectedValue = nil
    }

    var selectedTextSettable = DarwinBoolean(false)
    let selectedTextElement = try requireValidatedFocusedElement(expectedElement, appPID: appPID)
    if AXUIElementIsAttributeSettable(
        selectedTextElement,
        kAXSelectedTextAttribute as CFString,
        &selectedTextSettable
    ) == .success, selectedTextSettable.boolValue {
        let writeElement = try requireValidatedFocusedElement(expectedElement, appPID: appPID)
        guard CFEqual(selectedTextElement, writeElement) else {
            throw ProductRuntimeError.textInsertionFailed("The focused target changed before insertion.")
        }
        if AXUIElementSetAttributeValue(
            writeElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        ) == .success {
        usleep(30_000)
            let verifiedElement = try requireValidatedFocusedElement(expectedElement, appPID: appPID)
            let valueAfter = copyStringAttribute(kAXValueAttribute as CFString, from: verifiedElement)
            if let expectedValue, valueAfter == expectedValue {
                return .accessibilitySelectedText
            }
            if expectedValue == nil, valueBefore != nil, valueAfter != valueBefore {
                return .accessibilitySelectedText
            }
        }
    }

    guard allowValueReplacement, let expectedValue, let selectedRange else {
        return nil
    }
    var valueSettable = DarwinBoolean(false)
    let valueElement = try requireValidatedFocusedElement(expectedElement, appPID: appPID)
    guard AXUIElementIsAttributeSettable(
        valueElement,
        kAXValueAttribute as CFString,
        &valueSettable
    ) == .success, valueSettable.boolValue else {
        return nil
    }
    let writeElement = try requireValidatedFocusedElement(expectedElement, appPID: appPID)
    guard CFEqual(valueElement, writeElement),
          AXUIElementSetAttributeValue(
              writeElement,
              kAXValueAttribute as CFString,
              expectedValue as CFTypeRef
          ) == .success else {
        return nil
    }
    usleep(30_000)
    let verifiedElement = try requireValidatedFocusedElement(expectedElement, appPID: appPID)
    guard copyStringAttribute(kAXValueAttribute as CFString, from: verifiedElement) == expectedValue else {
        return nil
    }
    setSelectedTextRange(
        CFRange(location: selectedRange.location + text.utf16.count, length: 0),
        on: verifiedElement
    )
    return .accessibilityValueReplacement
}

func postUnicodeKeyboardEvents(
    _ text: String,
    appPID: pid_t,
    expectedElement: AXUIElement
) throws {
    guard let source = CGEventSource(stateID: .combinedSessionState) else {
        throw ProductRuntimeError.eventSourceUnavailable
    }
    let codeUnits = Array(text.utf16)
    guard !codeUnits.isEmpty else {
        throw ProductRuntimeError.invalidRequest("Insert requests require a non-empty text payload.")
    }

    for character in text {
        _ = try requireValidatedFocusedElement(expectedElement, appPID: appPID)
        var chunk = Array(String(character).utf16)
        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        else {
            throw ProductRuntimeError.eventCreationFailed
        }
        keyDown.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &chunk)
        keyDown.postToPid(appPID)
        keyUp.postToPid(appPID)
    }
}

func insertWithUnicodeKeyboardEvents(
    _ text: String,
    appPID: pid_t,
    expectedElement: AXUIElement
) throws {
    let focusedElementBefore = try requireValidatedFocusedElement(expectedElement, appPID: appPID)
    guard let valueBefore = copyStringAttribute(kAXValueAttribute as CFString, from: focusedElementBefore),
          let selectedRange = copySelectedTextRange(from: focusedElementBefore),
          selectedRange.location >= 0,
          selectedRange.length >= 0,
          selectedRange.location + selectedRange.length <= (valueBefore as NSString).length else {
        throw ProductRuntimeError.textInsertionFailed("The focused target value could not be verified.")
    }
    let expectedValue = (valueBefore as NSString).replacingCharacters(
        in: NSRange(location: selectedRange.location, length: selectedRange.length),
        with: text
    )

    try postUnicodeKeyboardEvents(text, appPID: appPID, expectedElement: expectedElement)

    usleep(30_000)
    let focusedElementAfter = try requireValidatedFocusedElement(expectedElement, appPID: appPID)
    guard CFEqual(focusedElementBefore, focusedElementAfter),
          copyStringAttribute(kAXValueAttribute as CFString, from: focusedElementAfter) == expectedValue else {
        throw ProductRuntimeError.textInsertionFailed("The inserted text could not be verified in the focused target.")
    }
}

func insertTextWithoutPasteboard(
    _ text: String,
    focus: FocusSnapshot?,
    expectedElement: AXUIElement
) throws -> InsertRoute {
    try validateInsertionTarget(focus)
    guard let pid = focus?.app?.pid else {
        throw ProductRuntimeError.textInsertionFailed("The target application could not be identified.")
    }
    guard InsertionTextPolicy.allowsInsertion(text, bundleID: focus?.app?.bundleID) else {
        throw ProductRuntimeError.textInsertionFailed(
            "Control-character text or multiline text for an unverified destination is not inserted."
        )
    }
    let allowsFallback = InsertionTargetPolicy.allowsUnicodeKeyboardFallback(
        editable: focus?.editable,
        role: focus?.role
    )
    if let route = try insertWithAccessibility(
        text,
        appPID: pid,
        expectedElement: expectedElement,
        allowValueReplacement: allowsFallback
    ) {
        return route
    }
    if allowsFallback {
        try insertWithUnicodeKeyboardEvents(text, appPID: pid, expectedElement: expectedElement)
        return .unicodeKeyboardEvents
    }
    throw ProductRuntimeError.nonEditableTarget
}

func isProductFrontmost(_ focus: FocusSnapshot?) -> Bool {
    focus?.app?.pid == ProcessInfo.processInfo.processIdentifier
}

func ensureDirectory(_ path: String) throws {
    let privateDirectoryAttributes: [FileAttributeKey: Any] = [.posixPermissions: 0o700]
    let standardizedPath = canonicalPathResolvingExistingAncestors(path)
    let homePath = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
    let anchor: String
    if standardizedPath == homePath || standardizedPath.hasPrefix(homePath + "/") {
        anchor = homePath
    } else if standardizedPath == "/private/tmp" || standardizedPath.hasPrefix("/private/tmp/") {
        anchor = "/private/tmp"
    } else {
        throw ProductRuntimeError.invalidRuntimeDirectory(standardizedPath)
    }

    let relative = String(standardizedPath.dropFirst(anchor.count)).split(separator: "/")
    var current = anchor
    for component in relative {
        current += "/\(component)"
        var info = stat()
        if lstat(current, &info) == 0 {
            guard (info.st_mode & S_IFMT) == S_IFDIR,
                  info.st_uid == geteuid() else {
                throw ProductRuntimeError.invalidRuntimeDirectory(current)
            }
        } else if errno == ENOENT {
            try FileManager.default.createDirectory(
                at: URL(fileURLWithPath: current),
                withIntermediateDirectories: false,
                attributes: privateDirectoryAttributes
            )
        } else {
            throw ProductRuntimeError.invalidRuntimeDirectory(current)
        }
    }
    try FileManager.default.setAttributes(privateDirectoryAttributes, ofItemAtPath: standardizedPath)
}

func canonicalPathResolvingExistingAncestors(_ path: String) -> String {
    var existingAncestor = URL(fileURLWithPath: path).standardizedFileURL
    var missingComponents: [String] = []
    while !FileManager.default.fileExists(atPath: existingAncestor.path),
          existingAncestor.path != "/" {
        missingComponents.append(existingAncestor.lastPathComponent)
        existingAncestor.deleteLastPathComponent()
    }
    var resolved = existingAncestor.resolvingSymlinksInPath()
    for component in missingComponents.reversed() {
        resolved.appendPathComponent(component, isDirectory: true)
    }
    let canonicalPath = resolved.standardizedFileURL.path
    if canonicalPath == "/tmp" || canonicalPath.hasPrefix("/tmp/") {
        return "/private\(canonicalPath)"
    }
    return canonicalPath
}

func validatePrivateRegularFile(_ path: String, allowMissing: Bool) throws {
    var info = stat()
    if lstat(path, &info) != 0 {
        if allowMissing && errno == ENOENT { return }
        throw ProductRuntimeError.invalidRuntimeDirectory(path)
    }
    guard (info.st_mode & S_IFMT) == S_IFREG,
          info.st_uid == geteuid() else {
        throw ProductRuntimeError.invalidRuntimeDirectory(path)
    }
}

func diagnosticContentPersistenceEnabled() -> Bool {
#if PUSHWRITE_QA_CONTROL_INTERFACE
    ProcessInfo.processInfo.environment["PUSHWRITE_ENABLE_CONTROL_INTERFACE"] == "1"
        && ProcessInfo.processInfo.environment["PUSHWRITE_INCLUDE_SENSITIVE_TEST_ARTIFACTS"] == "1"
#else
    false
#endif
}

func privacySafeJSONData<T: Encodable>(_ value: T, prettyPrinted: Bool) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
    let data = try encoder.encode(value)
    guard !diagnosticContentPersistenceEnabled() else {
        return data
    }

    let object = try JSONSerialization.jsonObject(with: data)
    func redacted(_ value: Any) -> Any {
        if let dictionary = value as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, pair in
                if PrivacySafeLog.shouldRedactField(named: pair.key) {
                    result[pair.key] = ""
                } else {
                    result[pair.key] = redacted(pair.value)
                }
            }
        }
        if let array = value as? [Any] {
            return array.map(redacted)
        }
        return value
    }
    let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
    return try JSONSerialization.data(withJSONObject: redacted(object), options: options)
}

func writeJSON<T: Encodable>(_ value: T, to path: String) throws {
    let data = try privacySafeJSONData(value, prettyPrinted: true)
    try ensureDirectory(URL(fileURLWithPath: path).deletingLastPathComponent().path)
    try validatePrivateRegularFile(path, allowMissing: true)
    try data.write(to: URL(fileURLWithPath: path), options: .atomic)
    try validatePrivateRegularFile(path, allowMissing: false)
}

func appendJSONLine<T: Encodable>(_ value: T, to path: String) throws {
    let data = try privacySafeJSONData(value, prettyPrinted: false)
    try ensureDirectory(URL(fileURLWithPath: path).deletingLastPathComponent().path)
    try validatePrivateRegularFile(path, allowMissing: true)

    let descriptor = open(path, O_WRONLY | O_APPEND | O_CREAT | O_CLOEXEC | O_NOFOLLOW, 0o600)
    guard descriptor >= 0 else {
        throw ProductRuntimeError.invalidRuntimeDirectory(path)
    }
    var info = stat()
    guard fstat(descriptor, &info) == 0,
          (info.st_mode & S_IFMT) == S_IFREG,
          info.st_uid == geteuid() else {
        close(descriptor)
        throw ProductRuntimeError.invalidRuntimeDirectory(path)
    }
    let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
    defer { try? handle.close() }
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
    private var recordingWatchdog: Timer?
    private var blockedWindowController: ProductFeedbackWindowController?
    private var menuBarController: PushWriteMenuBarController?
    private var settingsWindowController: PushWriteSettingsWindowController?
    private var activationObserver: NSObjectProtocol?
    private var instanceLockFileDescriptor: Int32 = -1
    private var runtimeWasPrepared = false
    private var launchBlockedUIHasBeenPresented = false
    private var isHotKeyHeld = false
    private var isAwaitingMicrophonePermission = false
    private var pendingStopAfterRecordingStart = false
    private var activeRecordingSession: ActiveRecordingSession?
    private let minimumUsableRecordingDurationMs = 300
#if PUSHWRITE_QA_CONTROL_INTERFACE
    private let controlInterfaceEnabled =
        ProcessInfo.processInfo.environment["PUSHWRITE_ENABLE_CONTROL_INTERFACE"] == "1"
#else
    private let controlInterfaceEnabled = false
#endif

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
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            if try !acquireInstanceLock() {
                observeActivationRequests()
                if !handOffToExistingInstanceIfNeeded() {
                    presentStartupError(ProductRuntimeError.instanceLockFailed("another process owns the lock but could not be activated"))
                }
                NSApp.terminate(nil)
                return
            }
        } catch {
            fputs("Product startup failed: \(error)\n", stderr)
            presentStartupError(error)
            NSApp.terminate(nil)
            return
        }

        observeActivationRequests()
        if waitForUncoordinatedInstanceToExit() == false {
            presentExistingInstanceConflict()
            NSApp.terminate(nil)
            return
        }

        do {
            try prepareRuntime()
            runtimeWasPrepared = true
            registerGlobalHotKey()
            configureMenuBar()
            try writeState(running: true)
        } catch {
            fputs("Product startup failed: \(error)\n", stderr)
            presentStartupError(error)
            NSApp.terminate(nil)
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.menuBarController?.showPopover()
        }

        if !isAccessibilityTrusted(prompt: false) {
            presentAccessibilityBlockedUIIfNeeded(triggeredByLaunch: true)
        }

        if controlInterfaceEnabled {
            pollTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                self?.pollRequestsDirectory()
            }
            pollRequestsDirectory()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        updateMenuBar()
        if runtimeWasPrepared {
            try? writeState(running: true)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        pollTimer?.invalidate()
        recordingWatchdog?.invalidate()
        unregisterGlobalHotKey()
        if let activationObserver {
            DistributedNotificationCenter.default().removeObserver(activationObserver)
            self.activationObserver = nil
        }
        if let activeRecordingSession {
            activeRecordingSession.recorder.stop()
            if !diagnosticContentPersistenceEnabled() {
                try? FileManager.default.removeItem(at: activeRecordingSession.fileURL)
                try? FileManager.default.removeItem(at: activeRecordingSession.metadataURL)
            }
            self.activeRecordingSession = nil
        }
        if runtimeWasPrepared {
            try? writeState(running: false)
        }
        releaseInstanceLock()
    }

    private func handOffToExistingInstanceIfNeeded() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return false }
        let currentPID = ProcessInfo.processInfo.processIdentifier
        guard let existing = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
            .first(where: { $0.processIdentifier != currentPID }) else {
            return false
        }

        let currentBundleURL = Bundle.main.bundleURL.standardizedFileURL
        let sameBundlePath = existing.bundleURL?.standardizedFileURL == currentBundleURL
        if sameBundlePath {
            let center = DistributedNotificationCenter.default()
            let requestID = UUID().uuidString
            let expectedVersion = instanceVersionIdentity()
            var acknowledged = false
            let acknowledgementObserver = center.addObserver(
                forName: .pushWriteInstanceAcknowledged,
                object: bundleIdentifier,
                queue: .main
            ) { notification in
                guard notification.userInfo?["requestID"] as? String == requestID,
                      notification.userInfo?["version"] as? String == expectedVersion else {
                    return
                }
                acknowledged = true
            }
            center.post(
                name: .pushWriteShowStatus,
                object: bundleIdentifier,
                userInfo: ["requestID": requestID]
            )
            let deadline = Date().addingTimeInterval(1.2)
            while !acknowledged, Date() < deadline {
                RunLoop.current.run(until: min(Date().addingTimeInterval(0.05), deadline))
            }
            center.removeObserver(acknowledgementObserver)
            if acknowledged {
                existing.activate(options: [.activateIgnoringOtherApps])
                return true
            }
        }

        presentExistingInstanceConflict()
        return true
    }

    private func presentExistingInstanceConflict() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Eine andere PushWrite-Version läuft bereits"
        alert.informativeText = "Beenden Sie die bereits laufende PushWrite-Version, bevor Sie diese Version starten. So greifen nie zwei Versionen gleichzeitig auf Mikrofon, Tastenkombination und Laufzeitdaten zu."
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func instanceVersionIdentity() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let executableDigest = Bundle.main.executableURL
            .flatMap { try? sha256OfFile(at: $0.path) }
            ?? "digest-unavailable"
        return "\(version)-\(build)-\(executableDigest)"
    }

    private func acquireInstanceLock() throws -> Bool {
        guard instanceLockFileDescriptor < 0 else { return true }
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "ch.baumanncreative.pushwrite"
        let lockDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
        try FileManager.default.createDirectory(
            at: lockDirectory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let lockURL = lockDirectory.appendingPathComponent("instance.lock", isDirectory: false)
        let descriptor = Darwin.open(lockURL.path, O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, mode_t(0o600))
        guard descriptor >= 0 else {
            throw ProductRuntimeError.instanceLockFailed(String(cString: strerror(errno)))
        }

        var metadata = stat()
        guard fstat(descriptor, &metadata) == 0,
              (metadata.st_mode & S_IFMT) == S_IFREG,
              metadata.st_uid == geteuid() else {
            let message = String(cString: strerror(errno))
            Darwin.close(descriptor)
            throw ProductRuntimeError.instanceLockFailed(message)
        }
        guard fchmod(descriptor, mode_t(0o600)) == 0 else {
            let message = String(cString: strerror(errno))
            Darwin.close(descriptor)
            throw ProductRuntimeError.instanceLockFailed(message)
        }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            let lockError = errno
            Darwin.close(descriptor)
            if lockError == EWOULDBLOCK || lockError == EAGAIN {
                return false
            }
            throw ProductRuntimeError.instanceLockFailed(String(cString: strerror(lockError)))
        }

        instanceLockFileDescriptor = descriptor
        return true
    }

    private func releaseInstanceLock() {
        guard instanceLockFileDescriptor >= 0 else { return }
        flock(instanceLockFileDescriptor, LOCK_UN)
        Darwin.close(instanceLockFileDescriptor)
        instanceLockFileDescriptor = -1
    }

    private func waitForUncoordinatedInstanceToExit() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return true }
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let otherInstances = {
            NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
                .filter { $0.processIdentifier != currentPID && !$0.isTerminated }
        }
        guard !otherInstances().isEmpty else { return true }

        let deadline = Date().addingTimeInterval(1.5)
        while Date() < deadline, !otherInstances().isEmpty {
            RunLoop.current.run(until: min(Date().addingTimeInterval(0.05), deadline))
        }
        return otherInstances().isEmpty
    }

    private func observeActivationRequests() {
        let center = DistributedNotificationCenter.default()
        if let activationObserver {
            center.removeObserver(activationObserver)
        }
        activationObserver = center.addObserver(
            forName: .pushWriteShowStatus,
            object: Bundle.main.bundleIdentifier,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            self.menuBarController?.showPopover()
            if let requestID = notification.userInfo?["requestID"] as? String,
               let bundleIdentifier = Bundle.main.bundleIdentifier {
                center.post(
                    name: .pushWriteInstanceAcknowledged,
                    object: bundleIdentifier,
                    userInfo: [
                        "requestID": requestID,
                        "version": self.instanceVersionIdentity(),
                    ]
                )
            }
        }
    }

    private func presentStartupError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "PushWrite konnte nicht gestartet werden"
        alert.informativeText = "Die lokalen Komponenten konnten nicht vorbereitet werden.\n\nTechnische Angabe: \(error)"
        alert.addButton(withTitle: "Beenden")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func configureMenuBar() {
        let controller = PushWriteMenuBarController(initialSnapshot: menuBarSnapshot())
        controller.onRefreshSnapshot = { [weak self] in self?.menuBarSnapshot() }
        controller.onOpenAccessibilitySettings = { [weak self] in self?.openAccessibilitySettings() }
        controller.onMicrophoneAction = { [weak self] in self?.handleMicrophonePermissionAction() }
        controller.onShowSettings = { [weak self] in self?.showSettings() }
        controller.onQuit = { NSApp.terminate(nil) }
        menuBarController = controller
    }

    private func menuBarSnapshot() -> MenuBarSnapshot {
        let state: MenuBarPresentationState
        let statusText: String
        let workflowStage: WorkflowPresentationStage
        switch flowSnapshot.state {
        case .recording:
            state = .recording
            statusText = "Aufnahme läuft"
            workflowStage = .recording
        case .processing:
            state = .processing
            statusText = "Verarbeitung läuft"
            workflowStage = .transforming
        case .transcribing:
            state = .processing
            statusText = "Transkription läuft"
            workflowStage = .transcribing
        case .inserting:
            state = .processing
            statusText = "Text wird eingefügt"
            workflowStage = .inserting
        case .blocked, .error:
            state = .attention
            statusText = "Handlungsbedarf"
            workflowStage = .attention
        case .idle, .triggered, .done:
            state = (hotKeyState.registered && isAccessibilityTrusted(prompt: false)) ? .ready : .attention
            statusText = state == .ready ? "Bereit" : "Berechtigung prüfen"
            workflowStage = state == .ready ? .ready : .attention
        }

        let microphoneText: String
        switch currentMicrophonePermissionStatus() {
        case .granted: microphoneText = "Erlaubt"
        case .denied: microphoneText = "Nicht erlaubt"
        case .restricted: microphoneText = "Eingeschränkt"
        case .notDetermined: microphoneText = "Noch nicht angefragt"
        }
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "0.3.2"
        let inputLanguage = UserDefaults.standard.string(forKey: "inputLanguage")
            ?? launchOptions.inputLanguage
        let outputLanguage = UserDefaults.standard.string(forKey: "outputLanguage")
            ?? UserDefaults.standard.string(forKey: "transcriptionLanguage")
            ?? launchOptions.outputLanguage
        return MenuBarSnapshot(
            state: state,
            statusText: statusText,
            hotKeyText: hotKeyConfiguration.displayString,
            accessibilityGranted: isAccessibilityTrusted(prompt: false),
            microphoneStatusText: microphoneText,
            versionText: version,
            recordingElapsed: activeRecordingSession?.recorder.currentTime ?? 0,
            audioLevel: activeRecordingSession?.recorder.normalizedLevel ?? 0,
            inputLanguageText: LanguageSettingsCatalog.inputTitle(for: inputLanguage),
            outputLanguageText: LanguageSettingsCatalog.outputTitle(for: outputLanguage),
            workflowStage: workflowStage
        )
    }

    private func updateMenuBar() {
        let snapshot = menuBarSnapshot()
        menuBarController?.update(snapshot)
        settingsWindowController?.updatePermissions(
            accessibilityGranted: snapshot.accessibilityGranted,
            microphoneStatus: snapshot.microphoneStatusText
        )
    }

    private func showSettings() {
        let snapshot = menuBarSnapshot()
        if let controller = settingsWindowController {
            controller.updatePermissions(
                accessibilityGranted: snapshot.accessibilityGranted,
                microphoneStatus: snapshot.microphoneStatusText
            )
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let selectedInputLanguage = UserDefaults.standard.string(forKey: "inputLanguage")
            ?? launchOptions.inputLanguage
        let selectedOutputLanguage = UserDefaults.standard.string(forKey: "outputLanguage")
            ?? UserDefaults.standard.string(forKey: "transcriptionLanguage")
            ?? launchOptions.outputLanguage
        let controller = PushWriteSettingsWindowController(
            hotKeyText: snapshot.hotKeyText,
            accessibilityGranted: snapshot.accessibilityGranted,
            microphoneStatus: snapshot.microphoneStatusText,
            selectedInputLanguage: selectedInputLanguage,
            selectedOutputLanguage: selectedOutputLanguage,
            versionText: snapshot.versionText
        )
        controller.onInputLanguageChanged = { value in
            UserDefaults.standard.set(value, forKey: "inputLanguage")
            self.updateMenuBar()
        }
        controller.onOutputLanguageChanged = { value in
            UserDefaults.standard.set(value, forKey: "outputLanguage")
            UserDefaults.standard.removeObject(forKey: "transcriptionLanguage")
            self.updateMenuBar()
        }
        settingsWindowController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showAbout() {
        let snapshot = menuBarSnapshot()
        let alert = NSAlert()
        alert.messageText = "PushWrite \(snapshot.versionText)"
        alert.informativeText = "Local voice input for macOS\nPowered by whisper.cpp and llama.cpp\n\nSpracherkennung, Schweizerdeutsch-Normalisierung und Übersetzung werden vollständig lokal verarbeitet."
        alert.addButton(withTitle: "OK")
        alert.runModal()
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
        transitionFlow(
            to: .triggered,
            id: flowID,
            trigger: .globalHotKey,
            textLength: 0,
            microphonePermissionStatus: currentMicrophonePermissionStatus()
        )

        guard receiptObservation.accessibilityTrusted else {
            presentAccessibilityBlockedUIIfNeeded(triggeredByLaunch: false)
            emitSystemBeep()
            completeGlobalHotKeyFlow(
                flowID: flowID,
                response: makeBlockedHotKeyResponse(
                    flowID: flowID,
                    receiptObservation: receiptObservation,
                    microphonePermissionStatus: currentMicrophonePermissionStatus(),
                    blockedReason: ProductRuntimeError.accessibilityDenied.description,
                    requestedMicrophonePermission: false,
                    localUserFeedback: .systemBeep
                )
            )
            return
        }

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
        let focusCapture = captureFocus(isTrusted: accessibilityTrusted)
        return ReceiptObservation(
            accessibilityTrusted: accessibilityTrusted,
            focusSnapshot: focusCapture?.snapshot,
            focusElement: focusCapture?.element
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
        case .transcriptionFailed:
            return .blockedPanel
        case .transcriptionSkipped, .emptyTranscriptionText, .whitespaceOnlyTranscriptionText, .empty, .tooShort:
            return .systemBeep
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
            windowTitle: "PushWrite einrichten",
            title: "Mikrofon erlauben",
            message: "\(bundleName) benötigt das Mikrofon nur während die Tastenkombination gehalten wird. Aktiviere den Zugriff unter Systemeinstellungen > Datenschutz & Sicherheit > Mikrofon.\n\n\(blockedReason)",
            primaryButtonTitle: "Systemeinstellungen öffnen",
            dismissButtonTitle: "Später",
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
                    self.armRecordingWatchdog(for: session)
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

        if runtimeMicrophoneRecorderStartFailureOverride {
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
            let recorder = try PushWriteAudioRecorder(url: fileURL, settings: settings)
#if PUSHWRITE_QA_CONTROL_INTERFACE
            recorder.isMeteringEnabled = true
#endif
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
                focusElementAtStart: receiptObservation.focusElement,
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
        recordingWatchdog?.invalidate()
        recordingWatchdog = nil
        activeRecordingSession = nil
        pendingStopAfterRecordingStart = false

        let measuredDurationMs = max(Int((session.recorder.currentTime * 1_000.0).rounded()), 0)
        let focusAtStop = captureFocusSnapshot(isTrusted: true)
        session.recorder.stop()
#if !PUSHWRITE_QA_CONTROL_INTERFACE
        session.inMemoryWAVData = session.recorder.wavData()
#endif
        logHotKeyRecordingEvent(
            flowID: session.flowID,
            event: "recording-stopped",
            detail: "durationMs=\(measuredDurationMs)"
        )

        transitionFlow(
            to: .transcribing,
            id: session.flowID,
            trigger: .globalHotKey,
            textLength: 0,
            recordingDurationMs: measuredDurationMs,
            recordingFilePath: session.fileURL.path,
            microphonePermissionStatus: .granted,
            requestedMicrophonePermission: session.requestedMicrophonePermission
        )
        logHotKeyRecordingEvent(flowID: session.flowID, event: "transcribing-state-entered", detail: nil)

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

    private func armRecordingWatchdog(for session: ActiveRecordingSession) {
        recordingWatchdog?.invalidate()
        recordingWatchdog = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { [weak self, weak session] _ in
            guard let self, let session, self.activeRecordingSession?.flowID == session.flowID else {
                return
            }
            self.logHotKeyRecordingEvent(
                flowID: session.flowID,
                event: "recording-watchdog-stop",
                detail: "Maximum recording duration of 120 seconds reached."
            )
            self.stopActiveRecordingSession(session)
        }
    }

    private func finishRecordingSession(
        _ session: ActiveRecordingSession,
        measuredDurationMs: Int,
        focusAtStop: FocusSnapshot?
    ) -> ProductResponse {
        defer {
            cleanupProcessingArtifacts(for: session)
        }
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

    private func cleanupProcessingArtifacts(for session: ActiveRecordingSession) {
        guard !diagnosticContentPersistenceEnabled() else {
            return
        }
        let pathsToRemove = [
            session.fileURL.path,
            session.metadataURL.path,
            paths.transcriptionTextFile(for: session.flowID),
            paths.transcriptionRawJSONFile(for: session.flowID),
            paths.transcriptionArtifactFile(for: session.flowID),
        ]
        for path in pathsToRemove where FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
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
                gatedTranscriptionFeedback: reason == .transcriptionFailed ? nil : .systemBeep,
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
            DispatchQueue.main.sync {
                self.transitionFlow(
                    to: .inserting,
                    id: session.flowID,
                    trigger: .globalHotKey,
                    textLength: text.count,
                    recordingDurationMs: recordingArtifact.durationMs,
                    recordingFilePath: recordingArtifact.filePath,
                    microphonePermissionStatus: .granted,
                    requestedMicrophonePermission: session.requestedMicrophonePermission
                )
            }
            logHotKeyRecordingEvent(
                flowID: session.flowID,
                event: "insert-started",
                detail: "textLength=\(text.count)"
            )

            let receiptObservation = ReceiptObservation(
                accessibilityTrusted: true,
                focusSnapshot: session.focusAtStart,
                focusElement: session.focusElementAtStart
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
        let configuredCLIPath = optionalNonEmptyTrimmed(launchOptions.whisperCLIPath) ?? bundledWhisperCLIPath()
        let configuredModelPath = optionalNonEmptyTrimmed(launchOptions.whisperModelPath) ?? bundledWhisperModelPath()
        let allowTestRuntimeOverride = testRuntimeOverridesEnabled()
        let configuredInputLanguageValue = allowTestRuntimeOverride
            ? launchOptions.inputLanguage
            : UserDefaults.standard.string(forKey: "inputLanguage") ?? launchOptions.inputLanguage
        let configuredInputLanguage = SpokenLanguage.configured(rawValue: configuredInputLanguageValue)
        let effectiveRecognitionLanguage = SpokenLanguage.effectiveRecognitionLanguage(
            configured: configuredInputLanguage,
            preferredLanguageIdentifiers: Locale.preferredLanguages
        )
        let configuredLanguage = effectiveRecognitionLanguage.whisperLanguageCode ?? "auto"
        let configuredOutputLanguageValue = allowTestRuntimeOverride
            ? launchOptions.outputLanguage
            : UserDefaults.standard.string(forKey: "outputLanguage")
                ?? UserDefaults.standard.string(forKey: "transcriptionLanguage")
                ?? launchOptions.outputLanguage
        let outputLanguage = OutputLanguage.resolved(
            configuredValue: configuredOutputLanguageValue,
            preferredLanguageIdentifiers: Locale.preferredLanguages
        )
#if PUSHWRITE_QA_CONTROL_INTERFACE
        let artifactPath = paths.transcriptionArtifactFile(for: session.flowID)
        let textFilePath = paths.transcriptionTextFile(for: session.flowID)
        let rawOutputJSONPath = paths.transcriptionRawJSONFile(for: session.flowID)
#else
        let artifactPath = "memory://transcription/\(session.flowID)/artifact"
        let textFilePath = "memory://transcription/\(session.flowID)/text"
        let rawOutputJSONPath = "memory://transcription/\(session.flowID)/json"
#endif
        let startedAt = isoTimestamp()
        let started = Date()

        do {
            let resolvedRuntime = try resolveWhisperRuntime(launchOptions: launchOptions)
            let cliPath = resolvedRuntime.cli.path
            let cliResolutionSource = resolvedRuntime.cli.source.rawValue
            let modelPath = resolvedRuntime.model.path
            let modelResolutionSource = resolvedRuntime.model.source.rawValue
            let recordingData: Data
#if PUSHWRITE_QA_CONTROL_INTERFACE
            recordingData = try Data(contentsOf: URL(fileURLWithPath: recordingArtifact.filePath))
#else
            guard let capturedData = session.inMemoryWAVData else {
                throw ProductRuntimeError.failedToInspectRecording("in-memory recording data is unavailable")
            }
            recordingData = capturedData
#endif
            let whisperResult = try runWhisperCLI(
                cliPath: cliPath,
                modelPath: modelPath,
                recordingData: recordingData,
                language: configuredLanguage
            )
            let rawTranscriptText = whisperResult.text
            let resolvedLanguage = whisperResult.language ?? configuredLanguage
            logHotKeyRecordingEvent(
                flowID: session.flowID,
                event: "transcription-runtime-resolved",
                detail: "cliSource=\(cliResolutionSource),modelSource=\(modelResolutionSource),cliPath=\(cliPath),modelPath=\(modelPath)"
            )
            let detectedLanguage = SpokenLanguage.fromDetectedLanguageCode(resolvedLanguage)
            let transformationSource = SpokenLanguage.transformationSource(
                configured: effectiveRecognitionLanguage,
                detected: detectedLanguage
            )
            DispatchQueue.main.sync {
                self.transitionFlow(
                    to: .processing,
                    id: session.flowID,
                    trigger: .globalHotKey,
                    textLength: rawTranscriptText.count,
                    recordingDurationMs: recordingArtifact.durationMs,
                    recordingFilePath: recordingArtifact.filePath,
                    microphonePermissionStatus: .granted,
                    requestedMicrophonePermission: session.requestedMicrophonePermission
                )
            }
            let transformation = try runLocalTextTransformation(
                transcript: rawTranscriptText,
                source: transformationSource,
                target: outputLanguage,
                flowID: session.flowID
            )
            let transcriptText = transformation.text
            let artifact = TranscriptionArtifact(
                id: session.flowID,
                recordingID: recordingArtifact.id,
                recordingFilePath: recordingArtifact.filePath,
                artifactPath: artifactPath,
                textFilePath: textFilePath,
                rawOutputJSONPath: rawOutputJSONPath,
                cliPath: cliPath,
                cliResolutionSource: cliResolutionSource,
                modelPath: modelPath,
                modelResolutionSource: modelResolutionSource,
                modelName: URL(fileURLWithPath: modelPath).lastPathComponent,
                language: resolvedLanguage,
                configuredInputLanguage: configuredInputLanguage.rawValue,
                outputLanguage: outputLanguage.rawValue,
                rawTextLength: rawTranscriptText.count,
                localTransformationApplied: true,
                localTransformationRuntime: transformation.runtimePath,
                localTransformationModel: URL(fileURLWithPath: transformation.modelPath).lastPathComponent,
                localTransformationDurationMs: transformation.durationMs,
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
                cliResolutionSource: "unresolved",
                modelPath: configuredModelPath,
                modelResolutionSource: "unresolved",
                modelName: URL(fileURLWithPath: configuredModelPath).lastPathComponent,
                language: configuredLanguage,
                configuredInputLanguage: configuredInputLanguage.rawValue,
                outputLanguage: outputLanguage.rawValue,
                rawTextLength: 0,
                localTransformationApplied: false,
                localTransformationRuntime: nil,
                localTransformationModel: nil,
                localTransformationDurationMs: nil,
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
        recordingData: Data,
        language: String
    ) throws -> WhisperCLIResult {
        let arguments = [
            "-m", modelPath,
            "-f", "-",
            "-l", language,
            "-nt",
            "-oj",
            "-of", "-"
        ]

        if cliPath == bundledWhisperCLIPath() {
            try verifyBundledExecutable(
                at: cliPath,
                expectedPath: bundledWhisperCLIPath(),
                expectedSHA256: bundledWhisperExecutableSHA256
            )
        }
        let sandboxExecutable = "/usr/bin/sandbox-exec"
        guard FileManager.default.isExecutableFile(atPath: sandboxExecutable) else {
            throw ProductRuntimeError.transcriptionLaunchFailed("macOS network-denial runtime is unavailable")
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sandboxExecutable)
        process.arguments = [
            "-p",
            "(version 1) (allow default) (deny network*) (deny file-write*) (allow file-write-data)",
            cliPath,
        ] + arguments
        process.environment = sanitizedChildProcessEnvironment()
        process.currentDirectoryURL = URL(fileURLWithPath: paths.recordingsDir, isDirectory: true)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let stdinPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = stdinPipe

        do {
            try process.run()
        } catch {
            throw ProductRuntimeError.transcriptionLaunchFailed("\(error)")
        }

        stdoutPipe.fileHandleForWriting.closeFile()
        stderrPipe.fileHandleForWriting.closeFile()
        let stdoutBuffer = ThreadSafeDataBuffer()
        let stderrBuffer = ThreadSafeDataBuffer()
        let pipeDrainGroup = DispatchGroup()
        pipeDrainGroup.enter()
        DispatchQueue.global(qos: .utility).async {
            stdoutBuffer.store(stdoutPipe.fileHandleForReading.readDataToEndOfFile())
            pipeDrainGroup.leave()
        }
        pipeDrainGroup.enter()
        DispatchQueue.global(qos: .utility).async {
            stderrBuffer.store(stderrPipe.fileHandleForReading.readDataToEndOfFile())
            pipeDrainGroup.leave()
        }
        DispatchQueue.global(qos: .utility).async {
            stdinPipe.fileHandleForWriting.write(recordingData)
            stdinPipe.fileHandleForWriting.closeFile()
        }

        let completion = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in completion.signal() }
        if completion.wait(timeout: .now() + 120) == .timedOut {
            process.terminate()
            if completion.wait(timeout: .now() + 5) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                _ = completion.wait(timeout: .now() + 2)
            }
            _ = pipeDrainGroup.wait(timeout: .now() + 2)
            throw ProductRuntimeError.transcriptionProcessFailed("inference exceeded the 120-second limit")
        }

        _ = pipeDrainGroup.wait(timeout: .now() + 2)

        guard process.terminationStatus == 0 else {
            throw ProductRuntimeError.transcriptionProcessFailed("exit status \(process.terminationStatus)")
        }
        let stdoutData = stdoutBuffer.load()
        guard
            let object = try? JSONSerialization.jsonObject(with: stdoutData) as? [String: Any],
            let segments = object["transcription"] as? [[String: Any]]
        else {
            let diagnostic = String(data: stderrBuffer.load(), encoding: .utf8) ?? "non-JSON output"
            throw ProductRuntimeError.transcriptionProcessFailed(
                "whisper.cpp returned invalid JSON: \(diagnostic.prefix(240))"
            )
        }
        let transcript = trimmingTrailingLineBreaks(
            segments.compactMap { $0["text"] as? String }.joined()
        )
        let result = object["result"] as? [String: Any]
        let detectedLanguage = optionalNonEmptyTrimmed(result?["language"] as? String)
        return WhisperCLIResult(text: transcript, language: detectedLanguage)
    }

    private func runLocalTextTransformation(
        transcript: String,
        source: SpokenLanguage,
        target: OutputLanguage,
        flowID: String
    ) throws -> LocalTextTransformationResult {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if source.canBypassLocalTransformation(to: target) {
            return LocalTextTransformationResult(
                text: trimmedTranscript,
                runtimePath: "local-language-identity",
                modelPath: "local-language-identity",
                durationMs: 0
            )
        }
        guard !trimmedTranscript.isEmpty else {
            throw ProductRuntimeError.emptyTranscriptionOutput
        }
        guard trimmedTranscript.count <= 20_000 else {
            throw ProductRuntimeError.localTextTransformationFailed(
                "transcript exceeds the local 20,000-character processing limit"
            )
        }

        if qaLocalTextBypassEnabled() {
            return LocalTextTransformationResult(
                text: trimmedTranscript,
                runtimePath: "test-bypass",
                modelPath: "test-bypass",
                durationMs: 0
            )
        }

        let runtime = try resolveLocalTextRuntime(launchOptions: launchOptions)
        let fallbackStarted = Date()
        var candidate = trimmedTranscript
        var candidateSource = source
        var passIndex = 0

        if source != .automatic,
           source.translationLanguageCode != target.translationLanguageCode,
           source.translationLanguageCode != "en",
           target.translationLanguageCode != "en" {
            let pivotRequest = LocalTextTransformationRequest(
                source: source,
                target: .english,
                transcript: candidate
            )
            candidate = try runLlamaInference(
                transcriptCharacterCount: candidate.count,
                systemPrompt: LocalTextTransformationRequest.systemPrompt,
                prompt: pivotRequest.prompt,
                runtime: runtime,
                flowID: flowID,
                passIndex: passIndex
            )
            candidateSource = .english
            passIndex += 1
        }

        let finalRequest = LocalTextTransformationRequest(
            source: candidateSource,
            target: target,
            transcript: candidate
        )
        candidate = try runLlamaInference(
            transcriptCharacterCount: candidate.count,
            systemPrompt: LocalTextTransformationRequest.systemPrompt,
            prompt: finalRequest.prompt,
            runtime: runtime,
            flowID: flowID,
            passIndex: passIndex
        )
        candidate = LocalTextTransformationOutput.corrected(candidate, for: target)

        return LocalTextTransformationResult(
            text: candidate,
            runtimePath: runtime.cli.path,
            modelPath: runtime.model.path,
            durationMs: max(Int(Date().timeIntervalSince(fallbackStarted) * 1_000.0), 0)
        )
    }

    private func runLlamaInference(
        transcriptCharacterCount: Int,
        systemPrompt: String,
        prompt: String,
        runtime: ResolvedLocalTextRuntime,
        flowID: String,
        passIndex: Int
    ) throws -> String {
        let predictedTokens = min(max(transcriptCharacterCount / 2, 128), 4_096)
        let llamaArguments = [
            "--offline",
            "--model", runtime.model.path,
            "--system-prompt", systemPrompt,
            "--file", "/dev/stdin",
            "--ctx-size", "8192",
            "--n-predict", "\(predictedTokens)",
            "--seed", "42",
            "--temp", "0.1",
            "--top-k", "20",
            "--top-p", "0.8",
            "--repeat-penalty", "1.05",
            "--jinja",
            "--single-turn",
            "--no-display-prompt",
            "--no-perf",
            "--no-warmup",
            "--color", "off",
        ]
        let sandboxExecutable = "/usr/bin/sandbox-exec"
        guard FileManager.default.isExecutableFile(atPath: sandboxExecutable) else {
            throw ProductRuntimeError.localTextTransformationFailed(
                "macOS network-denial runtime is unavailable"
            )
        }
        if runtime.cli.path == bundledLocalTextCLIPath() {
            try verifyBundledExecutable(
                at: runtime.cli.path,
                expectedPath: bundledLocalTextCLIPath(),
                expectedSHA256: bundledLocalTextExecutableSHA256
            )
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sandboxExecutable)
        process.arguments = [
            "-p",
            "(version 1) (allow default) (deny network*) (deny file-write*) (allow file-write-data)",
            runtime.cli.path,
        ] + llamaArguments
        process.environment = sanitizedChildProcessEnvironment()
        process.currentDirectoryURL = URL(fileURLWithPath: paths.recordingsDir, isDirectory: true)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let stdinPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = stdinPipe
        do {
            try process.run()
        } catch {
            throw ProductRuntimeError.localTextTransformationFailed("could not launch llama.cpp: \(error)")
        }

        stdoutPipe.fileHandleForWriting.closeFile()
        stderrPipe.fileHandleForWriting.closeFile()
        let stdoutBuffer = ThreadSafeDataBuffer()
        let stderrBuffer = ThreadSafeDataBuffer()
        let pipeDrainGroup = DispatchGroup()
        pipeDrainGroup.enter()
        DispatchQueue.global(qos: .utility).async {
            stdoutBuffer.store(stdoutPipe.fileHandleForReading.readDataToEndOfFile())
            pipeDrainGroup.leave()
        }
        pipeDrainGroup.enter()
        DispatchQueue.global(qos: .utility).async {
            stderrBuffer.store(stderrPipe.fileHandleForReading.readDataToEndOfFile())
            pipeDrainGroup.leave()
        }
        let completion = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in completion.signal() }
        let promptData = Data(prompt.utf8)
        DispatchQueue.global(qos: .utility).async {
            stdinPipe.fileHandleForWriting.write(promptData)
            stdinPipe.fileHandleForWriting.closeFile()
        }
        if completion.wait(timeout: .now() + 180) == .timedOut {
            process.terminate()
            if completion.wait(timeout: .now() + 5) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                _ = completion.wait(timeout: .now() + 2)
            }
            _ = pipeDrainGroup.wait(timeout: .now() + 2)
            throw ProductRuntimeError.localTextTransformationFailed("inference exceeded the 180-second limit")
        }
        _ = pipeDrainGroup.wait(timeout: .now() + 2)
        let stdoutData = stdoutBuffer.load()
        _ = stderrBuffer.load()

        guard process.terminationStatus == 0 else {
            throw ProductRuntimeError.localTextTransformationFailed(
                "llama.cpp exited with status \(process.terminationStatus)"
            )
        }

        guard var transformedText = String(data: stdoutData, encoding: .utf8) else {
            throw ProductRuntimeError.localTextTransformationFailed("llama.cpp returned non-UTF-8 output")
        }
        transformedText = LocalTextTransformationOutput.cleaned(transformedText)
        guard !transformedText.isEmpty else {
            throw ProductRuntimeError.localTextTransformationFailed("llama.cpp returned empty output")
        }
        let maximumOutputCharacters = max(transcriptCharacterCount * 4, 1_024)
        guard transformedText.count <= maximumOutputCharacters else {
            throw ProductRuntimeError.localTextTransformationFailed(
                "output exceeded the deterministic expansion limit"
            )
        }

        return transformedText
    }

    private func persistTranscriptionArtifact(_ artifact: TranscriptionArtifact) {
#if PUSHWRITE_QA_CONTROL_INTERFACE
        do {
            try writeJSON(artifact, to: artifact.artifactPath)
        } catch {
            fputs("Could not persist transcription artifact for \(artifact.id): \(error)\n", stderr)
        }
#else
        _ = artifact
#endif
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
#if PUSHWRITE_QA_CONTROL_INTERFACE
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
#else
        guard let recordingData = session.inMemoryWAVData else {
            throw ProductRuntimeError.failedToInspectRecording("in-memory recorder returned no audio data")
        }
        return RecordingArtifact(
            id: session.flowID,
            filePath: "memory://recording/\(session.flowID)",
            metadataPath: "memory://recording/\(session.flowID)/metadata",
            format: "wav-lpcm-16khz-mono",
            sampleRateHz: 16_000,
            channelCount: 1,
            durationMs: measuredDurationMs,
            fileSizeBytes: UInt64(recordingData.count),
            createdAt: session.startedAtTimestamp
        )
#endif
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
        let terminalState: ProductFlowState
        switch response.status {
        case .succeeded:
            completionEvent = "flow-completed-succeeded"
            terminalState = .done
        case .blocked:
            completionEvent = "flow-completed-blocked"
            terminalState = .blocked
        case .failed, .invalidRequest:
            completionEvent = "flow-completed-failed"
            terminalState = .error
        case .ready, .stopped:
            completionEvent = "flow-completed-unexpected-status"
            terminalState = .error
        }
        transitionFlow(
            to: terminalState,
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
            if response.localUserFeedback == .systemBeep {
                emitSystemBeep()
                logHotKeyRecordingEvent(
                    flowID: flowID,
                    event: "local-feedback-triggered",
                    detail: "feedbackCase=\(terminalFeedback?.feedbackCase.rawValue ?? "none"),channel=systemBeep"
                )
            } else if let terminalFeedback {
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
        updateMenuBar()

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
        try ensureDirectory(paths.logsDir)
        try ensureDirectory(paths.recordingsDir)
#if !PUSHWRITE_QA_CONTROL_INTERFACE
        let recordingsURL = URL(fileURLWithPath: paths.recordingsDir, isDirectory: true)
        for artifactURL in try FileManager.default.contentsOfDirectory(
            at: recordingsURL,
            includingPropertiesForKeys: nil,
            options: []
        ) {
            let artifactName = artifactURL.lastPathComponent
            let pattern = "^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}(?:\\.wav|\\.json|\\.transcription(?:\\.txt|\\.json|\\.artifact\\.json))$"
            guard artifactName.range(of: pattern, options: .regularExpression) != nil else {
                continue
            }
            try validatePrivateRegularFile(artifactURL.path, allowMissing: false)
            try FileManager.default.removeItem(at: artifactURL)
        }
#endif
        if controlInterfaceEnabled {
            try ensureDirectory(paths.requestsDir)
            try ensureDirectory(paths.responsesDir)
        }
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
            restoreClipboard: true,
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
        let directReceiptCapture = receiptObservation == nil
            ? captureFocus(isTrusted: accessibilityTrusted)
            : nil
        let focusAtReceipt = receiptObservation?.focusSnapshot ?? directReceiptCapture?.snapshot
        let focusElementAtReceipt = receiptObservation?.focusElement ?? directReceiptCapture?.element

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
                insertRoute: nil,
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
        let focusCaptureBeforePaste = captureFocus(isTrusted: true)
        let focusBeforePaste = focusCaptureBeforePaste?.snapshot
        let pasteboard = NSPasteboard.general
        let originalPasteboardMetadata = PasteboardMetadata(
            changeCount: pasteboard.changeCount,
            itemCount: pasteboard.pasteboardItems?.count ?? 0
        )
        let route: InsertRoute

        do {
            let currentElement = focusCaptureBeforePaste?.element
            let elementMatches = focusElementAtReceipt.map { receiptElement in
                currentElement.map { CFEqual(receiptElement, $0) } ?? false
            } ?? false
            guard FocusTargetBindingPolicy.allowsInsertion(
                receiptPID: focusAtReceipt?.app?.pid,
                currentPID: focusBeforePaste?.app?.pid,
                elementMatches: elementMatches
            ), let expectedElement = focusElementAtReceipt else {
                throw ProductRuntimeError.textInsertionFailed("The focused target changed while PushWrite was processing.")
            }
            route = try insertTextWithoutPasteboard(
                text,
                focus: focusBeforePaste,
                expectedElement: expectedElement
            )
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
                insertRoute: nil,
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
                clipboardRestored: pasteboard.changeCount == originalPasteboardMetadata.changeCount,
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
            insertRoute: route,
            insertSource: source,
            focusAtReceipt: focusAtReceipt,
            focusBeforePaste: focusBeforePaste,
            focusAfterPaste: focusAfterPaste,
            focusAtStop: nil,
            productFrontmostAtReceipt: isProductFrontmost(focusAtReceipt),
            productFrontmostBeforePaste: isProductFrontmost(focusBeforePaste),
            productFrontmostAfterPaste: isProductFrontmost(focusAfterPaste),
            originalPasteboard: originalPasteboardMetadata,
            syntheticPastePosted: false,
            clipboardRestored: pasteboard.changeCount == originalPasteboardMetadata.changeCount,
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
                windowTitle: "PushWrite einrichten",
                title: "Bedienungshilfen erlauben",
                message: "PushWrite benötigt diese Berechtigung, um erkannten Text an der aktuellen Einfügemarke einzusetzen. Audio und Text werden lokal verarbeitet. Aktiviere \(bundleName) unter Systemeinstellungen > Datenschutz & Sicherheit > Bedienungshilfen.",
                primaryButtonTitle: "Systemeinstellungen öffnen",
                dismissButtonTitle: "Später",
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
                        NSApp.setActivationPolicy(.accessory)
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
        NSApp.setActivationPolicy(.accessory)
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

    private func handleMicrophonePermissionAction() {
        switch currentMicrophonePermissionStatus() {
        case .granted:
            updateMenuBar()
            try? writeState(running: true)
        case .denied, .restricted:
            openMicrophoneSettings()
        case .notDetermined:
            requestMicrophoneAccess { [weak self] permissionStatus, _ in
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }
                    self.updateMenuBar()
                    try? self.writeState(running: true)
                    if let blockedReason = microphoneBlockedReason(for: permissionStatus) {
                        self.presentMicrophonePermissionBlockedUI(blockedReason: blockedReason)
                    }
                }
            }
        }
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
