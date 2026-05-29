import Testing

@testable import TextSplitter

@Suite("ChunkStats")
struct ChunkStatsTests {

    @Test func basicStats() throws {
        let splitter = try CharacterTextSplitter(separator: " ", chunkSize: 10, chunkOverlap: 0)
        let samples = ["one two three four five six seven eight nine ten"]
        let stats = ChunkStats.analyze(samples, using: splitter)
        #expect(stats.count > 0)
        #expect(stats.min <= stats.mean)
        #expect(stats.mean <= stats.max)
        #expect(stats.p25 <= stats.p50)
        #expect(stats.p50 <= stats.p75)
    }

    @Test func emptyInput() throws {
        let splitter = try CharacterTextSplitter(separator: " ", chunkSize: 100, chunkOverlap: 0)
        let stats = ChunkStats.analyze([], using: splitter)
        #expect(stats.count == 0)
        #expect(stats.underfilledRatio == 0)
        #expect(stats.atCeilingRatio == 0)
    }

    @Test func underfilledDetected() throws {
        // chunkSize=1000 but all text is tiny — everything should be underfilled.
        let splitter = try CharacterTextSplitter(separator: "\n", chunkSize: 1000, chunkOverlap: 0)
        let samples = ["short\nlines\nonly"]
        let stats = ChunkStats.analyze(samples, using: splitter)
        #expect(stats.underfilledRatio == 1.0)
    }

    @Test func atCeilingDetected() throws {
        // One separator, text longer than chunkSize — merger hits the ceiling.
        let splitter = try CharacterTextSplitter(separator: "|", chunkSize: 5, chunkOverlap: 0)
        let samples = ["abcde|fghij|klmno"]
        let stats = ChunkStats.analyze(samples, using: splitter)
        #expect(stats.atCeilingCount > 0)
        #expect(stats.atCeilingRatio > 0)
    }

    @Test func tokenRangeWithTokenizer() throws {
        let splitter = try CharacterTextSplitter(separator: " ", chunkSize: 20, chunkOverlap: 0)
        let tokenizer = Tokenizer(
            chunkOverlap: 0,
            tokensPerChunk: 100,
            decode: { String($0.map { Character(UnicodeScalar($0)!) }) },
            encode: { $0.unicodeScalars.map { Int($0.value) } }
        )
        let stats = ChunkStats.analyze(
            ["hello world foo bar baz"],
            using: splitter,
            tokenizer: tokenizer
        )
        #expect(stats.tokenRange != nil)
        #expect(stats.tokenRange!.min > 0)
        #expect(stats.tokenRange!.min <= stats.tokenRange!.max)
    }

    @Test func fromPrecomputedChunks() {
        let chunks = ["hello world", "foo bar", "baz"]
        let stats = ChunkStats.analyze(chunks: chunks, chunkSize: 20)
        #expect(stats.count == 3)
        #expect(stats.min == 3)  // "baz"
        #expect(stats.max == 11)  // "hello world"
    }

    @Test func descriptionDoesNotCrash() throws {
        let splitter = try CharacterTextSplitter(separator: " ", chunkSize: 10, chunkOverlap: 0)
        let stats = ChunkStats.analyze(["some sample text here"], using: splitter)
        #expect(!stats.description.isEmpty)
    }
}
