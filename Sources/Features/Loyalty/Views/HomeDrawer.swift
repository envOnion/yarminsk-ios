import SwiftUI

/// Right-side slide-over drawer navigation panel.
public struct HomeDrawer: View {
    @Binding public var isOpen: Bool
    public let profile: UserProfile?
    public let onSignOut: () -> Void

    @State private var showSignOutAlert: Bool = false

    public init(
        isOpen: Binding<Bool>,
        profile: UserProfile? = nil,
        onSignOut: @escaping () -> Void
    ) {
        self._isOpen = isOpen
        self.profile = profile
        self.onSignOut = onSignOut
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            if isOpen {
                // Dimmed background backdrop
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isOpen = false
                        }
                    }
                    .transition(.opacity)

                // Slide-over panel
                drawerView
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isOpen)
        .yarAlert(
            isPresented: $showSignOutAlert,
            title: "Вы действительно хотите выйти?",
            message: "Для доступа к карте лояльности потребуется повторная авторизация",
            confirmTitle: "ВЫЙТИ",
            cancelTitle: "ОСТАТЬСЯ",
            isDestructive: true,
            onConfirm: {
                withAnimation {
                    isOpen = false
                }
                onSignOut()
            }
        )
    }

    // MARK: - Drawer Content

    private var drawerView: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 0) {
                    // Top Bar with Close Button on right
                    HStack {
                        Spacer()

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isOpen = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.yarSubject00)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Закрыть")
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                    // User Profile Header
                    VStack(alignment: .leading, spacing: 8) {
                        YarLogoEmblem(height: 28)
                            .padding(.bottom, 8)

                        if let profile {
                            if !profile.displayName.isEmpty {
                                Text(profile.displayName.uppercased())
                                    .font(.yarHeadline4)
                                    .foregroundColor(.yarSubject00)
                                    .lineLimit(1)
                            }

                            if !profile.email.isEmpty {
                                Text(profile.email)
                                    .font(.yarBodyXSRegular)
                                    .foregroundColor(.yarSubject40)
                                    .lineLimit(1)
                            }

                            if !profile.phone.isEmpty {
                                Text(profile.phone)
                                    .font(.yarBodyXSRegular)
                                    .foregroundColor(.yarSubject50)
                            }
                        } else {
                            Text("ЯР МИНСК")
                                .font(.yarHeadline4)
                                .foregroundColor(.yarSubject00)
                                .tracking(1.5)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)

                    Spacer()

                    // Bottom Right: Sign Out Button
                    HStack {
                        Spacer()

                        Button(action: {
                            showSignOutAlert = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("ВЫЙТИ")
                                    .font(.yarBodySBold)
                                    .tracking(1.0)
                            }
                            .foregroundColor(.yarError)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.yarError.opacity(0.12))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
                .frame(width: min(geometry.size.width * 0.8, 320))
                .background(Color.yarSubject90)
                .overlay(
                    Rectangle()
                        .fill(Color.yarSubject80)
                        .frame(width: 1),
                    alignment: .leading
                )
                .ignoresSafeArea(edges: .vertical)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.yarSubject95.ignoresSafeArea()
        HomeDrawer(
            isOpen: .constant(true),
            profile: UserProfile(
                id: "preview_user",
                name: "Александр",
                lastName: "Белянский",
                email: "alex@yarminsk.by",
                phone: "+375 29 123-45-67"
            ),
            onSignOut: {}
        )
    }
}
