import XCTest
@testable import YarMinsk

final class VenueContentTests: XCTestCase {
    func testMenuIsBundledWithUniqueIDsAndExcludesRestrictedProducts() throws {
        let menu = try VenueMenu.load()
        let items = menu.categories.flatMap(\.items)
        XCTAssertFalse(items.isEmpty)
        XCTAssertEqual(Set(items.map(\.id)).count, items.count)
        XCTAssertTrue(items.allSatisfy { !$0.name.isEmpty && $0.price > 0 })
        let content = (menu.categories.map(\.title) + items.map { $0.name + " " + $0.description }).joined(separator: " ").lowercased()
        for forbidden in ["кальян", "табак", "курени", "виски", "водка", "текила", "ликер", "ликёр", "вермут", "пиво", "алкогольный", "prosecco", "jameson"] {
            XCTAssertFalse(content.contains(forbidden), "Restricted menu content: \(forbidden)")
        }
    }

    func testSearchFindsIngredientsAndCombinesWithCategorySelection() throws {
        let menu = try VenueMenu.load()
        let shrimp = menu.filtered(query: "  КРЕВЕТКИ  ", categoryID: nil).flatMap(\.items)
        XCTAssertFalse(shrimp.isEmpty)
        XCTAssertTrue(menu.filtered(query: "креветки", categoryID: "coffee").isEmpty)
        XCTAssertFalse(menu.filtered(query: "эспрессо", categoryID: "coffee").isEmpty)
    }

    func testFullPolicyIsBundledInsteadOfRequiringAnExternalWebsite() throws {
        let policy = try VenuePrivacyPolicy.load()
        XCTAssertEqual(policy.sections.count, 10)
        XCTAssertTrue(policy.sections.contains { $0.title == "Data Retention" })
        XCTAssertTrue(policy.sections.contains { $0.title == "Data Sharing and Transfers" })
        XCTAssertTrue(policy.sections.allSatisfy { !$0.text.isEmpty })
    }
}
