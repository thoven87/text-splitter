// Lightweight diagnostic for chunk configuration.
// Run before embedding to catch misconfigured splitters early.

/// Statistics produced by ``ChunkStats/analyze(_:chunkSize:tokenizer:)``.
///
/// Use this to sanity-check a splitter configuration on representative
/// sample text before committing to a full embedding pass.
///
/// **Reading the numbers:**
/// - `underfilledRatio` above ~0.3 suggests `chunkSize` is too large for the
///   corpus — most content is too short to fill a chunk.
/// - `atCeilingRatio` above ~0.1 suggests separators are too coarse — the
///   merger keeps hitting the size limit without finding a natural boundary.
/// - A very wide `p25…p75` range means chunk sizes are highly variable;
///   consider a smaller, more specific separator list.
/// - `tokenRange` shows whether chunks fit within the token budget your
///   embedding model supports.
public struct ChunkStats: Sendable, CustomStringConvertible {
    /// Number of chunks produced.
    public let count: Int
    /// Total characters across all chunks.
    public let totalCharacters: Int
    /// Mean chunk length in characters.
    public let mean: Int
    /// Shortest chunk.
    public let min: Int
    /// Longest chunk.
    public let max: Int
    /// 25th-percentile length.
    public let p25: Int
    /// Median length.
    public let p50: Int
    /// 75th-percentile length.
    public let p75: Int
    /// Chunks shorter than half `chunkSize` — likely orphaned fragments.
    public let underfilledCount: Int
    /// Chunks whose length equals `chunkSize` — hit the hard ceiling,
    /// possibly cut mid-sentence.
    public let atCeilingCount: Int
    /// Token-count range `(min, max)` when a `Tokenizer` was supplied.
    /// `nil` when analysed without a tokenizer.
    public let tokenRange: (min: Int, max: Int)?

    /// Fraction of chunks below half `chunkSize`.
    public var underfilledRatio: Double {
        count == 0 ? 0 : Double(underfilledCount) / Double(count)
    }
    /// Fraction of chunks at the hard ceiling.
    public var atCeilingRatio: Double {
        count == 0 ? 0 : Double(atCeilingCount) / Double(count)
    }

    public var description: String {
        var lines = [
            "chunks  : \(count)",
            "length  : min=\(min)  p25=\(p25)  p50=\(p50)  p75=\(p75)  max=\(max)  mean=\(mean)",
            "underfilled (<50% of chunkSize): \(underfilledCount) (\(pct(underfilledRatio)))",
            "at ceiling (==chunkSize)       : \(atCeilingCount) (\(pct(atCeilingRatio)))",
        ]
        if let t = tokenRange {
            lines.append("tokens  : min=\(t.min)  max=\(t.max)")
        }
        return lines.joined(separator: "\n")
    }

    private func pct(_ r: Double) -> String {
        "\(Int((r * 100).rounded()))%"
    }
}

// MARK: - Analysis

extension ChunkStats {

    /// Analyses the chunks produced by `splitter` on `samples`.
    ///
    /// - Parameters:
    ///   - samples: Representative texts from your corpus. A handful of
    ///     documents (5–20) is usually enough to characterise chunk behaviour.
    ///   - splitter: Any `TextSplitting` conformer to evaluate.
    ///   - tokenizer: Optional tokenizer for measuring token counts.
    ///     Pass one when your embedding model has a fixed sequence-length limit.
    public static func analyze(
        _ samples: [String],
        using splitter: some TextSplitting,
        tokenizer: Tokenizer? = nil
    ) -> ChunkStats {
        let chunkSize = splitter.config.chunkSize
        let chunks = samples.flatMap { splitter.splitText($0) }
        return compute(chunks: chunks, chunkSize: chunkSize, tokenizer: tokenizer)
    }

    /// Analyses a pre-computed chunk array directly.
    public static func analyze(
        chunks: [String],
        chunkSize: Int,
        tokenizer: Tokenizer? = nil
    ) -> ChunkStats {
        compute(chunks: chunks, chunkSize: chunkSize, tokenizer: tokenizer)
    }

    // MARK: - Private

    private static func compute(
        chunks: [String],
        chunkSize: Int,
        tokenizer: Tokenizer?
    ) -> ChunkStats {
        guard !chunks.isEmpty else {
            return ChunkStats(
                count: 0, totalCharacters: 0, mean: 0,
                min: 0, max: 0, p25: 0, p50: 0, p75: 0,
                underfilledCount: 0, atCeilingCount: 0, tokenRange: nil)
        }

        let lengths = chunks.map(\.count).sorted()
        let total = lengths.reduce(0, +)
        let half = chunkSize / 2

        let underfilledCount = lengths.filter { $0 < half }.count
        let atCeilingCount = lengths.filter { $0 >= chunkSize }.count

        let tokenRange: (Int, Int)? = tokenizer.map { tok in
            var minTok = Int.max
            var maxTok = 0
            for chunk in chunks {
                // Non-throwing call — encode errors are treated as 0 tokens.
                let n = (try? tok.encode(chunk))?.count ?? 0
                if n < minTok { minTok = n }
                if n > maxTok { maxTok = n }
            }
            return (minTok == Int.max ? 0 : minTok, maxTok)
        }

        return ChunkStats(
            count: chunks.count,
            totalCharacters: total,
            mean: total / chunks.count,
            min: lengths.first!,
            max: lengths.last!,
            p25: lengths[lengths.count / 4],
            p50: lengths[lengths.count / 2],
            p75: lengths[lengths.count * 3 / 4],
            underfilledCount: underfilledCount,
            atCeilingCount: atCeilingCount,
            tokenRange: tokenRange
        )
    }
}
