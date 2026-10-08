import SwiftUI

/// Sign-up screen with email registration and social authentication (Apple & Google).
public struct SignUpView: View {
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
        if !viewModel.password.isEmpty && !viewModel.isPasswordValid {
            return "Пароль должен содержать не менее 6 символов"
        }
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
                                placeholder: "Придумайте пароль",
                                title: "Пароль",
                                text: $viewModel.password,
                                isSecure: true,
                                errorMessage: passwordValidationMessage,
                                textContentType: .newPassword,
                                autocapitalization: .never,
                                autocorrectionDisabled: true
                            )
                        }
                        .padding(.top, 16)

                        // Primary Register Button
                        PrimaryButton("ЗАРЕГИСТРИРОВАТЬСЯ", isLoading: viewModel.isLoading) {
                            Task {
                                await viewModel.signUpWithEmail()
                                handleAuthResult()
                            }
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)
                        .padding(.top, 8)

                        // Divider with "ИЛИ"
                        orDivider

                        // Social Login Buttons
                        VStack(spacing: 14) {
                            OutlineButton(
                                "Войдите с помощью Google",
                                icon: googleIcon,
                                borderColor: .white
                            ) {
                                Task {
                                    await viewModel.signInWithGoogle()
                                    handleAuthResult()
                                }
                            }
                            .disabled(viewModel.isLoading)

                            OutlineButton(
                                "Войдите с помощью Apple",
                                icon: appleIcon,
                                borderColor: .white
                            ) {
                                Task {
                                    await viewModel.signInWithApple()
                                    handleAuthResult()
                                }
                            }
                            .disabled(viewModel.isLoading)
                        }

                        // Link back to Sign In
                        HStack(spacing: 6) {
                            Text("УЖЕ ЕСТЬ АККАУНТ?")
                                .font(.yarBodyXSRegular)
                                .foregroundColor(.yarSubject40)

                            Button(action: {
                                router.navigate(to: .signIn)
                            }) {
                                Text("ВОЙТИ")
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

            Text("РЕГИСТРАЦИЯ")
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

    // MARK: - Divider

    private var orDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.yarSubject80)
                .frame(height: 1)

            Text("ИЛИ")
                .font(.yarBodyXSMedium)
                .foregroundColor(.yarSubject40)
                .tracking(2.0)

            Rectangle()
                .fill(Color.yarSubject80)
                .frame(height: 1)
        }
        .padding(.vertical, 8)
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

    // MARK: - Social Icons

    private var appleIcon: Image {
        Image(systemName: "apple.logo")
    }

    private var googleIcon: Image {
        if let uiImage = UIImage(named: "googleLogo") {
            return Image(uiImage: uiImage)
        }
        return Image(uiImage: renderGoogleGlyph())
    }

    private func renderGoogleGlyph() -> UIImage {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let text = "G"
            let font = UIFont.systemFont(ofSize: 18, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let rect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: rect, withAttributes: attributes)
        }.withRenderingMode(.alwaysTemplate)
    }

    // MARK: - Handlers

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            router.navigate(to: .entry)
        }
    }

    private func handleAuthResult() {
        if viewModel.isAuthenticated {
            if let onSuccess {
                onSuccess()
            } else {
                router.navigate(to: .main)
            }
        }
    }
}

// MARK: - Previews

#Preview("SignUpView Default") {
    let mockAuth = MockAuthService()
    let mockStorage = KeychainSessionStorage()
    let vm = AuthViewModel(authService: mockAuth, sessionStorage: mockStorage)
    return SignUpView(viewModel: vm)
        .environmentObject(AppRouter())
}

#Preview("SignUpView with Error") {
    let mockAuth = MockAuthService()
    let mockStorage = KeychainSessionStorage()
    let vm = AuthViewModel(authService: mockAuth, sessionStorage: mockStorage)
    vm.email = "existing@example.com"
    vm.password = "123456"
    vm.errorMessage = "Пользователь с таким email уже существует"
    return SignUpView(viewModel: vm)
        .environmentObject(AppRouter())
}

#Preview("SignUpView Loading") {
    let mockAuth = MockAuthService()
    let mockStorage = KeychainSessionStorage()
    let vm = AuthViewModel(authService: mockAuth, sessionStorage: mockStorage)
    vm.email = "test@example.com"
    vm.password = "secret123"
    vm.isLoading = true
    return SignUpView(viewModel: vm)
        .environmentObject(AppRouter())
}
