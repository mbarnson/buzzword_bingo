<objective>
Implement three quality-of-life improvements focused on solo/single-player experience in Buzzword Bingo.
</objective>

<context>
This is a Swift iOS app for playing buzzword bingo during meetings. Players enter their names during setup, then listen for buzzwords during gameplay. When playing alone, the current UX has unnecessary friction.

Read the CLAUDE.md for project conventions, then examine:
- PlayerSetupView.swift (name entry UI)
- GameSession.swift (player/game state management)
- Any views handling player transitions or "pass" functionality
</context>

<requirements>

<requirement_1>
**Default Names for Empty Input**

If a user doesn't enter a name, assign them a randomly-selected name from a pool of 50 vaguely insulting corporate names. These should be entertaining but not truly offensive - think "eye-roll worthy" corporate humor.

Create this array of 50 names:
```swift
static let defaultPlayerNames = [
    "Corporate Shill",
    "Replaceable Drone",
    "No-Promotion Barry",
    "Synergy Enthusiast",
    "Meeting Filler",
    "PowerPoint Puppet",
    "Cubicle Dweller",
    "Yes-Person Prime",
    "Buzzword Regurgitator",
    "KPI Worshipper",
    "Quarterly Report Karen",
    "Action Item Andy",
    "Stakeholder Steve",
    "Bandwidth Bill",
    "Circle-Back Cheryl",
    "Low-Hanging Fruit Larry",
    "Pivot Patricia",
    "Deliverable Derek",
    "Touch-Base Tammy",
    "Deep-Dive Dave",
    "Value-Add Vince",
    "Best Practice Brenda",
    "Core Competency Carl",
    "Thought Leader Theo",
    "Disruptor Doug",
    "Scalable Sally",
    "Agile Alan",
    "Sprint Zero Sam",
    "Backlog Barbara",
    "Standup Stan",
    "Retro Rachel",
    "Velocity Victor",
    "Blocker Bob",
    "Scope Creep Susan",
    "Technical Debt Ted",
    "Legacy Code Linda",
    "Refactor Randy",
    "Code Review Chris",
    "Merge Conflict Mike",
    "Production Bug Pete",
    "Hotfix Hannah",
    "Deploy Friday Frank",
    "Rollback Rita",
    "Downtime Dan",
    "Incident Ivan",
    "Postmortem Paula",
    "Root Cause Ron",
    "Blameless Brad",
    "Learning Opportunity Lou",
    "Growth Mindset Greg"
]
```

Implementation: When creating a player and their name field is empty, randomly select from this array.
</requirement_1>

<requirement_2>
**Hide "Pass" Option for Single Player**

When there is only 1 player in the game, the "pass" or "pass turn" option should not be displayed. There's no one to pass to.

Find where the pass functionality is rendered and conditionally hide it when `players.count == 1` or equivalent check.
</requirement_2>

<requirement_3>
**Solo Player Splash Screen**

When a single player starts a game, instead of showing "Pass to [Player Name]" or similar transition screen, show a special solo-player screen with a randomly-selected quip about playing alone.

Create this array of 50 solo-player messages (vaguely self-deprecating humor about playing bingo alone):
```swift
static let soloPlayerQuips = [
    "Table for one, party of you.",
    "Playing with yourself again?",
    "Solitaire Bingo Champion",
    "The loneliest buzzword hunter",
    "Solo queue activated",
    "Party of one, your bingo is ready",
    "Just you and your buzzwords",
    "Self-care includes solo bingo",
    "Introvert mode: engaged",
    "No witnesses to your victory",
    "Playing both sides so you always win",
    "Your only competition is yourself",
    "Awkward meeting, party of one",
    "Flying solo through the synergy",
    "One-person brainstorm session",
    "Me, myself, and bingo",
    "Social distancing champion",
    "The sound of one hand dabbing",
    "Lone wolf of corporate meetings",
    "Self-partnered bingo enthusiast",
    "Playing with yourself is still playing",
    "Your own best teammate",
    "Solo mission: accepted",
    "Table for one at the buzzword buffet",
    "Independent bingo contractor",
    "Self-employed bingo player",
    "Freelance buzzword hunter",
    "Going it alone (as usual)",
    "Your imaginary friends couldn't make it",
    "All the buzzwords, none of the sharing",
    "Competing against your own high score",
    "Self-rivalry activated",
    "The hermit's guide to bingo",
    "Solitary confinement bingo",
    "Just you versus the jargon",
    "No one to blame but yourself",
    "Winner by default (still counts)",
    "Every square is yours alone",
    "Hoarding all the buzzwords",
    "Greedy bingo: keeping it all",
    "No sharing required",
    "All the glory, none of the splitting",
    "Undisputed champion (of one)",
    "Undefeated against yourself",
    "Playing favorites with #1",
    "VIP seating: just you",
    "Exclusive one-player tournament",
    "Premium solo experience",
    "First place guaranteed*",
    "(*only participant)"
]
```

Implementation:
- Detect when game has exactly 1 player
- Replace the standard "pass to player" transition with a solo-specific view
- Display one randomly-selected quip from the array
- Still allow the player to proceed to gameplay (tap to continue or similar)
</requirement_3>

</requirements>

<implementation_notes>
- Place the string arrays somewhere sensible (a Constants file, or as static properties on relevant models)
- Use `Int.random(in:)` or `.randomElement()` for selection
- Maintain existing functionality for multi-player games
- Keep the UI consistent with existing app styling
</implementation_notes>

<output>
Modify the necessary Swift files to implement all three features. Expected files to touch:
- PlayerSetupView.swift or equivalent (name handling)
- GameSession.swift or player model (default names)
- Transition/splash view files (solo player screen)
- Potentially a new Constants.swift or similar for the string arrays
</output>

<verification>
Test scenarios:
1. Start game with empty name field - verify random corporate name assigned
2. Start single-player game - verify no "pass" option visible
3. Start single-player game - verify solo quip screen appears instead of pass screen
4. Start multi-player game - verify all original functionality works as before
</verification>

<success_criteria>
- Empty name field results in random funny corporate name
- Single-player games have no pass option
- Single-player games show insulting solo quip instead of pass screen
- Multi-player games work exactly as before
- All 50 entries present in each array
</success_criteria>
