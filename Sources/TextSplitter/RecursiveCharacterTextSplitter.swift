/// Recursively tries a priority-ordered list of separators until one that
/// exists in the text is found, then splits on it and recurses on
/// over-sized pieces with the remaining separators.
public struct RecursiveCharacterTextSplitter: TextSplitting {
    public let config: SplitterConfig

    private let separators: [String]
    private let isSeparatorRegex: Bool
    private let compiled: [SendableRegex?]

    public init(
        separators: [String] = ["\n\n", "\n", " ", ""],
        isSeparatorRegex: Bool = false,
        config: SplitterConfig
    ) throws(SplitterError) {
        self.config = config
        self.separators = separators
        self.isSeparatorRegex = isSeparatorRegex

        var compiled: [SendableRegex?] = []
        for sep in separators {
            if sep.isEmpty {
                compiled.append(nil)
            } else {
                let pat = isSeparatorRegex ? sep : escapeRegexPattern(sep)
                do {
                    compiled.append(SendableRegex(try Regex(pat)))
                } catch {
                    throw SplitterError.invalidRegexPattern(pat)
                }
            }
        }
        self.compiled = compiled
    }

    /// Convenience initialiser that builds the config inline.
    public init(
        separators: [String] = ["\n\n", "\n", " ", ""],
        isSeparatorRegex: Bool = false,
        chunkSize: Int = 4000,
        chunkOverlap: Int = 200,
        keepSeparator: SeparatorPlacement = .start,
        stripWhitespace: Bool = true
    ) throws(SplitterError) {
        let cfg = try SplitterConfig(
            chunkSize: chunkSize,
            chunkOverlap: chunkOverlap,
            keepSeparator: keepSeparator,
            stripWhitespace: stripWhitespace
        )
        try self.init(separators: separators, isSeparatorRegex: isSeparatorRegex, config: cfg)
    }

    // MARK: - Factory

    /// Creates a splitter pre-configured for the given programming or markup language.
    public static func forLanguage(
        _ language: Language,
        config: SplitterConfig
    ) throws(SplitterError) -> RecursiveCharacterTextSplitter {
        try RecursiveCharacterTextSplitter(
            separators: language.separators,
            isSeparatorRegex: true,
            config: config
        )
    }

    /// Convenience factory that also builds the config inline.
    public static func forLanguage(
        _ language: Language,
        chunkSize: Int = 4000,
        chunkOverlap: Int = 0,
        keepSeparator: SeparatorPlacement = .start,
        stripWhitespace: Bool = true
    ) throws(SplitterError) -> RecursiveCharacterTextSplitter {
        let cfg = try SplitterConfig(
            chunkSize: chunkSize,
            chunkOverlap: chunkOverlap,
            keepSeparator: keepSeparator,
            stripWhitespace: stripWhitespace
        )
        return try forLanguage(language, config: cfg)
    }

    // MARK: - TextSplitting

    public func splitText(_ text: String) -> [String] {
        split(text[...], from: 0)
    }

    // MARK: - Core recursion (Substring-based, zero-copy pipeline)

    private func split(_ text: Substring, from startIdx: Int) -> [String] {
        var finalChunks: [String] = []

        var chosenIdx = compiled.count - 1
        for i in startIdx..<compiled.count {
            if separators[i].isEmpty {
                chosenIdx = i
                break
            }
            if let box = compiled[i], text.firstMatch(of: box.regex) != nil {
                chosenIdx = i
                break
            }
        }

        let chosenSep = separators[chosenIdx]
        let nextIdx = chosenIdx + 1

        let rawSplits: [Substring]
        if let box = compiled[chosenIdx] {
            rawSplits = splitWithRegexSubstrings(
                text, regex: box.regex,
                keepSeparator: config.keepSeparator)
        } else {
            rawSplits = splitIntoCharsSubstrings(text)
        }

        let mergeSep = config.keepSeparator != .discard ? "" : chosenSep
        let sepLen = config.length(mergeSep[...])

        var goodSplits = ContiguousArray<(Substring, Int)>()

        for s in rawSplits {
            let sLen = config.length(s)
            if sLen < config.chunkSize {
                goodSplits.append((s, sLen))
            } else {
                if !goodSplits.isEmpty {
                    finalChunks.append(
                        contentsOf: mergeSplitsPieces(
                            goodSplits, separator: mergeSep, sepLen: sepLen, config: config))
                    goodSplits.removeAll(keepingCapacity: true)
                }
                if nextIdx >= compiled.count {
                    finalChunks.append(String(s))
                } else {
                    finalChunks.append(contentsOf: split(s, from: nextIdx))
                }
            }
        }

        if !goodSplits.isEmpty {
            finalChunks.append(
                contentsOf: mergeSplitsPieces(
                    goodSplits, separator: mergeSep, sepLen: sepLen, config: config))
        }
        return finalChunks
    }
}

// MARK: - Language-specific convenience type aliases

/// Splits text along Markdown-formatted headings.
public typealias MarkdownTextSplitter = RecursiveCharacterTextSplitter

/// Splits text along Python-syntax boundaries.
public typealias PythonCodeTextSplitter = RecursiveCharacterTextSplitter

/// Splits text along LaTeX structural commands.
public typealias LatexTextSplitter = RecursiveCharacterTextSplitter
