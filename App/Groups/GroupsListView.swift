import SwiftUI

struct GroupsListView: View {
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var groups: [AdKanGroup] = []
    @State private var featuredGroup: AdKanGroup?
    @State private var showCreateGroup = false
    @State private var showPaywall = false
    @State private var isLoading = true
    @State private var loadError: String?

    private var favoriteGroup: AdKanGroup? {
        groups.first { $0.isFavorite }
    }

    private var podiumEntries: [PodiumEntry] {
        guard let group = featuredGroup else { return [] }
        let sorted = group.members.sorted { ($0.rank ?? 999) < ($1.rank ?? 999) }
        return sorted.prefix(3).map { member in
            PodiumEntry(
                id: member.userId,
                displayName: member.displayName,
                avatarEmoji: member.avatarEmoji,
                minutes: member.dailyTotalMinutes ?? 0,
                streak: member.currentStreak ?? 0,
                leagueBadge: member.badge,
                rank: member.rank ?? 0,
                isCurrentUser: member.isCurrentUser
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = loadError {
                    errorView(error)
                } else {
                    VStack(spacing: 20) {
                        featuredSection
                        groupsListSection
                        if !groups.isEmpty {
                            actionButton
                        }
                    }
                    .padding(.horizontal, AdKanTheme.screenPadding)
                    .padding(.vertical, 16)
                }
            }
            .background(Color(.systemGroupedBackground))
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

    @ViewBuilder
    private var featuredSection: some View {
        if let fav = favoriteGroup {
            VStack(spacing: 10) {
                NavigationLink {
                    GroupDetailView(groupId: fav.id)
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text(fav.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                }

                if podiumEntries.count >= 2 {
                    PodiumView(entries: podiumEntries, formatMinutes: { formatMinutes($0) })
                }
            }
        } else if !groups.isEmpty {
            PlainCard {
                HStack(spacing: 10) {
                    Image(systemName: "star")
                        .foregroundStyle(.secondary)
                    Text("groups.noFavorite")
                        .font(AdKanTheme.cardBody)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var groupsListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !groups.isEmpty {
                Text("groups.allGroups")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }

            if groups.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(groups) { group in
                        NavigationLink {
                            GroupDetailView(groupId: group.id)
                        } label: {
                            groupRow(group)
                        }
                        .buttonStyle(.plain)

                        if group.id != groups.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.cardCornerRadius))
            }
        }
    }

    private var actionButton: some View {
        Group {
            if !storeManager.canExpandGroups && groups.count >= StoreManager.freeGroupLimit {
                Button(action: { showPaywall = true }) {
                    Label {
                        Text("groups.upgradeCta")
                            .font(.subheadline.weight(.medium))
                    } icon: {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(AdKanTheme.brandPurple)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.cardCornerRadius))
                }
                .buttonStyle(.plain)
            } else {
                Button(action: { showCreateGroup = true }) {
                    Label {
                        Text("groups.create")
                            .font(.subheadline.weight(.medium))
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AdKanTheme.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.cardCornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func groupRow(_ group: AdKanGroup) -> some View {
        HStack(spacing: 12) {
            Text(group.type.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(group.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if group.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.system(size: 10))
                    }
                }

                Text("\(group.memberCount) \(Text("groups.members"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.forward")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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

    private func errorView(_ error: String) -> some View {
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
    }

    private func formatMinutes(_ minutes: Int) -> String {
        TimeFormatter.format(minutes: minutes, locale: languageManager.preferredLanguage)
    }

    private func loadGroups() async {
        loadError = nil
        do {
            groups = try await services.groups.fetchMyGroups()
            if let fav = favoriteGroup {
                var detail = try await services.groups.fetchGroupDetail(groupId: fav.id)
                if let userId = services.auth.currentUserId {
                    for i in detail.members.indices {
                        if detail.members[i].userId == userId {
                            detail.members[i].isCurrentUser = true
                        }
                    }
                }
                featuredGroup = detail
            } else {
                featuredGroup = nil
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}
