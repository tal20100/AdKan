import SwiftUI

struct GroupsListView: View {
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var storeManager: StoreManager
    @State private var groups: [AdKanGroup] = []
    @State private var showCreateGroup = false
    @State private var showPaywall = false
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                } else if let error = loadError {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(AdKanTheme.cardBody)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("common.retry") {
                            Task { await loadGroups() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else if groups.isEmpty {
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
                    if !storeManager.isPremium && groups.count >= StoreManager.freeGroupLimit {
                        Button(action: { showPaywall = true }) {
                            Label {
                                Text("groups.upgradeCta")
                            } icon: {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(AdKanTheme.brandPurple)
                            }
                        }
                    } else {
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
            }
            .navigationTitle(Text("groups.title"))
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView(onCreated: { newGroup in
                    groups.append(newGroup)
                    showCreateGroup = false
                })
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(context: .general)
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

                Text("\(group.memberCount) / \(storeManager.groupMemberLimit)")
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
        loadError = nil
        do {
            groups = try await services.groups.fetchMyGroups()
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}
