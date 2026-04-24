import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject private var services: ServiceContainer
    @Environment(\.dismiss) private var dismiss
    var onCreated: ((AdKanGroup) -> Void)?

    @State private var groupName: String = ""
    @State private var groupType: GroupType = .friends
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("groups.create.namePlaceholder", text: $groupName)
                } header: {
                    Text("groups.create.name")
                }

                Section {
                    ForEach(GroupType.allCases, id: \.self) { type in
                        Button {
                            groupType = type
                        } label: {
                            HStack(spacing: 12) {
                                Text(type.emoji)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LocalizedStringKey(type.nameKey))
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(LocalizedStringKey(type.inviteToneKey))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if groupType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AdKanTheme.primary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("groups.create.type")
                }

                Section {
                    AdKanButton(titleKey: "groups.create.cta", style: .primary) {
                        createGroup()
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(Text("groups.create"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("common.error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("common.ok") { errorMessage = nil }
            } message: {
                if let msg = errorMessage {
                    Text(msg)
                }
            }
        }
    }

    private func createGroup() {
        guard !groupName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isCreating = true
        errorMessage = nil
        Task {
            do {
                let newGroup = try await services.groups.createGroup(name: groupName, type: groupType)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onCreated?(newGroup)
            } catch {
                errorMessage = error.localizedDescription
                isCreating = false
            }
        }
    }
}
