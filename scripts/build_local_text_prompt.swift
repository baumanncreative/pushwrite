import Foundation

@main
enum LocalTextPromptBuilder {
    static func main() {
        if CommandLine.arguments == [CommandLine.arguments[0], "--system-prompt"] {
            print(LocalTextTransformationRequest.systemPrompt)
            return
        }
        guard CommandLine.arguments.count == 4 else {
            fputs("Usage: build_local_text_prompt <source> <target> <transcript>\n", stderr)
            exit(64)
        }
        guard let source = SpokenLanguage(rawValue: CommandLine.arguments[1]) else {
            fputs("Unsupported source language.\n", stderr)
            exit(64)
        }
        guard let target = OutputLanguage(rawValue: CommandLine.arguments[2]), target != .system else {
            fputs("Target must be one of de, en, es, fr.\n", stderr)
            exit(64)
        }
        print(
            LocalTextTransformationRequest(
                source: source,
                target: target,
                transcript: CommandLine.arguments[3]
            ).prompt
        )
    }
}
