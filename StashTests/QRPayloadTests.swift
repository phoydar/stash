import XCTest
@testable import Stash

final class QRPayloadTests: XCTestCase {
    func testMakeURLUsesStashContainerFormat() {
        let id = UUID(uuidString: "A2E3F54D-58F1-49C6-A198-95D079CE82C3")!

        XCTAssertEqual(
            QRPayload.makeURLString(for: id),
            "stash://container/A2E3F54D-58F1-49C6-A198-95D079CE82C3"
        )
    }

    func testParseStashContainerURL() {
        let id = UUID(uuidString: "A2E3F54D-58F1-49C6-A198-95D079CE82C3")!

        XCTAssertEqual(QRPayload.parse("stash://container/\(id.uuidString)"), id)
    }

    func testParseBareUUIDForDevelopmentCompatibility() {
        let id = UUID(uuidString: "A2E3F54D-58F1-49C6-A198-95D079CE82C3")!

        XCTAssertEqual(QRPayload.parse(id.uuidString), id)
    }

    func testRejectsWrongSchemeOrHost() {
        let id = UUID(uuidString: "A2E3F54D-58F1-49C6-A198-95D079CE82C3")!

        XCTAssertNil(QRPayload.parse("https://container/\(id.uuidString)"))
        XCTAssertNil(QRPayload.parse("stash://item/\(id.uuidString)"))
        XCTAssertNil(QRPayload.parse("not a qr payload"))
    }
}
