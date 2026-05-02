import SwiftUI

struct TimeBlockRuleEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ruleStore: BlockingRuleStore
    @AppStorage("blockedAppsJSON") private var blockedAppsJSON: String = ""

    var editingRule: TimeBlockRule?

    @State private var label: String = ""
    @State private var startDate: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @State private var endDate: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var selectedAppIDs: Set<String> = []

    private var apps: [BlockableAppRef] {
        guard let data = blockedAppsJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([BlockableAppRef].self, from: data)
        else { return [] }
        return decoded
    }

    private var isValid: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty && !selectedAppIDs.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("blocking.timeRule.labelPlaceholder", text: $label)
                }

                Section("blocking.timeRule.timeRange") {
                    DatePicker("blocking.timeRule.start", selection: $startDate, displayedComponents: .hourAndMinute)
                    DatePicker("blocking.timeRule.end", selection: $endDate, displayedComponents: .hourAndMinute)
                }

                Section("blocking.timeRule.apps") {
                    if apps.isEmpty {
                        Text("blocking.timeRule.noApps")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(apps) { app in
                            Button {
                                if selectedAppIDs.contains(app.id) {
                                    selectedAppIDs.remove(app.id)
                                } else {
                                    selectedAppIDs.insert(app.id)
                                }
                            } label: {
                                HStack {
                                    Text(app.icon)
                                    Text(LocalizedStringKey(app.nameKey))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedAppIDs.contains(app.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AdKanTheme.primary)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(editingRule == nil ? Text("blocking.timeRule.add") : Text("blocking.timeRule.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("blocking.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("blocking.save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if let rule = editingRule {
                    label = rule.label
                    startDate = Calendar.current.date(from: DateComponents(hour: rule.startHour, minute: rule.startMinute)) ?? Date()
                    endDate = Calendar.current.date(from: DateComponents(hour: rule.endHour, minute: rule.endMinute)) ?? Date()
                    selectedAppIDs = Set(rule.appIDs)
                }
            }
        }
    }

    private func save() {
        let compsStart = Calendar.current.dateComponents([.hour, .minute], from: startDate)
        let compsEnd = Calendar.current.dateComponents([.hour, .minute], from: endDate)

        let rule = TimeBlockRule(
            id: editingRule?.id ?? UUID(),
            appIDs: Array(selectedAppIDs),
            startHour: compsStart.hour ?? 22,
            startMinute: compsStart.minute ?? 0,
            endHour: compsEnd.hour ?? 8,
            endMinute: compsEnd.minute ?? 0,
            isEnabled: editingRule?.isEnabled ?? true,
            label: label.trimmingCharacters(in: .whitespaces)
        )

        if editingRule != nil {
            ruleStore.updateTimeBlockRule(rule)
        } else {
            ruleStore.addTimeBlockRule(rule)
        }
        dismiss()
    }
}

struct BlockableAppRef: Codable, Identifiable {
    let id: String
    let nameKey: String
    let icon: String
    let isBlocked: Bool
    let customLimitMinutes: Int?
}
