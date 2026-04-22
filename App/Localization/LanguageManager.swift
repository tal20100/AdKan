import SwiftUI

final class LanguageManager: ObservableObject {
    @AppStorage("preferredLanguage") var preferredLanguage: String = "he" {
        didSet { objectWillChange.send() }
    }

    var layoutDirection: LayoutDirection {
        preferredLanguage == "he" ? .rightToLeft : .leftToRight
    }

    var locale: Locale {
        Locale(identifier: preferredLanguage)
    }

    func setLanguage(_ code: String) {
        preferredLanguage = code
    }

    var isHebrew: Bool {
        preferredLanguage == "he"
    }
}
