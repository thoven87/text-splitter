/// Splits React (JSX), Vue, and Svelte code by detecting component tag
/// boundaries in addition to standard JS syntax separators.
///
/// Builds the separator list on each `splitText(_:)` call from the configured
/// separators, standard JS keywords, and component tags extracted from the input.
public struct JSFrameworkTextSplitter: TextSplitting {
    public let config: SplitterConfig
    /// Optional fixed separators prepended before the JS separators.
    private let extraSeparators: [String]

    private static let jsSeparators: [String] = [
        "\nexport ", " export ",
        "\nfunction ", "\nasync function ", " async function ",
        "\nconst ", "\nlet ", "\nvar ",
        "\nclass ", " class ",
        "\nif ", " if ",
        "\nfor ", " for ",
        "\nwhile ", " while ",
        "\nswitch ", " switch ",
        "\ncase ", " case ",
        "\ndefault ", " default ",
    ]

    private let tagRegex = #/<\s*([a-zA-Z0-9]+)[^>]*>/#

    public init(
        separators: [String] = [],
        chunkSize: Int = 2000,
        chunkOverlap: Int = 0,
        config: SplitterConfig? = nil
    ) throws(SplitterError) {
        if let cfg = config {
            self.config = cfg
        } else {
            self.config = try SplitterConfig(chunkSize: chunkSize, chunkOverlap: chunkOverlap)
        }
        self.extraSeparators = separators
    }

    public func splitText(_ text: String) -> [String] {
        // Collect unique opening component tags in document order.
        var seen: Set<String> = []
        var componentSeps: [String] = []
        for match in text.matches(of: tagRegex) {
            let name = String(match.1)
            if seen.insert(name).inserted {
                componentSeps.append("<\(name)")
            }
        }

        let separators =
            extraSeparators
            + Self.jsSeparators
            + componentSeps
            + ["<>", "\n\n", "&&\n", "||\n"]

        guard
            let splitter = try? RecursiveCharacterTextSplitter(
                separators: separators,
                isSeparatorRegex: false,
                config: config
            )
        else {
            return [text]
        }
        return splitter.splitText(text)
    }
}
// TODO: revisit if regex conforms to Sendable
extension JSFrameworkTextSplitter: @unchecked Sendable {}
