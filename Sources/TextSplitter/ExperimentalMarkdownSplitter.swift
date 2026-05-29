/// An experimental Markdown splitter that preserves original whitespace while
/// extracting structured metadata (headers, code blocks, horizontal rules).
///
/// Key differences from `MarkdownHeaderTextSplitter`:
/// - Retains exact whitespace / indentation.
/// - Also splits on horizontal rules (`---`, `***`, `___`).
/// - Records code-block language in the `"Code"` metadata key.
public struct ExperimentalMarkdownSyntaxTextSplitter: Sendable {

    private let splittableHeaders: [String: String]
    public let returnEachLine: Bool
    public let stripHeaders: Bool

    nonisolated(unsafe) private static let headerRx = #/^(#{1,6}) (.*)/#
    nonisolated(unsafe) private static let fenceRx = #/^(?:```|~~~)(.*)/#
    nonisolated(unsafe) private static let horzRx = #/^(?:\*\*\*+|---+|___+)[ \t]*$/#

    public init(
        headersToSplitOn: [(String, String)]? = nil,
        returnEachLine: Bool = false,
        stripHeaders: Bool = true
    ) {
        self.returnEachLine = returnEachLine
        self.stripHeaders = stripHeaders
        self.splittableHeaders =
            headersToSplitOn.map { Dictionary(uniqueKeysWithValues: $0) }
            ?? [
                "#": "Header 1", "##": "Header 2", "###": "Header 3",
                "####": "Header 4", "#####": "Header 5", "######": "Header 6",
            ]
    }

    // MARK: - Public API

    public func splitText(_ text: String) -> [Document] {
        // Split preserving line-ending newlines.
        let rawLines: [String] = splitLines(text)

        var chunks: [Document] = []
        var current = Document(pageContent: "")
        var headerStack: [(depth: Int, text: String)] = []
        var i = 0

        while i < rawLines.count {
            let raw = rawLines[i]
            let trimmed = trimWhitespace(raw)

            if let hm = trimmed.prefixMatch(of: Self.headerRx) {
                let hashes = String(hm.1)
                guard splittableHeaders[hashes] != nil else {
                    current.pageContent += raw
                    i += 1
                    continue
                }
                flush(&chunks, &current, stack: headerStack)
                if !stripHeaders { current.pageContent += raw }
                resolveStack(&headerStack, depth: hashes.count, text: String(hm.2))
                i += 1
            } else if let cm = trimmed.prefixMatch(of: Self.fenceRx) {
                flush(&chunks, &current, stack: headerStack)
                let lang = String(cm.1)
                var body = raw
                i += 1
                while i < rawLines.count {
                    let l = rawLines[i]
                    body += l
                    i += 1
                    if trimWhitespace(l).prefixMatch(of: Self.fenceRx) != nil { break }
                }
                current.pageContent = body
                current.metadata["Code"] = lang
                flush(&chunks, &current, stack: headerStack)
            } else if trimmed.wholeMatch(of: Self.horzRx) != nil {
                flush(&chunks, &current, stack: headerStack)
                i += 1
            } else {
                current.pageContent += raw
                i += 1
            }
        }
        flush(&chunks, &current, stack: headerStack)

        if returnEachLine {
            return chunks.flatMap { doc in
                doc.pageContent
                    .split(separator: "\n", omittingEmptySubsequences: false)
                    .map(String.init)
                    .filter { !$0.isEmpty && !$0.allSatisfy(\.isWhitespace) }
                    .map { Document(pageContent: $0, metadata: doc.metadata) }
            }
        }
        return chunks
    }

    // MARK: - Helpers

    private func splitLines(_ text: String) -> [String] {
        var lines: [String] = []
        var current = ""
        for ch in text {
            current.append(ch)
            if ch == "\n" {
                lines.append(current)
                current = ""
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }

    private func resolveStack(
        _ stack: inout [(depth: Int, text: String)],
        depth: Int,
        text: String
    ) {
        if let idx = stack.firstIndex(where: { $0.depth >= depth }) {
            stack.removeSubrange(idx...)
        }
        stack.append((depth, text))
    }

    private func flush(
        _ chunks: inout [Document],
        _ current: inout Document,
        stack: [(depth: Int, text: String)]
    ) {
        let body = current.pageContent
        guard !body.isEmpty && !body.allSatisfy(\.isWhitespace) else {
            current = Document(pageContent: "")
            return
        }
        var meta = current.metadata
        for (depth, value) in stack {
            let key =
                splittableHeaders[String(repeating: "#", count: depth)]
                ?? "Header \(depth)"
            meta[key] = value
        }
        chunks.append(Document(pageContent: body, metadata: meta))
        current = Document(pageContent: "")
    }
}
