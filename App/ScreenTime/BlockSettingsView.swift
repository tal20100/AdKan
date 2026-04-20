import SwiftUI

struct BlockSettingsView: View {
    @AppStorage("blockingEnabled") private var blockingEnabled = false
    @AppStorage("dailyLimitMinutes") private var dailyLimitMinutes: Int = 120
    @AppStorage("blockedCategories") private var blockedCategoriesRaw: String = "social,video"
    @Environment(\.dismiss) private var dismiss

    private let categories = AppCategory.allCases

    private var blockedSet: Set<String> {
        Set(blockedCategoriesRaw.split(separator: ",").map(String.init))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $blockingEnabled) {
                        Label {
                            Text("blocking.toggle")
                        } icon: {
                            Image(systemName: "shield.checkered")
                                .foregroundStyle(blockingEnabled ? AdKanTheme.successGreen : .secondary)
                        }
                    }
                    .tint(AdKanTheme.successGreen)
                } footer: {
                    Text("blocking.toggle.footer")
                        .font(.caption)
                }

                if blockingEnabled {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("blocking.dailyLimit")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(dailyLimitMinutes / 60)h \(dailyLimitMinutes % 60)m")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AdKanTheme.primary)
                            }

                            Slider(
                                value: Binding(
                                    get: { Double(dailyLimitMinutes) },
                                    set: { dailyLimitMinutes = Int($0) }
                                ),
                                in: 30...480,
                                step: 15
                            )
                            .tint(AdKanTheme.primary)

                            HStack {
                                Text("30m")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                                Text("8h")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } header: {
                        Text("blocking.limit.header")
                    }

                    Section {
                        ForEach(categories, id: \.self) { category in
                            Button(action: { toggleCategory(category) }) {
                                HStack(spacing: 14) {
                                    Text(category.icon)
                                        .font(.title2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(LocalizedStringKey(category.nameKey))
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text(LocalizedStringKey(category.descriptionKey))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: blockedSet.contains(category.rawValue) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(blockedSet.contains(category.rawValue) ? AdKanTheme.successGreen : Color(.systemGray3))
                                        .font(.title3)
                                }
                            }
                        }
                    } header: {
                        Text("blocking.categories.header")
                    }

                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AdKanTheme.warningOrange)
                            Text("blocking.entitlement.notice")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(Text("blocking.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("onboarding.next")
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: blockingEnabled)
        }
    }

    private func toggleCategory(_ category: AppCategory) {
        var set = blockedSet
        if set.contains(category.rawValue) {
            set.remove(category.rawValue)
        } else {
            set.insert(category.rawValue)
        }
        blockedCategoriesRaw = set.sorted().joined(separator: ",")
    }
}

enum AppCategory: String, CaseIterable {
    case social
    case video
    case games
    case messaging
    case news
    case shopping

    var icon: String {
        switch self {
        case .social: return "📱"
        case .video: return "📺"
        case .games: return "🎮"
        case .messaging: return "💬"
        case .news: return "📰"
        case .shopping: return "🛒"
        }
    }

    var nameKey: String { "blocking.category.\(rawValue)" }
    var descriptionKey: String { "blocking.category.\(rawValue).desc" }
}
