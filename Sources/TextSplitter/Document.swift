/// A piece of text with associated key-value metadata.
public struct Document: Sendable, Equatable {
    public var pageContent: String
    public var metadata: [String: String]

    @inlinable
    public init(pageContent: String, metadata: [String: String] = [:]) {
        self.pageContent = pageContent
        self.metadata = metadata
    }
}
