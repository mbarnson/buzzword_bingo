//
//  Player.swift
//  Buzzword Bingo
//
//  A poor soul trapped in a meeting, armed with a bingo card.
//

import Foundation

@MainActor
struct Player: Identifiable {
    let id: UUID
    let name: String
    var card: BingoCard

    init(id: UUID = UUID(), name: String, card: BingoCard) {
        self.id = id
        self.name = name
        self.card = card
    }

    /// True if this player has achieved bingo
    var hasWon: Bool {
        card.hasBingo
    }
}
