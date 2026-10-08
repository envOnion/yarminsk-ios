import SwiftUI

public enum CountryPhoneCode: String, CaseIterable, Identifiable, Sendable {
    case belarus = "+375"
    case russia = "+7"

    public var id: String { rawValue }

    public var dialCode: String { rawValue }

    public var flag: String {
        switch self {
        case .belarus: return "🇧🇾"
        case .russia: return "🇷🇺"
        }
    }

    public var countryName: String {
        switch self {
        case .belarus: return "Беларусь"
        case .russia: return "Россия"
        }
    }

    public var maxDigits: Int {
        switch self {
        case .belarus: return 9
        case .russia: return 10
        }
    }

    public var placeholderMask: String {
        switch self {
        case .belarus: return "XX XXX-XX-XX"
        case .russia: return "XXX XXX-XX-XX"
        }
    }
}

public struct PhoneInputField: View {
    public let title: String?
    public let errorMessage: String?
    @Binding public var phone: String
    @Binding public var isValid: Bool

    @State private var selectedCountry: CountryPhoneCode = .belarus
    @State private var formattedInput: String = ""
    @State private var rawDigits: String = ""
    @FocusState private var isFocused: Bool

    public init(
        title: String? = "НОМЕР ТЕЛЕФОНА",
        errorMessage: String? = nil,
        phone: Binding<String>,
        isValid: Binding<Bool> = .constant(false)
    ) {
        self.title = title
        self.errorMessage = errorMessage
        self._phone = phone
        self._isValid = isValid
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
                // Country Code Picker Menu
                countryPickerMenu

                // Phone Number Digits Input Field
                ZStack(alignment: .leading) {
                    if formattedInput.isEmpty {
                        Text(selectedCountry.placeholderMask)
                            .font(.yarBodySRegular)
                            .foregroundColor(.yarSubject50)
                            .tracking(0.6)
                    }

                    TextField("", text: Binding(
                        get: { formattedInput },
                        set: { handleInputChanged($0) }
                    ))
                    .focused($isFocused)
                    .font(.yarBodySRegular)
                    .foregroundColor(.yarSubject00)
                    .tint(.yarSecondary)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                }
            }
            .padding(.vertical, 8)

            // Underline border
            Rectangle()
                .fill(underlineColor)
                .frame(height: isFocused || hasError ? 2 : 1)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
                .animation(.easeInOut(duration: 0.2), value: hasError)

            // Error display
            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.yarBodyXSRegular)
                    .foregroundColor(.yarError)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            parseInitialPhone()
        }
    }

    private var countryPickerMenu: some View {
        Menu {
            ForEach(CountryPhoneCode.allCases) { country in
                Button(action: {
                    selectCountry(country)
                }) {
                    Text("\(country.flag) \(country.countryName) (\(country.dialCode))")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedCountry.flag)
                    .font(.system(size: 20))
                Text(selectedCountry.dialCode)
                    .font(.yarBodySRegular)
                    .foregroundColor(.yarSubject00)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.yarSubject40)
            }
            .padding(.trailing, 6)
        }
    }

    private func selectCountry(_ country: CountryPhoneCode) {
        selectedCountry = country
        // Re-process current digits under the new country rules
        processDigits(rawDigits)
    }

    private func handleInputChanged(_ newValue: String) {
        var digits = newValue.filter { $0.isNumber }

        // Check if pasted number includes full prefix
        if digits.hasPrefix("375") && digits.count > 3 {
            selectedCountry = .belarus
            digits = String(digits.dropFirst(3))
        } else if digits.hasPrefix("7") && digits.count > 1 {
            selectedCountry = .russia
            digits = String(digits.dropFirst(1))
        } else if digits.hasPrefix("8") && digits.count == 11 {
            selectedCountry = .russia
            digits = String(digits.dropFirst(1))
        }

        processDigits(digits)
    }

    private func processDigits(_ digits: String) {
        let maxLen = selectedCountry.maxDigits
        let truncated = String(digits.prefix(maxLen))
        rawDigits = truncated

        switch selectedCountry {
        case .belarus:
            formattedInput = Self.formatBelarusNumber(truncated)
            isValid = ValidationRules.isValidBelarusPhone(truncated)
        case .russia:
            formattedInput = Self.formatRussiaNumber(truncated)
            isValid = ValidationRules.isValidRussiaPhone(truncated)
        }

        if truncated.isEmpty {
            phone = ""
        } else {
            phone = "\(selectedCountry.dialCode)\(truncated)"
        }
    }

    private func parseInitialPhone() {
        guard !phone.isEmpty else { return }

        var digits = phone.filter { $0.isNumber }
        if phone.hasPrefix("+375") || digits.hasPrefix("375") {
            selectedCountry = .belarus
            if digits.hasPrefix("375") {
                digits = String(digits.dropFirst(3))
            }
        } else if phone.hasPrefix("+7") || digits.hasPrefix("7") {
            selectedCountry = .russia
            if digits.hasPrefix("7") {
                digits = String(digits.dropFirst(1))
            }
        }
        processDigits(digits)
    }

    public static func formatBelarusNumber(_ rawDigits: String) -> String {
        let digits = String(rawDigits.filter { $0.isNumber }.prefix(9))
        var result = ""
        for (index, char) in digits.enumerated() {
            if index == 2 {
                result.append(" ")
            } else if index == 5 || index == 7 {
                result.append("-")
            }
            result.append(char)
        }
        return result
    }

    public static func formatRussiaNumber(_ rawDigits: String) -> String {
        let digits = String(rawDigits.filter { $0.isNumber }.prefix(10))
        var result = ""
        for (index, char) in digits.enumerated() {
            if index == 3 {
                result.append(" ")
            } else if index == 6 || index == 8 {
                result.append("-")
            }
            result.append(char)
        }
        return result
    }
}

#Preview {
    ZStack {
        Color.yarSubject95.ignoresSafeArea()
        VStack(spacing: 24) {
            PhoneInputField(
                phone: .constant("+375291234567"),
                isValid: .constant(true)
            )
            PhoneInputField(
                phone: .constant(""),
                isValid: .constant(false)
            )
        }
        .padding()
    }
}
