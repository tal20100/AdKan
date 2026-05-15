import Foundation

enum ComparisonBank {
    static func random(savedMinutes: Int, count: Int = 3) -> [ResolvedComparison] {
        let minutes = max(savedMinutes, 1)
        return all
            .shuffled()
            .prefix(count)
            .map { $0.resolve(savedMinutes: minutes) }
    }

    static let all: [ComparisonTemplate] = [
        // Distance & travel
        ComparisonTemplate(icon: "🏔️") { m in
            let pct = Double(m) * 60 / (8 * 3600) * 100
            return (en: "hiked \(fmt(pct))% of Everest's summit push", he: "לטפס \(fmt(pct))% מהפסגה של האוורסט")
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
            return (en: "swum \(fmt(pct))% of the English Channel", he: "לשחות \(fmt(pct))% מתעלת למאנש")
        },
        ComparisonTemplate(icon: "✈️") { m in
            let pct = Double(m) / 660.0 * 100
            return (en: "flown \(fmt(pct))% from TLV to NYC", he: "לטוס \(fmt(pct))% מת״א לניו יורק")
        },
        ComparisonTemplate(icon: "🐕") { m in
            let walks = Double(m) / 30.0
            return (en: "taken your dog on \(fmt(walks)) walks", he: "להוציא את הכלב \(fmt(walks)) פעמים")
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

        // Fun facts
        ComparisonTemplate(icon: "🐋") { m in
            let beats = Double(m) * 6
            return (en: "a blue whale's heart beat \(fmtInt(beats)) times", he: "לב של לוויתן כחול היה פועם \(fmtInt(beats)) פעמים")
        },
        ComparisonTemplate(icon: "🦒") { m in
            let km = Double(m) / 60.0 * 5.0
            return (en: "a giraffe walked \(fmt(km)) km", he: "ג׳ירפה היתה הולכת \(fmt(km)) ק״מ")
        },
        ComparisonTemplate(icon: "🧊") { m in
            let meters = Double(m) * 11.67
            return (en: "an iceberg drifted \(fmtInt(meters)) meters", he: "קרחון היה נסחף \(fmtInt(meters)) מטר")
        },
        ComparisonTemplate(icon: "🌻") { m in
            let mm = Double(m) / 1440.0 * 30.0
            return (en: "a sunflower grew \(fmt(mm)) mm", he: "חמנייה היתה גדלה \(fmt(mm)) מ״מ")
        },
        ComparisonTemplate(icon: "🎬") { m in
            let pct = Double(m) / 3540.0 * 100
            return (en: "watched \(fmt(pct))% of every Marvel movie", he: "לצפות ב-\(fmt(pct))% מכל סרטי מארוול")
        },
        ComparisonTemplate(icon: "🏗️") { m in
            let pct = Double(m) / 1440.0 * 100
            return (en: "built \(fmt(pct))% of a LEGO Death Star", he: "לבנות \(fmt(pct))% מכוכב מוות מלגו")
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
