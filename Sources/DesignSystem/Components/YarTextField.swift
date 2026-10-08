import SwiftUI

public struct YarTextField: View {
    public let placeholder: String
    public let title: String?
    @Binding public var text: String
    public let isSecure: Bool
    public let errorMessage: String?
    public let keyboardType: UIKeyboardType
    public let textContentType: UITextContentType?
    public let autocapitalization: TextInputAutocapitalization
    public let autocorrectionDisabled: Bool

    @State private var isPasswordVisible: Bool = false
    @FocusState private var isFocused: Bool

    public init(
        placeholder: String,
        title: String? = nil,
        text: Binding<String>,
        isSecure: Bool = false,
        errorMessage: String? = nil,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .never,
        autocorrectionDisabled: Bool = true
    ) {
        self.placeholder = placeholder
        self.title = title
        self._text = text
        self.isSecure = isSecure
        self.errorMessage = errorMessage
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.autocorrectionDisabled = autocorrectionDisabled
    }

    private var hasError: Bool {
        guard let errorMessage else { return false }
        return !errorMessage.isEmpty
    }

    private var underlineColor: Color {
        if hasError {
            return .yarError
        } else if isFocused {
            return .yarSecondary
        } else {
            return .yarSubject80
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title, !title.isEmpty {
                Text(title.uppercased())
                    .font(.yarBodyXSMedium)
                    .foregroundColor(hasError ? .yarError : .yarSubject40)
                    .tracking(0.8)
            }

            HStack(spacing: 8) {
                inputFieldView

                if isSecure {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.yarSubject40)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)

            // Underline border
            Rectangle()
                .fill(underlineColor)
                .frame(height: isFocused || hasError ? 2 : 1)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
                .animation(.easeInOut(duration: 0.2), value: hasError)

            // Validation error message
            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.yarBodyXSRegular)
                    .foregroundColor(.yarError)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private var inputFieldView: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder.uppercased())
                    .font(.yarBodySRegular)
                    .foregroundColor(.yarSubject50)
                    .tracking(0.6)
            }

            if isSecure && !isPasswordVisible {
                SecureField("", text: $text)
                    .focused($isFocused)
                    .font(.yarBodySRegular)
                    .foregroundColor(.yarSubject00)
                    .tint(.yarSecondary)
                    .textContentType(textContentType)
            } else {
                TextField("", text: $text)
                    .focused($isFocused)
                    .font(.yarBodySRegular)
                    .foregroundColor(.yarSubject00)
                    .tint(.yarSecondary)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(autocorrectionDisabled)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.yarSubject95.ignoresSafeArea()
        VStack(spacing: 24) {
            YarTextField(
                placeholder: "Email",
                title: "Электронная почта",
                text: .constant("test@example.com")
            )
            YarTextField(
                placeholder: "Пароль",
                title: "Пароль",
                text: .constant("123456"),
                isSecure: true
            )
            YarTextField(
                placeholder: "Пароль с ошибкой",
                text: .constant("123"),
                isSecure: true,
                errorMessage: "Минимум 6 символов"
            )
        }
        .padding()
    }
}
