import SwiftUI

public struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    private let policy = try? VenuePrivacyPolicy.load()
    private let appDisclosure = try? VenuePrivacyPolicy.loadAppDisclosure()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let appDisclosure {
                        policyContent(appDisclosure)
                        Divider().overlay(Color.yarSubject80)
                    }
                    if let policy {
                        policyContent(policy)
                    } else {
                        Text("Не удалось открыть политику конфиденциальности. Обратитесь к хостесу: \(VenueDetails.phone)")
                            .font(.yarBodySRegular)
                    }
                }
                .padding(24)
            }
            .background(Color.yarSubject95)
            .navigationTitle("ПОЛИТИКА")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func policyContent(_ document: VenuePrivacyPolicy) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(document.title).font(.yarHeadline3)
            Text(document.effectiveDate)
                .font(.yarBodyXSRegular).foregroundColor(.yarSubject40)
            ForEach(Array(document.sections.enumerated()), id: \.offset) { _, section in
                VStack(alignment: .leading, spacing: 10) {
                    Text(section.title).font(.yarBodyMBold).foregroundColor(.yarSecondary)
                    Text(verbatim: section.text).font(.yarBodySRegular).foregroundColor(.yarSubject20)
                        .lineSpacing(5).textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
