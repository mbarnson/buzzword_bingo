//
//  HandoffView.swift
//  Buzzword Bingo
//
//  The ceremonial passing of the phone. No peeking, friend.
//

import SwiftUI

struct HandoffView: View {
    let playerName: String
    let isSoloGame: Bool
    var onReady: () -> Void

    // Dynamic Type support
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var buttonPadding: CGFloat = 14

    // Accessibility support
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let handoffMessages = [
        // No peeking theme
        "Don't peek, you sneaky rascal",
        "Eyes on your own card, buddy",
        "No peeking or you're buying coffee",
        "Hand it over, no looking back",
        "Look away or face corporate shame",
        "Peekers get assigned to the next all-hands",
        // Suffering theme
        "Your turn to suffer through this meeting",
        "May your buzzword tolerance be strong",
        "Prepare your jargon detector",
        "Time to zone out with purpose",
        "Another victim enters the arena",
        // Snarky handoff
        "Tag, you're it. Good luck.",
        "Quick, look busy while you switch",
        "Pass it like it's a hot potato of despair"
    ]

    @State private var message: String = ""
    @State private var nameScale: CGFloat = 0.8
    @State private var nameOpacity: Double = 0
    @State private var messageOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var arrowOffset: CGFloat = -20

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if isSoloGame {
                // Solo player view - no passing, just a quip
                soloPlayerContent
            } else {
                // Multiplayer handoff view
                multiplayerHandoffContent
            }

            Spacer()

            // Ready button with delayed appearance
            Button {
                onReady()
            } label: {
                HStack {
                    Text(isSoloGame ? "Let's Do This" : "I'm Ready")
                    Image(systemName: isSoloGame ? "play.fill" : "hand.raised.fill")
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, buttonPadding)
            }
            .buttonStyle(.borderedProminent)
            .tint(isSoloGame ? .purple : .blue)
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, horizontalPadding)
            .opacity(buttonOpacity)
            .scaleEffect(buttonOpacity > 0 ? 1.0 : 0.9)
        }
        .onAppear {
            // Select message from appropriate array based on game mode
            if isSoloGame {
                message = GameConstants.randomSoloPlayerQuip()
            } else {
                message = handoffMessages.randomElement() ?? handoffMessages[0]
            }

            if reduceMotion {
                // Instant appearance without animation
                nameScale = 1.0
                nameOpacity = 1.0
                arrowOffset = 0
                messageOpacity = 1.0
                buttonOpacity = 1.0
            } else {
                // Staggered entrance animations
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    nameScale = 1.0
                    nameOpacity = 1.0
                }

                // Bouncing arrow (only for multiplayer)
                if !isSoloGame {
                    withAnimation(
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                    ) {
                        arrowOffset = 0
                    }
                }

                withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                    messageOpacity = 1.0
                }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.4)) {
                    buttonOpacity = 1.0
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
    }

    // MARK: - Solo Player Content

    @ViewBuilder
    private var soloPlayerContent: some View {
        // Solo player icon
        Image(systemName: "person.fill")
            .font(.system(size: 60))
            .foregroundStyle(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(nameScale)
            .opacity(nameOpacity)

        // Player name with solo styling
        VStack(spacing: 16) {
            Text(playerName)
                .font(.largeTitle.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                .scaleEffect(nameScale)
                .opacity(nameOpacity)
        }

        // Solo quip message
        Text(message)
            .font(.headline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, horizontalPadding)
            .opacity(messageOpacity)
            .italic()
    }

    // MARK: - Multiplayer Handoff Content

    @ViewBuilder
    private var multiplayerHandoffContent: some View {
        // Animated arrow
        Image(systemName: "arrow.down.circle.fill")
            .font(.system(size: 40))
            .foregroundStyle(.blue.opacity(0.6))
            .offset(y: arrowOffset)
            .opacity(nameOpacity)

        // Big player name with entrance animation
        VStack(spacing: 16) {
            Text("Pass to")
                .font(.title2)
                .foregroundStyle(.secondary)
                .opacity(nameOpacity)

            Text(playerName)
                .font(.largeTitle.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                .scaleEffect(nameScale)
                .opacity(nameOpacity)
        }

        // Snarky message with fade in
        Text(message)
            .font(.headline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, horizontalPadding)
            .opacity(messageOpacity)
    }
}

#Preview("Multiplayer") {
    HandoffView(playerName: "Tim", isSoloGame: false) {
        print("Ready!")
    }
}

#Preview("Solo") {
    HandoffView(playerName: "Corporate Shill", isSoloGame: true) {
        print("Ready!")
    }
}
