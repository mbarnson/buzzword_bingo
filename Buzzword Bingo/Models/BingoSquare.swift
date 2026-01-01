//
//  BingoSquare.swift
//  Buzzword Bingo
//
//  A single square of corporate despair.
//

import Foundation

struct BingoSquare: Identifiable {
    let id: UUID
    let word: String
    var isMarked: Bool
    let isFreeSpace: Bool

    init(id: UUID = UUID(), word: String, isMarked: Bool = false, isFreeSpace: Bool = false) {
        self.id = id
        self.word = word
        self.isMarked = isFreeSpace ? true : isMarked  // free space always marked
        self.isFreeSpace = isFreeSpace
    }

    /// The glorious center square - always a freebie
    static let freeSpace = BingoSquare(
        word: "FREE SPACE",
        isMarked: true,
        isFreeSpace: true
    )
}
