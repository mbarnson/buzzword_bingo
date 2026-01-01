<objective>
Add a closed-caption style view that shows real-time speech transcription when voice recognition is active.

This provides visual feedback that the microphone is working and helps users understand what the system is hearing - useful for accessibility and debugging why certain buzzwords aren't being matched.
</objective>

<context>
SwiftUI multiplatform app (iOS 18 / macOS 15, Swift 6).

Key files:
@Buzzword Bingo/Buzzword Bingo/ContentView.swift - main game view, add caption display here
@Buzzword Bingo/Buzzword Bingo/Services/SpeechRecognitionService.swift - has `transcript` property with accumulated text
@Buzzword Bingo/Buzzword Bingo/Models/GameSession.swift - has `speechService` property

The `transcript` property already accumulates recognized speech and gets cleared periodically (every 30 sec or when exceeding 5000 chars).
</context>

<requirements>
1. Create a caption view that displays `session.speechService.transcript` in real-time
2. Only show when `session.isListening` is true AND transcript is not empty
3. Position at bottom of the game view, above the button row
4. Style as semi-transparent background (like TV closed captions)
5. Limit to 2-3 lines max, showing most recent text
6. Text should be readable but not dominate the UI
</requirements>

<implementation>
- Add a new `@ViewBuilder` function `captionView()` in ContentView
- Use `.ultraThinMaterial` or similar for the background
- Use `.lineLimit(3)` and show trailing text (most recent words)
- Animate appearance/disappearance with `.transition(.opacity)`
- Keep it simple - this is ~20-30 lines of SwiftUI
</implementation>

<output>
Modify: `./Buzzword Bingo/Buzzword Bingo/ContentView.swift`
- Add caption view component
- Insert into the playing state view layout
</output>

<verification>
1. Build for macOS: `xcodebuild -scheme "Buzzword Bingo" -destination "platform=macOS" -quiet`
2. Run the app, start a game, tap the mic button
3. Speak - caption text should appear and update in real-time
4. Stop listening - caption should fade away
</verification>

<success_criteria>
- Real-time text appears as speech is recognized
- Caption is visually distinct but not intrusive
- Smooth appearance/disappearance animation
- Works on both iOS and macOS
</success_criteria>
