#!/usr/bin/env swift

import AppKit
import ApplicationServices
import Foundation

struct Options {
    var text = "PushWrite 002A test äöü ß €."
    var pasteDelayMs: UInt32 = 200
    var restoreDelayMs: UInt32 = 500
    var restoreClipboard = false
    var promptAccessibility = false
    var showHelp = false
}

struct PasteboardItemSnapshot {
    let dataByType: [(NSPasteboard.PasteboardType, Data)]
}

struct PasteboardSnapshot {
    let changeCount: Int
    let items: [PasteboardItemSnapshot]
}

enum SpikeError: Error, CustomStringConvertible {
    case accessibilityDenied
    case eventSourceUnavailable
    case eventCreationFailed

    var description: String {
        switch self {
        case .accessibilityDenied:
            return "Accessibility access is required to post synthetic Cmd+V events."
        case .eventSourceUnavailable:
            return "Could not create a CGEventSource for keyboard events."
        case .eventCreationFailed:
            return "Could not create one or more keyboard events for Cmd+V."
        }
    }
}

func parseOptions(arguments: [String]) -> Options {
    var options = Options()
    var index = 0

    func requireValue(for flag: String) -> String {
        let valueIndex = index + 1
        guard valueIndex < arguments.count else {
            fputs("Missing value for \(flag)\n", stderr)
            exit(64)
        }
        index = valueIndex
        return arguments[valueIndex]
    }

    while index < arguments.count {
        let argument = arguments[index]
        switch argument {
        case "--text":
            options.text = requireValue(for: argument)
        case "--paste-delay-ms":
            let value = requireValue(for: argument)
            guard let parsed = UInt32(value) else {
                fputs("Invalid integer for \(argument): \(value)\n", stderr)
                exit(64)
            }
            options.pasteDelayMs = parsed
        case "--restore-delay-ms":
            let value = requireValue(for: argument)
            guard let parsed = UInt32(value) else {
                fputs("Invalid integer for \(argument): \(value)\n", stderr)
                exit(64)
            }
            options.restoreDelayMs = parsed
        case "--restore-clipboard":
            options.restoreClipboard = true
        case "--prompt-accessibility":
            options.promptAccessibility = true
        case "--help", "-h":
            options.showHelp = true
        default:
            fputs("Unknown argument: \(argument)\n", stderr)
            exit(64)
        }
        index += 1
    }

    return options
}

func printUsage() {
    let usage = """
    Usage:
      swift scripts/validate_text_insertion_paste_cmd_v.swift [options]

    Options:
      --text <value>                 Plain-text payload to place on the general pasteboard.
      --paste-delay-ms <value>       Delay between pasteboard write and synthetic Cmd+V. Default: 200
      --restore-clipboard            Snapshot and restore the full general pasteboard after paste.
      --restore-delay-ms <value>     Delay between Cmd+V and clipboard restore. Default: 500
      --prompt-accessibility         Ask macOS to show the Accessibility trust prompt if needed.
      --help                         Show this message.
    """

    print(usage)
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
    guard result == .success else {
        return nil
    }
    return (value as! AXUIElement)
}

func escapedForLog(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
}

func focusedValueDescription(for app: NSRunningApplication) -> String? {
    guard let focusedElement = copyFocusedElement(from: app) else {
        return nil
    }

    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(focusedElement, kAXValueAttribute as CFString, &value)
    guard result == .success else {
        return nil
    }

    guard let stringValue = value as? String else {
        return nil
    }

    return escapedForLog(stringValue)
}

func focusContextDescription(isTrusted: Bool) -> String {
    guard let app = currentFrontmostApp() else {
        return "frontmostApp=<none>"
    }

    var components = [
        "frontmostApp=\(app.localizedName ?? "<unknown>")",
        "bundleID=\(app.bundleIdentifier ?? "<unknown>")",
        "pid=\(app.processIdentifier)"
    ]

    guard isTrusted, let focusedElement = copyFocusedElement(from: app) else {
        return components.joined(separator: " ")
    }

    if let role = copyStringAttribute(kAXRoleAttribute as CFString, from: focusedElement) {
        components.append("role=\(role)")
    }
    if let subrole = copyStringAttribute(kAXSubroleAttribute as CFString, from: focusedElement) {
        components.append("subrole=\(subrole)")
    }
    if let title = copyStringAttribute(kAXTitleAttribute as CFString, from: focusedElement), !title.isEmpty {
        components.append("title=\(title)")
    }

    return components.joined(separator: " ")
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
        throw SpikeError.eventSourceUnavailable
    }

    let keyCodeV: CGKeyCode = 9

    guard
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: true),
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: false)
    else {
        throw SpikeError.eventCreationFailed
    }

    keyDown.flags = .maskCommand
    keyUp.flags = .maskCommand

    keyDown.post(tap: .cghidEventTap)
    usleep(15_000)
    keyUp.post(tap: .cghidEventTap)
}

func sleepMs(_ value: UInt32) {
    usleep(value * 1_000)
}

let options = parseOptions(arguments: Array(CommandLine.arguments.dropFirst()))

if options.showHelp {
    printUsage()
    exit(0)
}

let trusted = isAccessibilityTrusted(prompt: options.promptAccessibility)
print("[spike] accessibilityTrusted=\(trusted)")
print("[spike] focusBefore=\(focusContextDescription(isTrusted: trusted))")
if trusted, let app = currentFrontmostApp(), let value = focusedValueDescription(for: app) {
    print("[spike] focusedValueBefore=\"\(value)\"")
}

guard trusted else {
    fputs("\(SpikeError.accessibilityDenied)\n", stderr)
    exit(1)
}

let originalSnapshot = options.restoreClipboard ? snapshotGeneralPasteboard() : nil
if let snapshot = originalSnapshot {
    print("[spike] originalPasteboardChangeCount=\(snapshot.changeCount) items=\(snapshot.items.count)")
}

writePlainTextToPasteboard(options.text)
print("[spike] wrotePlainTextLength=\(options.text.count) pasteDelayMs=\(options.pasteDelayMs)")

sleepMs(options.pasteDelayMs)

do {
    try postSyntheticPaste()
    print("[spike] syntheticPaste=posted")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}

print("[spike] focusAfterPaste=\(focusContextDescription(isTrusted: true))")
if let app = currentFrontmostApp(), let value = focusedValueDescription(for: app) {
    print("[spike] focusedValueAfter=\"\(value)\"")
}

if let snapshot = originalSnapshot {
    sleepMs(options.restoreDelayMs)
    restoreGeneralPasteboard(from: snapshot)
    print("[spike] clipboardRestored=true restoreDelayMs=\(options.restoreDelayMs)")
}
