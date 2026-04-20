import SwiftUI

enum Route: Hashable {
    case onboarding
    case leaderboard
    case paywall
    case settings
}

final class Router: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to route: Route) {
        path.append(route)
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
