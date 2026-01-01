//
//  BingoGridView.swift
//  Buzzword Bingo
//
//  The full 5x5 grid of corporate suffering.
//

import SwiftUI

struct BingoGridView: View {
    var card: BingoCard

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)
    private let bingoLetters = ["B", "I", "N", "G", "O"]

    // Dynamic Type support
    @ScaledMetric(relativeTo: .body) private var gridSpacing: CGFloat = 6
    @ScaledMetric(relativeTo: .body) private var containerPadding: CGFloat = 12

    var body: some View {
        VStack(spacing: gridSpacing * 2) {
            // BINGO header with subtle styling
            HStack(spacing: gridSpacing) {
                ForEach(Array(bingoLetters.enumerated()), id: \.offset) { index, letter in
                    Text(letter)
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .padding(.horizontal, gridSpacing)
            .accessibilityHidden(true) // Decorative header

            // The grid with slightly more spacing
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(Array(card.squares.enumerated()), id: \.element.id) { index, square in
                    let row = index / 5 + 1
                    let col = index % 5 + 1
                    BingoSquareView(
                        square: square,
                        isWinning: card.winningSquareIndices.contains(index)
                    ) {
                        card.toggleSquare(at: index)
                    }
                    .accessibilitySortPriority(Double(25 - index)) // Navigate top-to-bottom, left-to-right
                    .accessibilityIdentifier("square_row\(row)_col\(col)")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Bingo card, 5 by 5 grid")
        }
        .padding(containerPadding)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    BingoGridView(card: .generate(from: .default))
        .padding()
        .frame(width: 400, height: 450)
}
