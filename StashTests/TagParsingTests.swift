import XCTest
@testable import Stash

final class TagParsingTests: XCTestCase {
    func testNormalizeSingleTagPreservesMultiWordTags() {
        XCTAssertEqual(
            TagParsing.normalizeSingleTag("  #Christmas ornaments  "),
            "christmas ornaments"
        )
    }

    func testAppendingSingleTagDeduplicates() {
        let tags = TagParsing.appending("Christmas ornaments", to: ["christmas ornaments"])

        XCTAssertEqual(tags, ["christmas ornaments"])
    }

    func testLocationDisplayNameTrimsAndCollapsesWhitespace() {
        XCTAssertEqual(
            LocationName.displayName(from: "  Garage   Shelf\nA  "),
            "Garage Shelf A"
        )
    }

    func testLocationDeduplicationKeyIgnoresCaseAndWhitespaceVariants() {
        XCTAssertEqual(
            LocationName.deduplicationKey(for: "  Garage   Shelf A "),
            LocationName.deduplicationKey(for: "garage shelf a")
        )
    }

    func testLocationMatchesRejectsBlankValues() {
        XCTAssertFalse(LocationName.matches("   ", "Garage"))
    }
}
