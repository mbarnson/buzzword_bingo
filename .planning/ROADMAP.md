# Roadmap: Buzzword Bingo

## Overview

Build a cross-platform SwiftUI game that turns soul-crushing corporate meetings into entertainment. Start with a working grid, add bingo detection, layer on pass-and-play multiplayer, then let people create their own bullshit bingo cards. Finish with some visual polish and salty win messages.

## Phases

- [x] **Phase 1: Foundation** - Project setup, models, display a damn grid
- [x] **Phase 2: Gameplay** - Tap to mark, detect bingo, announce winners
- [x] **Phase 3: Multiplayer** - Pass-and-play turns between players
- [x] **Phase 4: Custom Lists** - Create and save your own buzzword collections
- [x] **Phase 5: Polish** - Animations, flair, spicy victory messages

## Phase Details

### Phase 1: Foundation
**Goal**: Working app that displays a 5x5 grid of buzzwords
**Depends on**: Nothing (first phase)
**Plans**: 3 plans

Plans:
- [x] 01-01: Verify project structure, build targets, app entry
- [x] 01-02: Data models (BuzzwordList, BingoSquare, BingoCard) with salty defaults
- [x] 01-03: Grid view (BingoSquareView, BingoGridView, ContentView) + visual checkpoint

### Phase 2: Gameplay
**Goal**: Playable single-player bingo - tap squares, win games
**Depends on**: Phase 1
**Plans**: 3 plans

Plans:
- [x] 02-01: Make BingoCard @Observable, add tap gestures to squares
- [x] 02-02: Bingo detection (rows, columns, diagonals) + gold highlighting
- [x] 02-03: Win overlay with snarky messages + game reset + visual checkpoint

### Phase 3: Multiplayer
**Goal**: Pass the phone/laptop between players
**Depends on**: Phase 2
**Plans**: 2 plans

Plans:
- [x] 03-01: Player management (names, turns)
- [x] 03-02: Turn-based UI and handoff screen

### Phase 4: Custom Lists
**Goal**: Users can create, edit, and save their own buzzword lists
**Depends on**: Phase 3
**Plans**: TBD

Plans:
- [x] 04-01: List management & persistence (ListStore, ListPickerView)
- [x] 04-02: List editor UI (ListEditorView, full CRUD)

### Phase 5: Polish
**Goal**: Make it feel good to play
**Depends on**: Phase 4
**Plans**: TBD

Plans:
- [x] 05-01: Animations and visual feedback (spring, 3D tilt, pulsing glow, confetti)
- [x] 05-02: Victory messages and flair (22 victory, 14 handoff messages)

---

## v1.1 Feature Phases

### Phase 6: Accessibility
**Goal**: Full Apple HIG accessibility support for users with disabilities
**Depends on**: Phase 5 (v1.0 complete)
**Plans**: 2 plans

Plans:
- [x] 06-01: VoiceOver and Dynamic Type support
- [x] 06-02: Reduced motion and high contrast support

### Phase 7: Speech Recognition
**Goal**: Hands-free buzzword detection using on-device speech recognition
**Depends on**: Phase 6
**Plans**: 2 plans

Plans:
- [x] 07-01: Speech framework integration and listening service
- [x] 07-02: Fuzzy matching and UI integration

### Phase 8: Semantic Matching
**Goal**: Replace fuzzy matching with BERT-based semantic matching for better accuracy
**Depends on**: Phase 7
**Plans**: 2 plans

Plans:
- [x] 08-01: SemanticMatcher with NLContextualEmbedding (BERT embeddings, cosine similarity)
- [x] 08-02: Keyword-indexed hybrid matching (instant single-word, phonetic fallback, acronym expansion)

---

## v1.2 Maintenance

### Phase 9: CI Fix
**Goal**: Fix GitHub Actions CI for both platforms
**Depends on**: Phase 8
**Plans**: 1 plan

Plans:
- [x] 09-01: Add iOS simulator runtime download step

## Progress

### v1.0 (Complete)
| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 3/3 | Complete | 2025-12-30 |
| 2. Gameplay | 3/3 | Complete | 2025-12-30 |
| 3. Multiplayer | 2/2 | Complete | 2025-12-30 |
| 4. Custom Lists | 2/2 | Complete | 2025-12-30 |
| 5. Polish | 2/2 | Complete | 2025-12-30 |

### v1.1 (Complete)
| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 6. Accessibility | 2/2 | Complete | 2025-12-30 |
| 7. Speech Recognition | 2/2 | Complete | 2025-12-30 |
| 8. Semantic Matching | 2/2 | Complete | 2025-12-31 |

### v1.2 (Complete)
| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 9. CI Fix | 1/1 | Complete | 2025-12-31 |

## Default Buzzwords (for reference)

The default list should include gems like:
- "Let's double-click on that"
- "Circle back"
- "Synergy"
- "Low-hanging fruit"
- "Move the needle"
- "Pivot"
- "Take this offline"
- "Leverage"
- "Deep dive"
- "Unpack that"
- "Bandwidth"
- "Align on this"
- "Action items"
- "Touch base"
- "EOD"
- "Per my last email" (fuck that one especially)
- "Going forward"
- "Let's table this"
- "Stakeholders"
- "Value-add"
- "Run it up the flagpole"
- "Boil the ocean"
- "Ducks in a row"
- "Ping me"
- "What's the ask?"
- "Net-net"
- "Hard stop"
- "Thought leadership" (vomit)
- "Best practices"
- "Learnings"
- "Focus and simplify"
- "Skate where the puck is going"
- "See around corners"
