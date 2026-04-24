import Foundation

struct Comparison: Identifiable {
    let id = UUID()
    let icon: String
    let format: (Int) -> (en: String, he: String)
}

enum ComparisonBank {
    static func random(savedMinutes: Int, count: Int = 3) -> [ResolvedComparison] {
        guard savedMinutes > 0 else { return [] }
        return all
            .shuffled()
            .prefix(count)
            .map { $0.resolve(savedMinutes: savedMinutes) }
    }

    static let all: [ComparisonTemplate] = [
        // Distance & hiking
        ComparisonTemplate(icon: "🏔️") { m in
            let pct = Double(m) * 60 / (8 * 3600) * 100
            return (en: "hiked \(fmt(pct))% of Mount Everest's summit push", he: "לטפס \(fmt(pct))% מהפסגה של האוורסט")
        },
        ComparisonTemplate(icon: "🚶") { m in
            let km = Double(m) / 12.0
            return (en: "walked \(fmt(km)) km", he: "ללכת \(fmt(km)) ק״מ")
        },
        ComparisonTemplate(icon: "🇮🇱") { m in
            let pct = Double(m) * 60 / (54000) * 100
            return (en: "walked \(fmt(pct))% of Tel Aviv to Jerusalem", he: "ללכת \(fmt(pct))% מתל אביב לירושלים")
        },
        ComparisonTemplate(icon: "🏊") { m in
            let pct = Double(m) * 60 / (34200) * 100
            return (en: "swum \(fmt(pct))% of the English Channel", he: "לשחות \(fmt(pct))% מתעלת לה מאנש")
        },

        // Speed & animals
        ComparisonTemplate(icon: "🦥") { m in
            let meters = Double(m) * 0.15
            return (en: "a sloth could've moved \(fmt(meters)) meters", he: "עצלן היה זז \(fmt(meters)) מטר")
        },
        ComparisonTemplate(icon: "🐆") { m in
            let km = Double(m) / 60.0 * 120.0
            return (en: "a cheetah could've run \(fmtInt(km)) km", he: "צ׳יטה היתה רצה \(fmtInt(km)) ק״מ")
        },
        ComparisonTemplate(icon: "🐌") { m in
            let meters = Double(m) * 0.8
            return (en: "a snail could've crossed \(fmt(meters)) meters", he: "חילזון היה חוצה \(fmt(meters)) מטר")
        },
        ComparisonTemplate(icon: "🐕") { m in
            let walks = Double(m) / 30.0
            return (en: "taken your dog on \(fmt(walks)) walks", he: "להוציא את הכלב \(fmt(walks)) פעמים")
        },

        // Space & science
        ComparisonTemplate(icon: "🛸") { m in
            let orbits = Double(m) / 92.0
            return (en: "the ISS orbited Earth \(fmt(orbits)) times", he: "תחנת החלל הקיפה את כדור הארץ \(fmt(orbits)) פעמים")
        },
        ComparisonTemplate(icon: "🌙") { m in
            let pct = Double(m) * 60 / (259200) * 100
            return (en: "traveled \(fmt(pct))% of the way to the Moon", he: "לנסוע \(fmt(pct))% מהדרך לירח")
        },
        ComparisonTemplate(icon: "⚡") { m in
            let bolts = Double(m) * 60 / 0.001
            let billions = bolts / 1_000_000_000
            return (en: "lightning could've struck \(fmt(billions)) billion times", he: "ברק היה יכול לפגוע \(fmt(billions)) מיליארד פעמים")
        },

        // Food & cooking
        ComparisonTemplate(icon: "🍳") { m in
            let pans = Double(m) / 5.0
            return (en: "made \(fmt(pans)) pans of shakshuka", he: "להכין \(fmt(pans)) מחבתות שקשוקה")
        },
        ComparisonTemplate(icon: "☕") { m in
            let cups = Double(m) / 12.0
            return (en: "brewed \(fmt(cups)) cups of Turkish coffee", he: "להכין \(fmt(cups)) כוסות קפה טורקי")
        },
        ComparisonTemplate(icon: "🍕") { m in
            let pizzas = Double(m) / 90.0
            return (en: "made \(fmt(pizzas)) pizzas from scratch", he: "להכין \(fmt(pizzas)) פיצות מאפס")
        },
        ComparisonTemplate(icon: "🥙") { m in
            let falafel = Double(m) / 3.0
            return (en: "fried \(fmtInt(falafel)) falafel balls", he: "לטגן \(fmtInt(falafel)) כדורי פלאפל")
        },
        ComparisonTemplate(icon: "🧁") { m in
            let cakes = Double(m) / 45.0
            return (en: "baked \(fmt(cakes)) cakes", he: "לאפות \(fmt(cakes)) עוגות")
        },

        // Culture & media
        ComparisonTemplate(icon: "📚") { m in
            let pages = Double(m) * 1.1
            return (en: "read \(fmtInt(pages)) pages of a book", he: "לקרוא \(fmtInt(pages)) עמודים בספר")
        },
        ComparisonTemplate(icon: "🎬") { m in
            let pct = Double(m) / 201.0 * 100
            return (en: "watched \(fmt(pct))% of Lord of the Rings: Fellowship", he: "לצפות ב-\(fmt(pct))% משר הטבעות: אחוות הטבעת")
        },
        ComparisonTemplate(icon: "🎵") { m in
            let listens = Double(m) / 47.0
            return (en: "listened to Abbey Road \(fmt(listens)) times", he: "להאזין ל-Abbey Road \u{200F}\(fmt(listens)) פעמים")
        },
        ComparisonTemplate(icon: "🎮") { m in
            let matches = Double(m) / 25.0
            return (en: "played \(fmt(matches)) full game matches", he: "לשחק \(fmt(matches)) משחקים שלמים")
        },

        // Fitness
        ComparisonTemplate(icon: "🏃") { m in
            let km = Double(m) / 6.0
            return (en: "run \(fmt(km)) km", he: "לרוץ \(fmt(km)) ק״מ")
        },
        ComparisonTemplate(icon: "🚴") { m in
            let km = Double(m) / 2.4
            return (en: "cycled \(fmt(km)) km", he: "לרכב על אופניים \(fmt(km)) ק״מ")
        },
        ComparisonTemplate(icon: "🧘") { m in
            let sessions = Double(m) / 20.0
            return (en: "completed \(fmt(sessions)) meditation sessions", he: "להשלים \(fmt(sessions)) מפגשי מדיטציה")
        },
        ComparisonTemplate(icon: "💪") { m in
            let reps = Double(m) * 12
            return (en: "done \(fmtInt(reps)) push-ups", he: "לעשות \(fmtInt(reps)) שכיבות סמיכה")
        },

        // Absurd
        ComparisonTemplate(icon: "🧔") { m in
            let nm = Double(m) * 5.5
            return (en: "your beard grew \(fmtInt(nm)) nanometers", he: "הזקן שלך גדל \(fmtInt(nm)) ננומטר")
        },
        ComparisonTemplate(icon: "💓") { m in
            let beats = Double(m) * 72
            return (en: "your heart beat \(fmtInt(beats)) times", he: "הלב שלך דפק \(fmtInt(beats)) פעימות")
        },
        ComparisonTemplate(icon: "🌍") { m in
            let km = Double(m) / 60.0 * 1670.0
            return (en: "Earth carried you \(fmtInt(km)) km through space", he: "כדור הארץ נשא אותך \(fmtInt(km)) ק״מ בחלל")
        },
        ComparisonTemplate(icon: "✈️") { m in
            let pct = Double(m) / 660.0 * 100
            return (en: "flown \(fmt(pct))% from TLV to NYC", he: "לטוס \(fmt(pct))% מת״א לניו יורק")
        },
        ComparisonTemplate(icon: "🦠") { m in
            let divisions = Double(m) / 20.0
            let bacteria = pow(2.0, divisions)
            let formatted = bacteria > 1_000_000 ? "\(fmt(bacteria / 1_000_000))M" : fmtInt(bacteria)
            return (en: "one bacterium became \(formatted)", he: "חיידק אחד הפך ל-\(formatted)")
        },
    ]

    private static func fmt(_ value: Double) -> String {
        if value >= 100 { return String(format: "%.0f", value) }
        if value >= 10 { return String(format: "%.1f", value) }
        return String(format: "%.2f", value)
    }

    private static func fmtInt(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "%.1fK", value / 1_000) }
        return String(format: "%.0f", value)
    }
}

struct ComparisonTemplate {
    let icon: String
    let compute: (Int) -> (en: String, he: String)

    func resolve(savedMinutes: Int) -> ResolvedComparison {
        let result = compute(savedMinutes)
        return ResolvedComparison(icon: icon, textEN: result.en, textHE: result.he)
    }
}

struct ResolvedComparison: Identifiable {
    let id = UUID()
    let icon: String
    let textEN: String
    let textHE: String

    func text(locale: String) -> String {
        let str = locale.hasPrefix("he") ? textHE : textEN
        if locale.hasPrefix("he") {
            return "\u{200F}" + str
        }
        return str
    }
}
