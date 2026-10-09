import SwiftUI

/// Sign-in screen with email and password authentication.
public struct SignInView: View {
    @ObservedObject public var viewModel: AuthViewModel
    public var onBack: (() -> Void)?
    public var onSuccess: (() -> Void)?

    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    public init(
        viewModel: AuthViewModel,
        onBack: (() -> Void)? = nil,
        onSuccess: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onBack = onBack
        self.onSuccess = onSuccess
    }

    public init(
        authService: AuthServiceProtocol = MockAuthService(),
        sessionStorage: SessionStorageProtocol = KeychainSessionStorage(),
        onBack: (() -> Void)? = nil,
        onSuccess: (() -> Void)? = nil
    ) {
        self.viewModel = AuthViewModel(authService: authService, sessionStorage: sessionStorage)
        self.onBack = onBack
        self.onSuccess = onSuccess
    }

    private var emailValidationMessage: String? {
        if !viewModel.email.isEmpty && !viewModel.isEmailValid {
            return "Некорректный формат email"
        }
        return nil
    }

    private var passwordValidationMessage: String? {
        return nil
    }

    public var body: some View {
        ZStack {
            Color.yarSubject95
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                ScrollView {
                    VStack(spacing: 24) {
                        // Error banner
                        if let errorMessage = viewModel.errorMessage {
                            errorBanner(errorMessage)
                        }

                        // Input fields
                        VStack(spacing: 20) {
                            YarTextField(
                                placeholder: "example@mail.com",
                                title: "Email",
                                text: $viewModel.email,
                                errorMessage: emailValidationMessage,
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress,
                                autocapitalization: .never,
                                autocorrectionDisabled: true
                            )

                            YarTextField(
                                placeholder: "Введите пароль",
                                title: "Пароль",
                                text: $viewModel.password,
                                isSecure: true,
                                errorMessage: passwordValidationMessage,
                                textContentType: .password,
                                autocapitalization: .never,
                                autocorrectionDisabled: true
                            )
                        }
                        .padding(.top, 16)

                        // Action Button
                        PrimaryButton("ВОЙТИ", isLoading: viewModel.isLoading) {
                            Task {
                                if await viewModel.signInWithEmail() {
                                    if let onSuccess {
                                        onSuccess()
                                    } else {
                                        router.navigate(to: .main)
                                    }
                                }
                            }
                        }
                        .disabled(!viewModel.isSignInFormValid || viewModel.isLoading)
                        .padding(.top, 8)

                        // Navigate to Sign Up
                        HStack(spacing: 6) {
                            Text("НЕТ АККАУНТА?")
                                .font(.yarBodyXSRegular)
                                .foregroundColor(.yarSubject40)

                            Button(action: {
                                router.navigate(to: .signUp)
                            }) {
                                Text("ЗАРЕГИСТРИРОВАТЬСЯ")
                                    .font(.yarBodyXSBold)
                                    .foregroundColor(.yarSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button(action: {
                handleBack()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                    Text("НАЗАД")
                        .font(.yarBodySMedium)
                }
                .foregroundColor(.yarSubject00)
                .padding(.vertical, 12)
                .padding(.trailing, 16)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("АВТОРИЗАЦИЯ")
                .font(.yarHeadline4)
                .foregroundColor(.yarSubject00)
                .tracking(2.0)

            Spacer()

            // Balance placeholder for center alignment
            Color.clear
                .frame(width: 70, height: 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.yarError)
                .font(.system(size: 20))

            Text(message)
                .font(.yarBodySRegular)
                .foregroundColor(.yarSubject00)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(action: {
                viewModel.clearError()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.yarSubject40)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.yarError.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yarError.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
    }

    // MARK: - Back Navigation

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            router.navigate(to: .entry)
        }
    }
}

// MARK: - Previews

#Preview("SignInView Default") {
    let mockAuth = MockAuthService()
    let mockStorage = KeychainSessionStorage()
    let vm = AuthViewModel(authService: mockAuth, sessionStorage: mockStorage)
    return SignInView(viewModel: vm)
        .environmentObject(AppRouter())
}

#Preview("SignInView with Error") {
    let mockAuth = MockAuthService()
    let mockStorage = KeychainSessionStorage()
    let vm = AuthViewModel(authService: mockAuth, sessionStorage: mockStorage)
    vm.email = "bad_user@domain.com"
    vm.password = "123456"
    vm.errorMessage = "Неверный email или пароль"
    return SignInView(viewModel: vm)
        .environmentObject(AppRouter())
}

#Preview("SignInView Loading") {
    let mockAuth = MockAuthService()
    let mockStorage = KeychainSessionStorage()
    let vm = AuthViewModel(authService: mockAuth, sessionStorage: mockStorage)
    vm.email = "test@example.com"
    vm.password = "secret123"
    vm.isLoading = true
    return SignInView(viewModel: vm)
        .environmentObject(AppRouter())
}
