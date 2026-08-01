import Foundation

enum TestFailure: Error, CustomStringConvertible {
    case assertion(String)

    var description: String {
        switch self {
        case let .assertion(message): return message
        }
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw TestFailure.assertion(message)
    }
}

@main
enum PushWriteCoreTestRunner {
    static func main() throws {
        try testAllowedWorkflow()
        try testRejectedWorkflowTransitions()
        try testClipboardDeduplication()
        try testTranslationPairValidation()
        try testPrivacySafeLogging()
        try testInsertionTargetPolicy()
        print("PushWriteCoreTests: 6 passed")
    }

    private static func testAllowedWorkflow() throws {
        var machine = AlphaWorkflowStateMachine()
        try expect(machine.apply(.hotKeyDown), "idle -> recording must be allowed")
        try expect(machine.state == .recording, "state must be recording")
        try expect(machine.apply(.hotKeyUp), "recording -> processing must be allowed")
        try expect(machine.state == .processing, "state must be processing")
        try expect(machine.apply(.processingFinished), "processing -> idle must be allowed")
        try expect(machine.state == .idle, "state must return to idle")
    }

    private static func testRejectedWorkflowTransitions() throws {
        var machine = AlphaWorkflowStateMachine()
        try expect(!machine.apply(.hotKeyUp), "hotkey up without recording must be ignored")
        try expect(machine.apply(.hotKeyDown), "initial recording must start")
        try expect(!machine.apply(.hotKeyDown), "repeated hotkey down must be ignored")
        try expect(machine.apply(.hotKeyUp), "recording must stop")
        try expect(!machine.apply(.hotKeyDown), "new recording during processing must be ignored")
        try expect(machine.apply(.failed), "processing failure must enter error")
        try expect(machine.apply(.reset), "error must reset to idle")
    }

    private static func testClipboardDeduplication() throws {
        var deduplicator = ClipboardTextDeduplicator()
        try expect(!deduplicator.shouldProcess(text: "   "), "blank clipboard text must be ignored")
        try expect(deduplicator.shouldProcess(text: "Hello"), "new text must be processed")
        try expect(!deduplicator.shouldProcess(text: "Hello"), "identical text must be deduplicated")
        try expect(deduplicator.shouldProcess(text: "Hallo"), "changed text must be processed")
        try expect(!deduplicator.shouldProcess(text: String(repeating: "x", count: 101), maximumUTF8Bytes: 100), "oversized text must be rejected")
    }

    private static func testTranslationPairValidation() throws {
        try expect(TranslationPair(source: .automatic, target: .german).isValid, "automatic to German must be valid")
        try expect(TranslationPair(source: .german, target: .english).isValid, "German to English must be valid")
        try expect(!TranslationPair(source: .english, target: .english).isValid, "same source and target must be invalid")
    }

    private static func testPrivacySafeLogging() throws {
        let secret = "Vertraulicher Inhalt 7ef4"
        let metadata = PrivacySafeLog.textMetadata(secret)
        try expect(metadata == "textPresent=true,textLength=25", "only text metadata may be logged")
        try expect(!PrivacySafeLog.containsUserContent(log: metadata, forbiddenValues: [secret]), "metadata must not contain user text")
    }

    private static func testInsertionTargetPolicy() throws {
        try expect(
            InsertionTargetPolicy.evaluate(protectedContent: true, editable: true) == .rejectProtected,
            "protected fields must be rejected"
        )
        try expect(
            InsertionTargetPolicy.evaluate(protectedContent: false, editable: false) == .rejectNonEditable,
            "non-editable targets must be rejected"
        )
        try expect(
            InsertionTargetPolicy.evaluate(protectedContent: false, editable: nil) == .allow,
            "unknown editability must allow the compatibility fallback"
        )
    }
}
