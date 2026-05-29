/// Errors thrown by text splitters and token-based splitting.
public enum SplitterError: Error, Sendable, Equatable {
    // Configuration errors
    case invalidChunkSize(Int)
    case invalidChunkOverlap(Int)
    case overlapExceedsChunkSize(overlap: Int, chunkSize: Int)
    case invalidRegexPattern(String)
    case tokensPerChunkTooSmall
    // Token encode/decode errors — wraps the underlying tokenizer's message.
    case encodingFailed(String)
    case decodingFailed(String)
}
