import SwiftUI

struct GroupDetailView: View {
    let groupId: String
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var storeManager: StoreManager
    @State private var group: AdKanGroup?
    @State private var showAddFriend = false
    @State private var showPaywall = false
    @State private var isLoading = true
    @State private var loadError: String?

    private var sortedMembers: [GroupMember] {
        (group?.members ?? []).sorted { ($0.rank ?? 999) < ($1.rank ?? 999) }
    }

    private var isAtFreeLimit: Bool {
        !storeManager.isPremium && (group?.memberCount ?? 0) >= AdKanGroup.freeMaxMembers
    }

    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .listRowBackground(Color.clear)
            } else if let error = loadError {
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
                .listRowBackground(Color.clear)
            } else if let group = group {
                headerSection(group)
                leaderboardSection
                if isAtFreeLimit {
                    paywallBanner
                } else if !storeManager.isPremium {
                    upsellHint
                }
            }
        }
        .navigationTitle(group?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    favoriteButton
                    addFriendButton
                }
            }
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendView(groupId: groupId, memberCount: group?.memberCount ?? 0)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .groupLimit(groupName: group?.name ?? ""))
        }
        .task {
            await loadDetail()
        }
    }

    private func headerSection(_ group: AdKanGroup) -> some View {
        Section {
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

                Text("\(group.memberCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AdKanTheme.primary)

                Text("groups.members")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var leaderboardSection: some View {
        Section {
            ForEach(sortedMembers) { member in
                HStack(spacing: 12) {
                    Text("#\(member.rank ?? 0)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, alignment: .leading)

                    Text(member.avatarEmoji)
                        .font(.title2)

                    Text(member.displayName)
                        .font(.body.weight(.medium))

                    Spacer()

                    if let minutes = member.dailyTotalMinutes {
                        Text("\(minutes)m")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AdKanTheme.minutesColor(minutes))
                    }

                    RankChangeIndicator(previousRank: nil, currentRank: member.rank ?? 0)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("groups.leaderboard")
        }
    }

    private var paywallBanner: some View {
        Section {
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
            .padding(.vertical, 8)
        }
    }

    private var upsellHint: some View {
        Section {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text("groups.paywall.upsell")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
            group = try await services.groups.fetchGroupDetail(groupId: groupId)
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}
