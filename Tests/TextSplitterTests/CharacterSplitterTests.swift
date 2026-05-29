import Testing

@testable import TextSplitter

@Suite("CharacterTextSplitter")
struct CharacterSplitterTests {

    @Test func basicSplit() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 7, chunkOverlap: 3)
        #expect(s.splitText("foo bar baz 123") == ["foo bar", "bar baz", "baz 123"])
    }

    @Test func emptyDocsSkipped() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 2, chunkOverlap: 0)
        #expect(s.splitText("foo  bar") == ["foo", "bar"])
    }

    @Test func separatorOnlyText() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 2, chunkOverlap: 0)
        #expect(s.splitText("f b") == ["f", "b"])
    }

    @Test func longWords() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 3, chunkOverlap: 1)
        #expect(s.splitText("foo bar baz a a") == ["foo", "bar", "baz", "a a"])
    }

    @Test func shortWordsFirst() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 3, chunkOverlap: 1)
        #expect(s.splitText("a a foo bar baz") == ["a a", "foo", "bar", "baz"])
    }

    @Test func longerWords() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 1, chunkOverlap: 1)
        #expect(s.splitText("foo bar baz 123") == ["foo", "bar", "baz", "123"])
    }

    @Test func noSeparatorInText() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 10, chunkOverlap: 0)
        #expect(s.splitText("singleword") == ["singleword"])
    }

    @Test func chunkSizeEqualsOverlap() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 5, chunkOverlap: 5)
        #expect(s.splitText("hello") == ["hello"])
    }

    @Test func emptyInput() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 5, chunkOverlap: 0)
        #expect(s.splitText("") == [])
    }

    @Test func whitespaceOnlyInput() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 5, chunkOverlap: 0)
        #expect(s.splitText(" ") == [])
    }

    @Test func keepSeparatorStart() throws {
        let s = try CharacterTextSplitter(
            separator: ".", isSeparatorRegex: false,
            chunkSize: 1, chunkOverlap: 0,
            keepSeparator: .start)
        #expect(s.splitText("foo.bar.baz.123") == ["foo", ".bar", ".baz", ".123"])
    }

    @Test func keepSeparatorEnd() throws {
        let s = try CharacterTextSplitter(
            separator: ".", isSeparatorRegex: false,
            chunkSize: 1, chunkOverlap: 0,
            keepSeparator: .end)
        #expect(s.splitText("foo.bar.baz.123") == ["foo.", "bar.", "baz.", "123"])
    }

    @Test func keepSeparatorRegex() throws {
        let s = try CharacterTextSplitter(
            separator: "\\.", isSeparatorRegex: true,
            chunkSize: 1, chunkOverlap: 0,
            keepSeparator: .start)
        #expect(s.splitText("foo.bar.baz.123") == ["foo", ".bar", ".baz", ".123"])
    }

    @Test func discardSeparatorRegex() throws {
        let s = try CharacterTextSplitter(
            separator: "\\.", isSeparatorRegex: true,
            chunkSize: 1, chunkOverlap: 0,
            keepSeparator: .discard)
        #expect(s.splitText("foo.bar.baz.123") == ["foo", "bar", "baz", "123"])
    }

    @Test func invalidArguments() throws {
        #expect(throws: SplitterError.overlapExceedsChunkSize(overlap: 4, chunkSize: 2)) {
            try CharacterTextSplitter(separator: " ", chunkSize: 2, chunkOverlap: 4)
        }
        #expect(throws: SplitterError.invalidChunkSize(0)) {
            try CharacterTextSplitter(separator: " ", chunkSize: 0, chunkOverlap: 0)
        }
        #expect(throws: SplitterError.invalidChunkOverlap(-1)) {
            try CharacterTextSplitter(separator: " ", chunkSize: 2, chunkOverlap: -1)
        }
    }

    @Test func mergeSplitsDirect() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 9, chunkOverlap: 2)
        let out = mergeSplits(["foo", "bar", "baz"], separator: " ", config: s.config)
        #expect(out == ["foo bar", "baz"])
    }

    @Test func createDocuments() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 7, chunkOverlap: 3)
        let docs = s.createDocuments(from: ["foo bar baz 123"])
        #expect(docs.map(\.pageContent) == ["foo bar", "bar baz", "baz 123"])
    }

    @Test func createDocumentsWithMetadata() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 7, chunkOverlap: 3)
        let docs = s.createDocuments(
            from: ["foo bar baz 123"],
            metadatas: [["source": "test"]])
        for doc in docs {
            #expect(doc.metadata["source"] == "test")
        }
    }

    @Test func metadataDeepCopy() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 7, chunkOverlap: 3)
        let docs = s.createDocuments(
            from: ["foo bar baz 123", "foo bar baz 123"],
            metadatas: [["source": "a"], ["source": "b"]])
        #expect(docs[0].metadata["source"] == "a")
        #expect(docs[3].metadata["source"] == "b")
    }

    @Test func splitDocuments() throws {
        let s = try CharacterTextSplitter(separator: " ", chunkSize: 7, chunkOverlap: 3)
        let input = [
            Document(pageContent: "foo bar baz 123", metadata: ["source": "1"]),
            Document(pageContent: "foo bar baz 456", metadata: ["source": "2"]),
        ]
        let out = s.splitDocuments(input)
        #expect(out.count == 6)
        #expect(out[0].metadata["source"] == "1")
        #expect(out[3].metadata["source"] == "2")
    }
}
