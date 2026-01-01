# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build macOS
xcodebuild -scheme "Buzzword Bingo" -destination "platform=macOS" -quiet build

# Build iOS
xcodebuild -scheme "Buzzword Bingo" -destination "platform=iOS Simulator,name=iPhone 16" -quiet build

# Run tests
xcodebuild -scheme "Buzzword Bingo" -destination "platform=macOS" test
```

## Project Overview

Buzzword Bingo is a SwiftUI game for iOS 18+ and macOS 15+ (Swift 6.0). Pass-and-play multiplayer where players tap bingo squares when they hear corporate buzzwords in meetings. Features speech recognition for hands-free auto-marking.

## Architecture

### Core Flow
`ContentView` → `GameSession` → `BingoCard` → `BingoSquare`

- **ContentView**: Main view controller managing game phases (setup → handoff → playing → won)
- **GameSession**: Orchestrates multiplayer, owns `SpeechRecognitionService`, routes recognized phrases to current player's card
- **BingoCard**: 5x5 grid with bingo detection (rows/columns/diagonals). Calls `SemanticMatcher` for speech-to-buzzword matching
- **Player**: Holds a `BingoCard` and tracks win state

### Speech Recognition Pipeline
```
SpeechRecognitionService (Apple Speech framework)
    → 50-word sliding window with 2.5s debounce
    → Overlap check (skip if >50% already processed, unless 10+ new words)
    → 3-second flush timer for end-of-speech detection
    → GameSession.handleRecognizedPhrase()
    → BingoCard.markAllMatchingSquares()
    → SemanticMatcher.findAllMatches()
```

**Key timing parameters** (SpeechRecognitionService):
- `callbackDebounceInterval`: 2.5s between callbacks (lets Apple finalize transcription)
- `slidingWindowWordCount`: 50 words sent to matcher
- `flushInterval`: 3s timeout forces final callback when speech stops
- Overlap threshold: 50% (but always process if ≥10 new words)

### SemanticMatcher (Services/SemanticMatcher.swift)
Keyword-indexed hybrid matching using `NLContextualEmbedding`:
1. **Keyword index**: Hash map from significant words → buzzword entries (O(1) lookup)
2. **Phonetic index**: Soundex codes for accent/transcription tolerance ("boil" ≈ "bother")
3. **Acronym expansion**: "EOD" indexes both "eod" and ["end", "day"]
4. **Keyword coverage**: If ALL keywords (≥2 required) from multi-word buzzword appear in phrase → instant match (word order independent)
5. **Semantic fallback**: BERT-based cosine similarity for paraphrases (0.85 threshold, 0.80 for phonetic matches)

### Data Models
- **BuzzwordList**: Collection of buzzwords (has a static `.default` with corporate classics)
- **ListStore**: Persistence for custom buzzword lists (JSON in app documents)

## Key Patterns

- Uses Swift Observation framework (`@Observable`) instead of Combine
- Respects `accessibilityReduceMotion` throughout - animations have reduced motion alternatives
- All logging uses `[ServiceName]` prefix format for grep-ability
