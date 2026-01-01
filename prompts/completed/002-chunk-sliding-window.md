<objective>
Implement chunked semantic matching in SemanticMatcher to fix the "50-word window dilutes buzzword signal" problem.

Currently, sending a 50-word sliding window to compare against 2-4 word buzzwords results in low similarity scores (0.75-0.88) even for exact matches because the buzzword signal is diluted by surrounding words. The solution is to chunk the window into overlapping segments and test each chunk against buzzwords.
</objective>

<context>
Working directory: /Users/patbarnson/devel/sandbox/worboys/Buzzword Bingo

Files to modify:
- `Buzzword Bingo/Buzzword Bingo/Services/SemanticMatcher.swift`

The problem demonstrated:
- User says: "per my last email i think we should table this and circle the wagons"
- "Circle the wagons" buzzword scores only 0.881 (below 0.93 threshold)
- WHY: The 15-word sentence embedding averages ALL words, diluting the 3-word buzzword signal

The solution:
- Instead of embedding the entire window and comparing once
- Chunk the window into overlapping 8-word segments
- Compare each chunk against buzzwords
- Return the best match across all chunks
</context>

<requirements>
Modify `findBestMatch()` in SemanticMatcher.swift to:

1. **Chunk the input phrase** into overlapping segments:
   - Chunk size: 8 words (captures 2-4 word buzzwords with context)
   - Stride: 4 words (50% overlap ensures no boundary misses)
   - Example: "we should table this and circle the wagons now" →
     - Chunk 1: "we should table this and circle the wagons"
     - Chunk 2: "and circle the wagons now" (if enough words)

2. **Optimize embedding computation**:
   - Get token vectors for the ENTIRE phrase once (single model call)
   - Mean-pool different token ranges to create chunk embeddings
   - This avoids calling the model multiple times

3. **Compare each chunk** against all buzzwords:
   - Track the best (highest score) match across ALL chunks
   - Only return a match if it exceeds the threshold

4. **Handle short phrases**:
   - If phrase is ≤8 words, process it as a single chunk (current behavior)
   - Only chunk when phrase is longer than chunk size

5. **Add configuration constants**:
   ```swift
   private let chunkWordCount = 8
   private let chunkStride = 4
   ```
</requirements>

<implementation>
Key changes to SemanticMatcher.swift:

```swift
// Add constants at class level
private let chunkWordCount = 8
private let chunkStride = 4

// In findBestMatch(), replace single embedding with chunked approach:

func findBestMatch(...) -> ...? {
    // ... existing guard checks ...

    let normalizedPhrase = normalize(phrase)
    let words = normalizedPhrase.split(separator: " ")

    // For short phrases, use existing single-embedding approach
    if words.count <= chunkWordCount {
        // existing logic
    }

    // For longer phrases, chunk and test each
    var bestMatch: (index: Int, word: String, score: Double)?

    // Get all token vectors once
    guard let allTokenVectors = getTokenVectors(for: normalizedPhrase, using: model) else {
        return nil
    }

    // Create chunk embeddings by mean-pooling token ranges
    // Note: Token count may differ from word count due to tokenization
    // Use word-based chunking of the text, then embed each chunk

    for startWord in stride(from: 0, to: words.count - chunkWordCount + 1, by: chunkStride) {
        let endWord = min(startWord + chunkWordCount, words.count)
        let chunkWords = words[startWord..<endWord]
        let chunkText = chunkWords.joined(separator: " ")

        guard let chunkEmbedding = getEmbedding(for: chunkText, using: model) else {
            continue
        }

        // Compare this chunk against all buzzwords
        for (index, word) in buzzwords {
            let normalizedWord = normalize(word)
            guard let wordEmbedding = getCachedOrComputeEmbedding(...) else { continue }

            let similarity = cosineSimilarity(chunkEmbedding, wordEmbedding)

            if similarity >= threshold && (bestMatch == nil || similarity > bestMatch!.score) {
                bestMatch = (index, word, similarity)
            }
        }
    }

    // Also test the last chunk if we didn't land exactly on it
    // (handles case where stride doesn't reach the end)

    return bestMatch
}
```

The above is pseudocode - adapt to existing code structure. The key insight is:
- Word-based chunking of the input text
- Each chunk gets its own embedding
- Best match wins across all chunks
</implementation>

<constraints>
- Keep the 0.93 threshold - chunking should make it achievable again
- Keep existing caching for buzzword embeddings (they're still reused)
- Don't change the public API signature of `findBestMatch()`
- Maintain debug logging (log which chunk matched, if any)
- Keep the `precomputeEmbeddings()` method working as-is
</constraints>

<output>
Modify: `./Buzzword Bingo/Services/SemanticMatcher.swift`
</output>

<verification>
After implementation:
1. Build for macOS: `xcodebuild -scheme "Buzzword Bingo" -destination "platform=macOS" -quiet`
2. Verify the build succeeds

Expected behavior after fix:
- "per my last email i think we should table this" should match "Per my last email" or "Let's table this"
- "circle the wagons" within a longer sentence should score 0.93+ and match
- Short phrases (≤8 words) should work exactly as before
</verification>

<success_criteria>
- Chunking implemented with 8-word chunks and 4-word stride
- Short phrases (≤8 words) handled as single chunk
- Each chunk compared against all buzzwords
- Best match across all chunks returned
- Build succeeds for macOS
- Debug logging shows which chunk matched
</success_criteria>
