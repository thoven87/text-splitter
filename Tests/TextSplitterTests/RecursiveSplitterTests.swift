import Testing

@testable import TextSplitter

@Suite("RecursiveCharacterTextSplitter")
struct RecursiveSplitterTests {

    @Test func keepSeparatorsStart() throws {
        let s = try RecursiveCharacterTextSplitter(
            separators: [",", "."],
            chunkSize: 10, chunkOverlap: 0,
            keepSeparator: .start)
        let result = s.splitText("Apple,banana,orange and tomato.")
        #expect(result == ["Apple", ",banana", ",orange and tomato", "."])
    }

    @Test func keepSeparatorsEnd() throws {
        let s = try RecursiveCharacterTextSplitter(
            separators: [",", "."],
            chunkSize: 10, chunkOverlap: 0,
            keepSeparator: .end)
        let result = s.splitText("Apple,banana,orange and tomato.")
        #expect(result == ["Apple,", "banana,", "orange and tomato."])
    }

    @Test func pythonCodeSplitter() throws {
        let chunkSize = 50
        let s = try RecursiveCharacterTextSplitter.forLanguage(
            .python, chunkSize: chunkSize, chunkOverlap: 0)
        let code = """
            class Foo:

                def bar():
                    pass


                def baz():
                    return 1
            """
        let chunks = s.splitText(code)
        #expect(chunks.count > 1)
        for chunk in chunks { #expect(chunk.count <= chunkSize) }
    }

    @Test func latexSplitter() throws {
        // CHUNK_SIZE = 16 matches Python test suite constant.
        let s = try RecursiveCharacterTextSplitter.forLanguage(
            .latex, chunkSize: 16, chunkOverlap: 0)
        let code = "\nHi Harrison!\n\\chapter{1}\n"
        let chunks = s.splitText(code)
        #expect(chunks.contains("Hi Harrison!"))
        #expect(chunks.contains { $0.contains("chapter") })
    }

    @Test func htmlLanguageSplitter() throws {
        let s = try RecursiveCharacterTextSplitter.forLanguage(
            .html, chunkSize: 60, chunkOverlap: 0)
        let html = """
            <h1>Sample Document</h1>
                <h2>Section</h2>
                    <p id="1234">Reference content.</p>
            """
        let chunks = s.splitText(html)
        #expect(chunks.count > 1)
        for chunk in chunks { #expect(chunk.count <= 60 + 5) }  // small tolerance
    }

    @Test func goCodeSplitter() throws {
        let s = try RecursiveCharacterTextSplitter.forLanguage(
            .go, chunkSize: 50, chunkOverlap: 0)
        let code = """
            package main

            import "fmt"

            func main() {
                fmt.Println("Hello, World!")
            }

            func helper() int {
                return 42
            }
            """
        let chunks = s.splitText(code)
        #expect(chunks.count > 1)
    }

    @Test func swiftCodeSplitter() throws {
        let s = try RecursiveCharacterTextSplitter.forLanguage(
            .swift, chunkSize: 60, chunkOverlap: 0)
        let code = """
            struct Foo {
                func bar() -> Int { 1 }
                func baz() -> Int { 2 }
            }
            class Thing {
                var x = 0
            }
            """
        let chunks = s.splitText(code)
        #expect(chunks.count > 1)
    }

    @Test func csharpNoJavaKeywords() throws {
        // C# should have "foreach" but Java should not.
        #expect(Language.csharp.separators.contains("\nforeach "))
        #expect(!Language.java.separators.contains("\nforeach "))
    }

    @Test func elixirNoWhile() throws {
        #expect(!Language.elixir.separators.contains("\nwhile "))
    }

    @Test func tokenizer() throws {
        let tokenizer = Tokenizer(
            chunkOverlap: 3,
            tokensPerChunk: 7,
            decode: { chars in String(chars.map { Character(UnicodeScalar($0)!) }) },
            encode: { text in text.unicodeScalars.map { Int($0.value) } }
        )
        let out = try splitTextOnTokens(text: "foo bar baz 123", tokenizer: tokenizer)
        #expect(out == ["foo bar", "bar baz", "baz 123"])
    }
}
