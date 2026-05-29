import Testing

@testable import TextSplitter

@Suite("HTMLHeaderTextSplitter")
struct HTMLSplitterTests {

    @Test func basicH1H2() {
        let html = """
            <html><body>
            <h1>Introduction</h1>
            <p>Welcome to the introduction section.</p>
            <h2>Background</h2>
            <p>Some background details here.</p>
            <h1>Conclusion</h1>
            <p>Final thoughts.</p>
            </body></html>
            """
        let splitter = HTMLHeaderTextSplitter(headersToSplitOn: [
            ("h1", "Main Topic"), ("h2", "Sub Topic"),
        ])
        let docs = splitter.splitText(html)
        #expect(!docs.isEmpty)

        // The h1 "Introduction" document should exist.
        let intro = docs.first { $0.pageContent == "Introduction" }
        #expect(intro?.metadata["Main Topic"] == "Introduction")
    }

    @Test func nestedHeaders() {
        let html = """
            <h1>Title</h1>
            <p>Intro text</p>
            <h2>Chapter 1</h2>
            <p>Chapter one content</p>
            <h2>Chapter 2</h2>
            <p>Chapter two content</p>
            """
        let splitter = HTMLHeaderTextSplitter(headersToSplitOn: [
            ("h1", "Title"), ("h2", "Chapter"),
        ])
        let docs = splitter.splitText(html)
        let ch2 = docs.first { $0.metadata["Chapter"] == "Chapter 2" }
        #expect(ch2 != nil)
    }

    @Test func returnEachElement() {
        let html = "<h1>Head</h1><p>Para</p>"
        let splitter = HTMLHeaderTextSplitter(
            headersToSplitOn: [("h1", "H1")],
            returnEachElement: true)
        let docs = splitter.splitText(html)
        // Each element is its own document.
        #expect(docs.count >= 2)
    }

    @Test func noHeaders() {
        let html = "<p>Just some text.</p><p>More text.</p>"
        let splitter = HTMLHeaderTextSplitter(headersToSplitOn: [("h1", "H1")])
        let docs = splitter.splitText(html)
        // No headers → all text collected into one chunk.
        #expect(docs.count == 1)
        #expect(docs[0].pageContent.contains("Just some text"))
    }

    @Test func selfClosingTagsIgnored() {
        let html = "<h1>Title</h1><br/><p>Text</p>"
        let splitter = HTMLHeaderTextSplitter(headersToSplitOn: [("h1", "H1")])
        let docs = splitter.splitText(html)
        #expect(docs.first { $0.pageContent == "Title" } != nil)
    }
}
