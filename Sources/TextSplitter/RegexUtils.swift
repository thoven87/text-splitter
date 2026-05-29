// MARK: - Sendable wrapper for Regex<AnyRegexOutput>

/// A `Sendable` wrapper for `Regex<AnyRegexOutput>`.
struct SendableRegex: Sendable {
    nonisolated(unsafe) let regex: Regex<AnyRegexOutput>
    init(_ r: Regex<AnyRegexOutput>) { regex = r }
}

// MARK: - Pattern helpers

/// Escapes all regex metacharacters in `s` so it can be used as a literal pattern.
@inline(__always)
func escapeRegexPattern(_ s: String) -> String {
    let meta: Set<Character> = [
        ".", "+", "*", "?", "^", "$", "{", "}", "(", ")", "|", "[", "]", "\\",
    ]
    return String(s.flatMap { c -> String in meta.contains(c) ? "\\" + String(c) : String(c) })
}

// MARK: - Zero-copy Substring split (primary path)

/// Splits `text` on every match of `regex`, returning `Substring` views into `text`.
/// No heap allocation occurs for the individual pieces.
///
/// For `.start` / `.end` the separator and its adjacent text piece share a single
/// extended `Substring` range — no string concatenation.
func splitWithRegexSubstrings(
    _ text: Substring,
    regex: Regex<AnyRegexOutput>,
    keepSeparator: SeparatorPlacement
) -> [Substring] {

    if keepSeparator == .discard {
        var result: [Substring] = []
        var lastEnd = text.startIndex
        for match in text.matches(of: regex) {
            let piece = text[lastEnd..<match.range.lowerBound]
            if !piece.isEmpty { result.append(piece) }
            lastEnd = match.range.upperBound
        }
        let tail = text[lastEnd...]
        if !tail.isEmpty { result.append(tail) }
        return result
    }

    // Collect K+1 text bits and K separator bits (all Substring, zero-copy).
    var textBits: [Substring] = []
    var sepBits: [Substring] = []
    var lastEnd = text.startIndex
    for match in text.matches(of: regex) {
        textBits.append(text[lastEnd..<match.range.lowerBound])
        sepBits.append(text[match.range])
        lastEnd = match.range.upperBound
    }
    textBits.append(text[lastEnd...])  // tail

    let K = sepBits.count
    var result = [Substring]()
    result.reserveCapacity(K + 1)

    switch keepSeparator {
    case .end:
        for i in 0..<K {
            let combined = text[textBits[i].startIndex..<sepBits[i].endIndex]
            if !combined.isEmpty { result.append(combined) }
        }
        if !textBits[K].isEmpty { result.append(textBits[K]) }

    case .start:
        if !textBits[0].isEmpty { result.append(textBits[0]) }
        for i in 0..<K {
            let combined = text[sepBits[i].startIndex..<textBits[i + 1].endIndex]
            if !combined.isEmpty { result.append(combined) }
        }

    case .discard:
        fatalError("unreachable")
    }
    return result
}

/// Splits `text` into individual character `Substring` views (empty-separator fallback).
func splitIntoCharsSubstrings(_ text: Substring) -> [Substring] {
    var result = [Substring]()
    result.reserveCapacity(text.count)
    var idx = text.startIndex
    while idx < text.endIndex {
        let next = text.index(after: idx)
        result.append(text[idx..<next])
        idx = next
    }
    return result
}
