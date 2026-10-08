import SwiftUI

public enum AppRoute: Hashable {
    case splash
    case entry
    case signIn
    case signUp
    case main
}

@MainActor
public final class AppRouter: ObservableObject {
    @Published public var currentRoute: AppRoute = .splash

    public init(initialRoute: AppRoute = .splash) {
        self.currentRoute = initialRoute
    }

    public func navigate(to route: AppRoute) {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.currentRoute = route
        }
    }
}
