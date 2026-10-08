import SwiftUI

public extension Font {
    enum OswaldWeight: String {
        case extraLight = "Oswald-ExtraLight"
        case light = "Oswald-Light"
        case regular = "Oswald-Regular"
        case medium = "Oswald-Medium"
        case semiBold = "Oswald-SemiBold"
        case bold = "Oswald-Bold"
    }

    static func oswald(_ weight: OswaldWeight = .regular, size: CGFloat) -> Font {
        return .custom(weight.rawValue, size: size)
    }

    // Typography styles matching Flutter AppTextTheme
    static let yarHeadline1 = Font.oswald(.semiBold, size: 64)
    static let yarHeadline2 = Font.oswald(.semiBold, size: 48)
    static let yarHeadline3 = Font.oswald(.regular, size: 32)
    static let yarHeadline4 = Font.oswald(.semiBold, size: 20)

    static let yarBodyLBold = Font.oswald(.bold, size: 24)
    static let yarBodyLMedium = Font.oswald(.semiBold, size: 24)
    static let yarBodyLRegular = Font.oswald(.regular, size: 24)

    static let yarBodyMBold = Font.oswald(.bold, size: 20)
    static let yarBodyMMedium = Font.oswald(.semiBold, size: 20)
    static let yarBodyMRegular = Font.oswald(.regular, size: 20)

    static let yarBodySBold = Font.oswald(.bold, size: 16)
    static let yarBodySMedium = Font.oswald(.semiBold, size: 16)
    static let yarBodySRegular = Font.oswald(.regular, size: 16)

    static let yarBodyXSBold = Font.oswald(.bold, size: 12)
    static let yarBodyXSMedium = Font.oswald(.semiBold, size: 12)
    static let yarBodyXSRegular = Font.oswald(.regular, size: 12)
}
