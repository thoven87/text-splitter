/// Controls how separator chunks are handled after a split.
public enum SeparatorPlacement: Sendable, Equatable {
    /// Remove separators from output (default for `CharacterTextSplitter`).
    case discard
    /// Prepend each separator to the following chunk (default for `RecursiveCharacterTextSplitter`).
    case start
    /// Append each separator to the preceding chunk.
    case end
}

/// Shared configuration for all text splitters.
public struct SplitterConfig: Sendable {
    public let chunkSize: Int
    public let chunkOverlap: Int
    public let keepSeparator: SeparatorPlacement
    /// If `true`, adds a `"start_index"` key to each document's metadata.
    public let addStartIndex: Bool
    /// If `true`, strips leading/trailing whitespace from each merged chunk.
    public let stripWhitespace: Bool

    // nil means character count (`String.count`); non-nil is a custom function.
    private let _customLength: (@Sendable (String) -> Int)?

    /// The length measurement function.
    public var lengthFunction: @Sendable (String) -> Int {
        _customLength ?? { $0.count }
    }

    public init(
        chunkSize: Int = 4000,
        chunkOverlap: Int = 200,
        // nil means use character count.
        lengthFunction: (@Sendable (String) -> Int)? = nil,
        keepSeparator: SeparatorPlacement = .discard,
        addStartIndex: Bool = false,
        stripWhitespace: Bool = true
    ) throws(SplitterError) {
        guard chunkSize > 0 else { throw SplitterError.invalidChunkSize(chunkSize) }
        guard chunkOverlap >= 0 else { throw SplitterError.invalidChunkOverlap(chunkOverlap) }
        guard chunkOverlap <= chunkSize else {
            throw SplitterError.overlapExceedsChunkSize(overlap: chunkOverlap, chunkSize: chunkSize)
        }
        self.chunkSize = chunkSize
        self.chunkOverlap = chunkOverlap
        self._customLength = lengthFunction
        self.keepSeparator = keepSeparator
        self.addStartIndex = addStartIndex
        self.stripWhitespace = stripWhitespace
    }

    // MARK: - Internal measurement helpers

    /// Measures the length of a `Substring`.
    @inline(__always)
    func length(_ s: Substring) -> Int {
        if let fn = _customLength { return fn(String(s)) }
        return s.count
    }

    @inline(__always)
    func length(_ s: String) -> Int {
        if let fn = _customLength { return fn(s) }
        return s.count
    }
}
