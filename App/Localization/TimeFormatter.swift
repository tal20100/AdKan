import Foundation

enum TimeFormatter {
    static func format(minutes: Int, locale: String) -> String {
        let h = minutes / 60
        let m = minutes % 60
        let isHebrew = locale.hasPrefix("he")

        if isHebrew {
            let hourPart = hebrewHours(h)
            let minPart = hebrewMinutes(m)
            if h > 0 && m > 0 { return "\u{200F}\(hourPart) ו\u{2011}\(minPart)\u{200F}" }
            if h > 0 { return "\u{200F}\(hourPart)\u{200F}" }
            return "\u{200F}\(minPart)\u{200F}"
        } else {
            if h > 0 && m > 0 { return "\(h)h \(m)m" }
            if h > 0 { return "\(h)h" }
            return "\(m)m"
        }
    }

    private static func hebrewHours(_ h: Int) -> String {
        switch h {
        case 1: return "שעה"
        case 2: return "שעתיים"
        default: return "\(h) שעות"
        }
    }

    private static func hebrewMinutes(_ m: Int) -> String {
        switch m {
        case 1: return "דקה"
        default: return "\(m) דקות"
        }
    }
}
