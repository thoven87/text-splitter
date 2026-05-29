/// Splits text using a single separator (literal or regex pattern).
///
/// After the initial split the pieces are re-merged with the sliding-window
/// algorithm to honour `chunkSize` / `chunkOverlap`.
public struct CharacterTextSplitter: TextSplitting {
    public let config: SplitterConfig

    private let separator: String
    private let isSeparatorRegex: Bool
    private let compiledRegex: SendableRegex?

    public init(
        separator: String = "\n\n",
        isSeparatorRegex: Bool = false,
        config: SplitterConfig
    ) throws(SplitterError) {
        self.config = config
        self.separator = separator
        self.isSeparatorRegex = isSeparatorRegex
        if separator.isEmpty {
            self.compiledRegex = nil
        } else {
            let pattern = isSeparatorRegex ? separator : escapeRegexPattern(separator)
            do {
                self.compiledRegex = SendableRegex(try Regex(pattern))
            } catch {
                throw SplitterError.invalidRegexPattern(pattern)
            }
        }
    }

    /// Convenience initialiser that builds the config inline.
    public init(
        separator: String = "\n\n",
        isSeparatorRegex: Bool = false,
        chunkSize: Int = 4000,
        chunkOverlap: Int = 200,
        keepSeparator: SeparatorPlacement = .discard,
        stripWhitespace: Bool = true
    ) throws(SplitterError) {
        let cfg = try SplitterConfig(
            chunkSize: chunkSize,
            chunkOverlap: chunkOverlap,
            keepSeparator: keepSeparator,
            stripWhitespace: stripWhitespace
        )
        try self.init(separator: separator, isSeparatorRegex: isSeparatorRegex, config: cfg)
    }

    public func splitText(_ text: String) -> [String] {
        let sub = text[...]
        let rawSplits: [Substring]
        if let box = compiledRegex {
            rawSplits = splitWithRegexSubstrings(
                sub, regex: box.regex,
                keepSeparator: config.keepSeparator)
        } else {
            rawSplits = splitIntoCharsSubstrings(sub)
        }

        let isLookaround =
            isSeparatorRegex
            && (separator.hasPrefix("(?=") || separator.hasPrefix("(?!")
                || separator.hasPrefix("(?<=") || separator.hasPrefix("(?<!"))

        let mergeSep = (config.keepSeparator != .discard || isLookaround) ? "" : separator
        let sepLen = config.length(mergeSep[...])

        var pieces = ContiguousArray<(Substring, Int)>()
        pieces.reserveCapacity(rawSplits.count)
        for s in rawSplits { pieces.append((s, config.length(s))) }

        return mergeSplitsPieces(pieces, separator: mergeSep, sepLen: sepLen, config: config)
    }
}
