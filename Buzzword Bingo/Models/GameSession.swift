//
//  GameSession.swift
//  Buzzword Bingo
//
//  Manages the chaos of multiple people playing bingo in the same meeting.
//

import Foundation
import Observation

@Observable
@MainActor
final class GameSession: Identifiable {
    let id: UUID
    var players: [Player]
    var currentPlayerIndex: Int
    let buzzwordList: BuzzwordList

    // MARK: - Speech Recognition

    /// Speech recognition service for hands-free gameplay
    let speechService: SpeechRecognitionService

    /// Whether speech recognition is currently listening
    var isListening: Bool {
        speechService.isListening
    }

    /// The last recognized phrase (for UI feedback)
    private(set) var lastRecognizedPhrase: String?

    /// The index of the last square marked via speech (for visual feedback)
    private(set) var lastSpeechMarkedIndex: Int?

    /// Callback fired when a square is marked via speech recognition
    var onSpeechMarkedSquare: ((Int, String) -> Void)?

    init(id: UUID = UUID(), players: [Player], buzzwordList: BuzzwordList) {
        self.id = id
        self.players = players
        self.currentPlayerIndex = 0
        self.buzzwordList = buzzwordList
        self.speechService = SpeechRecognitionService()

        // Wire up speech recognition callback
        setupSpeechRecognition()
    }

    private func setupSpeechRecognition() {
        speechService.onPhraseRecognized = { [weak self] phrase in
            self?.handleRecognizedPhrase(phrase)
        }
    }

    private func handleRecognizedPhrase(_ phrase: String) {
        // Store the phrase for UI feedback
        lastRecognizedPhrase = phrase

        // Try to mark ALL matching squares on the current player's card
        let matches = currentCard.markAllMatchingSquares(forPhrase: phrase)

        if !matches.isEmpty {
            // Fire callback for each matched square (for UI feedback/animation)
            for match in matches {
                lastSpeechMarkedIndex = match.index
                onSpeechMarkedSquare?(match.index, match.word)
            }

            // Signal to speech service that matches were found (prevents duplicate matches)
            speechService.markMatchFound()
        }
    }

    // MARK: - Speech Control

    /// Request authorization and start listening for speech
    @MainActor
    func startListening() async {
        // Request authorization if needed
        if !speechService.isAuthorized {
            let authorized = await speechService.requestAuthorization()
            guard authorized else { return }
        }

        speechService.startListening()
    }

    /// Stop listening for speech
    func stopListening() {
        speechService.stopListening()
        // Clear feedback state
        lastRecognizedPhrase = nil
        lastSpeechMarkedIndex = nil
    }

    /// Clear the speech marked index (for UI feedback reset)
    func clearSpeechMarkedIndex() {
        lastSpeechMarkedIndex = nil
    }

    /// Create a new game session with the given player names
    static func create(playerNames: [String], using list: BuzzwordList = .default) -> GameSession {
        let players = playerNames.map { name in
            Player(name: name, card: BingoCard.generate(from: list, playerName: name))
        }
        return GameSession(players: players, buzzwordList: list)
    }

    /// The player whose turn it currently is
    var currentPlayer: Player {
        players[currentPlayerIndex]
    }

    /// All players who have achieved bingo
    var winners: [Player] {
        players.filter { $0.hasWon }
    }

    /// True if at least one player has won
    var hasWinner: Bool {
        !winners.isEmpty
    }

    /// True if all players have achieved bingo
    var allPlayersFinished: Bool {
        players.allSatisfy { $0.hasWon }
    }

    /// Advance to the next player's turn
    func nextTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }

    /// Mark a square on the current player's card
    func markSquare(at index: Int) {
        players[currentPlayerIndex].card.toggleSquare(at: index)
    }

    /// Get the current player's card (for binding in views)
    var currentCard: BingoCard {
        players[currentPlayerIndex].card
    }
}
