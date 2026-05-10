import SwiftUI

struct GroupDetailView: View {
    let groupId: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var group: AdKanGroup?
    @State private var previousRanks: [String: Int] = [:]
    @State private var showAddFriend = false
    @State private var showPaywall = false
    @State private var showRenameAlert = false
    @State private var showLeaveConfirm = false
    @State private var renameText = ""
    @State private var isLoading = true
    @State private var loadError: String?

    private var isAtFreeLimit: Bool {
        (group?.memberCount ?? 0) >= storeManager.groupMemberLimit
    }

    private var isOwner: Bool {
        group?.createdBy == services.auth.currentUserId
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let error = loadError {
                errorView(error)
            } else if let group {
                VStack(spacing: AdKanTheme.cardSpacing) {
                    headerSection(group)
                    if !storeManager.canExpandGroups && group.memberCount > StoreManager.freeGroupMemberLimit {
                        lapseBanner
                    }
                    LeaderboardView(group: group, previousRanks: previousRanks)
                    if isAtFreeLimit {
                        paywallBanner
                    }
                }
                .padding(.horizontal, AdKanTheme.screenPadding)
                .padding(.vertical, 16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(group?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    renameButton
                    favoriteButton
                    addFriendButton
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                leaveButton
            }
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendView(groupId: groupId, memberCount: group?.memberCount ?? 0)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .groupLimit(groupName: group?.name ?? ""))
        }
        .task { await loadDetail() }
        .alert("groups.rename.title", isPresented: $showRenameAlert) {
            TextField("groups.rename.placeholder", text: $renameText)
            Button("common.save") {
                guard !renameText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                Task {
                    try? await services.groups.renameGroup(groupId: groupId, newName: renameText.trimmingCharacters(in: .whitespaces))
                    group?.name = renameText.trimmingCharacters(in: .whitespaces)
                }
            }
            Button("common.cancel", role: .cancel) {}
        }
        .alert("groups.leave.confirm", isPresented: $showLeaveConfirm) {
            Button("groups.leave", role: .destructive) {
                Task {
                    try? await services.groups.leaveGroup(groupId: groupId)
                    dismiss()
                }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text(isOwner ? "groups.leave.ownerMessage" : "groups.leave.message")
        }
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(error)
                .font(AdKanTheme.cardBody)
                .foregroundStyle(.secondary)
            Button("common.retry") {
                Task { await loadDetail() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func headerSection(_ group: AdKanGroup) -> some View {
        HStack(spacing: 12) {
            Text(group.type.emoji)
                .font(.largeTitle)

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.title3.bold())
                Text(LocalizedStringKey(group.type.nameKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(group.memberCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AdKanTheme.primary)
                Text("groups.members")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var paywallBanner: some View {
        PlainCard {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(AdKanTheme.warningOrange)

                Text("groups.paywall.banner")
                    .font(AdKanTheme.cardBody)
                    .multilineTextAlignment(.center)

                AdKanButton(titleKey: "groups.paywall.cta", style: .primary) {
                    showPaywall = true
                }
            }
        }
    }

    private var lapseBanner: some View {
        Button(action: { showPaywall = true }) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text("groups.lapse.banner")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var leaveButton: some View {
        Button {
            showLeaveConfirm = true
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var renameButton: some View {
        Button {
            renameText = group?.name ?? ""
            showRenameAlert = true
        } label: {
            Image(systemName: "pencil")
        }
    }

    private var favoriteButton: some View {
        Button {
            guard var g = group else { return }
            g.isFavorite.toggle()
            group = g
            Task {
                try? await services.groups.setFavorite(groupId: groupId, isFavorite: g.isFavorite)
            }
        } label: {
            Image(systemName: group?.isFavorite == true ? "star.fill" : "star")
                .foregroundStyle(group?.isFavorite == true ? .yellow : .secondary)
        }
    }

    private var addFriendButton: some View {
        Button {
            if isAtFreeLimit {
                showPaywall = true
            } else {
                showAddFriend = true
            }
        } label: {
            Image(systemName: "person.badge.plus")
        }
    }

    private func loadDetail() async {
        loadError = nil
        do {
            var loaded = try await services.groups.fetchGroupDetail(groupId: groupId)
            if let userId = services.auth.currentUserId {
                for i in loaded.members.indices {
                    if loaded.members[i].userId == userId {
                        loaded.members[i].isCurrentUser = true
                    }
                }
            }
            group = loaded

            var prev: [String: Int] = [:]
            for member in loaded.members {
                if let r = RankHistoryStore.shared.previousRank(for: member.userId, groupId: groupId) {
                    prev[member.userId] = r
                }
            }
            previousRanks = prev

            let todayRanks = Dictionary(uniqueKeysWithValues: loaded.members.compactMap { m -> (String, Int)? in
                guard let r = m.rank else { return nil }
                return (m.userId, r)
            })
            RankHistoryStore.shared.saveRanks(todayRanks, groupId: groupId)
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}
