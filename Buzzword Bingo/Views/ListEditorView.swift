//
//  ListEditorView.swift
//  Buzzword Bingo
//
//  Craft your own special brand of corporate torture.
//

import SwiftUI

struct ListEditorView: View {
    @Bindable var listStore: ListStore
    let existingList: BuzzwordList?

    @Environment(\.dismiss) private var dismiss

    @State private var listName: String = ""
    @State private var words: [String] = []
    @State private var newWord: String = ""
    @State private var editingIndex: Int?
    @State private var editingText: String = ""
    @State private var showingDiscardAlert = false

    private let minimumWords = 1

    private var isEditing: Bool {
        existingList != nil
    }

    private var hasChanges: Bool {
        if let existing = existingList {
            return listName != existing.name || words != existing.words
        }
        return !listName.isEmpty || !words.isEmpty
    }

    private var canSave: Bool {
        !listName.trimmingCharacters(in: .whitespaces).isEmpty &&
        words.count >= minimumWords
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // List name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("List Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("Give it a catchy name", text: $listName)
                        .textFieldStyle(.roundedBorder)
                        .font(.headline)
                }
                .padding()

                Divider()

                // Word count indicator
                HStack {
                    Text("Buzzwords")
                        .font(.headline)

                    Spacer()

                    if words.count < 24 {
                        Text("\(words.count) words (fills from defaults)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(words.count) words")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Words list
                List {
                    ForEach(words.indices, id: \.self) { index in
                        wordRow(index: index, word: words[index])
                    }
                    .onDelete(perform: deleteWords)
                    .onMove(perform: moveWords)
                }
                .listStyle(.inset)
                .frame(minHeight: 200)

                Divider()

                // Add new word field (outside List to fix focus issues)
                HStack {
                    TextField("Add new buzzword...", text: $newWord)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            addWord()
                        }

                    Button {
                        addWord()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                    .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit List" : "New List")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveList()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .onAppear {
                if let existing = existingList {
                    listName = existing.name
                    words = existing.words
                }
            }
        }
    }

    @ViewBuilder
    private func wordRow(index: Int, word: String) -> some View {
        if editingIndex == index {
            HStack {
                TextField("Edit buzzword", text: $editingText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        finishEditing()
                    }

                Button {
                    finishEditing()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)

                Button {
                    cancelEditing()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        } else {
            HStack {
                Text(word)
                    .lineLimit(2)

                Spacer()

                Button {
                    startEditing(index: index, word: word)
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                startEditing(index: index, word: word)
            }
        }
    }

    // MARK: - Actions

    private func addWord() {
        let trimmed = newWord.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !words.contains(trimmed) else {
            // Already exists, just clear
            newWord = ""
            return
        }
        words.append(trimmed)
        newWord = ""
    }

    private func deleteWords(at offsets: IndexSet) {
        words.remove(atOffsets: offsets)
    }

    private func moveWords(from source: IndexSet, to destination: Int) {
        words.move(fromOffsets: source, toOffset: destination)
    }

    private func startEditing(index: Int, word: String) {
        editingIndex = index
        editingText = word
    }

    private func finishEditing() {
        guard let index = editingIndex else { return }
        let trimmed = editingText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            words[index] = trimmed
        }
        editingIndex = nil
        editingText = ""
    }

    private func cancelEditing() {
        editingIndex = nil
        editingText = ""
    }

    private func saveList() {
        let trimmedName = listName.trimmingCharacters(in: .whitespaces)

        if let existing = existingList {
            // Update existing list
            var updated = existing
            updated.name = trimmedName
            updated.words = words
            listStore.update(list: updated)
        } else {
            // Create new list
            let newList = BuzzwordList(name: trimmedName, words: words)
            listStore.add(list: newList)
            // Auto-select the new list
            listStore.selectedListId = newList.id
        }

        dismiss()
    }
}

#Preview("New List") {
    ListEditorView(listStore: ListStore(), existingList: nil)
}

#Preview("Edit List") {
    ListEditorView(
        listStore: ListStore(),
        existingList: BuzzwordList(
            name: "Tech Startup BS",
            words: ["Pivot", "Disrupt", "Scale", "10x", "Moonshot"]
        )
    )
}
