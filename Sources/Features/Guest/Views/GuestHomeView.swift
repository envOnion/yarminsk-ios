import SwiftUI

public struct GuestHomeView: View {
    public let onMenu: () -> Void
    public let onContacts: () -> Void
    public let onLoyalty: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var showPrivacy = false

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ЯР МИНСК")
                                .font(.oswald(.bold, size: 38))
                                .tracking(2)
                            Text("Встречаемся в центре города")
                                .font(.yarBodySRegular)
                                .foregroundColor(.yarSubject40)
                        }
                        Spacer(minLength: 12)
                        YarLogoEmblem(height: 44)
                            .padding(.top, 8)
                    }
                    .padding(.top, 20)

                    Button(action: onMenu) {
                        VStack(alignment: .leading, spacing: 28) {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 30))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 22))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ВКУС ВСТРЕЧИ")
                                    .font(.oswald(.bold, size: 30))
                                Text("Кухня, кофе и любимые напитки")
                                    .font(.yarBodySRegular)
                            }
                            Text("ОТКРЫТЬ МЕНЮ")
                                .font(.yarBodySBold)
                                .tracking(1)
                        }
                        .foregroundColor(.white)
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LinearGradient.yarPrimaryGradient)
                        .cornerRadius(24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("guest.openMenu")

                    VStack(spacing: 0) {
                        Button(action: onContacts) {
                            contactRow(icon: "mappin.and.ellipse", title: "НАШ АДРЕС", value: VenueDetails.address)
                        }
                        Divider().overlay(Color.yarSubject80).padding(.horizontal, 20)
                        Button { openURL(VenueDetails.phoneURL) } label: {
                            contactRow(icon: "phone", title: "ХОСТЕС · ПОЗВОНИТЬ", value: VenueDetails.phone)
                        }
                    }
                    .buttonStyle(.plain)
                    .background(Color.yarSubject90)
                    .cornerRadius(20)

                    Button(action: onLoyalty) {
                        HStack(spacing: 16) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 28))
                                .foregroundColor(.yarSecondary)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("МОЯ КАРТА")
                                    .font(.yarBodyMBold)
                                Text("Карта лояльности всегда с собой")
                                    .font(.yarBodyXSRegular)
                                    .foregroundColor(.yarSubject40)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.yarSubject40)
                        }
                        .padding(20)
                        .background(Color.yarSubject90)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)

                    Button("Политика конфиденциальности") { showPrivacy = true }
                        .font(.yarBodyXSRegular)
                        .foregroundColor(.yarSubject40)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.yarSubject95)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
        }
    }

    private func contactRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 23))
                .foregroundColor(.yarSecondary)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.yarBodyXSRegular).foregroundColor(.yarSubject40)
                Text(value).font(.yarBodyMMedium).foregroundColor(.white)
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.right").foregroundColor(.yarSubject40)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
