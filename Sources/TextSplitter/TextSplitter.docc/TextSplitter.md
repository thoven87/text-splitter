# ``TextSplitter``

Split text into chunks for embedding and retrieval pipelines.

## Overview

TextSplitter provides a suite of splitters for prose, source code, Markdown,
HTML, and JSON. Every splitter conforms to ``TextSplitting`` and can be used
synchronously or as a lazy ``SplittingSequence`` over any async source.

Pure Swift, no Foundation, no ObjC runtime, Linux-compatible.

## Topics

### Protocol and configuration

- ``TextSplitting``
- ``SplitterConfig``
- ``SeparatorPlacement``
- ``Document``
- ``SplitterError``

### Character splitters

- ``CharacterTextSplitter``
- ``RecursiveCharacterTextSplitter``
- ``Language``

### Format splitters

- ``MarkdownHeaderTextSplitter``
- ``ExperimentalMarkdownSyntaxTextSplitter``
- ``HTMLHeaderTextSplitter``
- ``RecursiveJsonSplitter``
- ``JSONValue``
- ``JSFrameworkTextSplitter``
- ``SentenceTextSplitter``

### Streaming

- <doc:Streaming>
- ``SplittingSequence``

### Token-based splitting

- ``Tokenizer``
- ``splitTextOnTokens(text:tokenizer:)``

### Diagnostics

- <doc:TuningChunkSize>
- ``ChunkStats``

### Guides

- <doc:GettingStarted>
