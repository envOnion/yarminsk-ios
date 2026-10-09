import SwiftUI

public struct RootView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var router: AppRouter

    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var loyaltyViewModel: LoyaltyViewModel
    @State private var selectedTab: GuestTab = .home

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
        TabView(selection: $selectedTab) {
            GuestHomeView(onMenu: { selectedTab = .menu }, onContacts: { selectedTab = .contacts },
                          onLoyalty: { selectedTab = .loyalty })
                .tabItem { Label("Главная", systemImage: "house") }.tag(GuestTab.home)
            MenuView()
                .tabItem { Label("Меню", systemImage: "fork.knife") }.tag(GuestTab.menu)
            ContactsView()
                .tabItem { Label("Контакты", systemImage: "mappin.and.ellipse") }.tag(GuestTab.contacts)
            loyaltyContent
                .tabItem { Label("Моя карта", systemImage: "qrcode") }.tag(GuestTab.loyalty)
        }
        .tint(.yarSecondary)
        .task {
            for await profile in container.authService.observeAuthState() {
                authViewModel.updateAuthState(profile)
                router.navigate(to: profile == nil ? .entry : .main)
            }
        }
    }

    private var loyaltyContent: some View {
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
                    .id(authViewModel.currentUser?.id)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: router.currentRoute)
    }

    private var splashView: some View {
        VStack(spacing: 24) {
            YarLogoEmblem(height: 96)
            ProgressView()
                .tint(.yarSecondary)
        }
    }
}

private enum GuestTab: Hashable {
    case home, menu, contacts, loyalty
}
