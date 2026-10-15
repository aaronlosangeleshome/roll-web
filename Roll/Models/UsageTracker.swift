import Foundation

/// Tracks the free daily pic allowance. Stored in UserDefaults (declared in PrivacyInfo.xcprivacy).
@MainActor
final class UsageTracker: ObservableObject {
    @Published private(set) var usedToday: Int = 0

    private let dayKey = "usage.day"
    private let countKey = "usage.count"
    private let defaults = UserDefaults.standard

    init() { refresh() }

    var remaining: Int { max(0, AppConfig.freeDailyPics - usedToday) }

    func refresh() {
        let today = Self.dayString(Date())
        if defaults.string(forKey: dayKey) != today {
            defaults.set(today, forKey: dayKey)
            defaults.set(0, forKey: countKey)
        }
        usedToday = defaults.integer(forKey: countKey)
    }

    func recordShot() {
        refresh()
        usedToday += 1
        defaults.set(usedToday, forKey: countKey)
    }

    private static func dayString(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }
}
