import Testing

@testable import TextSplitter

@Suite("Tokenizer & splitTextOnTokens")
struct TokenizerTests {

    // Character-level tokeniser: ord(char) → [Int], chr([Int]) → String
    private static let charTokenizer = Tokenizer(
        chunkOverlap: 3,
        tokensPerChunk: 7,
        decode: { ids in String(ids.map { Character(UnicodeScalar($0)!) }) },
        encode: { text in text.unicodeScalars.map { Int($0.value) } }
    )

    @Test func basicSplit() throws {
        let out = try splitTextOnTokens(text: "foo bar baz 123", tokenizer: Self.charTokenizer)
        #expect(out == ["foo bar", "bar baz", "baz 123"])
    }

    @Test func emptyDecodeProducesNoChunks() throws {
        let silentTokenizer = Tokenizer(
            chunkOverlap: 3,
            tokensPerChunk: 7,
            decode: { _ in "" },
            encode: { text in text.unicodeScalars.map { Int($0.value) } }
        )
        let out = try splitTextOnTokens(text: "foo bar baz 123", tokenizer: silentTokenizer)
        #expect(out.isEmpty)
    }

    @Test func throwsWhenOverlapGeTokensPerChunk() {
        let bad = Tokenizer(
            chunkOverlap: 7,
            tokensPerChunk: 7,
            decode: { _ in "" },
            encode: { _ in [] }
        )
        #expect(throws: SplitterError.tokensPerChunkTooSmall) {
            try splitTextOnTokens(text: "anything", tokenizer: bad)
        }
    }

    @Test func singleChunk() throws {
        let small = Tokenizer(
            chunkOverlap: 0,
            tokensPerChunk: 100,
            decode: { ids in String(ids.map { Character(UnicodeScalar($0)!) }) },
            encode: { text in text.unicodeScalars.map { Int($0.value) } }
        )
        let out = try splitTextOnTokens(text: "hello", tokenizer: small)
        #expect(out == ["hello"])
    }
}
