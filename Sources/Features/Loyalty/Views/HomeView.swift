import SwiftUI

/// Root home view coordinating top bar, loyalty discount card, questionnaire, and side drawer.
public struct HomeView: View {
    @ObservedObject public var viewModel: LoyaltyViewModel
    @State private var isDrawerOpen: Bool = false

    public init(viewModel: LoyaltyViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            // Background
            Color.yarSubject95
                .ignoresSafeArea()

            // Main Screen Content
            VStack(spacing: 0) {
                // Top Navigation Bar
                HomeAppBar(
                    photoUrl: viewModel.profile?.photoUrl,
                    onMenuTapped: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isDrawerOpen = true
                        }
                    }
                )

                // Body: Pre-registration questionnaire or Active Discount Card
                if viewModel.needsRegistration {
                    PreRegistrationView(viewModel: viewModel)
                        .transition(.opacity)
                } else {
                    DiscountCardView(viewModel: viewModel)
                        .transition(.opacity)
                }
            }

            // Slide-over drawer navigation overlay
            HomeDrawer(
                isOpen: $isDrawerOpen,
                profile: viewModel.profile,
                onSignOut: {
                    Task {
                        await viewModel.signOut()
                    }
                }
            )
        }
        .task {
            await viewModel.loadData()
        }
    }
}

#Preview("Home - Active Card") {
    let mockAuth = MockAuthService(
        initialUser: UserProfile(
            id: "user_active",
            name: "Александр",
            lastName: "Белянский",
            email: "alex@yarminsk.by",
            phone: "+375 29 123-45-67"
        )
    )
    let card = DiscountCard(
        id: "D1E2F3A4B5C6",
        userId: "user_active",
        cardHolder: "АЛЕКСАНДР БЕЛЯНСКИЙ",
        discount: 10.0,
        qrData: "D1E2F3",
        phone: "+375 29 123-45-67"
    )
    let mockDiscount = MockDiscountService(initialCards: ["user_active": card])
    let mockStorage = KeychainSessionStorage()
    let viewModel = LoyaltyViewModel(
        authService: mockAuth,
        discountService: mockDiscount,
        sessionStorage: mockStorage
    )
    viewModel.profile = mockAuth.currentUser()
    viewModel.discountCard = card
    viewModel.needsRegistration = false

    return HomeView(viewModel: viewModel)
}

#Preview("Home - Needs Questionnaire") {
    let mockAuth = MockAuthService(
        initialUser: UserProfile(
            id: "user_new",
            name: "",
            lastName: "",
            email: "guest@yarminsk.by",
            phone: ""
        )
    )
    let mockDiscount = MockDiscountService()
    let mockStorage = KeychainSessionStorage()
    let viewModel = LoyaltyViewModel(
        authService: mockAuth,
        discountService: mockDiscount,
        sessionStorage: mockStorage
    )
    viewModel.profile = mockAuth.currentUser()
    viewModel.discountCard = nil
    viewModel.needsRegistration = true

    return HomeView(viewModel: viewModel)
}
