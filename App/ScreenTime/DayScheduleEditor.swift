import SwiftUI

struct DayScheduleEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ruleStore: BlockingRuleStore

    let rule: DayScheduleRule

    @State private var activeDays: Set<Int> = []
    @State private var limitMinutes: Int = 60

    private let daySymbols: [(Int, String)] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return Array(zip(1...7, symbols))
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("blocking.schedule.days") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(daySymbols, id: \.0) { day, symbol in
                            let isActive = activeDays.contains(day)
                            Button {
                                if isActive { activeDays.remove(day) }
                                else { activeDays.insert(day) }
                            } label: {
                                Text(symbol)
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isActive ? AdKanTheme.primary : Color(.systemGray5))
                                    .foregroundStyle(isActive ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("blocking.schedule.limit") {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent {
                            Text(formattedLimit(limitMinutes))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AdKanTheme.primary)
                        } label: {
                            Text("blocking.defaultLimit.label")
                        }

                        Slider(
                            value: Binding(
                                get: { Double(limitMinutes) },
                                set: { limitMinutes = Int($0) }
                            ),
                            in: 15...480,
                            step: 15
                        )
                        .tint(AdKanTheme.primary)
                    }
                }
            }
            .navigationTitle(Text(LocalizedStringKey(rule.name)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("blocking.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("blocking.save") { save() }
                }
            }
            .onAppear {
                activeDays = rule.activeDays
                limitMinutes = rule.defaultLimitMinutes
            }
        }
    }

    private func save() {
        var updated = rule
        updated.activeDays = activeDays
        updated.defaultLimitMinutes = limitMinutes
        ruleStore.updateDaySchedule(updated)
        dismiss()
    }

    private func formattedLimit(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}
