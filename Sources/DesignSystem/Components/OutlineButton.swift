import SwiftUI

public enum OutlineButtonBorderColor {
    case white
    case primary
    case custom(Color)

    public var color: Color {
        switch self {
        case .white:
            return .yarSubject00
        case .primary:
            return .yarSecondary
        case .custom(let color):
            return color
        }
    }
}

public struct OutlineButton: View {
    public let title: String
    public let icon: Image?
    public let borderColor: Color
    public let isFullWidth: Bool
    public let cornerRadius: CGFloat
    public let isPill: Bool
    public let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ title: String,
        icon: Image? = nil,
        borderColor: OutlineButtonBorderColor = .white,
        isFullWidth: Bool = true,
        cornerRadius: CGFloat = 16,
        isPill: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.borderColor = borderColor.color
        self.isFullWidth = isFullWidth
        self.cornerRadius = cornerRadius
        self.isPill = isPill
        self.action = action
    }

    public init(
        _ title: String,
        icon: Image? = nil,
        color: Color,
        isFullWidth: Bool = true,
        cornerRadius: CGFloat = 16,
        isPill: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.borderColor = color
        self.isFullWidth = isFullWidth
        self.cornerRadius = cornerRadius
        self.isPill = isPill
        self.action = action
    }

    public init(
        _ title: String,
        systemIcon: String,
        borderColor: OutlineButtonBorderColor = .white,
        isFullWidth: Bool = true,
        cornerRadius: CGFloat = 16,
        isPill: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = Image(systemName: systemIcon)
        self.borderColor = borderColor.color
        self.isFullWidth = isFullWidth
        self.cornerRadius = cornerRadius
        self.isPill = isPill
        self.action = action
    }

    private var effectiveRadius: CGFloat {
        isPill ? 27 : cornerRadius
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    icon
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(borderColor)
                }

                Text(title.uppercased())
                    .font(.yarBodySBold)
                    .foregroundColor(borderColor)
                    .tracking(1.0)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: 54)
            .padding(.horizontal, isFullWidth ? 16 : 28)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: effectiveRadius)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
            .cornerRadius(effectiveRadius)
            .opacity(isEnabled ? 1.0 : 0.45)
        }
        .disabled(!isEnabled)
        .buttonStyle(OutlinePressableButtonStyle())
    }
}

private struct OutlinePressableButtonStyle: ButtonStyle {
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
            OutlineButton("Войти") {}
            OutlineButton("Зарегистрироваться", borderColor: .primary) {}
            OutlineButton("С иконкой", systemIcon: "arrow.right", isPill: true) {}
            OutlineButton("Неактивно") {}
                .disabled(true)
        }
        .padding()
    }
}
