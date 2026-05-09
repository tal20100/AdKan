import Foundation

enum TimeFormatter {
    static func format(minutes: Int, locale: String) -> String {
        let h = minutes / 60
        let m = minutes % 60
        let isHebrew = locale.hasPrefix("he")
        let hourUnit = isHebrew ? "שעות" : "h"
        let minUnit = isHebrew ? "דקות" : "m"
        if h > 0 && m > 0 { return "\(h) \(hourUnit) \(m) \(minUnit)" }
        if h > 0 { return "\(h) \(hourUnit)" }
        return "\(m) \(minUnit)"
    }
}
