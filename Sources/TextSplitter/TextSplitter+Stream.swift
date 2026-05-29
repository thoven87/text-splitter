// Transforms an AsyncSequence<String> into a chunked AsyncSequence<String>.

extension TextSplitting {

    /// Returns a lazy `AsyncSequence` that splits text fragments from `stream`
    /// into chunks, emitting each chunk as soon as it is committable.
    ///
    /// ```swift
    /// for try await chunk in splitter.split(pdf.textStream()) {
    ///     await store.upsert(Document(pageContent: chunk))
    /// }
    /// ```
    ///
    /// The upstream is pulled once per downstream `next()` call.
    public func split<Base: AsyncSequence & Sendable>(
        _ stream: Base
    ) -> SplittingSequence<Self, Base> where Base.Element == String {
        SplittingSequence(splitter: self, base: stream)
    }
}

// MARK: - SplittingSequence

/// The `AsyncSequence` returned by ``TextSplitting/split(_:)``.
///
/// Conforms to `AsyncSequence`, so it composes with any standard operator
/// (`map`, `filter`, `prefix`, etc.) and can be iterated with `for try await`.
public struct SplittingSequence<S: TextSplitting, Base: AsyncSequence & Sendable>: Sendable
where Base.Element == String {
    let splitter: S
    let base: Base
}

extension SplittingSequence: AsyncSequence {
    public typealias Element = String

    public struct AsyncIterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator
        let splitter: S
        let threshold: Int
        var buffer: String = ""
        var pending = ContiguousArray<String>()
        var pendingIndex: Int = 0

        init(base: Base.AsyncIterator, splitter: S) {
            self.base = base
            self.splitter = splitter
            self.threshold = splitter.config.chunkSize + splitter.config.chunkOverlap
        }

        public mutating func next() async throws -> String? {
            if pendingIndex < pending.count {
                return advance()
            }

            while let fragment = try await base.next() {
                guard !fragment.isEmpty else { continue }

                if splitter.config.stripWhitespace,
                    !buffer.isEmpty,
                    buffer.last?.isWhitespace == false,
                    fragment.first?.isWhitespace == false
                {
                    buffer += " "
                }
                buffer += fragment

                guard buffer.count > threshold else { continue }

                let chunks = splitter.splitText(buffer)
                guard chunks.count > 1 else { continue }

                pending.removeAll(keepingCapacity: true)
                pending.append(contentsOf: chunks.dropLast())
                buffer = chunks.last ?? ""
                pendingIndex = 0
                return advance()
            }

            guard !buffer.isEmpty else { return nil }
            let remaining = splitter.splitText(buffer)
            buffer = ""
            guard !remaining.isEmpty else { return nil }
            pending.removeAll(keepingCapacity: true)
            pending.append(contentsOf: remaining.dropFirst())
            pendingIndex = 0
            return remaining.first
        }

        private mutating func advance() -> String {
            let chunk = pending[pendingIndex]
            pendingIndex += 1
            if pendingIndex == pending.count {
                pending.removeAll(keepingCapacity: true)
                pendingIndex = 0
            }
            return chunk
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator(), splitter: splitter)
    }
}
