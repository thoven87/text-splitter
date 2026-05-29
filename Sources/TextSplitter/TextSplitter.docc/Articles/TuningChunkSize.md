# Tuning Chunk Size

Measure chunk distribution before committing to an embedding run.

## Overview

``ChunkStats`` analyses the output of any splitter on representative sample
documents. Run it first — it costs nothing and surfaces misconfigured splitters
before you spend time or money on embeddings.

## Reading the output

```swift
let splitter = try RecursiveCharacterTextSplitter(chunkSize: 512, chunkOverlap: 50)
let stats = ChunkStats.analyze(sampleDocs, using: splitter)
print(stats)
```

```
chunks  : 1 847
length  : min=12  p25=380  p50=498  p75=511  max=512  mean=467
underfilled (<50% of chunkSize): 94 (5%)
at ceiling (==chunkSize)       : 312 (17%)
tokens  : min=3  max=128
```

## Interpreting the signals

| Signal | Interpretation |
|---|---|
| `atCeilingRatio > 10%` | Separators too coarse — the merger keeps hitting the hard limit. Try finer separators or reduce `chunkSize`. |
| `underfilledRatio > 30%` | `chunkSize` larger than most content. Chunks carry mostly whitespace. |
| Wide `p25–p75` spread | High variance in chunk informativeness. |
| `tokenRange.max` near or above your model's limit | Chunks will be silently truncated. Reduce `chunkSize`. |
| `tokenRange.max` well below your model's limit | Room to increase `chunkSize` and reduce retrieval cost. |

## Sweep before embedding

```swift
for chunkSize in stride(from: 200, through: 1000, by: 100) {
    let s = try RecursiveCharacterTextSplitter(
        chunkSize: chunkSize, chunkOverlap: chunkSize / 5)
    let st = ChunkStats.analyze(sampleDocs, using: s)
    print("size=\(chunkSize)  ceil=\(Int(st.atCeilingRatio * 100))%  " +
          "under=\(Int(st.underfilledRatio * 100))%")
}
```

Pick two or three configurations with low ceiling and underfill ratios, then
run a retrieval quality evaluation (precision@k, recall@k, or RAGAS) against
a golden question-answer set using your actual embedding model. `ChunkStats`
answers "are my chunks structurally sound?" — the embedding evaluation answers
"do they retrieve the right content?"

## Token-aware analysis

Pass a ``Tokenizer`` to measure token counts alongside character lengths:

```swift
let tokenizer = Tokenizer(
    chunkOverlap: 0, tokensPerChunk: 512,
    decode: { … }, encode: { … }
)
let stats = ChunkStats.analyze(sampleDocs, using: splitter, tokenizer: tokenizer)
// stats.tokenRange → (min: 12, max: 128)
```
