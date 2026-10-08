import SwiftUI

public extension Color {
    // Basic Subject Colors
    static let yarSubject00 = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let yarSubject02 = Color(red: 250/255, green: 250/255, blue: 250/255)
    static let yarSubject05 = Color(red: 240/255, green: 242/255, blue: 242/255)
    static let yarSubject10 = Color(red: 230/255, green: 230/255, blue: 230/255)
    static let yarSubject20 = Color(red: 200/255, green: 204/255, blue: 204/255)
    static let yarSubject30 = Color(red: 171/255, green: 171/255, blue: 171/255)
    static let yarSubject40 = Color(red: 150/255, green: 153/255, blue: 153/255)
    static let yarSubject50 = Color(red: 135/255, green: 135/255, blue: 135/255)
    static let yarSubject60 = Color(red: 102/255, green: 102/255, blue: 102/255)
    static let yarSubject80 = Color(red: 46/255, green: 51/255, blue: 50/255)
    static let yarSubject90 = Color(red: 20/255, green: 26/255, blue: 25/255)
    static let yarSubject95 = Color(red: 16/255, green: 16/255, blue: 16/255)
    static let yarSubject100 = Color(red: 0.0, green: 0.0, blue: 0.0)

    // Brand accent colors
    static let yarSecondary = Color(red: 49/255, green: 127/255, blue: 83/255)
    static let yarError = Color(red: 216/255, green: 26/255, blue: 26/255)
    static let yarSuccess = Color(red: 5/255, green: 232/255, blue: 118/255)
    static let yarWarning = Color(red: 248/255, green: 223/255, blue: 0/255)
}

public extension LinearGradient {
    static let yarPrimaryGradient = LinearGradient(
        colors: [Color(red: 49/255, green: 127/255, blue: 83/255), Color(red: 51/255, green: 121/255, blue: 43/255)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let yarCardBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 26/255, green: 26/255, blue: 26/255),
            Color(red: 43/255, green: 43/255, blue: 43/255),
            Color(red: 58/255, green: 58/255, blue: 58/255)
        ],
        startPoint: .topTrailing,
        endPoint: .center
    )

    static let yarSilverGradient = LinearGradient(
        colors: [
            Color(red: 207/255, green: 216/255, blue: 220/255),
            Color(red: 176/255, green: 190/255, blue: 197/255),
            Color(red: 236/255, green: 239/255, blue: 241/255)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let yarGoldGradient = LinearGradient(
        colors: [
            Color(red: 255/255, green: 215/255, blue: 0/255),
            Color(red: 255/255, green: 165/255, blue: 0/255),
            Color(red: 255/255, green: 236/255, blue: 139/255)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let yarPlatinumGradient = LinearGradient(
        colors: [
            Color(red: 240/255, green: 248/255, blue: 255/255),
            Color(red: 217/255, green: 228/255, blue: 236/255),
            Color(red: 176/255, green: 196/255, blue: 222/255),
            Color(red: 220/255, green: 220/255, blue: 220/255)
        ],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )
}
