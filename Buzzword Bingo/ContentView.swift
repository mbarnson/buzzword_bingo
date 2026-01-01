//
//  ContentView.swift
//  Buzzword Bingo
//
//  Because meetings are tedious, but at least now they're a game.
//

import SwiftUI

enum GamePhase {
    case setup
    case handoff
    case playing
    case won
}

struct ContentView: View {
    @State private var listStore = ListStore()
    @State private var session: GameSession?
    @State private var phase: GamePhase = .setup
    @State private var victoryMessage: String = ""
    @State private var winnerName: String = ""

    // Speech recognition state
    @State private var speechMarkedSquareIndex: Int?
    @State private var speechMarkedWord: String?
    @State private var showSpeechFeedback = false
    @State private var micPulseScale: CGFloat = 1.0

    // Dynamic Type support
    @ScaledMetric(relativeTo: .body) private var verticalSpacing: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 12

    // Accessibility support
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let victoryMessages = [
        // Classic burns
        "Well hot dang, %@ actually won!",
        "%@ survived the jargon jungle!",
        "Corporate buzzword champion: %@!",
        "%@ wins! That meeting was worth something.",
        "Time to circle back to %@'s victory!",
        // Corporate roasts
        "Congratulations %@, you're fluent in jargon!",
        "%@ just got promoted to VP of Jargon",
        "%@ has achieved peak corporate enlightenment",
        "Someone give %@ a raise... in buzzwords",
        "%@ is now certified in executive nonsense",
        // Meeting commentary
        "This meeting could've been an email, but %@ won anyway",
        "%@ wins! Your suffering has been synergized",
        "That's a W for %@. Let's take this offline to celebrate",
        "%@ crushed it! Time to leverage this win going forward",
        // Savage options
        "%@ won! Management is proud of themselves somehow",
        "Congrats %@! You've wasted this meeting productively",
        "%@ has mastered the art of nodding through nonsense",
        "Winner: %@! Losers: everyone's time in this meeting",
        "%@ wins! Let's unpack that in the next standup",
        // Extra spicy
        "%@ is the jargon whisperer",
        "Plot twist: %@ actually paid attention to this stuff",
        "%@ wins! Quick, pretend you were all engaged"
    ]

    var body: some View {
        Group {
            switch phase {
            case .setup:
                PlayerSetupView(listStore: listStore) { names, list in
                    startGame(with: names, using: list)
                }

            case .handoff:
                if let session {
                    HandoffView(
                        playerName: session.currentPlayer.name,
                        isSoloGame: session.players.count == 1
                    ) {
                        if reduceMotion {
                            phase = .playing
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                phase = .playing
                            }
                        }
                    }
                }

            case .playing:
                if let session {
                    playingView(session: session)
                }

            case .won:
                winOverlay
            }
        }
    }

    @ViewBuilder
    private func playingView(session: GameSession) -> some View {
        ZStack {
            VStack(spacing: verticalSpacing) {
                // Header with player name - enhanced styling
                VStack(spacing: 6) {
                    Text("\(session.currentPlayer.name)'s Card")
                        .font(.title.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .accessibilityAddTraits(.isHeader)

                    Text("Tap when you hear the jargon")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .padding(.top, 16)

                // The grid
                BingoGridView(card: session.currentCard)
                    .padding(.horizontal, horizontalPadding)

                // Speech feedback - shows last recognized phrase
                if showSpeechFeedback, let phrase = session.lastRecognizedPhrase {
                    speechFeedbackView(phrase: phrase, markedWord: speechMarkedWord)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Closed caption view - real-time transcript
                captionView(session: session)

                // Action buttons with better styling
                HStack(spacing: verticalSpacing) {
                    // Microphone toggle button
                    microphoneButton(session: session)

                    // Only show End Turn button in multiplayer games
                    if session.players.count > 1 {
                        Button {
                            endTurn()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                Text("End Turn")
                            }
                            .padding(.horizontal, 8)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("End Turn")
                        .accessibilityHint("Pass the device to the next player")
                    }

                    Button {
                        resetToSetup()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("New Game")
                        }
                        .padding(.horizontal, 8)
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("New Game")
                    .accessibilityHint("Start a new game from the beginning")
                }
                .padding(.bottom, verticalSpacing)
            }
            .padding()

            // Speech error overlay
            if let error = session.speechService.lastError {
                speechErrorOverlay(error: error)
            }
        }
        .onChange(of: session.currentCard.hasBingo) { _, hasBingo in
            if hasBingo && phase == .playing {
                triggerWin(for: session.currentPlayer.name)
                // Announce bingo win for VoiceOver users
                AccessibilityNotification.Announcement("Bingo! \(session.currentPlayer.name) wins!").post()
            }
        }
        .onAppear {
            setupSpeechCallback(session: session)
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 720)
        #endif
    }

    // MARK: - Speech Recognition UI Components

    @ViewBuilder
    private func microphoneButton(session: GameSession) -> some View {
        Button {
            Task {
                if session.isListening {
                    session.stopListening()
                    stopMicPulseAnimation()
                } else {
                    await session.startListening()
                    if session.isListening {
                        startMicPulseAnimation()
                    }
                }
            }
        } label: {
            ZStack {
                // Pulsing background when listening
                if session.isListening && !reduceMotion {
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .scaleEffect(micPulseScale)
                        .frame(width: 44, height: 44)
                }

                HStack {
                    Image(systemName: session.isListening ? "mic.fill" : "mic")
                        .foregroundStyle(session.isListening ? .blue : .primary)
                    if session.isListening {
                        Text("Listening")
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .buttonStyle(.bordered)
        .tint(session.isListening ? .blue : nil)
        .accessibilityLabel(session.isListening ? "Stop listening" : "Start listening")
        .accessibilityHint(session.isListening
            ? "Double tap to stop speech recognition"
            : "Double tap to start listening for buzzwords")
        .accessibilityAddTraits(session.isListening ? .isSelected : [])
    }

    @ViewBuilder
    private func speechFeedbackView(phrase: String, markedWord: String?) -> some View {
        VStack(spacing: 4) {
            if let word = markedWord {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Matched: \(word)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
            }
            Text("Heard: \"\(phrase)\"")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(markedWord != nil
            ? "Matched buzzword: \(markedWord!). Heard phrase: \(phrase)"
            : "Heard phrase: \(phrase)")
    }

    @ViewBuilder
    private func captionView(session: GameSession) -> some View {
        let transcript = session.speechService.transcript
        let shouldShow = session.isListening && !transcript.isEmpty

        if shouldShow {
            Text(transcript)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .truncationMode(.head)  // Show most recent text (trailing)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .padding(.horizontal, horizontalPadding)
                .transition(.opacity)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: shouldShow)
                .accessibilityLabel("Live caption: \(transcript)")
                .accessibilityHint("Shows what the microphone is hearing in real-time")
        }
    }

    @ViewBuilder
    private func speechErrorOverlay(error: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            )
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Speech recognition error: \(error)")
    }

    // MARK: - Speech Recognition Helpers

    private func setupSpeechCallback(session: GameSession) {
        session.onSpeechMarkedSquare = { [self] index, word in
            // Show feedback
            speechMarkedSquareIndex = index
            speechMarkedWord = word
            if reduceMotion {
                showSpeechFeedback = true
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSpeechFeedback = true
                }
            }

            // Announce for VoiceOver
            AccessibilityNotification.Announcement("Auto-marked: \(word)").post()

            // Hide feedback after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if reduceMotion {
                    showSpeechFeedback = false
                    speechMarkedWord = nil
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSpeechFeedback = false
                        speechMarkedWord = nil
                    }
                }
            }
        }
    }

    private func startMicPulseAnimation() {
        guard !reduceMotion else { return }
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            micPulseScale = 1.3
        }
    }

    private func stopMicPulseAnimation() {
        if reduceMotion {
            micPulseScale = 1.0
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                micPulseScale = 1.0
            }
        }
    }

    @State private var bingoScale: CGFloat = 0.5
    @State private var bingoRotation: Double = -10
    @State private var messageOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var confettiOffset: CGFloat = -200

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            // Simple confetti-like particles (disabled in reduced motion mode)
            if !reduceMotion {
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(confettiColors[index % confettiColors.count])
                        .frame(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 8...16))
                        .offset(
                            x: CGFloat.random(in: -180...180),
                            y: confettiOffset + CGFloat(index * 30)
                        )
                        .opacity(0.8)
                }
            }

            VStack(spacing: 28) {
                // Epic BINGO text
                Text("BINGO!")
                    .font(.system(size: 80, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .orange.opacity(0.9), radius: 15, x: 0, y: 5)
                    .shadow(color: .red.opacity(0.5), radius: 25, x: 0, y: 10)
                    .scaleEffect(reduceMotion ? 1.0 : bingoScale)
                    .rotationEffect(.degrees(reduceMotion ? 0 : bingoRotation))

                // Victory message
                Text(victoryMessage)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(reduceMotion ? 1.0 : messageOpacity)

                // Subtitle snark
                Text("Your meeting productivity: still zero")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(reduceMotion ? 1.0 : messageOpacity)

                Button {
                    resetToSetup()
                } label: {
                    Text("Play Again (Masochist)")
                        .font(.title3.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .opacity(reduceMotion ? 1.0 : buttonOpacity)
                .padding(.top, 8)
                .accessibilityLabel("Play Again")
                .accessibilityHint("Start a new game")
            }
            .padding(40)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Bingo! \(winnerName) wins! \(victoryMessage)")
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity)
        .onAppear {
            if reduceMotion {
                // Instant appearance without animation
                bingoScale = 1.0
                bingoRotation = 0
                messageOpacity = 1.0
                buttonOpacity = 1.0
            } else {
                // Animate BINGO entrance
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    bingoScale = 1.0
                    bingoRotation = 0
                }
                // Animate message
                withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                    messageOpacity = 1.0
                }
                // Animate button
                withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                    buttonOpacity = 1.0
                }
                // Animate confetti
                withAnimation(.easeOut(duration: 2.0)) {
                    confettiOffset = 600
                }
            }
        }
    }

    private let confettiColors: [Color] = [
        .yellow, .orange, .red, .green, .blue, .purple, .pink
    ]

    private func startGame(with names: [String], using list: BuzzwordList) {
        session = GameSession.create(playerNames: names, using: list)
        if reduceMotion {
            phase = .handoff
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                phase = .handoff
            }
        }
    }

    private func endTurn() {
        // Stop listening when changing turns
        session?.stopListening()
        stopMicPulseAnimation()
        showSpeechFeedback = false
        speechMarkedWord = nil

        session?.nextTurn()
        if reduceMotion {
            phase = .handoff
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                phase = .handoff
            }
        }
        // Announce turn change for VoiceOver users
        if let currentPlayerName = session?.currentPlayer.name {
            AccessibilityNotification.Announcement("Pass to \(currentPlayerName)").post()
        }
    }

    private func triggerWin(for name: String) {
        winnerName = name
        let template = victoryMessages.randomElement() ?? victoryMessages[0]
        victoryMessage = String(format: template, name)
        if reduceMotion {
            phase = .won
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                phase = .won
            }
        }
    }

    private func resetToSetup() {
        // Stop listening before resetting
        session?.stopListening()
        stopMicPulseAnimation()
        showSpeechFeedback = false
        speechMarkedWord = nil
        speechMarkedSquareIndex = nil

        session = nil
        // Reset animation states
        bingoScale = 0.5
        bingoRotation = -10
        messageOpacity = 0
        buttonOpacity = 0
        confettiOffset = -200
        if reduceMotion {
            phase = .setup
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                phase = .setup
            }
        }
    }
}

#Preview {
    ContentView()
}
