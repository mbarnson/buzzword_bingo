<objective>
Modify SpeechRecognitionService to batch speech transcripts before sending them to the semantic matcher. Currently, we send incremental deltas immediately, which causes issues when Apple Speech Recognition corrects earlier portions of the transcript (e.g., "going" → "going forward" gets split and misses the match).
</objective>

<context>
@Buzzword Bingo/Buzzword Bingo/Services/SpeechRecognitionService.swift

The current implementation:
- Uses `callbackDebounceInterval` of 0.5 seconds (too short)
- `processNewTranscript()` extracts only the NEW portion since last callback
- This means corrections by Apple Speech are often missed

The problem demonstrated:
- Speech hears "going" → we process "going" (0.924 score, just under 0.93 threshold)
- Speech corrects to "going forward" → we only process "forward we" (delta)
- "going forward" as a complete phrase would have matched

The semantic matcher threshold is 0.93 in SemanticMatcher.swift.
</context>

<requirements>
Implement these 3 changes:

1. **Increase debounce to 2.5 seconds**
   - Change `callbackDebounceInterval` from 0.5 to 2.5
   - This gives Apple Speech time to correct/finalize transcription
   - WHY: Speech recognition frequently revises transcripts as it gains more context

2. **Send sliding window instead of delta**
   - Instead of extracting only "new text since last callback"
   - Send the last ~50 words of the current transcript
   - Use a helper method to extract the trailing N words
   - WHY: Complete phrases match better semantically than fragments

3. **Track already-matched content**
   - Maintain a property like `lastMatchedPhrase: String?` or similar
   - After a successful match, store what was matched
   - Don't send phrases that substantially overlap with already-matched content
   - This prevents the same buzzword from being detected multiple times
   - Reset this tracking when the transcript is cleared (in `clearTranscriptIfNeeded`)
   - WHY: Prevents re-triggering on the same buzzword as speech continues

</requirements>

<implementation>
Key changes to make in SpeechRecognitionService.swift:

```swift
// Change debounce interval
private let callbackDebounceInterval: TimeInterval = 2.5  // was 0.5

// Add tracking for matched content
private var lastMatchedStartIndex: Int = 0  // Track where we've matched up to

// Modify processNewTranscript to use sliding window
private func processNewTranscript(_ newTranscript: String) {
    // Extract last ~50 words as sliding window
    let slidingWindow = extractSlidingWindow(from: newTranscript, wordCount: 50)

    // Skip if this window substantially overlaps with already-matched content
    // (implement overlap detection logic)

    // Fire callback with sliding window instead of delta
    onPhraseRecognized?(slidingWindow)
}

// Add helper method
private func extractSlidingWindow(from text: String, wordCount: Int) -> String {
    let words = text.split(separator: " ")
    let startIndex = max(0, words.count - wordCount)
    return words[startIndex...].joined(separator: " ")
}
```

The callback consumer (BingoCard) already handles finding the best match - we just need to give it better input.

</implementation>

<constraints>
- Keep the existing 30-second `clearTimer` for memory management
- Don't change the `onPhraseRecognized` callback signature
- The `transcript` property should still contain the full transcript for the closed-caption display
- Reset match tracking in `clearTranscriptIfNeeded()` and when listening stops
</constraints>

<output>
Modify: `./Buzzword Bingo/Services/SpeechRecognitionService.swift`
</output>

<verification>
After implementation:
1. Build for macOS: `xcodebuild -scheme "Buzzword Bingo" -destination "platform=macOS" -quiet`
2. Run the app and enable voice recognition
3. Test phrases like "going forward" - they should match even if speech initially hears "going" then corrects
4. Test that saying the same buzzword twice doesn't mark two squares
5. Verify the closed-caption display still shows the full transcript
</verification>

<success_criteria>
- Debounce increased to 2.5 seconds
- Sliding window of ~50 words sent to callback instead of incremental deltas
- Already-matched content is tracked to prevent duplicate matches
- Build succeeds for macOS
- Closed-caption transcript display still works correctly
</success_criteria>
