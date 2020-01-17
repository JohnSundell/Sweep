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

    func testMatchingStartOfString() {
        let string = "<Scanned> Some text."
        let matches = string.substrings(between: "<", and: ">")
        XCTAssertEqual(matches, ["Scanned"])
    }

    func testMatchingStartOfStringWithStartIdentifier() {
        let string = "<Scanned> Some text."
        let matches = string.substrings(between: .start, and: ">")
        XCTAssertEqual(matches, ["<Scanned"])
    }

    func testMatchingEndOfString() {
        let string = "Some text <Scanned>"
        let matches = string.substrings(between: "<", and: ">")
        XCTAssertEqual(matches, ["Scanned"])
    }

    func testMatchingEndOfStringWithEndTerminator() {
        let string = "Some text <Scanned>"
        let matches = string.substrings(between: "<", and: .end)
        XCTAssertEqual(matches, ["Scanned>"])
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

    func testHTMLScanning() {
        let html = "<p>Hello, <b>this text should be bold</b>, right?</p>"

        let tags = html.substrings(between: "<", and: ">")
        XCTAssertEqual(tags, ["p", "b", "/b", "/p"])

        let boldText = html.substrings(between: "<b>", and: "</b>")
        XCTAssertEqual(boldText, ["this text should be bold"])
    }

    func testMarkdownScanning() {
        let markdown = """
        # Title

        Text

        ## Section 1

        More text

        ## Section 2
        """

        let h1s = markdown.substrings(between: [.prefix("# "), "\n# "], and: [.end, "\n"])
        XCTAssertEqual(h1s, ["Title"])

        let h2s = markdown.substrings(between: [.prefix("## "), "\n## "], and: [.end, "\n"])
        XCTAssertEqual(h2s, ["Section 1", "Section 2"])
    }

    func testMultipleMatchers() {
        let string = "Some text <First> some other text [[Second]]."
        var matches = (a: [Substring](), b: [Substring]())
        var ranges = (a: [ClosedRange<String.Index>](), b: [ClosedRange<String.Index>]())

        string.scan(using: [
            Matcher(identifier: "<", terminator: ">") { match, range in
                matches.a.append(match)
                ranges.a.append(range)
            },
            Matcher(identifier: "[[", terminator: "]]") { match, range in
                matches.b.append(match)
                ranges.b.append(range)
            }
        ])

        XCTAssertEqual(matches.a, ["First"])
        XCTAssertEqual(ranges.a.map { string[$0] }, ["<First>"])
        XCTAssertEqual(matches.b, ["Second"])
        XCTAssertEqual(ranges.b.map { string[$0] }, ["[[Second]]"])
    }

    func testDisallowingMultipleMatches() {
        let string = "Some text <First> some other text <Second>, <Third>."
        var matches = [Substring]()

        string.scan(using: [
            Matcher(
                identifier: "<",
                terminator: ">",
                allowMultipleMatches: false,
                handler: { match, _ in
                    matches.append(match)
                }
            )
        ])

        XCTAssertEqual(matches, ["First"])
    }

    func testScanningForSingleSubstring() {
        let string = "Some text <First> some other text <Second>, <Third>."
        let match = string.firstSubstring(between: "<", and: ">")
        XCTAssertEqual(match, "First")
    }

    func testScanningForSingleSubstringWithMultipleIdentifiers() {
        let string = "Some text <First> some other text [Second], <Third>."
        let match = string.firstSubstring(between: ["<", "["], and: [">", "]"])
        XCTAssertEqual(match, "First")
    }

    func testAllTestsRunOnLinux() {
        verifyAllTestsRunOnLinux()
    }
}

extension SweepTests: LinuxTestable {
    static var allTests: [(String, (SweepTests) -> () throws -> Void)] {
        return [
            ("testBasicScanning", testBasicScanning),
            ("testMatchingStartOfString", testMatchingStartOfString),
            ("testMatchingStartOfStringWithStartIdentifier", testMatchingStartOfStringWithStartIdentifier),
            ("testMatchingEndOfString", testMatchingEndOfString),
            ("testMatchingEndOfStringWithEndTerminator", testMatchingEndOfStringWithEndTerminator),
            ("testMatchingMultipleSegments", testMatchingMultipleSegments),
            ("testMatchingBackToBackSegments", testMatchingBackToBackSegments),
            ("testMultipleIdentifiersAndTerminators", testMultipleIdentifiersAndTerminators),
            ("testIgnoringNestedIdentifier", testIgnoringNestedIdentifier),
            ("testMultipleNestedIdentifiers", testMultipleNestedIdentifiers),
            ("testIgnoringUnterminatedMatch", testIgnoringUnterminatedMatch),
            ("testIgnoringEmptyMatch", testIgnoringEmptyMatch),
            ("testHTMLScanning", testHTMLScanning),
            ("testMarkdownScanning", testMarkdownScanning),
            ("testMultipleMatchers", testMultipleMatchers),
            ("testDisallowingMultipleMatches", testDisallowingMultipleMatches),
            ("testScanningForSingleSubstring", testScanningForSingleSubstring),
            ("testScanningForSingleSubstringWithMultipleIdentifiers", testScanningForSingleSubstringWithMultipleIdentifiers)
        ]
    }
}
