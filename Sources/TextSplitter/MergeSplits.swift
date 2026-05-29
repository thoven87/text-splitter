// MARK: - String utilities

/// Strips leading and trailing whitespace.
@inline(__always)
func trimWhitespace(_ s: some StringProtocol) -> String {
    var v = s[s.startIndex...]
    while v.first?.isWhitespace == true { v = v.dropFirst() }
    while v.last?.isWhitespace == true { v = v.dropLast() }
    return String(v)
}

// MARK: - Piece-based merge

/// Merges `splits` into chunks that fit within `config.chunkSize`.
func mergeSplitsPieces(
    _ splits: ContiguousArray<(Substring, Int)>,
    separator: String,
    sepLen: Int,
    config: SplitterConfig
) -> [String] {
    var docs: [String] = []
    var buf = ContiguousArray<(Substring, Int)>()
    var winStart = 0
    var total = 0

    for (s, sLen) in splits {
        let addSep = (buf.count - winStart == 0) ? 0 : sepLen

        if total + sLen + addSep > config.chunkSize {
            let wc = buf.count - winStart
            if wc > 0 {
                if let doc = joinPieces(
                    buf, from: winStart, separator: separator, sepLen: sepLen,
                    strip: config.stripWhitespace)
                {
                    docs.append(doc)
                }
                while total > config.chunkOverlap
                    || (buf.count - winStart > 0
                        && total + sLen + sepLen > config.chunkSize
                        && total > 0)
                {
                    let wc2 = buf.count - winStart
                    total -= buf[winStart].1 + (wc2 > 1 ? sepLen : 0)
                    winStart += 1
                }
                if winStart > 0 {
                    buf.removeFirst(winStart)
                    winStart = 0
                }
            }
        }
        buf.append((s, sLen))
        total += sLen + (buf.count - winStart > 1 ? sepLen : 0)
    }

    if let doc = joinPieces(
        buf, from: winStart, separator: separator, sepLen: sepLen,
        strip: config.stripWhitespace)
    {
        docs.append(doc)
    }
    return docs
}

/// Joins `buf[from...]` into a single `String`.
@inline(__always)
private func joinPieces(
    _ buf: ContiguousArray<(Substring, Int)>,
    from start: Int,
    separator: String,
    sepLen: Int,
    strip: Bool
) -> String? {
    let count = buf.count - start
    guard count > 0 else { return nil }

    let totalLen = buf[start...].reduce(0) { $0 + $1.1 } + max(0, count - 1) * sepLen
    var result = ""
    result.reserveCapacity(totalLen)
    var first = true
    for i in start..<buf.count {
        if !first { result += separator }
        result += buf[i].0
        first = false
    }
    if strip { result = trimWhitespace(result) }
    return result.isEmpty ? nil : result
}

// MARK: - String-slice merge (used by SentenceTextSplitter and other String-based callers)

/// Merges `splits` into chunks that fit within `config.chunkSize`.
func mergeSplits(
    _ splits: some Sequence<String>,
    separator: String,
    config: SplitterConfig
) -> [String] {
    let sepLen = config.length(separator[...])
    var docs: [String] = []
    var buf = ContiguousArray<(String, Int)>()
    var winStart = 0
    var total = 0

    for d in splits {
        let dLen = config.length(d)
        let addSep = (buf.count - winStart == 0) ? 0 : sepLen

        if total + dLen + addSep > config.chunkSize {
            let wc = buf.count - winStart
            if wc > 0 {
                if let doc = joinDocs(
                    buf[winStart...], separator: separator, sepLen: sepLen,
                    strip: config.stripWhitespace)
                {
                    docs.append(doc)
                }
                while total > config.chunkOverlap
                    || (buf.count - winStart > 0
                        && total + dLen + sepLen > config.chunkSize
                        && total > 0)
                {
                    let wc2 = buf.count - winStart
                    total -= buf[winStart].1 + (wc2 > 1 ? sepLen : 0)
                    winStart += 1
                }
                if winStart > 0 {
                    buf.removeFirst(winStart)
                    winStart = 0
                }
            }
        }
        buf.append((d, dLen))
        total += dLen + (buf.count - winStart > 1 ? sepLen : 0)
    }

    if let doc = joinDocs(
        buf[winStart...], separator: separator, sepLen: sepLen,
        strip: config.stripWhitespace)
    {
        docs.append(doc)
    }
    return docs
}

@inline(__always)
private func joinDocs(
    _ docs: ArraySlice<(String, Int)>,
    separator: String,
    sepLen: Int,
    strip: Bool
) -> String? {
    guard !docs.isEmpty else { return nil }
    var totalLen = max(0, docs.count - 1) * sepLen
    for (_, len) in docs { totalLen += len }
    var result = ""
    result.reserveCapacity(totalLen)
    var first = true
    for (s, _) in docs {
        if !first { result += separator }
        result += s
        first = false
    }
    if strip { result = trimWhitespace(result) }
    return result.isEmpty ? nil : result
}

// MARK: - Start-index helper

/// Returns the character offset of `needle` in `haystack` at or after `from`.
func findSubstringOffset(_ needle: String, in haystack: String, from: Int) -> Int? {
    guard !needle.isEmpty, from >= 0 else { return nil }
    guard
        let startIdx = haystack.index(
            haystack.startIndex, offsetBy: from, limitedBy: haystack.endIndex),
        startIdx < haystack.endIndex
    else { return nil }
    guard let range = haystack[startIdx...].firstRange(of: needle) else { return nil }
    return haystack.distance(from: haystack.startIndex, to: range.lowerBound)
}
