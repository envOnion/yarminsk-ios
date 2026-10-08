import Foundation

public enum ValidationRules {
    private static let emailRegex = try? NSRegularExpression(
        pattern: #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#,
        options: .caseInsensitive
    )

    private static let belPhoneRegex = try? NSRegularExpression(pattern: #"^\d{9}$"#)
    private static let rusPhoneRegex = try? NSRegularExpression(pattern: #"^\d{10}$"#)

    public static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let regex = emailRegex else { return !trimmed.isEmpty }
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        return regex.firstMatch(in: trimmed, options: [], range: range) != nil
    }

    public static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }

    public static func isValidBelarusPhone(_ phoneDigits: String) -> Bool {
        guard let regex = belPhoneRegex else { return phoneDigits.count == 9 }
        let range = NSRange(location: 0, length: phoneDigits.utf16.count)
        return regex.firstMatch(in: phoneDigits, options: [], range: range) != nil
    }

    public static func isValidRussiaPhone(_ phoneDigits: String) -> Bool {
        guard let regex = rusPhoneRegex else { return phoneDigits.count == 10 }
        let range = NSRange(location: 0, length: phoneDigits.utf16.count)
        return regex.firstMatch(in: phoneDigits, options: [], range: range) != nil
    }
}
