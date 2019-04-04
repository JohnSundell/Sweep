/**
 *  Sweep
 *  Copyright (c) John Sundell 2019
 *  Licensed under the MIT license (see LICENSE.md)
 */

import XCTest
import Sweep

final class SweepTests: XCTestCase {
    func testBasicScanning() {
        let string = "Some text <Scanned> some other text."
        let matches = string.substrings(between: "<", and: ">")
        XCTAssertEqual(matches, ["Scanned"])
    }

    func testMatchingMultipleSegments() {
        let string = "Some text <First> some other text <Second>."
        let matches = string.substrings(between: "<", and: ">")
        XCTAssertEqual(matches, ["First", "Second"])
    }

    func testMatchingBackToBackSegments() {
        let string = "Some text |First|Second| some other text."
        let matches = string.substrings(between: "|", and: "|")
        XCTAssertEqual(matches, ["First", "Second"])
    }

    func testMultipleIdentifiersAndTerminators() {
        let string = "Some text <First> some other text -[Second]-"
        let matches = string.substrings(between: ["<", "-["], and: [">", "]-"])
        XCTAssertEqual(matches, ["First", "Second"])
    }

    func testIgnoringNestedIdentifier() {
        let string = "Some text <Par<Nested>sed> some other text."
        let matches = string.substrings(between: "<", and: ">")
        XCTAssertEqual(matches, ["Par<Nested"])
    }

    func testMultipleNestedIdentifiers() {
        let string = "Some text <Par{First}<Second>sed> some other text."
        let matches = string.substrings(between: ["<", "{"], and: [">", "}"])
        XCTAssertEqual(matches, ["Par{First", "Second"])
    }

    func testIgnoringUnterminatedMatch() {
        let string = "Some text [(Match"
        let matches = string.substrings(between: "[(", and: ")]")
        XCTAssertEqual(matches, [])
    }

    func testIgnoringEmptyMatch() {
        let string = "Some text [()]"
        let matches = string.substrings(between: "[(", and: ")]")
        XCTAssertEqual(matches, [])
    }

    func testMultipleMatchers() {
        let string = "Some text <First> some other text [Second]."
        var matches = (
            a: [Substring](),
            b: [Substring]()
        )

        string.scan(using: [
            Matcher(identifier: "<", terminator: ">") {
                matches.a.append($0)
            },
            Matcher(identifier: "[", terminator: "]") {
                matches.b.append($0)
            }
        ])

        XCTAssertEqual(matches.a, ["First"])
        XCTAssertEqual(matches.b, ["Second"])
    }

    func testAllTestsRunOnLinux() {
        verifyAllTestsRunOnLinux()
    }
}

extension SweepTests: LinuxTestable {
    static var allTests: [(String, (SweepTests) -> () throws -> Void)] {
        return [
            ("testBasicScanning", testBasicScanning),
            ("testMatchingMultipleSegments", testMatchingMultipleSegments),
            ("testMatchingBackToBackSegments", testMatchingBackToBackSegments),
            ("testMultipleIdentifiersAndTerminators", testMultipleIdentifiersAndTerminators),
            ("testIgnoringNestedIdentifier", testIgnoringNestedIdentifier),
            ("testMultipleNestedIdentifiers", testMultipleNestedIdentifiers),
            ("testIgnoringUnterminatedMatch", testIgnoringUnterminatedMatch),
            ("testIgnoringEmptyMatch", testIgnoringEmptyMatch),
            ("testMultipleMatchers", testMultipleMatchers)
        ]
    }
}
