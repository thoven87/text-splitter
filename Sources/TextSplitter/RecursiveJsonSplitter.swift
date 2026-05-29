// MARK: - JSONValue

/// A typed JSON value that can be serialised without Foundation.
public indirect enum JSONValue: Sendable, Equatable, Hashable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    // MARK: - JSON serialisation

    /// Produces a compact JSON string.  Key order is alphabetically sorted for
    /// deterministic output and size measurements.
    public func jsonString() -> String {
        switch self {
        case .null: return "null"
        case .bool(let b): return b ? "true" : "false"
        case .int(let n): return "\(n)"
        case .double(let d): return serializeDouble(d)
        case .string(let s): return "\"\(escapeJSON(s))\""
        case .array(let a):
            return "[" + a.map { $0.jsonString() }.joined(separator: ", ") + "]"
        case .object(let o):
            let pairs = o.keys.sorted().map { k in
                "\"\(escapeJSON(k))\": \(o[k]!.jsonString())"
            }
            return "{" + pairs.joined(separator: ", ") + "}"
        }
    }

    private func serializeDouble(_ d: Double) -> String {
        if d.truncatingRemainder(dividingBy: 1) == 0, !d.isInfinite, !d.isNaN {
            return "\(Int(d))"
        }
        return "\(d)"
    }

    private func escapeJSON(_ s: String) -> String {
        var out = ""
        for c in s {
            switch c {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                let sv = c.unicodeScalars.first!.value
                if sv < 0x20 {
                    let hex = String(sv, radix: 16, uppercase: false)
                    let pad = String(repeating: "0", count: max(0, 4 - hex.count))
                    out += "\\u\(pad)\(hex)"
                } else {
                    out.append(c)
                }
            }
        }
        return out
    }
}

// MARK: - RecursiveJsonSplitter

/// Splits a JSON object into smaller `[String: JSONValue]` chunks while
/// preserving the nested structure.
public struct RecursiveJsonSplitter: Sendable {
    public let maxChunkSize: Int
    public let minChunkSize: Int

    public init(maxChunkSize: Int = 2000, minChunkSize: Int? = nil) {
        self.maxChunkSize = maxChunkSize
        self.minChunkSize = minChunkSize ?? max(maxChunkSize - 200, 50)
    }

    // MARK: - Public API

    /// Splits a JSON object into a list of smaller objects.
    public func splitJSON(_ data: [String: JSONValue], convertLists: Bool = false) -> [[String:
        JSONValue]]
    {
        let input =
            convertLists ? convertListsToObjects(JSONValue.object(data)) : JSONValue.object(data)
        guard case .object(let obj) = input else { return [] }
        var chunks: [[String: JSONValue]] = [[:]]
        splitValue(JSONValue.object(obj), path: [], into: &chunks)
        if chunks.last?.isEmpty == true { chunks.removeLast() }
        return chunks
    }

    /// Splits and serialises to JSON strings.
    public func splitText(_ data: [String: JSONValue], convertLists: Bool = false) -> [String] {
        splitJSON(data, convertLists: convertLists).map { JSONValue.object($0).jsonString() }
    }

    /// Creates `Document` objects from a list of JSON objects.
    public func createDocuments(
        texts: [[String: JSONValue]],
        convertLists: Bool = false,
        metadatas: [[String: String]]? = nil
    ) -> [Document] {
        let metas = metadatas ?? Array(repeating: [:], count: texts.count)
        var docs: [Document] = []
        for (i, obj) in texts.enumerated() {
            for chunk in splitText(obj, convertLists: convertLists) {
                docs.append(Document(pageContent: chunk, metadata: metas[i]))
            }
        }
        return docs
    }

    // MARK: - Core recursion

    private func splitValue(
        _ value: JSONValue,
        path: [String],
        into chunks: inout [[String: JSONValue]]
    ) {
        if case .object(let obj) = value, !obj.isEmpty {
            for key in obj.keys.sorted() {
                guard let val = obj[key] else { continue }
                let newPath = path + [key]
                let chunkSize = jsonSize(chunks[chunks.count - 1])
                let itemSize = jsonSize([key: val])
                let remaining = maxChunkSize - chunkSize

                if itemSize < remaining {
                    setNested(val, at: newPath, in: &chunks[chunks.count - 1])
                } else {
                    if chunkSize >= minChunkSize {
                        chunks.append([:])
                    }
                    splitValue(val, path: newPath, into: &chunks)
                }
            }
        } else if !path.isEmpty {
            setNested(value, at: path, in: &chunks[chunks.count - 1])
        }
    }

    private func setNested(
        _ value: JSONValue,
        at path: [String],
        in dict: inout [String: JSONValue]
    ) {
        guard !path.isEmpty else { return }
        if path.count == 1 {
            dict[path[0]] = value
        } else {
            var nested: [String: JSONValue]
            if case .object(let existing) = dict[path[0]] {
                nested = existing
            } else {
                nested = [:]
            }
            setNested(value, at: Array(path.dropFirst()), in: &nested)
            dict[path[0]] = .object(nested)
        }
    }

    private func jsonSize(_ dict: [String: JSONValue]) -> Int {
        JSONValue.object(dict).jsonString().count
    }

    // MARK: - List conversion

    private func convertListsToObjects(_ value: JSONValue) -> JSONValue {
        switch value {
        case .object(let o):
            return .object(
                Dictionary(
                    uniqueKeysWithValues:
                        o.map { ($0.key, convertListsToObjects($0.value)) }))
        case .array(let a):
            let dict = Dictionary(
                uniqueKeysWithValues:
                    a.enumerated().map { ("\($0.offset)", convertListsToObjects($0.element)) })
            return .object(dict)
        default:
            return value
        }
    }
}
