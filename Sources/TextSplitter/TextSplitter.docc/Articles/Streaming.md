# Streaming

Split text from any async source without loading the full content into memory.

## Overview

``TextSplitting/split(_:)`` returns a ``SplittingSequence`` — a lazy
`AsyncSequence` that pulls from the upstream source one fragment at a time.
The buffer stays bounded to `chunkSize + chunkOverlap` characters regardless
of document length.

## Usage

```swift
for try await chunk in splitter.split(pdf.textStream()) {
    await store.upsert(Document(pageContent: chunk))
}
```

The upstream (here `pdf.textStream()`) is pulled exactly once per downstream
`next()` call, so cancellation and backpressure work correctly — if the
consumer stops, the upstream stops too.

## Any AsyncSequence source

``SplittingSequence`` accepts any `AsyncSequence<String>`:

```swift
// PopplerKit — one string per non-empty PDF page
splitter.split(pdf.textStream())

// Lines from a file URL (Swift standard library)
splitter.split(url.lines)

// Custom page-by-page source
splitter.split(myDocumentPageStream)
```

## Page metadata

Because the stream emits chunks as they fill, a chunk may span the boundary
between two upstream fragments. Attach metadata after the loop or track the
last-seen page number alongside:

```swift
var approxPage = 1
for try await page in pdf.pages {
    defer { approxPage += 1 }
    for chunk in splitter.splitText(page.text()) {
        await store.upsert(Document(
            pageContent: chunk,
            metadata: ["page": "\(approxPage)"]
        ))
    }
}
```

Use the streaming variant when your priority is bounded memory. Use
``TextSplitting/splitDocuments(_:)`` when accurate per-chunk page attribution
matters more than memory footprint.

## Composing with other operators

``SplittingSequence`` conforms to `AsyncSequence`, so standard operators
chain naturally:

```swift
for try await chunk in splitter.split(source).prefix(100) { … }
for try await chunk in splitter.split(source).filter({ $0.count > 100 }) { … }
```
