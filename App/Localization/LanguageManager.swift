import SwiftUI

final class LanguageManager: ObservableObject {
    @AppStorage("preferredLanguage") var preferredLanguage: String = "he" {
        didSet {
            objectWillChange.send()
            UserDefaults.standard.set([preferredLanguage], forKey: "AppleLanguages")
        }
    }

    var locale: Locale {
        Locale(identifier: preferredLanguage)
    }

    var isHebrew: Bool {
        preferredLanguage == "he"
    }

    init() {
        UserDefaults.standard.set([preferredLanguage], forKey: "AppleLanguages")
    }
}
