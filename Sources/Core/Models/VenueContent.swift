import Foundation

public enum VenueDetails {
    public static let address = "Минск, ул. Володарского, 18"
    public static let phone = "+375 29 145-55-31"
    public static let phoneURL = URL(string: "tel:+375291455531")!
    // Building coordinates verified against the address in Yandex Maps.
    public static let mapURL = URL(string: "https://yandex.ru/map-widget/v1/?ll=27.552560%2C53.896262&pt=27.552560%2C53.896262%2Cpm2gnm&z=17&l=map&lang=ru_RU")!
    public static let routeURL = URL(string: "https://yandex.ru/maps/?rtext=~53.896262%2C27.552560&rtt=pd&z=17")!
    public static let mapTermsURL = URL(string: "https://yandex.ru/legal/maps_termsofuse/")!
    public static let mapReferer = "http://6821147058.ymapapp"
}

public struct VenueMenu: Decodable {
    public let updatedAt: String
    public let categories: [MenuCategory]

    public static func load() throws -> VenueMenu { try BundledContent.load("menu") }

    public func filtered(query: String, categoryID: String?) -> [MenuCategory] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return categories.compactMap { category in
            guard categoryID == nil || category.id == categoryID else { return nil }
            let items = category.items.filter {
                query.isEmpty || $0.name.localizedStandardContains(query)
                    || $0.description.localizedStandardContains(query)
                    || category.title.localizedStandardContains(query)
            }
            guard !items.isEmpty else { return nil }
            return MenuCategory(id: category.id, title: category.title, note: category.note, items: items)
        }
    }
}

public struct MenuCategory: Decodable, Identifiable {
    public let id: String
    public let title: String
    public let note: String?
    public let items: [MenuItem]
}

public struct MenuItem: Decodable, Identifiable {
    public let id: String
    public let name: String
    public let price: Double
    public let portion: String
    public let description: String

    public var formattedPrice: String {
        price.formatted(.number.precision(.fractionLength(0...2))) + " BYN"
    }
}

public struct VenuePrivacyPolicy: Decodable {
    public let title: String
    public let effectiveDate: String
    public let sections: [PolicySection]
    public static func load() throws -> VenuePrivacyPolicy { try BundledContent.load("privacy-policy") }
    public static func loadAppDisclosure() throws -> VenuePrivacyPolicy { try BundledContent.load("app-privacy") }
}

public struct PolicySection: Decodable {
    public let title: String
    public let text: String
}

private enum BundledContent {
    static func load<T: Decodable>(_ name: String) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
}
