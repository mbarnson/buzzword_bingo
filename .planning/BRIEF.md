# Buzzword Bingo

**One-liner**: A pass-and-play SwiftUI game for surviving meetings by marking off corporate buzzwords.

## Problem

Meetings are full of meaningless corporate jargon. Instead of suffering in silence, you and your colleagues can turn it into a game. Hear "let's double-click that" or "circle back"? Tap the square. First to bingo wins (or at least survives with sanity intact).

## Success Criteria

How we know it worked:

- [x] Game launches on iOS and macOS from same codebase
- [x] 5x5 bingo grid displays with randomized buzzwords
- [x] Players can tap squares to mark heard buzzwords
- [x] Game detects and announces bingo (row, column, or diagonal)
- [x] Pass-and-play works for 2+ players
- [x] Custom buzzword lists can be created and saved
- [x] GitHub Actions CI passes for both platforms
- [x] Published to GitHub with README, screenshots, and Unlicense

## Constraints

- Swift 6.2, SwiftUI, iOS 18+ / macOS 15+
- CLI-buildable (xcodebuild), no Xcode dependency for Claude
- Architecture follows KISS, DRY, YAGNI, SOLID principles
- Start skeletal, grow elegantly

## Scope Creep (for the LOLs)

Things we said "out of scope" but built anyway:

- **Speech Recognition** - Hands-free auto-marking using Apple's Speech framework with semantic matching (BERT embeddings via NLContextualEmbedding). Because manually tapping is for peasants.
- **Fuzzy/Semantic Matching** - Says "end of day" when the square says "EOD"? Still counts. Uses keyword indexing, phonetic fallback (Soundex), and cosine similarity.
- **Fruit Company List** - 35 Apple-flavored buzzwords for those who know the pain of "file a radar" and "this doesn't feel Apple"
- **Full Accessibility** - VoiceOver, Dynamic Type, reduced motion support. Apple HIG compliance because we're not monsters.
- **Snarky UI Copy** - "Let's Fucking Go", "Undisputed champion (of one)", randomly generated player names like "Low-Hanging Fruit Larry"

## Actually Out of Scope

- Online multiplayer / networking
- Accounts / login
- In-app purchases
- Push notifications
- AI-generated buzzwords (the human-curated bullshit is funnier)
