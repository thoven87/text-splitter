// Sentence boundary detection for English and Latin-script text.

/// Splits text at sentence boundaries using regex heuristics.
public struct SentenceTextSplitter: TextSplitting {
    public let config: SplitterConfig

    private static let abbreviations: Set<String> = [
        "Mr", "Mrs", "Ms", "Dr", "Prof", "Sr", "Jr", "St", "vs",
        "etc", "Co", "Corp", "Inc", "Ltd", "Ave", "Blvd", "Dept",
    ]

    // Matches sentence-ending punctuation before whitespace + uppercase or end of string.
    nonisolated(unsafe) private static let boundaryRx =
        #/[.!?]+(?=[ \t]+[A-Z]|[ \t]*$)/#

    /// Initialise with an existing `SplitterConfig`. Never throws.
    public init(config: SplitterConfig) {
        self.config = config
    }

    public init(chunkSize: Int = 4000, chunkOverlap: Int = 200) throws(SplitterError) {
        self.config = try SplitterConfig(chunkSize: chunkSize, chunkOverlap: chunkOverlap)
    }

    public func splitText(_ text: String) -> [String] {
        var sentences: [String] = []
        var lastEnd = text.startIndex

        for match in text.matches(of: Self.boundaryRx) {
            let matchStart = match.range.lowerBound

            // Walk back to find the word immediately before the punctuation.
            var tokenStart = matchStart
            while tokenStart > lastEnd {
                let prev = text.index(before: tokenStart)
                if text[prev].isWhitespace { break }
                tokenStart = prev
            }
            let token = String(text[tokenStart..<matchStart])
            let bare = token.hasSuffix(".") ? String(token.dropLast()) : token
            if Self.abbreviations.contains(bare) { continue }

            let sentence = String(text[lastEnd..<match.range.upperBound])
            if !sentence.isEmpty { sentences.append(sentence) }
            lastEnd = match.range.upperBound
        }

        let tail = String(text[lastEnd...])
        if !trimWhitespace(tail).isEmpty { sentences.append(tail) }

        return sentences.isEmpty ? [text] : mergeSplits(sentences, separator: " ", config: config)
    }
}
