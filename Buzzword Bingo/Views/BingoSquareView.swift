//
//  BingoSquareView.swift
//  Buzzword Bingo
//
//  A single square of corporate despair, beautifully rendered.
//

import SwiftUI

struct BingoSquareView: View {
    let square: BingoSquare
    var isWinning: Bool = false
    var onTap: (() -> Void)?

    @State private var isPressed = false
    @State private var showCheckmark = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.6

    // Dynamic Type support
    @ScaledMetric(relativeTo: .body) private var squarePadding: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var checkmarkSize: CGFloat = 24

    // Accessibility support
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        ZStack {
            // Background with gradient for marked squares
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundGradient)

            // Glow effect for winning squares (disabled in reduced motion mode)
            if isWinning && !reduceMotion {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        RadialGradient(
                            colors: [.yellow.opacity(glowOpacity), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .blur(radius: 8)
                    .scaleEffect(pulseScale)
            }

            // The word
            Text(square.word)
                .font(.callout.weight(.medium))
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(squarePadding)
                .foregroundStyle(textColor)

            // Checkmark overlay for marked squares
            if square.isMarked && !square.isFreeSpace && showCheckmark {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: checkmarkSize))
                    .foregroundStyle(.green)
                    .background(Circle().fill(.white).padding(2))
                    .offset(x: 20, y: -20)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }

            // Additional visual indicator for differentiateWithoutColor mode
            if differentiateWithoutColor && square.isMarked && !square.isFreeSpace {
                // Diagonal stripes pattern overlay for marked squares
                Image(systemName: "checkmark")
                    .font(.system(size: checkmarkSize * 1.5, weight: .bold))
                    .foregroundStyle(.primary.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowRadius > 0 ? 2 : 0)
        .scaleEffect(reduceMotion ? 1.0 : (isPressed ? 0.92 : (isWinning ? pulseScale : 1.0)))
        .rotation3DEffect(
            .degrees(reduceMotion ? 0 : (isPressed ? 5 : 0)),
            axis: (x: 1, y: 0, z: 0)
        )
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.5), value: square.isMarked)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: isWinning)
        .onTapGesture {
            guard !square.isFreeSpace else { return }

            if reduceMotion {
                // Instant state change without animation
                onTap?()
            } else {
                // Satisfying press animation
                withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                    isPressed = true
                }

                // Haptic-like bounce back
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        isPressed = false
                    }
                }

                onTap?()
            }
        }
        .onChange(of: square.isMarked) { _, newValue in
            if reduceMotion {
                // Instant state change
                showCheckmark = newValue
            } else if newValue {
                // Animate checkmark appearance
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) {
                    showCheckmark = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    showCheckmark = false
                }
            }
        }
        .onChange(of: isWinning) { _, newValue in
            if newValue && !reduceMotion {
                // Start pulsing animation for winning squares (only if motion allowed)
                startPulseAnimation()
            } else {
                pulseScale = 1.0
                glowOpacity = 0.6
            }
        }
        .onAppear {
            // Initialize checkmark state
            showCheckmark = square.isMarked && !square.isFreeSpace
            if isWinning && !reduceMotion {
                startPulseAnimation()
            }
        }
        // MARK: - Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(square.isFreeSpace ? [] : .isButton)
    }

    // MARK: - Accessibility Helpers

    private var accessibilityLabel: String {
        var label = square.word
        if isWinning {
            label += ", part of winning bingo"
        }
        return label
    }

    private var accessibilityValue: String {
        if square.isFreeSpace {
            return "Free space, always marked"
        } else if square.isMarked {
            return "Marked"
        } else {
            return "Not marked"
        }
    }

    private var accessibilityHint: String {
        if square.isFreeSpace {
            return ""
        } else if square.isMarked {
            return "Double tap to unmark this square"
        } else {
            return "Double tap to mark this square"
        }
    }

    private func startPulseAnimation() {
        // Continuous pulse for winning squares
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.05
            glowOpacity = 0.9
        }
    }

    private var backgroundGradient: LinearGradient {
        if isWinning {
            return LinearGradient(
                colors: [.yellow.opacity(0.5), .orange.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if square.isFreeSpace {
            return LinearGradient(
                colors: [.orange.opacity(0.35), .orange.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if square.isMarked {
            return LinearGradient(
                colors: [.green.opacity(0.35), .green.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.gray.opacity(0.12), .gray.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var textColor: Color {
        // Using .primary ensures good contrast in both light and dark mode
        // for WCAG AA compliance (4.5:1 ratio)
        if isWinning {
            return .primary
        } else if square.isFreeSpace {
            // Use darker orange-brown for better contrast on orange background
            return Color(red: 0.6, green: 0.3, blue: 0.0)
        } else {
            return .primary
        }
    }

    private var borderColor: Color {
        if differentiateWithoutColor {
            // High contrast borders for accessibility
            if isWinning {
                return .primary
            } else if square.isFreeSpace {
                return .primary
            } else if square.isMarked {
                return .primary
            } else {
                return .secondary
            }
        } else {
            if isWinning {
                return .yellow
            } else if square.isFreeSpace {
                return .orange
            } else if square.isMarked {
                return .green
            } else {
                return .gray.opacity(0.3)
            }
        }
    }

    private var borderWidth: CGFloat {
        // Thicker borders when differentiateWithoutColor is enabled
        let baseWidth: CGFloat = differentiateWithoutColor ? 1.5 : 1.0
        if isWinning {
            return 4 * baseWidth
        } else if square.isMarked {
            return 3 * baseWidth
        } else {
            return 2
        }
    }

    private var shadowColor: Color {
        if isWinning {
            return .yellow.opacity(0.7)
        } else if square.isMarked {
            return .green.opacity(0.3)
        } else {
            return .black.opacity(0.1)
        }
    }

    private var shadowRadius: CGFloat {
        if isWinning {
            return 8
        } else if square.isMarked {
            return 4
        } else {
            return 2
        }
    }
}

#Preview("Regular Square") {
    BingoSquareView(square: BingoSquare(word: "Synergy"))
        .frame(width: 100, height: 100)
        .padding()
}

#Preview("Free Space") {
    BingoSquareView(square: .freeSpace)
        .frame(width: 100, height: 100)
        .padding()
}

#Preview("Marked Square") {
    BingoSquareView(square: BingoSquare(word: "Circle back", isMarked: true))
        .frame(width: 100, height: 100)
        .padding()
}

#Preview("Winning Square") {
    BingoSquareView(square: BingoSquare(word: "Synergy", isMarked: true), isWinning: true)
        .frame(width: 100, height: 100)
        .padding()
}
