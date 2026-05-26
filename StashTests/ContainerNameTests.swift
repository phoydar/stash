import XCTest
@testable import Stash

final class ContainerNameTests: XCTestCase {
    func testDisplayNameTrimsAndCollapsesWhitespace() {
        XCTAssertEqual(ContainerName.displayName(from: "  Holiday   bins\n2026  "), "Holiday bins 2026")
    }

    func testBlankNameCanBeStoredAsEmptyString() {
        XCTAssertNil(ContainerName.displayName(from: "   \n  "))
        XCTAssertEqual(ContainerName.storedName(from: "   \n  "), "")
    }
}
