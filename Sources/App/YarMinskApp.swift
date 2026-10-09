import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct YarMinskApp: App {
    @StateObject private var container: AppContainer
    @StateObject private var router = AppRouter()

    init() {
        var isFirebaseAvailable = false

        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           FileManager.default.fileExists(atPath: path) {
            FirebaseApp.configure()
            isFirebaseAvailable = true
        }

        let sessionStorage = KeychainSessionStorage()

        let authService: AuthServiceProtocol
        let discountService: DiscountServiceProtocol

        if isFirebaseAvailable {
            authService = FirebaseAuthService()
            discountService = FirebaseDiscountService()
        } else {
            authService = MockAuthService()
            discountService = MockDiscountService()
        }

        _container = StateObject(wrappedValue: AppContainer(
            authService: authService,
            discountService: discountService,
            sessionStorage: sessionStorage
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .environmentObject(container)
                .environmentObject(router)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
