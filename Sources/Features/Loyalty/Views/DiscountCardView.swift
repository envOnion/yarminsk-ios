import SwiftUI

/// Luxury dark loyalty card display with tier gradient, dynamic QR code, and pull-to-refresh.
public struct DiscountCardView: View {
    @ObservedObject public var viewModel: LoyaltyViewModel

    public init(viewModel: LoyaltyViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading && viewModel.discountCard == nil {
                    skeletonCardView
                } else if let card = viewModel.discountCard {
                    cardContent(card: card)
                } else {
                    emptyCardPlaceholder
                }

                // Subtitle helper
                Text("Покажите QR-код при расчете для получения скидки")
                    .font(.yarBodyXSRegular)
                    .foregroundColor(.yarSubject50)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .background(Color.yarSubject95.ignoresSafeArea())
    }

    // MARK: - Active Card View

    private func cardContent(card: DiscountCard) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // Top row: Logo emblem + "ЯР МИНСК"
            HStack(spacing: 12) {
                YarLogoEmblem(height: 24)

                Text("ЯР МИНСК")
                    .font(.yarHeadline4)
                    .foregroundColor(.yarSubject00)
                    .tracking(2.0)

                Spacer()
            }

            // Thin divider
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)

            // Card tier title with gradient
            tierTitleView(tier: card.tier)

            // Two-column info: Cardholder name & Discount percentage
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ДЕРЖАТЕЛЬ КАРТЫ")
                        .font(.yarBodyXSRegular)
                        .foregroundColor(.yarSubject40)
                        .tracking(1.0)

                    Text(card.cardHolder.uppercased())
                        .font(.yarBodySBold)
                        .foregroundColor(.yarSubject00)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("СКИДКА")
                        .font(.yarBodyXSRegular)
                        .foregroundColor(.yarSubject40)
                        .tracking(1.0)

                    Text("\(Int(card.discount))%")
                        .font(.yarBodyMBold)
                        .foregroundColor(.yarSubject00)
                }
            }

            // Centered QR Code
            VStack(spacing: 10) {
                QRCodeView(
                    data: card.qrData,
                    size: 190,
                    padding: 14,
                    cornerRadius: 18,
                    boxColor: .white
                )

                Text(card.qrData)
                    .font(.oswald(.medium, size: 16))
                    .foregroundColor(.yarSubject40)
                    .tracking(3.0)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .padding(24)
        .background(LinearGradient.yarCardBackgroundGradient)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: 10)
    }

    // MARK: - Tier Title

    @ViewBuilder
    private func tierTitleView(tier: DiscountTier) -> some View {
        Text(tier.title)
            .font(.oswald(.bold, size: 30))
            .tracking(2.5)
            .overlay(
                tierGradient(for: tier)
                    .mask(
                        Text(tier.title)
                            .font(.oswald(.bold, size: 30))
                            .tracking(2.5)
                    )
            )
    }

    private func tierGradient(for tier: DiscountTier) -> LinearGradient {
        switch tier {
        case .silver:
            return .yarSilverGradient
        case .gold:
            return .yarGoldGradient
        case .platinum:
            return .yarPlatinumGradient
        case .unknown:
            return .yarSilverGradient
        }
    }

    // MARK: - Skeleton Shimmer View

    private var skeletonCardView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Top Row Placeholder
            HStack(spacing: 12) {
                ShimmerBox(cornerRadius: 6, height: 24)
                    .frame(width: 40)
                ShimmerBox(cornerRadius: 6, height: 24)
                    .frame(width: 120)
                Spacer()
            }

            // Divider Placeholder
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            // Tier Placeholder
            ShimmerBox(cornerRadius: 6, height: 32)
                .frame(width: 140)

            // Two-column Info Placeholder
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    ShimmerBox(cornerRadius: 4, height: 12)
                        .frame(width: 90)
                    ShimmerBox(cornerRadius: 4, height: 18)
                        .frame(width: 140)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    ShimmerBox(cornerRadius: 4, height: 12)
                        .frame(width: 50)
                    ShimmerBox(cornerRadius: 4, height: 18)
                        .frame(width: 40)
                }
            }

            // Center QR Code Placeholder
            VStack(spacing: 12) {
                ShimmerBox(cornerRadius: 18, height: 218)
                    .frame(width: 218)

                ShimmerBox(cornerRadius: 4, height: 16)
                    .frame(width: 80)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .padding(24)
        .background(LinearGradient.yarCardBackgroundGradient)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    // MARK: - Empty State Placeholder

    private var emptyCardPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 48))
                .foregroundColor(.yarSubject40)

            Text("КАРТА НЕ НАЙДЕНА")
                .font(.yarHeadline4)
                .foregroundColor(.yarSubject00)

            Text("Потяните экран вниз для обновления данных")
                .font(.yarBodySRegular)
                .foregroundColor(.yarSubject40)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
        .background(Color.yarSubject90)
        .cornerRadius(24)
    }
}

#Preview("Active Silver Card") {
    let mockAuth = MockAuthService(
        initialUser: UserProfile(
            id: "user_silver",
            name: "Александр",
            lastName: "Белянский",
            email: "user@yarminsk.by",
            phone: "+375291234567"
        )
    )
    let card = DiscountCard(
        id: "D1E2F3A4B5C6",
        userId: "user_silver",
        cardHolder: "АЛЕКСАНДР БЕЛЯНСКИЙ",
        discount: 10.0,
        qrData: "D1E2F3",
        phone: "+375291234567"
    )
    let mockDiscount = MockDiscountService(initialCards: ["user_silver": card])
    let mockStorage = KeychainSessionStorage()
    let viewModel = LoyaltyViewModel(
        authService: mockAuth,
        discountService: mockDiscount,
        sessionStorage: mockStorage
    )
    viewModel.profile = mockAuth.currentUser()
    viewModel.discountCard = card

    return DiscountCardView(viewModel: viewModel)
}

#Preview("Active Gold Card") {
    let mockAuth = MockAuthService(
        initialUser: UserProfile(
            id: "user_gold",
            name: "Максим",
            lastName: "Ковалев",
            email: "gold@yarminsk.by",
            phone: "+375297654321"
        )
    )
    let card = DiscountCard(
        id: "A9B8C7D6E5F4",
        userId: "user_gold",
        cardHolder: "МАКСИМ КОВАЛЕВ",
        discount: 20.0,
        qrData: "A9B8C7",
        phone: "+375297654321"
    )
    let mockDiscount = MockDiscountService(initialCards: ["user_gold": card])
    let mockStorage = KeychainSessionStorage()
    let viewModel = LoyaltyViewModel(
        authService: mockAuth,
        discountService: mockDiscount,
        sessionStorage: mockStorage
    )
    viewModel.profile = mockAuth.currentUser()
    viewModel.discountCard = card

    return DiscountCardView(viewModel: viewModel)
}

#Preview("Loading Skeleton") {
    let mockAuth = MockAuthService()
    let mockDiscount = MockDiscountService()
    let mockStorage = KeychainSessionStorage()
    let viewModel = LoyaltyViewModel(
        authService: mockAuth,
        discountService: mockDiscount,
        sessionStorage: mockStorage
    )
    viewModel.isLoading = true

    return DiscountCardView(viewModel: viewModel)
}
