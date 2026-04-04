import Foundation
import WidgetKit

struct WidgetSummary: Codable {
    var monthlyBudget: Double
    var balance: Double
    var needsProgress: Double
    var wantsProgress: Double
    var savingsProgress: Double
    var nextTitle: String
    var nextDateText: String
    var updatedAt: Date
}

enum WidgetDataStore {
    static let appGroupId = "group.lk.uni.vaultapp"
    private static let storageKey = "widget_summary"

    static func save(_ summary: WidgetSummary) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        if let data = try? JSONEncoder().encode(summary) {
            defaults.set(data, forKey: storageKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    static func load() -> WidgetSummary? {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return nil }
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSummary.self, from: data)
    }
}
