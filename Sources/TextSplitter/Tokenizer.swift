// Token-aware text splitting. Provide encode/decode closures from any
// tokenizer to split text by token count rather than character count.

/// A lightweight, tokenizer-agnostic splitting interface.
///
/// `encode` and `decode` throw `SplitterError`; non-throwing closures are
/// accepted transparently.
public struct Tokenizer: Sendable {
    public let chunkOverlap: Int
    public let tokensPerChunk: Int
    /// Decodes a sequence of token IDs back to text.
    public let decode: @Sendable ([Int]) throws(SplitterError) -> String
    /// Encodes text into a sequence of token IDs.
    public let encode: @Sendable (String) throws(SplitterError) -> [Int]

    public init(
        chunkOverlap: Int,
        tokensPerChunk: Int,
        decode: @escaping @Sendable ([Int]) throws(SplitterError) -> String,
        encode: @escaping @Sendable (String) throws(SplitterError) -> [Int]
    ) {
        self.chunkOverlap = chunkOverlap
        self.tokensPerChunk = tokensPerChunk
        self.decode = decode
        self.encode = encode
    }
}

/// Splits `text` into chunks of at most `tokenizer.tokensPerChunk` tokens,
/// with `tokenizer.chunkOverlap` tokens of overlap between consecutive chunks.
///
/// Encodes `text`, then slides a fixed-width window over the token array
/// to produce overlapping chunks.
public func splitTextOnTokens(
    text: String,
    tokenizer: Tokenizer
) throws(SplitterError) -> [String] {
    guard tokenizer.tokensPerChunk > tokenizer.chunkOverlap else {
        throw SplitterError.tokensPerChunkTooSmall
    }

    let ids = try tokenizer.encode(text)
    var splits: [String] = []
    var start = 0

    while start < ids.count {
        let end = min(start + tokenizer.tokensPerChunk, ids.count)
        let chunk = Array(ids[start..<end])
        if chunk.isEmpty { break }
        let decoded = try tokenizer.decode(chunk)
        if !decoded.isEmpty { splits.append(decoded) }
        if end == ids.count { break }
        start += tokenizer.tokensPerChunk - tokenizer.chunkOverlap
    }
    return splits
}
