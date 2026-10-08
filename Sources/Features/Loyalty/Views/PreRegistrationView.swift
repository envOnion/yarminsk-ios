import SwiftUI

/// Questionnaire screen shown when the user has not yet registered a loyalty card.
public struct PreRegistrationView: View {
    @ObservedObject public var viewModel: LoyaltyViewModel

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""
    @State private var isPhoneValid: Bool = false
    @State private var email: String = ""
    @State private var isAgreed: Bool = false

    public init(viewModel: LoyaltyViewModel) {
        self.viewModel = viewModel
    }

    private var isNameValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isLastNameValid: Bool {
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isFormValid: Bool {
        isNameValid && isLastNameValid && isPhoneValid && isAgreed
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header section
                VStack(alignment: .leading, spacing: 8) {
                    Text("ЗАПОЛНИТЕ ИНФОРМАЦИЮ")
                        .font(.yarHeadline3)
                        .foregroundColor(.yarSubject00)
                        .tracking(1.0)

                    Text("Для получения персональной клубной карты лояльности")
                        .font(.yarBodySRegular)
                        .foregroundColor(.yarSubject40)
                }
                .padding(.top, 16)

                // Input fields section
                VStack(spacing: 20) {
                    // Name field
                    YarTextField(
                        placeholder: "Иван",
                        title: "Имя",
                        text: Binding(
                            get: { firstName },
                            set: { firstName = capitalizeFirstLetter($0) }
                        ),
                        keyboardType: .default,
                        textContentType: .givenName,
                        autocapitalization: .words
                    )

                    // Surname field
                    YarTextField(
                        placeholder: "Иванов",
                        title: "Фамилия",
                        text: Binding(
                            get: { lastName },
                            set: { lastName = capitalizeFirstLetter($0) }
                        ),
                        keyboardType: .default,
                        textContentType: .familyName,
                        autocapitalization: .words
                    )

                    // Phone input field
                    PhoneInputField(
                        title: "Номер телефона",
                        phone: $phone,
                        isValid: $isPhoneValid
                    )

                    // Email field (prefilled from profile)
                    YarTextField(
                        placeholder: "example@mail.com",
                        title: "Электронная почта",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: .never
                    )
                }

                // Privacy agreement checkbox
                YarCheckbox(
                    "Соглашаюсь на обработку и хранение персональных данных",
                    isChecked: $isAgreed
                )
                .padding(.vertical, 4)

                // Error message banner
                if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.yarBodySRegular)
                        .foregroundColor(.yarError)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 4)
                }

                // Register button
                PrimaryButton(
                    "ЗАРЕГИСТРИРОВАТЬСЯ",
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.createCard(
                            name: firstName,
                            lastName: lastName,
                            phone: phone
                        )
                    }
                }
                .disabled(!isFormValid)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.yarSubject95.ignoresSafeArea())
        .onAppear {
            prefillUserData()
        }
    }

    private func capitalizeFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return "" }
        return String(first).uppercased() + text.dropFirst()
    }

    private func prefillUserData() {
        if let currentProfile = viewModel.profile {
            if email.isEmpty {
                email = currentProfile.email
            }
            if firstName.isEmpty {
                firstName = currentProfile.name
            }
            if lastName.isEmpty {
                lastName = currentProfile.lastName
            }
            if phone.isEmpty {
                phone = currentProfile.phone
            }
        }
    }
}

#Preview {
    let mockAuth = MockAuthService(
        initialUser: UserProfile(
            id: "preview_user_1",
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

    return PreRegistrationView(viewModel: viewModel)
}
