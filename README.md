# TextSplitter

Split text into chunks for embedding and retrieval pipelines.

**Requirements:** Swift 6.3+ · macOS 26+ · Linux

## Install

```swift
.package(url: "https://github.com/thoven87/text-splitter", from: "1.0.0")
```

## Quick start

```swift
import TextSplitter

// chunkSize/chunkOverlap are in characters; 2 048 chars ≈ 512 tokens
let splitter = try RecursiveCharacterTextSplitter(chunkSize: 2048, chunkOverlap: 256)
let chunks   = splitter.splitText(myDocument)

// or stream page by page
for try await chunk in splitter.split(pdf.textStream()) {
    await store.upsert(Document(pageContent: chunk))
}
```
