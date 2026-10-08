import SwiftUI

/// Sanitized Yar emblem logo component.
/// Displays the winged crest emblem without any restricted branding text.
public struct YarLogoEmblem: View {
    public let height: CGFloat

    public init(height: CGFloat = 26) {
        self.height = height
    }

    public var body: some View {
        if let uiImage = UIImage(named: "logo") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: height)
        } else {
            // High-fidelity fallback vector representation of the brand emblem
            HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.system(size: height * 0.75, weight: .bold))
                    .foregroundColor(.yarSubject00)
            }
            .frame(height: height)
        }
    }
}

#Preview {
    ZStack {
        Color.yarSubject95.ignoresSafeArea()
        VStack(spacing: 20) {
            YarLogoEmblem(height: 32)
            YarLogoEmblem(height: 24)
            YarLogoEmblem(height: 18)
        }
    }
}
