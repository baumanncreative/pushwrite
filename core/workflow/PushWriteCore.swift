import Foundation

enum AlphaWorkflowState: String, Codable, CaseIterable {
    case idle
    case recording
    case processing
    case error
}

enum AlphaWorkflowEvent: String, Codable {
    case hotKeyDown
    case hotKeyUp
    case processingFinished
    case failed
    case reset
}

struct AlphaWorkflowStateMachine {
    private(set) var state: AlphaWorkflowState = .idle

    mutating func apply(_ event: AlphaWorkflowEvent) -> Bool {
        let nextState: AlphaWorkflowState?
        switch (state, event) {
        case (.idle, .hotKeyDown):
            nextState = .recording
        case (.recording, .hotKeyUp):
            nextState = .processing
        case (.processing, .processingFinished):
            nextState = .idle
        case (.recording, .failed), (.processing, .failed):
            nextState = .error
        case (.error, .reset):
            nextState = .idle
        default:
            nextState = nil
        }

        guard let nextState else {
            return false
        }
        state = nextState
        return true
    }
}

enum TranslationLanguage: String, Codable, CaseIterable {
    case automatic = "auto"
    case german = "de"
    case english = "en"
}

struct TranslationPair: Codable, Equatable {
    var source: TranslationLanguage
    var target: TranslationLanguage

    var isValid: Bool {
        source == .automatic || source != target
    }
}

struct ClipboardTextDeduplicator {
    private(set) var lastFingerprint: String?

    mutating func shouldProcess(text: String, maximumUTF8Bytes: Int = 100_000) -> Bool {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, normalized.lengthOfBytes(using: .utf8) <= maximumUTF8Bytes else {
            return false
        }
        let fingerprint = Self.stableFingerprint(normalized)
        guard fingerprint != lastFingerprint else {
            return false
        }
        lastFingerprint = fingerprint
        return true
    }

    static func stableFingerprint(_ value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }
}

enum PrivacySafeLog {
    static func textMetadata(_ text: String?) -> String {
        guard let text else {
            return "textPresent=false,textLength=0"
        }
        return "textPresent=true,textLength=\(text.count)"
    }

    static func containsUserContent(log: String, forbiddenValues: [String]) -> Bool {
        forbiddenValues
            .filter { !$0.isEmpty }
            .contains { log.contains($0) }
    }
}

enum InsertionTargetDecision: Equatable {
    case allow
    case rejectProtected
    case rejectNonEditable
}

enum InsertionTargetPolicy {
    static func evaluate(protectedContent: Bool, editable: Bool?) -> InsertionTargetDecision {
        if protectedContent {
            return .rejectProtected
        }
        if editable == false {
            return .rejectNonEditable
        }
        return .allow
    }
}
