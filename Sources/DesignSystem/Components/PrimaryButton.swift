import SwiftUI

public struct PrimaryButton: View {
    public let title: String
    public let isFullWidth: Bool
    public let cornerRadius: CGFloat
    public let isPill: Bool
    public let isLoading: Bool
    public let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ title: String,
        isFullWidth: Bool = true,
        cornerRadius: CGFloat = 16,
        isPill: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isFullWidth = isFullWidth
        self.cornerRadius = cornerRadius
        self.isPill = isPill
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .yarSubject00))
                        .scaleEffect(0.9)
                }

                Text(title.uppercased())
                    .font(.yarBodySBold)
                    .foregroundColor(.yarSubject00)
                    .tracking(1.0)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: 54)
            .padding(.horizontal, isFullWidth ? 16 : 28)
            .background(LinearGradient.yarPrimaryGradient)
            .cornerRadius(isPill ? 27 : cornerRadius)
            .opacity(isEnabled && !isLoading ? 1.0 : 0.45)
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PrimaryButtonStyle())
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color.yarSubject95.ignoresSafeArea()
        VStack(spacing: 16) {
            PrimaryButton("Войти") {}
            PrimaryButton("Зарегистрироваться", isPill: true) {}
            PrimaryButton("Загрузка...", isLoading: true) {}
            PrimaryButton("Неактивно") {}
                .disabled(true)
        }
        .padding()
    }
}
