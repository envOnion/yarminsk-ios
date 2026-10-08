# Yar Minsk iOS

Нативное приложение для гостей клубного пространства «Яр Минск» (электронная карта лояльности, динамический QR-код и личный кабинет).

## Стек технологий
- **Язык**: Swift 6
- **UI**: SwiftUI (iOS 16.0+)
- **Архитектура**: Clean Architecture + MVVM
- **Аутентификация**: Firebase Auth (Email/Пароль, Sign in with Apple, Google Sign In)
- **База данных**: Firebase Realtime Database
- **Генератор проекта**: XcodeGen (`project.yml`)
- **Безопасное хранилище**: iOS Keychain

## Структура проекта
- `Sources/DesignSystem/` — Токены цветов, Oswald-типографика, переиспользуемые UI-компоненты.
- `Sources/Core/` — Доменные сущности (`UserProfile`, `DiscountCard`, `DiscountTier`), правила валидации, протоколы сервисов, Keychain-хранилище.
- `Sources/Services/` — Сервисы Firebase (`FirebaseAuthService`, `FirebaseDiscountService`) и мок-сервисы (`MockAuthService`, `MockDiscountService`).
- `Sources/Features/Auth/` — Экран приветствия, авторизации и регистрации.
- `Sources/Features/Loyalty/` — Анкета гостя, экран карты лояльности со статусами (Silver/Gold/Platinum), шторка меню.
- `Sources/App/` — Точка входа `@main`, DI-контейнер и роутер.
- `Resources/` — Шрифты Oswald, иконки, векторный логотип, `GoogleService-Info.plist`.

## Сборка и запуск
1. Установите XcodeGen (если проект еще не сгенерирован):
   ```bash
   brew install xcodegen
   ```
2. Сгенерируйте Xcode-проект:
   ```bash
   xcodegen generate
   ```
3. Откройте `YarMinsk.xcodeproj` в Xcode и запустите на симуляторе или устройстве.

## Проверка чистоты контента (App Store Compliance)
В проекте действует строгая политика отсутствия табачной терминологии. Запуск проверки:
```bash
./scripts/verify_clean_code.sh
```
