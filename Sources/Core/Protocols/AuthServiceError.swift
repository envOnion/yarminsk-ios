import Foundation

public enum AuthServiceError: LocalizedError, Sendable {
    case invalidCredentials
    case userNotFound
    case userAlreadyExists
    case notAuthenticated
    case invalidInput(String)
    case underlying(String)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Неверный email или пароль"
        case .userNotFound:
            return "Пользователь не найден"
        case .userAlreadyExists:
            return "Пользователь с таким email уже существует"
        case .notAuthenticated:
            return "Пользователь не авторизован"
        case .invalidInput(let message):
            return message
        case .underlying(let message):
            return message
        }
    }
}
