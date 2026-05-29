// Scans HTML tags and text nodes in order, grouping content under
// the h1–h6 headers that are open at each point in the document.

/// Splits HTML content into `Document` objects using specified header tags
/// (e.g. h1, h2) to build a section-hierarchy stored as document metadata.
public struct HTMLHeaderTextSplitter: Sendable {
    private let headerList: [(tag: String, name: String)]  // sorted h1 < h2 < …
    public let returnEachElement: Bool

    public init(
        headersToSplitOn: [(String, String)],
        returnEachElement: Bool = false
    ) {
        self.headerList = headersToSplitOn.sorted {
            (Int(String($0.0.dropFirst())) ?? 9999) < (Int(String($1.0.dropFirst())) ?? 9999)
        }
        self.returnEachElement = returnEachElement
    }

    // MARK: - Public API

    public func splitText(_ html: String) -> [Document] {
        let headerTags = Set(headerList.map(\.tag))
        let nameFor = Dictionary(uniqueKeysWithValues: headerList)

        // Active header state: updated as we encounter header tags.
        var active: [ActiveHeader] = []
        var chunk: [String] = []
        var tagStack: [String] = []  // tracks nesting depth
        var docs: [Document] = []

        for token in HTMLTokenizer(html) {
            switch token {
            case .open(let tag, let selfClose):
                tagStack.append(tag)
                let depth = tagStack.count

                if headerTags.contains(tag) {
                    if !returnEachElement, let doc = makeDoc(&chunk, headers: active) {
                        docs.append(doc)
                    }
                    let level = Int(tag.dropFirst()) ?? 9999
                    active.removeAll { $0.level >= level }
                    active.append(
                        ActiveHeader(
                            tag: tag, name: nameFor[tag] ?? tag,
                            text: "", level: level, depth: depth))
                }

                if selfClose { tagStack = Array(tagStack.dropLast()) }

            case .close(let tag):
                let depth = tagStack.count
                active.removeAll { $0.tag == tag && $0.depth == depth }
                tagStack = tagStack.isEmpty ? [] : Array(tagStack.dropLast())

            case .text(let raw):
                let flat = flattenText(raw)
                guard !flat.isEmpty else { continue }

                let depth = tagStack.count

                // If we're directly inside a header tag, fill its text entry.
                if let innerTag = tagStack.last,
                    headerTags.contains(innerTag),
                    let idx = active.lastIndex(where: { $0.tag == innerTag && $0.text.isEmpty })
                {
                    active[idx].text = flat
                    let meta = Dictionary(uniqueKeysWithValues: active.map { ($0.name, $0.text) })
                    docs.append(Document(pageContent: flat, metadata: meta))
                } else {
                    active.removeAll { $0.depth > depth }

                    if returnEachElement {
                        let meta = Dictionary(
                            uniqueKeysWithValues: active.map { ($0.name, $0.text) })
                        docs.append(Document(pageContent: flat, metadata: meta))
                    } else {
                        chunk.append(flat)
                    }
                }
            }
        }

        if !returnEachElement, let doc = makeDoc(&chunk, headers: active) {
            docs.append(doc)
        }
        return docs
    }

    // MARK: - Helpers

    private func makeDoc(_ lines: inout [String], headers: [ActiveHeader]) -> Document? {
        let text = lines.filter { !trimWhitespace($0).isEmpty }.joined(separator: "  \n")
        lines.removeAll()
        guard !trimWhitespace(text).isEmpty else { return nil }
        let meta = Dictionary(uniqueKeysWithValues: headers.map { ($0.name, $0.text) })
        return Document(pageContent: text, metadata: meta)
    }

    private func flattenText(_ s: Substring) -> String {
        var out = ""
        var prevSpace = false
        for c in s {
            if c.isWhitespace {
                if !prevSpace {
                    out.append(" ")
                    prevSpace = true
                }
            } else {
                out.append(c)
                prevSpace = false
            }
        }
        return trimWhitespace(out)
    }
}

// MARK: - Active header record

private struct ActiveHeader {
    var tag: String  // e.g. "h2"
    var name: String  // metadata key, e.g. "Header 2"
    var text: String  // header text content
    var level: Int  // numeric, e.g. 2
    var depth: Int  // DOM depth when this header was opened
}

// MARK: - Minimal HTML Tokenizer

private enum HTMLTok {
    case open(tag: String, selfClose: Bool)
    case close(tag: String)
    case text(Substring)
}

private struct HTMLTokenizer: Sequence, Sendable {
    private let html: String
    init(_ html: String) { self.html = html }

    func makeIterator() -> Iterator { Iterator(html) }

    struct Iterator: IteratorProtocol {
        private var idx: String.Index
        private let html: String

        init(_ html: String) {
            self.html = html
            self.idx = html.startIndex
        }

        mutating func next() -> HTMLTok? {
            guard idx < html.endIndex else { return nil }

            if html[idx] != "<" {
                let start = idx
                while idx < html.endIndex && html[idx] != "<" { advance() }
                let text = html[start..<idx]
                return text.isEmpty ? next() : .text(text)
            }

            advance()
            guard idx < html.endIndex else { return nil }

            if html[idx] == "/" {
                advance()
                let name = scanName()
                skipUntil(">")
                advanceIfAt(">")
                return name.isEmpty ? next() : .close(tag: name)
            }

            // Opening / self-closing tag.
            let name = scanName()
            guard !name.isEmpty else {
                skipUntil(">")
                advanceIfAt(">")
                return next()
            }
            if name.hasPrefix("!") || name.hasPrefix("?") {
                skipUntil(">")
                advanceIfAt(">")
                return next()
            }

            // Scan attributes to detect self-close.
            var selfClose = false
            var inQ: Character? = nil
            while idx < html.endIndex {
                let c = html[idx]
                if let q = inQ {
                    if c == q { inQ = nil }
                } else if c == "\"" || c == "'" {
                    inQ = c
                } else if c == "/" {
                    selfClose = true
                } else if c == ">" {
                    advance()
                    break
                }
                advance()
            }
            return .open(tag: name, selfClose: selfClose)
        }

        // MARK: - Scanner helpers
        private mutating func advance() {
            guard idx < html.endIndex else { return }
            html.formIndex(after: &idx)
        }
        private mutating func advanceIfAt(_ c: Character) {
            if idx < html.endIndex && html[idx] == c { advance() }
        }
        private mutating func skipUntil(_ c: Character) {
            while idx < html.endIndex && html[idx] != c { advance() }
        }
        private mutating func scanName() -> String {
            var name = ""
            while idx < html.endIndex {
                let c = html[idx]
                if c == ">" || c.isWhitespace || c == "/" { break }
                name.append(c)
                advance()
            }
            return name.lowercased()
        }
    }
}
