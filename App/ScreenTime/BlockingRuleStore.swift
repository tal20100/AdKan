import SwiftUI

@MainActor
final class BlockingRuleStore: ObservableObject {
    @AppStorage("timeBlockRulesJSON") private var timeBlockRulesJSON: String = ""
    @AppStorage("dayScheduleRulesJSON") private var dayScheduleRulesJSON: String = ""
    @AppStorage("globalLimitRuleJSON") private var globalLimitRuleJSON: String = ""

    @Published var timeBlockRules: [TimeBlockRule] = []
    @Published var dayScheduleRules: [DayScheduleRule] = []
    @Published var globalLimitRule: GlobalLimitRule = GlobalLimitRule()

    init() {
        loadAll()
    }

    func addTimeBlockRule(_ rule: TimeBlockRule) {
        timeBlockRules.append(rule)
        saveTimeBlockRules()
    }

    func removeTimeBlockRule(at offsets: IndexSet) {
        timeBlockRules.remove(atOffsets: offsets)
        saveTimeBlockRules()
    }

    func updateTimeBlockRule(_ rule: TimeBlockRule) {
        if let index = timeBlockRules.firstIndex(where: { $0.id == rule.id }) {
            timeBlockRules[index] = rule
            saveTimeBlockRules()
        }
    }

    func toggleDaySchedule(_ rule: DayScheduleRule) {
        if let index = dayScheduleRules.firstIndex(where: { $0.id == rule.id }) {
            dayScheduleRules[index].isEnabled.toggle()
            saveDayScheduleRules()
        }
    }

    func updateDaySchedule(_ rule: DayScheduleRule) {
        if let index = dayScheduleRules.firstIndex(where: { $0.id == rule.id }) {
            dayScheduleRules[index] = rule
            saveDayScheduleRules()
        }
    }

    func updateGlobalLimit(_ rule: GlobalLimitRule) {
        globalLimitRule = rule
        saveGlobalLimitRule()
    }

    private func loadAll() {
        timeBlockRules = decode(timeBlockRulesJSON) ?? []
        dayScheduleRules = decode(dayScheduleRulesJSON) ?? [.weekFocus, .weekendRelaxed]
        globalLimitRule = decode(globalLimitRuleJSON) ?? GlobalLimitRule()
    }

    private func saveTimeBlockRules() {
        timeBlockRulesJSON = encode(timeBlockRules)
    }

    private func saveDayScheduleRules() {
        dayScheduleRulesJSON = encode(dayScheduleRules)
    }

    private func saveGlobalLimitRule() {
        globalLimitRuleJSON = encode(globalLimitRule)
    }

    private func encode<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let str = String(data: data, encoding: .utf8)
        else { return "" }
        return str
    }

    private func decode<T: Decodable>(_ raw: String) -> T? {
        guard let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
