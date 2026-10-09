import SwiftUI

public struct MenuView: View {
    @State private var query = ""
    @State private var selectedCategoryID: String?
    private let menu = try? VenueMenu.load()

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let menu {
                    categoryPicker(menu)
                    let categories = menu.filtered(query: query, categoryID: selectedCategoryID)
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            if categories.isEmpty {
                                Text("Ничего не найдено. Попробуйте другое название или ингредиент.")
                                    .font(.yarBodySRegular)
                                    .foregroundColor(.yarSubject40)
                                    .padding(.vertical, 40)
                            }
                            ForEach(categories) { category in
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(category.title.uppercased())
                                        .font(.yarHeadline3)
                                    if let note = category.note {
                                        Text(note).font(.yarBodyXSRegular).foregroundColor(.yarSubject40)
                                    }
                                    VStack(spacing: 0) {
                                        ForEach(category.items) { item in
                                            menuRow(item)
                                            if item.id != category.items.last?.id {
                                                Divider().overlay(Color.yarSubject80).padding(.horizontal, 18)
                                            }
                                        }
                                    }
                                    .background(Color.yarSubject90)
                                    .cornerRadius(20)
                                }
                            }
                            Text("Цены в белорусских рублях. Актуальное наличие уточняйте у хостеса.")
                                .font(.yarBodyXSRegular)
                                .foregroundColor(.yarSubject40)
                                .padding(.bottom, 20)
                        }
                        .padding(20)
                    }
                } else {
                    Text("Не удалось открыть меню. Уточните меню у хостеса: \(VenueDetails.phone)")
                        .font(.yarBodySRegular).padding(24)
                }
            }
            .background(Color.yarSubject95)
            .navigationTitle("МЕНЮ")
            .searchable(text: $query, prompt: "Блюдо или ингредиент")
        }
    }

    private func categoryPicker(_ menu: VenueMenu) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryButton("Всё меню", id: nil)
                ForEach(menu.categories) { category in
                    categoryButton(category.title, id: category.id)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func categoryButton(_ title: String, id: String?) -> some View {
        Button { selectedCategoryID = id } label: {
            Text(title)
                .font(.yarBodySRegular)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(selectedCategoryID == id ? Color.yarSecondary : Color.yarSubject90)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedCategoryID == id ? .isSelected : [])
    }

    private func menuRow(_ item: MenuItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.name).font(.yarBodyMMedium).frame(maxWidth: .infinity, alignment: .leading)
                Text(item.formattedPrice).font(.yarBodyMBold).fixedSize()
            }
            if !item.description.isEmpty {
                Text(item.description).font(.yarBodyXSRegular).foregroundColor(.yarSubject40)
            }
            if !item.portion.isEmpty {
                Text(item.portion).font(.yarBodyXSRegular).foregroundColor(.yarSubject50)
            }
        }
        .padding(18)
        .accessibilityElement(children: .combine)
    }
}
