# Getting Started

Add TextSplitter to your package, pick a splitter, produce chunks.

## Installation

```swift
// Package.swift
.package(url: "https://github.com/thoven87/text-splitter", from: "1.0.0")
```

```swift
.product(name: "TextSplitter", package: "text-splitter")
```

## Choosing a splitter

| Content | Splitter |
|---|---|
| General prose | ``RecursiveCharacterTextSplitter`` |
| Source code | ``RecursiveCharacterTextSplitter/forLanguage(_:chunkSize:chunkOverlap:keepSeparator:stripWhitespace:)`` |
| Markdown with headers | ``MarkdownHeaderTextSplitter`` |
| HTML | ``HTMLHeaderTextSplitter`` |
| JSON objects | ``RecursiveJsonSplitter`` |
| JSX / Vue / Svelte | ``JSFrameworkTextSplitter`` |
| Sentences | ``SentenceTextSplitter`` |

## Chunk size units

`chunkSize` and `chunkOverlap` are measured in **characters** by default
(`lengthFunction: { $0.count }`), not tokens. A rough conversion for English prose:

| Token budget | `chunkSize` (chars) | `chunkOverlap` (chars) |
|---|---|---|
| 128 tokens | 512 | 64 |
| 256 tokens | 1 024 | 128 |
| 512 tokens | 2 048 | 256 |

The overlap is 64 / 512 = **12.5%** — the empirically validated sweet spot
that prevents context loss at boundaries without excessive redundancy.
To operate directly on tokens, supply a `lengthFunction` backed by your
tokenizer (see ``splitTextOnTokens(text:tokenizer:)``).

## Basic usage

Split a string into chunks of roughly 512 tokens (≈ 2 048 characters):

```swift
import TextSplitter

let splitter = try RecursiveCharacterTextSplitter(
    chunkSize: 2048,   // ≈ 512 tokens
    chunkOverlap: 256  // 12.5% overlap
)

let chunks: [String] = splitter.splitText(longDocument)
```

Wrap chunks in ``Document`` objects with metadata:

```swift
let docs = splitter.createDocuments(
    from: [pageText],
    metadatas: [["source": "annual-report.pdf", "page": "3"]]
)
// docs[0].pageContent  → chunk text
// docs[0].metadata     → ["source": "annual-report.pdf", "page": "3"]
```

## Language-aware code splitting

``Language`` provides built-in separator sets for 28 languages.
The splitter breaks preferentially at class, function, and control-flow
boundaries before falling back to line and character splits.

```swift
let splitter = try RecursiveCharacterTextSplitter.forLanguage(
    .swift,
    chunkSize: 1500,
    chunkOverlap: 0
)
```

Available languages: `.c`, `.cpp`, `.go`, `.java`, `.kotlin`, `.js`, `.ts`,
`.php`, `.proto`, `.python`, `.r`, `.rst`, `.ruby`, `.rust`, `.scala`,
`.swift`, `.markdown`, `.latex`, `.html`, `.sol`, `.csharp`, `.cobol`,
`.lua`, `.perl`, `.haskell`, `.elixir`, `.powershell`, `.visualBasic6`

## Markdown with section metadata

``MarkdownHeaderTextSplitter`` assigns heading hierarchy to each chunk's
metadata, making it possible to filter retrieved chunks by section.

```swift
let splitter = MarkdownHeaderTextSplitter(headersToSplitOn: [
    ("#",  "h1"),
    ("##", "h2"),
])

let docs = splitter.splitText(markdownText)
// docs[0].metadata["h1"] → "Introduction"
// docs[0].metadata["h2"] → "Background"
```

## Adding `start_index` to metadata

When ``SplitterConfig/addStartIndex`` is `true`, each ``Document`` receives
a `"start_index"` metadata key containing its character offset in the original
text — useful for snippet highlighting in a search UI.

```swift
let config = try SplitterConfig(
    chunkSize: 500,
    chunkOverlap: 50,
    addStartIndex: true
)
let splitter = try CharacterTextSplitter(separator: "\n", config: config)
let docs = splitter.createDocuments(from: [text])
// docs[1].metadata["start_index"] → "487"
```
