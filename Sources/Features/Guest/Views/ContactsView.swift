import SwiftUI
import WebKit

public struct ContactsView: View {
    @Environment(\.openURL) private var openURL
    @State private var showPrivacy = false
    @State private var mapFailed = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ЖДЁМ В ГОСТИ").font(.yarHeadline3)
                        Text(VenueDetails.address).font(.yarBodyMRegular).textSelection(.enabled)
                    }

                    VStack(spacing: 0) {
                        YandexMapView(failed: $mapFailed)
                            .frame(height: 280)
                        if mapFailed {
                            Text("Для загрузки карты нужен интернет. Адрес и телефон доступны ниже.")
                                .font(.yarBodyXSRegular).foregroundColor(.yarSubject40).padding(16)
                        }
                    }
                    .background(Color.yarSubject90).cornerRadius(20)
                    .accessibilityLabel("Яндекс Карты: \(VenueDetails.address)")

                    PrimaryButton("МАРШРУТ В ЯНДЕКС КАРТАХ") { openURL(VenueDetails.routeURL) }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("ХОСТЕС").font(.yarBodySBold).foregroundColor(.yarSubject40)
                        Text("Свяжитесь с нами, чтобы забронировать столик или уточнить детали.")
                            .font(.yarBodySRegular)
                        Button { openURL(VenueDetails.phoneURL) } label: {
                            Label(VenueDetails.phone, systemImage: "phone.fill")
                                .font(.yarBodyMBold).foregroundColor(.white)
                        }
                        .padding(.top, 4)
                        .accessibilityIdentifier("contacts.callHostess")
                    }
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yarSubject90).cornerRadius(20)

                    Button("Политика конфиденциальности") { showPrivacy = true }
                        .font(.yarBodyXSRegular).foregroundColor(.yarSubject40)
                    Link("Условия использования сервиса Яндекс.Карты", destination: VenueDetails.mapTermsURL)
                        .font(.yarBodyXSRegular).foregroundColor(.yarSubject40)
                }
                .padding(20)
            }
            .background(Color.yarSubject95)
            .navigationTitle("КОНТАКТЫ")
            .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
        }
    }
}

private struct YandexMapView: UIViewRepresentable {
    @Binding var failed: Bool

    func makeCoordinator() -> Coordinator { Coordinator(failed: $failed) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.isOpaque = false
        view.backgroundColor = UIColor(Color.yarSubject90)
        view.navigationDelegate = context.coordinator
        var request = URLRequest(url: VenueDetails.mapURL)
        request.setValue(VenueDetails.mapReferer, forHTTPHeaderField: "Referer")
        view.load(request)
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        private var failed: Binding<Bool>
        init(failed: Binding<Bool>) { self.failed = failed }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { failed.wrappedValue = false }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            failed.wrappedValue = true
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            failed.wrappedValue = true
        }
    }
}
