import Testing

@testable import TextSplitter

@Suite("MarkdownHeaderTextSplitter")
struct MarkdownHeaderTests {

    @Test func case1() {
        let md = """
            # Foo

                ## Bar

            Hi this is Jim

            Hi this is Joe

             ## Baz

             Hi this is Molly
            """
        let splitter = MarkdownHeaderTextSplitter(headersToSplitOn: [
            ("#", "Header 1"), ("##", "Header 2"),
        ])
        let docs = splitter.splitText(md)
        #expect(docs.count == 2)
        #expect(docs[0].pageContent == "Hi this is Jim  \nHi this is Joe")
        #expect(docs[0].metadata == ["Header 1": "Foo", "Header 2": "Bar"])
        #expect(docs[1].pageContent == "Hi this is Molly")
        #expect(docs[1].metadata == ["Header 1": "Foo", "Header 2": "Baz"])
    }

    @Test func case2() {
        let md = """
            # Foo

                ## Bar

            Hi this is Jim

            Hi this is Joe

             ### Boo

             Hi this is Lance

             ## Baz

             Hi this is Molly
            """
        let splitter = MarkdownHeaderTextSplitter(headersToSplitOn: [
            ("#", "Header 1"), ("##", "Header 2"), ("###", "Header 3"),
        ])
        let docs = splitter.splitText(md)
        #expect(docs.count == 3)
        #expect(docs[1].metadata["Header 3"] == "Boo")
        #expect(docs[2].metadata == ["Header 1": "Foo", "Header 2": "Baz"])
    }

    @Test func case3FourLevels() {
        let md = """
            # Foo

                ## Bar

            Hi this is Jim

             ### Boo

             Hi this is Lance

             #### Bim

             Hi this is John

             ## Baz

             Hi this is Molly
            """
        let splitter = MarkdownHeaderTextSplitter(headersToSplitOn: [
            ("#", "Header 1"), ("##", "Header 2"),
            ("###", "Header 3"), ("####", "Header 4"),
        ])
        let docs = splitter.splitText(md)
        #expect(docs.count == 4)
        #expect(docs[2].metadata["Header 4"] == "Bim")
    }

    @Test func fencedCodeBlock() {
        let md = """
            # Header

            ```python
            code here
            ```

            More text
            """
        let splitter = MarkdownHeaderTextSplitter(headersToSplitOn: [("#", "Header 1")])
        let docs = splitter.splitText(md)
        // Code block content should not be treated as headers.
        let allContent = docs.map(\.pageContent).joined()
        #expect(!allContent.contains("# Header"))
    }

    @Test func invisibleCharactersStripped() {
        // Zero-width space inside a header should not prevent matching.
        let md = "# Foo\u{200B}\n\nSome text"
        let splitter = MarkdownHeaderTextSplitter(headersToSplitOn: [("#", "H1")])
        let docs = splitter.splitText(md)
        #expect(docs.first?.metadata["H1"] != nil)
    }
}

// MARK: - ExperimentalMarkdownSyntaxTextSplitter

@Suite("ExperimentalMarkdownSyntaxTextSplitter")
struct ExperimentalMarkdownTests {

    @Test func basicHeaderSplit() {
        let text = "# Title\nContent\n## Subtitle\nMore content\n"
        let s = ExperimentalMarkdownSyntaxTextSplitter()
        let docs = s.splitText(text)
        #expect(docs.count == 2)
        #expect(docs[0].metadata["Header 1"] == "Title")
        #expect(docs[1].metadata["Header 2"] == "Subtitle")
    }

    @Test func codeBlockExtracted() {
        let text = "# Title\n\n```swift\nlet x = 1\n```\n\nAfter code\n"
        let s = ExperimentalMarkdownSyntaxTextSplitter()
        let docs = s.splitText(text)
        let codeDoc = docs.first { $0.metadata["Code"] != nil }
        #expect(codeDoc != nil)
        #expect(codeDoc?.metadata["Code"] == "swift")
    }

    @Test func horizontalRuleSplits() {
        let text = "Before\n\n---\n\nAfter\n"
        let s = ExperimentalMarkdownSyntaxTextSplitter()
        let docs = s.splitText(text)
        #expect(docs.count == 2)
    }

    @Test func customHeaderConfig() {
        let text = "# Root\nRoot content\n## Sub\nSub content\n"
        let s = ExperimentalMarkdownSyntaxTextSplitter(
            headersToSplitOn: [("#", "H1"), ("##", "H2")])
        let docs = s.splitText(text)
        #expect(docs.first { $0.metadata["H1"] == "Root" } != nil)
    }

    @Test func stripHeadersTrue() {
        let text = "# Title\nContent\n"
        let s = ExperimentalMarkdownSyntaxTextSplitter(stripHeaders: true)
        let docs = s.splitText(text)
        #expect(docs.first?.pageContent.contains("# Title") == false)
    }

    @Test func stripHeadersFalse() {
        let text = "# Title\nContent\n"
        let s = ExperimentalMarkdownSyntaxTextSplitter(stripHeaders: false)
        let docs = s.splitText(text)
        #expect(docs.first?.pageContent.contains("# Title") == true)
    }
}
