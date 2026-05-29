/// Core protocol every splitter must satisfy.
public protocol TextSplitting: Sendable {
    var config: SplitterConfig { get }
    /// Splits `text` into a list of chunks.
    func splitText(_ text: String) -> [String]
}

// MARK: - Document helpers

extension TextSplitting {
    /// Creates `Document` objects from a list of texts, optionally enriching
    /// each document's metadata.  When `config.addStartIndex` is `true` a
    /// `"start_index"` key (character offset in the original text) is injected.
    public func createDocuments(
        from texts: [String],
        metadatas: [[String: String]]? = nil
    ) -> [Document] {
        let metas = metadatas ?? Array(repeating: [:], count: texts.count)
        var result: [Document] = []
        for (i, text) in texts.enumerated() {
            var previousChunkLen = 0
            var searchOffset = 0
            for chunk in splitText(text) {
                var meta = metas[i]
                if config.addStartIndex {
                    let offset = max(0, searchOffset + previousChunkLen - config.chunkOverlap)
                    if let idx = findSubstringOffset(chunk, in: text, from: offset) {
                        searchOffset = idx
                        meta["start_index"] = "\(idx)"
                    }
                    previousChunkLen = chunk.count
                }
                result.append(Document(pageContent: chunk, metadata: meta))
            }
        }
        return result
    }

    /// Splits a sequence of `Document` objects, preserving their metadata.
    public func splitDocuments(_ documents: [Document]) -> [Document] {
        createDocuments(
            from: documents.map(\.pageContent),
            metadatas: documents.map(\.metadata)
        )
    }
}
