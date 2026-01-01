//
//  ListPickerView.swift
//  Buzzword Bingo
//
//  Pick your poison. What flavor of jargon are we playing today?
//

import SwiftUI

struct ListPickerView: View {
    @Bindable var listStore: ListStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingEditor = false
    @State private var listToEdit: BuzzwordList?
    @State private var showingNewListEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(listStore.lists) { list in
                    listRow(for: list)
                }
                .onDelete(perform: deleteList)
            }
            .frame(minHeight: 300)
            .navigationTitle("Buzzword Lists")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewListEditor = true
                    } label: {
                        Label("Create New", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewListEditor) {
                ListEditorView(listStore: listStore, existingList: nil)
            }
            .sheet(item: $listToEdit) { list in
                ListEditorView(listStore: listStore, existingList: list)
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 400)
        #endif
    }

    @ViewBuilder
    private func listRow(for list: BuzzwordList) -> some View {
        // Only Corporate Classics is pre-selected when no selection made yet
        let isSelected = listStore.selectedListId == list.id ||
            (listStore.selectedListId == nil && list.id == BuzzwordList.defaultID)
        let isDefault = listStore.isDefault(id: list.id)

        Button {
            listStore.selectedListId = list.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(list.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if isDefault {
                            Text("OG")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(list.words.count) buzzwords")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }

                if !isDefault {
                    Button {
                        listToEdit = list
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !isDefault {
                Button {
                    listToEdit = list
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }

            Button {
                duplicateList(list)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            if !isDefault {
                Button(role: .destructive) {
                    listStore.delete(id: list.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .deleteDisabled(isDefault)
    }

    private func deleteList(at offsets: IndexSet) {
        for index in offsets {
            let list = listStore.lists[index]
            if !listStore.isDefault(id: list.id) {
                listStore.delete(id: list.id)
            }
        }
    }

    private func duplicateList(_ list: BuzzwordList) {
        var newList = list
        newList.id = UUID()
        newList.name = "\(list.name) Copy"
        listStore.add(list: newList)
    }
}

#Preview {
    ListPickerView(listStore: ListStore())
}
