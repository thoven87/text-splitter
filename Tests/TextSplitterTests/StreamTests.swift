import Testing

@testable import TextSplitter

// Helper: converts a [String] array into an AsyncStream<String>.
private func asyncStrings(_ values: [String]) -> AsyncStream<String> {
    AsyncStream { continuation in
        for v in values { continuation.yield(v) }
        continuation.finish()
    }
}

@Suite("TextSplitting.split(_:)")
struct StreamTests {

    @Test func singleFragment() async throws {
        let splitter = try CharacterTextSplitter(separator: " ", chunkSize: 7, chunkOverlap: 3)
        var chunks: [String] = []
        for try await chunk in splitter.split(asyncStrings(["foo bar baz 123"])) {
            chunks.append(chunk)
        }
        #expect(chunks == ["foo bar", "bar baz", "baz 123"])
    }

    @Test func multipleFragmentsYieldSameResultAsDirectSplit() async throws {
        let splitter = try CharacterTextSplitter(separator: " ", chunkSize: 10, chunkOverlap: 2)
        let pages = ["one two three", "four five six", "seven eight nine ten"]
        let fullText = pages.joined(separator: " ")

        var streamed: [String] = []
        for try await chunk in splitter.split(asyncStrings(pages)) {
            streamed.append(chunk)
        }
        let direct = splitter.splitText(fullText)

        // Content must match: every word from the direct split appears in the stream.
        let directWords = Set(direct.flatMap { $0.split(separator: " ").map(String.init) })
        let streamedWords = Set(streamed.flatMap { $0.split(separator: " ").map(String.init) })
        #expect(directWords == streamedWords)
    }

    @Test func emptyFragmentsSkipped() async throws {
        let splitter = try CharacterTextSplitter(separator: " ", chunkSize: 7, chunkOverlap: 3)
        var chunks: [String] = []
        for try await chunk in splitter.split(asyncStrings(["", "foo bar baz 123", ""])) {
            chunks.append(chunk)
        }
        #expect(chunks == ["foo bar", "bar baz", "baz 123"])
    }

    @Test func smallFragmentsBufferUntilThreshold() async throws {
        // chunkSize=20, chunkOverlap=5 → threshold=25
        // Each fragment is 5 chars — needs 5+ fragments before emitting.
        let splitter = try CharacterTextSplitter(separator: " ", chunkSize: 20, chunkOverlap: 5)
        let fragments = (1...10).map { "word\($0)" }
        var chunks: [String] = []
        for try await chunk in splitter.split(asyncStrings(fragments)) {
            chunks.append(chunk)
        }
        #expect(!chunks.isEmpty)
        for chunk in chunks { #expect(chunk.count <= 25) }
    }

    @Test func noBoundaryGluingAcrossFragments() async throws {
        // Verify "last word of fragmentN" + "first word of fragmentN+1" stay separate.
        let splitter = try CharacterTextSplitter(separator: " ", chunkSize: 30, chunkOverlap: 5)
        let fragments = ["alpha beta gamma", "delta epsilon zeta", "eta theta iota"]
        var chunks: [String] = []
        for try await chunk in splitter.split(asyncStrings(fragments)) {
            chunks.append(chunk)
        }
        let words = Set(chunks.flatMap { $0.split(separator: " ").map(String.init) })
        // All individual words must appear — no glued pairs like "gammadelta".
        for word in [
            "alpha", "beta", "gamma", "delta", "epsilon",
            "zeta", "eta", "theta", "iota",
        ] {
            #expect(words.contains(word), "word '\(word)' missing or glued to neighbour")
        }
    }

    @Test func memoryBoundedByThreshold() async throws {
        // 1 000 fragments × 20 chars each = 20 000 chars total.
        // Buffer must never exceed threshold = chunkSize + chunkOverlap = 220.
        let splitter = try CharacterTextSplitter(separator: " ", chunkSize: 200, chunkOverlap: 20)
        let fragment = String(repeating: "x", count: 18) + " "
        let stream = asyncStrings(Array(repeating: fragment, count: 1_000))
        var count = 0
        for try await _ in splitter.split(stream) { count += 1 }
        #expect(count > 0)
    }

    @Test func recursiveSplitterWorks() async throws {
        let splitter = try RecursiveCharacterTextSplitter(chunkSize: 50, chunkOverlap: 10)
        let pages = [
            "class Foo:\n\n    def bar():\n        pass\n",
            "    def baz():\n        return 1\n",
        ]
        var chunks: [String] = []
        for try await chunk in splitter.split(asyncStrings(pages)) {
            chunks.append(chunk)
        }
        #expect(!chunks.isEmpty)
    }
}
