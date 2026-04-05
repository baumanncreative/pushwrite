import AppKit
import ApplicationServices
import Foundation

struct Options {
    var text = "PushWrite 002B test äöü ß €."
    var settleDelayMs: UInt32 = 150
    var pasteDelayMs: UInt32 = 120
    var restoreDelayMs: UInt32 = 350
    var restoreClipboard = false
    var promptAccessibility = false
    var preflightOnly = false
    var resultFile: String
}

struct PasteboardItemSnapshot {
    let dataByType: [(NSPasteboard.PasteboardType, Data)]
}

struct PasteboardSnapshot {
    let changeCount: Int
    let items: [PasteboardItemSnapshot]
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

struct HarnessResult: Codable {
    let timestamp: String
    let harnessBundleID: String?
    let harnessPID: Int32
    let accessibilityTrusted: Bool
    let promptAccessibility: Bool
    let preflightOnly: Bool
    let settleDelayMs: UInt32
    let pasteDelayMs: UInt32
    let restoreClipboard: Bool
    let restoreDelayMs: UInt32
    let textLength: Int
    let initialFocus: FocusSnapshot?
    let focusBeforePaste: FocusSnapshot?
    let focusAfterPaste: FocusSnapshot?
    let harnessFrontmostAtEntry: Bool
    let harnessFrontmostBeforePaste: Bool
    let harnessFrontmostAfterPaste: Bool
    let originalPasteboard: PasteboardMetadata?
    let syntheticPastePosted: Bool
    let clipboardRestored: Bool
    let error: String?
}

enum HarnessError: Error, CustomStringConvertible {
    case missingResultFile
    case invalidInteger(flag: String, value: String)
    case missingValue(flag: String)
    case unknownArgument(String)
    case accessibilityDenied
    case eventSourceUnavailable
    case eventCreationFailed
    case writeResultFailed(String)

    var description: String {
        switch self {
        case .missingResultFile:
            return "Missing required --result-file argument."
        case let .invalidInteger(flag, value):
            return "Invalid integer for \(flag): \(value)"
        case let .missingValue(flag):
            return "Missing value for \(flag)"
        case let .unknownArgument(argument):
            return "Unknown argument: \(argument)"
        case .accessibilityDenied:
            return "Accessibility access is required to post synthetic Cmd+V events."
        case .eventSourceUnavailable:
            return "Could not create a CGEventSource for keyboard events."
        case .eventCreationFailed:
            return "Could not create one or more keyboard events for Cmd+V."
        case let .writeResultFailed(path):
            return "Could not write result file to \(path)."
        }
    }
}

func parseOptions(arguments: [String]) throws -> Options {
    var text = "PushWrite 002B test äöü ß €."
    var settleDelayMs: UInt32 = 150
    var pasteDelayMs: UInt32 = 120
    var restoreDelayMs: UInt32 = 350
    var restoreClipboard = false
    var promptAccessibility = false
    var preflightOnly = false
    var resultFile: String?
    var index = 0

    func requireValue(for flag: String) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < arguments.count else {
            throw HarnessError.missingValue(flag: flag)
        }
        index = valueIndex
        return arguments[valueIndex]
    }

    func requireUInt32(for flag: String) throws -> UInt32 {
        let value = try requireValue(for: flag)
        guard let parsed = UInt32(value) else {
            throw HarnessError.invalidInteger(flag: flag, value: value)
        }
        return parsed
    }

    while index < arguments.count {
        let argument = arguments[index]
        switch argument {
        case "--text":
            text = try requireValue(for: argument)
        case "--settle-delay-ms":
            settleDelayMs = try requireUInt32(for: argument)
        case "--paste-delay-ms":
            pasteDelayMs = try requireUInt32(for: argument)
        case "--restore-delay-ms":
            restoreDelayMs = try requireUInt32(for: argument)
        case "--restore-clipboard":
            restoreClipboard = true
        case "--prompt-accessibility":
            promptAccessibility = true
        case "--preflight-only":
            preflightOnly = true
        case "--result-file":
            resultFile = try requireValue(for: argument)
        default:
            throw HarnessError.unknownArgument(argument)
        }
        index += 1
    }

    guard let resultFile else {
        throw HarnessError.missingResultFile
    }

    return Options(
        text: text,
        settleDelayMs: settleDelayMs,
        pasteDelayMs: pasteDelayMs,
        restoreDelayMs: restoreDelayMs,
        restoreClipboard: restoreClipboard,
        promptAccessibility: promptAccessibility,
        preflightOnly: preflightOnly,
        resultFile: resultFile
    )
}

func sleepMs(_ value: UInt32) {
    usleep(value * 1_000)
}

func isoTimestamp() -> String {
    ISO8601DateFormatter().string(from: Date())
}

func isAccessibilityTrusted(prompt: Bool) -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
}

func currentFrontmostApp() -> NSRunningApplication? {
    NSWorkspace.shared.frontmostApplication
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
    return (focused as! AXUIElement)
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
    guard let source = CGEventSource(stateID: .combinedSessionState) else {
        throw HarnessError.eventSourceUnavailable
    }

    let keyCodeV: CGKeyCode = 9

    guard
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: true),
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: false)
    else {
        throw HarnessError.eventCreationFailed
    }

    keyDown.flags = .maskCommand
    keyUp.flags = .maskCommand

    keyDown.post(tap: .cghidEventTap)
    usleep(15_000)
    keyUp.post(tap: .cghidEventTap)
}

func isHarnessFrontmost(_ focus: FocusSnapshot?) -> Bool {
    focus?.app?.pid == ProcessInfo.processInfo.processIdentifier
}

func writeResult(_ result: HarnessResult, to path: String) throws {
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(result)
    try data.write(to: url, options: .atomic)
}

final class HarnessDelegate: NSObject, NSApplicationDelegate {
    private let options: Options
    private let initialFocus: FocusSnapshot?

    init(options: Options, initialFocus: FocusSnapshot?) {
        self.options = options
        self.initialFocus = initialFocus
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(options.promptAccessibility ? .accessory : .prohibited)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if options.promptAccessibility {
            NSApp.activate(ignoringOtherApps: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(options.settleDelayMs))) {
            self.run()
        }
    }

    private func complete(
        accessibilityTrusted: Bool,
        focusBeforePaste: FocusSnapshot?,
        focusAfterPaste: FocusSnapshot?,
        originalPasteboard: PasteboardMetadata?,
        syntheticPastePosted: Bool,
        clipboardRestored: Bool,
        error: String?
    ) {
        let result = HarnessResult(
            timestamp: isoTimestamp(),
            harnessBundleID: Bundle.main.bundleIdentifier,
            harnessPID: ProcessInfo.processInfo.processIdentifier,
            accessibilityTrusted: accessibilityTrusted,
            promptAccessibility: options.promptAccessibility,
            preflightOnly: options.preflightOnly,
            settleDelayMs: options.settleDelayMs,
            pasteDelayMs: options.pasteDelayMs,
            restoreClipboard: options.restoreClipboard,
            restoreDelayMs: options.restoreDelayMs,
            textLength: options.text.count,
            initialFocus: initialFocus,
            focusBeforePaste: focusBeforePaste,
            focusAfterPaste: focusAfterPaste,
            harnessFrontmostAtEntry: isHarnessFrontmost(initialFocus),
            harnessFrontmostBeforePaste: isHarnessFrontmost(focusBeforePaste),
            harnessFrontmostAfterPaste: isHarnessFrontmost(focusAfterPaste),
            originalPasteboard: originalPasteboard,
            syntheticPastePosted: syntheticPastePosted,
            clipboardRestored: clipboardRestored,
            error: error
        )

        do {
            try writeResult(result, to: options.resultFile)
        } catch {
            fputs("\(HarnessError.writeResultFailed(options.resultFile))\n", stderr)
        }

        NSApp.terminate(nil)
    }

    private func run() {
        let accessibilityTrusted = isAccessibilityTrusted(prompt: options.promptAccessibility)
        let focusBeforePaste = captureFocusSnapshot(isTrusted: accessibilityTrusted)

        if options.preflightOnly {
            complete(
                accessibilityTrusted: accessibilityTrusted,
                focusBeforePaste: focusBeforePaste,
                focusAfterPaste: focusBeforePaste,
                originalPasteboard: nil,
                syntheticPastePosted: false,
                clipboardRestored: false,
                error: nil
            )
            return
        }

        guard accessibilityTrusted else {
            complete(
                accessibilityTrusted: accessibilityTrusted,
                focusBeforePaste: focusBeforePaste,
                focusAfterPaste: captureFocusSnapshot(isTrusted: false),
                originalPasteboard: nil,
                syntheticPastePosted: false,
                clipboardRestored: false,
                error: HarnessError.accessibilityDenied.description
            )
            return
        }

        let originalPasteboardSnapshot = options.restoreClipboard ? snapshotGeneralPasteboard() : nil
        let originalPasteboardMetadata = originalPasteboardSnapshot.map {
            PasteboardMetadata(changeCount: $0.changeCount, itemCount: $0.items.count)
        }

        writePlainTextToPasteboard(options.text)
        sleepMs(options.pasteDelayMs)

        do {
            try postSyntheticPaste()
        } catch {
            complete(
                accessibilityTrusted: accessibilityTrusted,
                focusBeforePaste: focusBeforePaste,
                focusAfterPaste: captureFocusSnapshot(isTrusted: true),
                originalPasteboard: originalPasteboardMetadata,
                syntheticPastePosted: false,
                clipboardRestored: false,
                error: "\(error)"
            )
            return
        }

        let focusAfterPaste = captureFocusSnapshot(isTrusted: true)

        if let snapshot = originalPasteboardSnapshot {
            sleepMs(options.restoreDelayMs)
            restoreGeneralPasteboard(from: snapshot)
        }

        complete(
            accessibilityTrusted: accessibilityTrusted,
            focusBeforePaste: focusBeforePaste,
            focusAfterPaste: focusAfterPaste,
            originalPasteboard: originalPasteboardMetadata,
            syntheticPastePosted: true,
            clipboardRestored: originalPasteboardSnapshot != nil,
            error: nil
        )
    }
}

let options: Options
do {
    options = try parseOptions(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
    fputs("\(error)\n", stderr)
    exit(64)
}

let initialTrusted = isAccessibilityTrusted(prompt: false)
let initialFocus = captureFocusSnapshot(isTrusted: initialTrusted)

let app = NSApplication.shared
let delegate = HarnessDelegate(options: options, initialFocus: initialFocus)
app.delegate = delegate
app.run()
