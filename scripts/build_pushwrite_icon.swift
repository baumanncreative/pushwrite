#!/usr/bin/env swift

import Foundation

enum IconBuildError: Error, CustomStringConvertible {
    case usage
    case missingInput(String)

    var description: String {
        switch self {
        case .usage:
            return "Usage: build_pushwrite_icon.swift <input.iconset> <output.icns>"
        case .missingInput(let path):
            return "Missing icon input: \(path)"
        }
    }
}

func bigEndian(_ value: UInt32) -> Data {
    var encoded = value.bigEndian
    return Data(bytes: &encoded, count: MemoryLayout<UInt32>.size)
}

func appendChunk(type: String, pngPath: String, to output: inout Data) throws {
    guard let typeData = type.data(using: .ascii), typeData.count == 4 else {
        throw IconBuildError.missingInput(type)
    }
    guard let pngData = FileManager.default.contents(atPath: pngPath) else {
        throw IconBuildError.missingInput(pngPath)
    }
    output.append(typeData)
    output.append(bigEndian(UInt32(pngData.count + 8)))
    output.append(pngData)
}

do {
    guard CommandLine.arguments.count == 3 else {
        throw IconBuildError.usage
    }
    let iconset = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
    let chunks = [
        ("icp4", "icon_16x16.png"),
        ("icp5", "icon_16x16@2x.png"),
        ("icp6", "icon_32x32@2x.png"),
        ("ic07", "icon_128x128.png"),
        ("ic08", "icon_128x128@2x.png"),
        ("ic09", "icon_256x256@2x.png"),
        ("ic10", "icon_512x512@2x.png"),
    ]

    var body = Data()
    for (type, fileName) in chunks {
        try appendChunk(type: type, pngPath: iconset.appendingPathComponent(fileName).path, to: &body)
    }

    var icon = Data("icns".utf8)
    icon.append(bigEndian(UInt32(body.count + 8)))
    icon.append(body)
    try icon.write(to: outputURL, options: .atomic)
    print(outputURL.path)
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
