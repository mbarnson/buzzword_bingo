//
//  PlayerSetupView.swift
//  Buzzword Bingo
//
//  Where you name the victims before the meeting starts.
//

import SwiftUI

struct PlayerSetupView: View {
    @Bindable var listStore: ListStore
    @State private var playerNames: [String] = ["", ""]
    @State private var showingListPicker = false
    @State private var titleScale: CGFloat = 0.9
    @State private var titleOpacity: Double = 0
    var onStart: ([String], BuzzwordList) -> Void

    // Dynamic Type support
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var buttonPadding: CGFloat = 14

    // Accessibility support
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Returns names with empty fields replaced by random corporate names
    private var processedNames: [String] {
        playerNames.enumerated().compactMap { index, name -> String? in
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            // Only include player slots that the user has interacted with
            // (first slot always counts, additional slots count if they have content or are not the last empty one)
            if index == 0 {
                // First player always gets a name (random if empty)
                return trimmed.isEmpty ? GameConstants.randomDefaultPlayerName() : trimmed
            } else if !trimmed.isEmpty {
                // Non-empty additional players get their name
                return trimmed
            } else {
                // Empty additional player slots are skipped
                return nil
            }
        }
    }

    private var canStart: Bool {
        // Can always start - first player will get a random name if empty
        true
    }

    var body: some View {
        VStack(spacing: 28) {
            // Header with entrance animation
            VStack(spacing: 10) {
                Text("Buzzword Bingo")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(titleScale)
                    .opacity(titleOpacity)

                Text("Who's braving this jargon?")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .opacity(titleOpacity)
            }
            .padding(.top, 44)
            .onAppear {
                if reduceMotion {
                    // Instant appearance without animation
                    titleScale = 1.0
                    titleOpacity = 1.0
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        titleScale = 1.0
                        titleOpacity = 1.0
                    }
                }
            }

            // List picker button with better styling
            Button {
                showingListPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Playing with")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(listStore.selectedList.name)
                            .font(.headline)
                    }

                    Spacer()

                    Text("\(listStore.selectedList.words.count) words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.quaternary)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, horizontalPadding)

            // Player name fields
            VStack(spacing: 12) {
                ForEach(playerNames.indices, id: \.self) { index in
                    HStack {
                        Text("Player \(index + 1)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)

                        TextField("Name", text: $playerNames[index])
                            .textFieldStyle(.roundedBorder)
                    }
                }

                // Add player button
                if playerNames.count < 8 {
                    Button {
                        if reduceMotion {
                            playerNames.append("")
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                playerNames.append("")
                            }
                        }
                    } label: {
                        Label("Add Player", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, horizontalPadding)

            Spacer()

            // Start button with better styling
            Button {
                onStart(processedNames, listStore.selectedList)
            } label: {
                HStack {
                    Text("Let's Gooo!")
                    Image(systemName: "arrow.right.circle.fill")
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, buttonPadding)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(!canStart)
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 8)
            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)

            Text("Leave names blank for a surprise identity")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
        .sheet(isPresented: $showingListPicker) {
            ListPickerView(listStore: listStore)
        }
        .alert("Storage Error", isPresented: .init(
            get: { listStore.lastError != nil },
            set: { if !$0 { listStore.clearError() } }
        )) {
            Button("OK") { listStore.clearError() }
        } message: {
            Text(listStore.lastError ?? "Unknown error")
        }
    }
}

#Preview {
    PlayerSetupView(listStore: ListStore()) { names, list in
        print("Starting with: \(names) using \(list.name)")
    }
}
