import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject private var services: ServiceContainer
    @Environment(\.dismiss) private var dismiss
    var onCreated: ((AdKanGroup) -> Void)?

    @State private var groupName: String = ""
    @State private var groupType: GroupType = .friends
    @State private var isCreating = false

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
        }
    }

    private func createGroup() {
        guard !groupName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isCreating = true
        Task {
            do {
                let newGroup = try await services.groups.createGroup(name: groupName, type: groupType)
                onCreated?(newGroup)
            } catch {
                isCreating = false
            }
        }
    }
}
