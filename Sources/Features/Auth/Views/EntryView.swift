import SwiftUI

/// Welcome and landing screen of the application.
public struct EntryView: View {
    public var onSignIn: (() -> Void)?
    public var onSignUp: (() -> Void)?

    @EnvironmentObject private var router: AppRouter
    @State private var isPrivacyPolicyPresented: Bool = false

    public init(
        onSignIn: (() -> Void)? = nil,
        onSignUp: (() -> Void)? = nil
    ) {
        self.onSignIn = onSignIn
        self.onSignUp = onSignUp
    }

    public var body: some View {
        ZStack {
            // Background
            Color.yarSubject95
                .ignoresSafeArea()

            // Subtle gradient glow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.yarSecondary.opacity(0.12),
                    Color.clear
                ]),
                center: .top,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                // Clean Logo Emblem
                logoSection
                    .padding(.bottom, 48)

                Spacer()

                // Actions Section
                VStack(spacing: 16) {
                    OutlineButton("ВОЙТИ", borderColor: .white) {
                        handleSignInTap()
                    }

                    OutlineButton("ЗАРЕГИСТРИРОВАТЬСЯ", borderColor: .primary) {
                        handleSignUpTap()
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)

                // Privacy Policy Footer
                Button(action: {
                    isPrivacyPolicyPresented = true
                }) {
                    Text("Ознакомиться с политикой конфиденциальности")
                        .font(.yarBodyXSRegular)
                        .foregroundColor(.yarSubject40)
                        .multilineTextAlignment(.center)
                        .underline()
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $isPrivacyPolicyPresented) {
            PrivacyPolicyView()
        }
    }

    // MARK: - Logo Section

    @ViewBuilder
    private var logoSection: some View {
        VStack(spacing: 16) {
            if let _ = UIImage(named: "logo") {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 80)
            } else {
                SanitizedVectorEmblem(size: 96)
            }

            VStack(spacing: 4) {
                Text("ЯР")
                    .font(.yarHeadline1)
                    .foregroundColor(.yarSubject00)
                    .tracking(6.0)

                Text("МИНСК")
                    .font(.yarBodySMedium)
                    .foregroundColor(.yarSubject30)
                    .tracking(8.0)
            }
        }
    }

    // MARK: - Handlers

    private func handleSignInTap() {
        if let onSignIn {
            onSignIn()
        } else {
            router.navigate(to: .signIn)
        }
    }

    private func handleSignUpTap() {
        if let onSignUp {
            onSignUp()
        } else {
            router.navigate(to: .signUp)
        }
    }
}

// MARK: - Sanitized Vector Emblem

/// Clean vector emblem providing an elegant emblem for the Yar brand.
public struct SanitizedVectorEmblem: View {
    public let size: CGFloat

    public init(size: CGFloat = 80) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Background circular badge with subtle border
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.yarSubject90, Color.yarSubject100],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.yarSubject40.opacity(0.6), Color.yarSubject80.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            // Stylized Red Accent on top
            VStack(spacing: 4) {
                RubyAccentShape()
                    .fill(Color(red: 237/255, green: 28/255, blue: 36/255))
                    .frame(width: size * 0.14, height: size * 0.18)

                // Lettermark monogram
                Text("ЯР")
                    .font(.oswald(.bold, size: size * 0.36))
                    .foregroundColor(.yarSubject00)
                    .tracking(1.0)
            }
        }
    }
}

private struct RubyAccentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        let left = CGPoint(x: rect.minX, y: rect.midY)
        let right = CGPoint(x: rect.maxX, y: rect.midY)

        path.move(to: top)
        path.addQuadCurve(to: right, control: CGPoint(x: rect.maxX, y: rect.minY * 0.5 + rect.midY * 0.5))
        path.addQuadCurve(to: bottom, control: CGPoint(x: rect.maxX * 0.9, y: rect.maxY * 0.9))
        path.addQuadCurve(to: left, control: CGPoint(x: rect.minX * 0.9, y: rect.maxY * 0.9))
        path.addQuadCurve(to: top, control: CGPoint(x: rect.minX, y: rect.minY * 0.5 + rect.midY * 0.5))
        path.closeSubpath()
        return path
    }
}

// MARK: - Privacy Policy Modal Sheet

public struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.yarSubject95
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        policySection(
                            title: "1. ОБЩИЕ ПОЛОЖЕНИЯ",
                            content: "Настоящая Политика конфиденциальности определяет порядок обработки и защиты информации о физических лицах, использующих мобильное приложение «ЯР МИНСК»."
                        )

                        policySection(
                            title: "2. СОБИРАЕМЫЕ ДАННЫЕ",
                            content: "Мы обрабатываем адрес электронной почты, фамилию, имя и контактный телефон пользователя исключительно для идентификации в программе лояльности, предоставления персональных скидок и начисления бонусов."
                        )

                        policySection(
                            title: "3. БЕЗОПАСНОСТЬ ДАННЫХ",
                            content: "Безопасность персональных данных обеспечивается использованием защищенных протоколов передачи информации, системного хранилища iOS Keychain и сертифицированной облачной инфраструктуры."
                        )

                        policySection(
                            title: "4. ПРАВА ПОЛЬЗОВАТЕЛЯ",
                            content: "Пользователь имеет право в любой момент запросить информацию о своих персональных данных, их обновление или полное удаление своего аккаунта."
                        )

                        policySection(
                            title: "5. КОНТАКТНАЯ ИНФОРМАЦИЯ",
                            content: "По всем вопросам обработки данных вы можете связаться со службой поддержки по электронной почте: info@yarminsk.by."
                        )

                        Button(action: {
                            if let url = URL(string: "https://yarminsk.by/privacy") {
                                openURL(url)
                            }
                        }) {
                            HStack {
                                Text("ОТКРЫТЬ ПОЛНУЮ ВЕРСИЮ НА САЙТЕ")
                                    .font(.yarBodySBold)
                                    .foregroundColor(.yarSubject00)
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.yarSubject00)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(LinearGradient.yarPrimaryGradient)
                            .cornerRadius(12)
                        }
                        .padding(.top, 12)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("ПОЛИТИКА")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.yarSubject00)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.yarBodySMedium)
                .foregroundColor(.yarSecondary)
                .tracking(0.8)

            Text(content)
                .font(.yarBodySRegular)
                .foregroundColor(.yarSubject20)
                .lineSpacing(4)
        }
    }
}

// MARK: - Previews

#Preview("EntryView Default") {
    EntryView()
        .environmentObject(AppRouter())
}

#Preview("Privacy Policy Sheet") {
    PrivacyPolicyView()
}
