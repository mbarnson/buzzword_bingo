//
//  BingoCard.swift
//  Buzzword Bingo
//
//  A 5x5 grid of suffering, I mean, fun.
//

import Foundation
import Observation

@Observable
@MainActor
final class BingoCard: Identifiable {
    let id: UUID
    var squares: [BingoSquare]
    var playerName: String

    init(id: UUID = UUID(), squares: [BingoSquare], playerName: String = "Player 1") {
        self.id = id
        self.squares = squares
        self.playerName = playerName
    }

    /// Generate a randomized bingo card from a buzzword list
    /// Custom words are always included first, then filled from default list
    static func generate(from list: BuzzwordList, playerName: String = "Player 1") -> BingoCard {
        let neededWords = 24  // 25 squares minus free space

        // Start with custom words (shuffled)
        var selectedWords = list.words.shuffled()

        // If we need more words, fill from default list (excluding duplicates)
        if selectedWords.count < neededWords {
            let customSet = Set(list.words)
            let defaultFiller = BuzzwordList.default.words
                .filter { !customSet.contains($0) }
                .shuffled()

            let needed = neededWords - selectedWords.count
            selectedWords.append(contentsOf: defaultFiller.prefix(needed))
        }

        // Take exactly 24 words
        selectedWords = Array(selectedWords.prefix(neededWords))

        // Create 25 squares with free space at center (index 12)
        var squares: [BingoSquare] = []
        var wordIndex = 0

        for i in 0..<25 {
            if i == 12 {
                // Center square is free space
                squares.append(.freeSpace)
            } else {
                squares.append(BingoSquare(word: selectedWords[wordIndex]))
                wordIndex += 1
            }
        }

        return BingoCard(squares: squares, playerName: playerName)
    }

    /// Toggle the marked state of a square at the given index
    func toggleSquare(at index: Int) {
        guard index >= 0 && index < 25 else { return }
        guard !squares[index].isFreeSpace else { return }  // Can't unmark free space
        squares[index].isMarked.toggle()
    }

    // MARK: - Speech Recognition Support

    /// Find and mark ALL squares matching the recognized phrase
    /// - Parameter phrase: The recognized speech phrase
    /// - Returns: Array of (index, word) tuples for all matched and marked squares
    func markAllMatchingSquares(forPhrase phrase: String) -> [(index: Int, word: String)] {
        // Build list of unmarked squares with their indices
        let unmarkedSquares: [(index: Int, word: String)] = squares.enumerated()
            .filter { !$0.element.isMarked && !$0.element.isFreeSpace }
            .map { (index: $0.offset, word: $0.element.word) }

        guard !unmarkedSquares.isEmpty else { return [] }

        // Find ALL matches using semantic matching
        let matches = SemanticMatcher.shared.findAllMatches(
            forPhrase: phrase,
            in: unmarkedSquares
        )

        // Mark all matched squares
        var markedSquares: [(index: Int, word: String)] = []
        for match in matches {
            squares[match.index].isMarked = true
            markedSquares.append((index: match.index, word: match.word))
        }

        return markedSquares
    }

    /// Find and mark a square matching the recognized phrase (backward compatibility)
    /// - Parameter phrase: The recognized speech phrase
    /// - Returns: The index of the matched and marked square, or nil if no match
    func markMatchingSquare(forPhrase phrase: String) -> Int? {
        let matches = markAllMatchingSquares(forPhrase: phrase)
        return matches.first?.index
    }

    /// Access squares as 5 rows of 5
    var rows: [[BingoSquare]] {
        stride(from: 0, to: 25, by: 5).map { startIndex in
            Array(squares[startIndex..<startIndex + 5])
        }
    }

    /// Subscript access by row and column
    subscript(row: Int, col: Int) -> BingoSquare {
        get { squares[row * 5 + col] }
        set { squares[row * 5 + col] = newValue }
    }

    // MARK: - Bingo Detection

    /// All possible winning lines (indices into squares array)
    private static let allLines: [[Int]] = [
        // Rows
        [0, 1, 2, 3, 4],
        [5, 6, 7, 8, 9],
        [10, 11, 12, 13, 14],
        [15, 16, 17, 18, 19],
        [20, 21, 22, 23, 24],
        // Columns
        [0, 5, 10, 15, 20],
        [1, 6, 11, 16, 21],
        [2, 7, 12, 17, 22],
        [3, 8, 13, 18, 23],
        [4, 9, 14, 19, 24],
        // Diagonals
        [0, 6, 12, 18, 24],
        [4, 8, 12, 16, 20]
    ]

    /// Returns all lines where all 5 squares are marked
    var winningLines: [[Int]] {
        Self.allLines.filter { line in
            line.allSatisfy { squares[$0].isMarked }
        }
    }

    /// True if any winning line exists
    var hasBingo: Bool {
        !winningLines.isEmpty
    }

    /// Indices of all squares in winning lines (for highlighting)
    var winningSquareIndices: Set<Int> {
        Set(winningLines.flatMap { $0 })
    }
}
