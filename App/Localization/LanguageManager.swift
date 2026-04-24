import SwiftUI
import UIKit

final class LanguageManager: ObservableObject {
    @AppStorage("preferredLanguage") var preferredLanguage: String = "he" {
        didSet {
            objectWillChange.send()
            applyUIKitDirection()
        }
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

    init() {
        applyUIKitDirection()
    }

    private func applyUIKitDirection() {
        let attr: UISemanticContentAttribute = preferredLanguage == "he"
            ? .forceRightToLeft
            : .forceLeftToRight
        UserDefaults.standard.set([preferredLanguage], forKey: "AppleLanguages")
        UIView.appearance().semanticContentAttribute = attr
        UINavigationBar.appearance().semanticContentAttribute = attr
        UITabBar.appearance().semanticContentAttribute = attr
    }
}
