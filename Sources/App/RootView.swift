import SwiftUI

public struct RootView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var router: AppRouter

    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var loyaltyViewModel: LoyaltyViewModel

    public init(container: AppContainer) {
        _authViewModel = StateObject(wrappedValue: AuthViewModel(
            authService: container.authService,
            sessionStorage: container.sessionStorage
        ))
        _loyaltyViewModel = StateObject(wrappedValue: LoyaltyViewModel(
            authService: container.authService,
            discountService: container.discountService,
            sessionStorage: container.sessionStorage
        ))
    }

    public var body: some View {
        ZStack {
            Color.yarSubject95
                .ignoresSafeArea()

            switch router.currentRoute {
            case .splash:
                splashView
            case .entry:
                EntryView(
                    onSignIn: { router.navigate(to: .signIn) },
                    onSignUp: { router.navigate(to: .signUp) }
                )
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity
                ))
            case .signIn:
                SignInView(
                    viewModel: authViewModel,
                    onBack: { router.navigate(to: .entry) },
                    onSuccess: { router.navigate(to: .main) }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .signUp:
                SignUpView(
                    viewModel: authViewModel,
                    onBack: { router.navigate(to: .entry) },
                    onSuccess: { router.navigate(to: .main) }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .main:
                HomeView(viewModel: loyaltyViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: router.currentRoute)
        .task {
            // Check current user session on launch
            if let user = container.authService.currentUser() {
                authViewModel.currentUser = user
                authViewModel.isAuthenticated = true
                router.navigate(to: .main)
            } else if container.sessionStorage.getToken() != nil {
                // If token exists, wait briefly or observe auth
                router.navigate(to: .main)
            } else {
                router.navigate(to: .entry)
            }

            // Observe auth state changes
            for await profile in container.authService.observeAuthState() {
                if profile != nil {
                    if router.currentRoute != .main {
                        router.navigate(to: .main)
                    }
                } else {
                    if router.currentRoute == .main {
                        router.navigate(to: .entry)
                    }
                }
            }
        }
    }

    private var splashView: some View {
        VStack(spacing: 24) {
            YarLogoEmblem(height: 96)
            ProgressView()
                .tint(.yarSecondary)
        }
    }
}
