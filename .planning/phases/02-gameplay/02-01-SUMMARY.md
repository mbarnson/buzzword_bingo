# Phase 2 Plan 01: Tap to Mark Summary

**Squares are now tappable. Tap a buzzword, it turns green. Tap again, it unmarks.**

## Accomplishments
- Converted BingoCard from struct to @Observable class
- Added toggleSquare(at:) method to BingoCard for state management
- Added onTap closure to BingoSquareView
- Added press animation (subtle scale effect on tap)
- Updated BingoGridView to pass tap handlers with square indices
- Free space cannot be unmarked (stays orange)

## Files Modified
- `Buzzword Bingo/Models/BingoCard.swift` - Now @Observable class with toggleSquare()
- `Buzzword Bingo/Views/BingoSquareView.swift` - Added onTap, press animation
- `Buzzword Bingo/Views/BingoGridView.swift` - Passes tap handlers via enumerated()

## Technical Notes
- Using Swift Observation framework (@Observable macro)
- BingoCard is now a final class (required for @Observable)
- Press animation uses scaleEffect with 0.1s duration
- ForEach uses enumerated() to get index for toggle

## Decisions Made
- Kept BingoSquare as struct (mutations happen through BingoCard)
- Added subtle 0.95 scale press feedback (not too distracting)
- Free space tap is ignored (guard in both view and model)

## Issues Encountered
None.

## Next Step
Ready for 02-02-PLAN.md (Bingo Detection)
