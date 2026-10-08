import SwiftUI

public struct YarAlertView: View {
    public let title: String
    public let message: String?
    public let confirmTitle: String
    public let cancelTitle: String
    public let isDestructive: Bool
    public let onConfirm: () -> Void
    public let onCancel: () -> Void

    public init(
        title: String = "ВЫ ДЕЙСТВИТЕЛЬНО ХОТИТЕ ВЫЙТИ?",
        message: String? = nil,
        confirmTitle: String = "ВЫЙТИ",
        cancelTitle: String = "ОСТАТЬСЯ",
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.isDestructive = isDestructive
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        ZStack {
            // Darkened backdrop
            Color.yarSubject100.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }

            // Dialog Card
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text(title.uppercased())
                        .font(.yarHeadline4)
                        .foregroundColor(.yarSubject00)
                        .multilineTextAlignment(.center)
                        .tracking(0.5)

                    if let message, !message.isEmpty {
                        Text(message)
                            .font(.yarBodySRegular)
                            .foregroundColor(.yarSubject40)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 4)

                // Action buttons
                VStack(spacing: 12) {
                    OutlineButton(
                        cancelTitle,
                        borderColor: .white,
                        isFullWidth: true
                    ) {
                        onCancel()
                    }

                    if isDestructive {
                        OutlineButton(
                            confirmTitle,
                            color: .yarError,
                            isFullWidth: true
                        ) {
                            onConfirm()
                        }
                    } else {
                        PrimaryButton(
                            confirmTitle,
                            isFullWidth: true
                        ) {
                            onConfirm()
                        }
                    }
                }
            }
            .padding(24)
            .background(Color.yarSubject90)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.yarSubject80, lineWidth: 1)
            )
            .padding(.horizontal, 32)
            .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 12)
        }
    }
}

public extension View {
    func yarAlert(
        isPresented: Binding<Bool>,
        title: String = "ВЫ ДЕЙСТВИТЕЛЬНО ХОТИТЕ ВЫЙТИ?",
        message: String? = nil,
        confirmTitle: String = "ВЫЙТИ",
        cancelTitle: String = "ОСТАТЬСЯ",
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void
    ) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue {
                YarAlertView(
                    title: title,
                    message: message,
                    confirmTitle: confirmTitle,
                    cancelTitle: cancelTitle,
                    isDestructive: isDestructive,
                    onConfirm: {
                        isPresented.wrappedValue = false
                        onConfirm()
                    },
                    onCancel: {
                        isPresented.wrappedValue = false
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented.wrappedValue)
    }
}

#Preview {
    ZStack {
        Color.yarSubject95.ignoresSafeArea()
        YarAlertView(
            title: "Вы действительно хотите выйти?",
            message: "Вам потребуется снова войти для доступа к карте лояльности",
            confirmTitle: "Выйти",
            cancelTitle: "Остаться",
            onConfirm: {},
            onCancel: {}
        )
    }
}
