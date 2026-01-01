//
//  ListStore.swift
//  Buzzword Bingo
//
//  Where we save the corporate jargon for future suffering.
//

import Foundation
import Observation

@Observable
@MainActor
final class ListStore {
    private(set) var lists: [BuzzwordList] = []
    var selectedListId: UUID?
    var lastError: String?

    private let fileName = "buzzword_lists.json"

    init() {
        load()
        ensureBuiltInLists()
    }

    // MARK: - Computed Properties

    /// The currently selected list, or default if none selected
    var selectedList: BuzzwordList {
        if let id = selectedListId, let list = lists.first(where: { $0.id == id }) {
            return list
        }
        return BuzzwordList.default
    }

    /// ID of the default list (fixed, guaranteed to exist)
    var defaultListId: UUID {
        BuzzwordList.defaultID
    }

    /// All built-in list IDs
    var builtInListIds: Set<UUID> {
        BuzzwordList.builtInIDs
    }

    // MARK: - CRUD Operations

    /// Add a new list
    func add(list: BuzzwordList) {
        lists.append(list)
        save()
    }

    /// Delete a list by ID (won't delete built-in lists)
    func delete(id: UUID) {
        guard !builtInListIds.contains(id) else {
            print("Nice try, you can't delete the built-in lists.")
            return
        }
        lists.removeAll { $0.id == id }
        // If we deleted the selected list, reset selection
        if selectedListId == id {
            selectedListId = nil
        }
        save()
    }

    /// Update an existing list
    func update(list: BuzzwordList) {
        guard let index = lists.firstIndex(where: { $0.id == list.id }) else { return }
        lists[index] = list
        save()
    }

    /// Check if a list is built-in (can't be deleted)
    func isBuiltIn(id: UUID) -> Bool {
        builtInListIds.contains(id)
    }

    /// Legacy: Check if a list is the default (can't be deleted)
    func isDefault(id: UUID) -> Bool {
        isBuiltIn(id: id)
    }

    // MARK: - Persistence

    private var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(fileName)
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(lists)
            try data.write(to: fileURL)
            lastError = nil
        } catch {
            lastError = "Failed to save: \(error.localizedDescription)"
        }
    }

    func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            lists = try JSONDecoder().decode([BuzzwordList].self, from: data)
            lastError = nil
        } catch {
            // First launch or corrupted file - start fresh
            lists = []
            // Don't set error on first launch (file doesn't exist yet)
        }
    }

    func clearError() {
        lastError = nil
    }

    private func ensureBuiltInLists() {
        // Make sure we always have all built-in lists
        var didAdd = false
        for (index, builtIn) in BuzzwordList.builtInLists.enumerated() {
            if !lists.contains(where: { $0.id == builtIn.id }) {
                lists.insert(builtIn, at: index)
                didAdd = true
            }
        }
        if didAdd {
            save()
        }
    }
}
