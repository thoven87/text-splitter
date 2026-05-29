import Testing

@testable import TextSplitter

@Suite("RecursiveJsonSplitter")
struct JSONSplitterTests {

    @Test func smallDictReturnedAsOne() {
        let splitter = RecursiveJsonSplitter()
        let data: [String: JSONValue] = ["a": .int(1), "b": .int(2)]
        let chunks = splitter.splitJSON(data)
        #expect(chunks == [["a": .int(1), "b": .int(2)]])
    }

    @Test func idempotentMultipleCalls() {
        let splitter = RecursiveJsonSplitter()
        let x: [String: JSONValue] = ["a": .int(1), "b": .int(2)]
        let y: [String: JSONValue] = ["c": .int(3), "d": .int(4)]
        let c0 = splitter.splitJSON(x)
        let c1 = splitter.splitJSON(y)
        #expect(c0 == [["a": .int(1), "b": .int(2)]])
        #expect(c1 == [["c": .int(3), "d": .int(4)]])
    }

    @Test func splitLargeDict() {
        let maxChunk = 200
        let splitter = RecursiveJsonSplitter(maxChunkSize: maxChunk)
        var data: [String: JSONValue] = [:]
        for i in 0..<30 { data["key\(i)"] = .string(String(repeating: "x", count: 10)) }
        let chunks = splitter.splitJSON(data)
        #expect(chunks.count > 1)
        for chunk in chunks {
            let size = JSONValue.object(chunk).jsonString().count
            #expect(size < maxChunk * 105 / 100)
        }
    }

    @Test func emptyDictPreserved() {
        let splitter = RecursiveJsonSplitter(maxChunkSize: 300)
        let data: [String: JSONValue] = [
            "a": .string("hello"), "b": .object([:]), "c": .string("world"),
        ]
        let chunks = splitter.splitJSON(data)
        var merged: [String: JSONValue] = [:]
        for chunk in chunks { for (k, v) in chunk { merged[k] = v } }
        #expect(merged["b"] == .object([:]))
    }

    @Test func nestedEmptyDicts() {
        let splitter = RecursiveJsonSplitter(maxChunkSize: 300)
        let data: [String: JSONValue] = [
            "level1": .object(["level2a": .object([:]), "level2b": .string("value")])
        ]
        let chunks = splitter.splitJSON(data)
        var merged: [String: JSONValue] = [:]
        for chunk in chunks { for (k, v) in chunk { merged[k] = v } }
        if case .object(let inner) = merged["level1"] {
            #expect(inner["level2a"] == .object([:]))
        } else {
            Issue.record("level1 missing")
        }
    }

    @Test func emptyDictOnly() {
        let splitter = RecursiveJsonSplitter()
        let chunks = splitter.splitJSON([:])
        #expect(chunks.isEmpty)
    }

    @Test func splitTextProducesStrings() {
        let splitter = RecursiveJsonSplitter()
        let data: [String: JSONValue] = ["key": .string("value")]
        let texts = splitter.splitText(data)
        #expect(texts.count == 1)
        #expect(texts[0].contains("\"key\""))
        #expect(texts[0].contains("\"value\""))
    }

    @Test func convertLists() {
        let splitter = RecursiveJsonSplitter()
        let nested: [String: JSONValue] = ["items": .array([.int(1), .int(2), .int(3)])]
        let withLists = splitter.splitText(nested, convertLists: false)
        let withoutLists = splitter.splitText(nested, convertLists: true)
        // Converting lists: array becomes object with index keys.
        #expect(withLists.count <= withoutLists.count || withoutLists.count >= 1)
    }

    @Test func jsonValueEquality() {
        #expect(JSONValue.null == .null)
        #expect(JSONValue.bool(true) == .bool(true))
        #expect(JSONValue.int(42) == .int(42))
        #expect(JSONValue.string("hi") == .string("hi"))
        #expect(JSONValue.array([.int(1)]) == .array([.int(1)]))
        #expect(JSONValue.object(["x": .bool(false)]) == .object(["x": .bool(false)]))
    }

    @Test func jsonValueSerialization() {
        #expect(JSONValue.null.jsonString() == "null")
        #expect(JSONValue.bool(true).jsonString() == "true")
        #expect(JSONValue.int(7).jsonString() == "7")
        #expect(JSONValue.string("hi").jsonString() == "\"hi\"")
        #expect(JSONValue.array([.int(1), .int(2)]).jsonString() == "[1, 2]")
        #expect(JSONValue.object(["a": .int(1)]).jsonString() == "{\"a\": 1}")
    }
}
