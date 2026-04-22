import SwiftUI

struct GroupsListView: View {
    @EnvironmentObject private var services: ServiceContainer
    @State private var groups: [AdKanGroup] = []
    @State private var showCreateGroup = false

    var body: some View {
        NavigationStack {
            List {
                if groups.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                } else {
                    ForEach(groups) { group in
                        NavigationLink {
                            GroupDetailView(groupId: group.id)
                        } label: {
                            groupRow(group)
                        }
                    }
                }

                Section {
                    Button(action: { showCreateGroup = true }) {
                        Label {
                            Text("groups.create")
                        } icon: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AdKanTheme.primary)
                        }
                    }
                }
            }
            .navigationTitle(Text("groups.title"))
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView(onCreated: { newGroup in
                    groups.append(newGroup)
                    showCreateGroup = false
                })
            }
            .refreshable {
                await loadGroups()
            }
            .task {
                await loadGroups()
            }
        }
    }

    private func groupRow(_ group: AdKanGroup) -> some View {
        HStack(spacing: 12) {
            Text(group.type.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.body.weight(.medium))

                Text("\(group.memberCount) / \(AdKanGroup.freeMaxMembers)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if group.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }

            Image(systemName: "chevron.forward")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 40)

            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(AdKanTheme.primary.opacity(0.5))

            Text("groups.empty.title")
                .font(AdKanTheme.cardTitle)

            Text("groups.empty.body")
                .font(AdKanTheme.cardBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            AdKanButton(titleKey: "groups.create", style: .primary) {
                showCreateGroup = true
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadGroups() async {
        do {
            groups = try await services.groups.fetchMyGroups()
        } catch {}
    }
}
