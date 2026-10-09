# Yar Minsk iOS

Нативное приложение для гостей «Яр Минск»: меню, контакты, Яндекс Карты и электронная карта лояльности с QR-кодом. Приложение открывается на гостевой главной; вход нужен только во вкладке «Моя карта».

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
- `Sources/Features/Guest/` — Гостевая главная, каталог с поиском и категориями, контакты и карта.
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

## Авторизация и подпись

Firebase использует конфигурацию `Resources/GoogleService-Info.plist` для приложения `by.yarminsk.app`. В Firebase Authentication должны быть включены Email/Password, Google и Apple.

Google-вход открывает интерфейс Google Sign-In; обратный URL обрабатывается в `YarMinskApp`. Apple-вход использует AuthenticationServices, случайный nonce и его SHA-256. Capability Sign in with Apple задана в `Configuration/YarMinsk.entitlements`.

В проекте включена автоматическая подпись для команды `2W876M34X7`. Для запуска на устройстве добавьте аккаунт этой команды в Xcode → Settings → Apple Accounts. Приложение зарегистрировано в Apple Developer с bundle ID `by.yarminsk.app` и Sign in with Apple.

Не отключайте `CODE_SIGNING_ALLOWED`: Firebase Auth сохраняет сессию в Keychain, а неподписанная сборка может получать ошибку `SecItemCopyMatching (-34018)` даже на симуляторе. Восстановление сессии основано на текущем пользователе Firebase; старый сохранённый UID не используется как подтверждение входа.

Обычные тесты:
```bash
xcodebuild -project YarMinsk.xcodeproj -scheme YarMinsk \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

Проверка настоящего Firebase запускается отдельно. Она создаёт один временный аккаунт, проверяет регистрацию, вход, неверный пароль, восстановление сессии чтение отсутствующей карты, создание собственной временной карты и её удаление через экранную модель приложения. Отсутствие карты подтверждается чтением сервера до удаления Auth, после чего повторный вход должен завершиться отказом. Тест очищает только свой временный аккаунт:
```bash
xcodebuild -project YarMinsk.xcodeproj -scheme YarMinskLiveAuth \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:YarMinskTests/FirebaseLiveAuthTests test
```

## Меню, политика и удаление аккаунта

`Resources/Content/menu.json` — локальный снимок меню от 8 октября 2026 из https://yarkalyan.by/ru_menu_qr. Импортированы кухня, десерты, снэки, кофе, чай и безалкогольные напитки. Алкоголь, табачные позиции, рекламные акции и внешняя навигация сайта не включены. При изменении цен обновляйте локальный JSON.

`Resources/Content/privacy-policy.json` — полный текст десяти разделов политики из https://yarkalyan.by/appprivacy, включая название оператора и контакты. Исходный текст на английском; шапка и футер сайта не импортируются. Политика доступна без интернета с главной, из контактов, анкеты и меню аккаунта. Импорт не изменяет исходный юридический текст. Перед ним отображается `Resources/Content/app-privacy.json` с фактическими данными мобильного аккаунта и карты, Firebase, Яндекс Карт и удалением аккаунта. Публичная страница политики пока содержит только исходную политику сайта.

Удаление находится в меню карты лояльности. После подтверждения и повторной аутентификации приложение удаляет `/discount/{uid}` с ожиданием ответа сервера, отзывает авторизацию Apple для связанных Apple-аккаунтов и удаляет пользователя Firebase Auth. Если сервер не разрешает очистку карты, пользователь Auth сохраняется. Если финальное удаление не завершилось, приложение явно сообщает об этом и позволяет повторить операцию. Удаление между Auth и RTDB не является одной транзакцией. Правила RTDB должны разрешать пользователю удаление только собственной записи.

## Проверка контента
Меню и интерфейс проверяются на табачную терминологию. Оригинальная политика исключена из словарного сканера, чтобы сохранить имя оператора и контакты без подмены. Запуск проверки:
```bash
./scripts/verify_clean_code.sh
```

## Материалы App Store

Новая карточка Apple: `6821147058` («Яр Минск»), bundle ID `by.yarminsk.app`, версия `1.0`, сборка `1`. Конфигурация Firebase взята из существующего приложения с этим Bundle ID в том же проекте; новый Firebase-проект не создавался.

10 октября 2026 года сборка 1.0 (1) загружена, обработана и отправлена на App Review. Подтверждён статус `Waiting for Review`; включён автоматический выпуск после одобрения. Бесплатная версия распространяется в прежних 18 регионах, включая Беларусь.

Старая карточка YARMINSK (`6752119729`, `com.yarkalyan.yarhookah`) снята со всех регионов и перемещена в `Removed Apps`. Новый релиз использует отдельную карточку «Яр Минск».

Иконка 1024×1024 создана из фирменного SVG на непрозрачном зелёном фоне. Воспроизведение: `swift scripts/generate_app_icon.swift`. Скриншоты настоящей сборки для iPhone 6.3, iPhone Pro Max и iPad 13 находятся в `AppStore/Screenshots`. Описание и заметки проверяющему — в `AppStore/Metadata`. Архив без подписи пригоден только для проверки компиляции; для загрузки нужен подписанный архив и аккаунт команды в Xcode.

Поддержка приложения: https://yarminsk-app-support.web.app/. Политика для карточки App Store: https://yarminsk-app-support.web.app/privacy.html. Исходники публичных страниц — `AppStore/Support/public`, отдельный сайт Firebase Hosting — `yarminsk-app-support` в существующем проекте. Обновление: из `AppStore/Support` выполнить `firebase deploy --only hosting --project yarkalyan-6bbef --config firebase.json`. При изменении встроенной политики обновляйте и публичную страницу. Прежний сайт Firebase Hosting приложения не изменяется.

Для следующей загрузки увеличьте номер сборки и запустите `./scripts/upload_app_store.sh`: он собирает подписанный архив и загружает его в App Store Connect. Загрузка не отправляет версию на App Review: после обработки нужно выбрать новую сборку и отправить подготовленную версию. Настройки экспорта находятся в `Configuration/AppStoreExport.plist`; номер сборки не меняется автоматически. Последнее подтверждённое состояние публикации — `AppStore/Metadata/release-status.json`.
