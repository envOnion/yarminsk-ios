import SwiftUI

/// Top navigation bar for Home screen with user avatar, brand emblem, and drawer toggle.
public struct HomeAppBar: View {
    public let photoUrl: URL?
    public let onMenuTapped: () -> Void

    public init(
        photoUrl: URL? = nil,
        onMenuTapped: @escaping () -> Void
    ) {
        self.photoUrl = photoUrl
        self.onMenuTapped = onMenuTapped
    }

    public var body: some View {
        HStack(alignment: .center) {
            // Left: User Avatar Circle
            avatarView

            Spacer()

            // Center: Sanitized Logo Emblem
            YarLogoEmblem(height: 26)

            Spacer()

            // Right: Burger Menu Button
            Button(action: onMenuTapped) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.yarSubject00)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Меню")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.yarSubject95)
    }

    // MARK: - Avatar View

    private var avatarView: some View {
        Group {
            if let photoUrl {
                AsyncImage(url: photoUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 38, height: 38)
                            .clipShape(Circle())
                    case .failure, .empty:
                        placeholderAvatar
                    @unknown default:
                        placeholderAvatar
                    }
                }
            } else {
                placeholderAvatar
            }
        }
        .frame(width: 38, height: 38)
        .overlay(
            Circle()
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
        )
    }

    private var placeholderAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.yarSubject80)

            Image(systemName: "person.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.yarSubject20)
        }
    }
}

#Preview {
    ZStack {
        Color.yarSubject95.ignoresSafeArea()
        VStack {
            HomeAppBar(photoUrl: nil, onMenuTapped: {})
            Spacer()
        }
    }
}
