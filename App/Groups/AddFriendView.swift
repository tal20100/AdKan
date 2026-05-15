import SwiftUI

struct AddFriendView: View {
    let groupId: String
    let memberCount: Int
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storeManager: StoreManager
    @State private var showPaywall = false

    private var wouldExceedFreeLimit: Bool {
        memberCount + 1 > storeManager.groupMemberLimit
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.badge.plus")
                    .font(.system(size: 56))
                    .foregroundStyle(AdKanTheme.primary)

                Text("groups.addFriend.title")
                    .font(.title2.bold())

                Text("groups.addFriend.body")
                    .font(AdKanTheme.cardBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(AdKanTheme.successGreen)
                        .font(.caption)
                    Text("groups.addFriend.privacyNote")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    AdKanButton(titleKey: "groups.addFriend.shareLink", style: .primary) {
                        if wouldExceedFreeLimit {
                            showPaywall = true
                        } else {
                            shareInviteLink()
                        }
                    }

                    if wouldExceedFreeLimit {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text("groups.addFriend.limitReached")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, AdKanTheme.screenPadding)
                .padding(.bottom, 48)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(context: .groupLimit(groupName: ""))
            }
        }
    }

    private func shareInviteLink() {
        let baseText = NSLocalizedString("invite.shareText", comment: "")
        let deepLink = "adkan://join?group=\(groupId)"
        let fullText = "\(baseText)\n\(deepLink)"
        let av = UIActivityViewController(activityItems: [fullText], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
           let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            var topVC = root
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            av.popoverPresentationController?.sourceView = topVC.view
            topVC.present(av, animated: true)
        }
    }
}
