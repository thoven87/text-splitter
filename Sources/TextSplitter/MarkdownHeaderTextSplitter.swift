// MARK: - MarkdownHeaderTextSplitter

/// Splits a Markdown document at specified heading levels, returning one
/// `Document` per logical section with the heading hierarchy in metadata.
public struct MarkdownHeaderTextSplitter: Sendable {
    private let headers: [(marker: String, key: String)]  // sorted longest-first
    private let returnEachLine: Bool
    private let stripHeaders: Bool
    private let customHeaderLevels: [String: Int]

    public init(
        headersToSplitOn: [(String, String)],
        returnEachLine: Bool = false,
        stripHeaders: Bool = true,
        customHeaderPatterns: [String: Int] = [:]
    ) {
        self.headers =
            headersToSplitOn
            .map { ($0.0, $0.1) }
            .sorted { $0.marker.count > $1.marker.count }
        self.returnEachLine = returnEachLine
        self.stripHeaders = stripHeaders
        self.customHeaderLevels = customHeaderPatterns
    }

    // MARK: - Public API

    public func splitText(_ text: String) -> [Document] {
        return process(lines: text.split(separator: "\n", omittingEmptySubsequences: false))
    }

    // MARK: - Private types

    private struct LineChunk {
        var content: String
        var metadata: [String: String]
    }
    private struct StackEntry {
        var level: Int
        var name: String  // metadata key
    }

    // MARK: - Core algorithm

    private func process(lines: [Substring]) -> [Document] {
        var chunks: [LineChunk] = []
        var currentContent: [String] = []
        var currentMeta: [String: String] = [:]
        var headerStack: [StackEntry] = []
        var initialMeta: [String: String] = [:]
        var inCodeBlock = false
        var openingFence = ""

        for line in lines {
            let stripped = removePrintable(trimWhitespace(line))

            if !inCodeBlock {
                if stripped.hasPrefix("```") && stripped.filter({ $0 == "`" }).count == 3 {
                    inCodeBlock = true
                    openingFence = "```"
                } else if stripped.hasPrefix("~~~") {
                    inCodeBlock = true
                    openingFence = "~~~"
                }
            } else if stripped.hasPrefix(openingFence) {
                inCodeBlock = false
                openingFence = ""
            }

            if inCodeBlock {
                currentContent.append(stripped)
                currentMeta = initialMeta
                continue
            }

            // Try to match a configured header.
            var matched = false
            for (marker, key) in headers {
                let isStd =
                    stripped.hasPrefix(marker)
                    && (stripped.count == marker.count
                        || stripped.dropFirst(marker.count).first == " ")
                let isCustom = matchCustomHeader(stripped, marker: marker)
                guard isStd || isCustom else { continue }

                if !currentContent.isEmpty {
                    chunks.append(
                        LineChunk(
                            content: currentContent.joined(separator: "\n"),
                            metadata: currentMeta))
                    currentContent.removeAll()
                }

                let level: Int
                if let lvl = customHeaderLevels[marker] {
                    level = lvl
                } else {
                    level = marker.filter({ $0 == "#" }).count
                }

                while let last = headerStack.last, last.level >= level {
                    initialMeta.removeValue(forKey: headerStack.removeLast().name)
                }

                let text: String
                if isCustom {
                    text = trimWhitespace(
                        String(
                            stripped.dropFirst(marker.count).dropLast(marker.count)))
                } else {
                    text = trimWhitespace(String(stripped.dropFirst(marker.count)))
                }
                headerStack.append(StackEntry(level: level, name: key))
                initialMeta[key] = text
                if !stripHeaders { currentContent.append(stripped) }
                matched = true
                break
            }

            if !matched {
                if !stripped.isEmpty {
                    currentContent.append(stripped)
                } else if !currentContent.isEmpty {
                    chunks.append(
                        LineChunk(
                            content: currentContent.joined(separator: "\n"),
                            metadata: currentMeta))
                    currentContent.removeAll()
                }
            }
            currentMeta = initialMeta
        }

        if !currentContent.isEmpty {
            chunks.append(
                LineChunk(
                    content: currentContent.joined(separator: "\n"),
                    metadata: currentMeta))
        }

        return returnEachLine
            ? chunks.map { Document(pageContent: $0.content, metadata: $0.metadata) }
            : aggregate(chunks)
    }

    private func aggregate(_ chunks: [LineChunk]) -> [Document] {
        var result: [LineChunk] = []
        for chunk in chunks {
            if let last = result.last, last.metadata == chunk.metadata {
                result[result.count - 1].content += "  \n" + chunk.content
            } else if !stripHeaders,
                let last = result.last,
                last.metadata.count < chunk.metadata.count,
                last.content.split(separator: "\n").last?.hasPrefix("#") == true
            {
                result[result.count - 1].content += "  \n" + chunk.content
                result[result.count - 1].metadata = chunk.metadata
            } else {
                result.append(chunk)
            }
        }
        return result.map { Document(pageContent: $0.content, metadata: $0.metadata) }
    }

    private func matchCustomHeader(_ line: String, marker: String) -> Bool {
        guard customHeaderLevels[marker] != nil else { return false }
        guard line.hasPrefix(marker) && line.hasSuffix(marker) && line.count > 2 * marker.count
        else { return false }
        let inner = trimWhitespace(String(line.dropFirst(marker.count).dropLast(marker.count)))
        return !inner.isEmpty
            && !inner.unicodeScalars.allSatisfy { marker.unicodeScalars.contains($0) }
    }
}

// MARK: - Module-internal utilities

/// Removes non-printable control characters (ASCII < 0x20, DEL, C1 0x80–0x9F).
private func removePrintable(_ s: String) -> String {
    String(
        s.unicodeScalars.filter {
            let v = $0.value
            return v >= 0x20 && v != 0x7F && !(v >= 0x80 && v <= 0x9F)
        })
}
