/**
 *  Sweep
 *  Copyright (c) John Sundell 2019
 *  Licensed under the MIT license (see LICENSE.md)
 */

import Foundation

/// Type used to define an identifier to scan for within a string.
/// An identifier can also be defined using a string literal.
/// Create a value using either .start, .prefix, or .anyString.
public struct Identifier {
    /// The string to scan for within a string.
    public var string: String
    /// Whether or not the identifier is required to be located
    /// right at the start of the scanned string.
    public var isPrefix: Bool
}

public extension Identifier {
    /// Match the very start of a string.
    static var start: Identifier {
        return .prefix("")
    }

    /// Match a starting prefix of a string.
    static func prefix(_ string: String) -> Identifier {
        return Identifier(string: string, isPrefix: true)
    }

    /// Match against a string located anywhere within the scanned string.
    static func anyString(_ string: String) -> Identifier {
        return Identifier(string: string, isPrefix: false)
    }
}

extension Identifier: ExpressibleByStringLiteral {
    /// Initialize an Identifier using a string literal.
    public init(stringLiteral value: String) {
        self.init(string: value, isPrefix: false)
    }
}

/// Type used to define a terminator that ends a matching session.
/// A terminator can also be defined using a string literal.
/// Create a value using either .end, .suffix, or .anyString.
public struct Terminator {
    /// The string to use as a terminator when scanning a string.
    public var string: String
    /// Whether or not the terminator is required to be located
    /// right at the end of the scanned string.
    public var isSuffix: Bool
}

public extension Terminator {
    /// Match the very end of a string.
    static var end: Terminator {
        return .suffix("")
    }

    /// Match an ending prefix of a string.
    static func suffix(_ string: String) -> Terminator {
        return Terminator(string: string, isSuffix: true)
    }

    /// Match against a string located anywhere within the scanned string.
    static func anyString(_ string: String) -> Terminator {
        return Terminator(string: string, isSuffix: false)
    }
}

extension Terminator: ExpressibleByStringLiteral {
    /// Initialize a Terminator using a string literal.
    public init(stringLiteral value: String) {
        self.init(string: value, isSuffix: false)
    }
}

/// Type used to define a custom string scanning matcher,
/// which gets all substrings that appear between a set of
/// identifiers and terminators passed to its handler.
public struct Matcher {
    /// Closure type used to define a handler for a matcher. When
    /// a match is found, the handler is passed the substring that
    /// was matched, as well as the range containing the match plus
    /// the identifier and terminator that the match is located between.
    public typealias Handler = (Substring, ClosedRange<String.Index>) -> Void

    /// The identifiers to look for when scanning. When any
    /// of the identifiers are found, a matching session begins.
    public var identifiers: [Identifier]
    /// The terminators that end a matching session, causing the
    /// substring between any of the found terminators and the
    /// identifier that started the session to be passed to the
    /// matcher's handler.
    public var terminators: [Terminator]
    /// Whether this matcher should be allowed to handle multiple
    /// matches, or if it's single-use only. Default value: true.
    public var allowMultipleMatches: Bool
    /// The handler to be called when a match was found. A match
    /// is considered found when a substring appears between any
    /// of the matcher's identifiers and its terminators.
    public var handler: Handler

    /// Create a new matcher with the desired parameters. See
    /// the documentation for each property for more information.
    public init(identifiers: [Identifier],
                terminators: [Terminator],
                allowMultipleMatches: Bool = true,
                handler: @escaping Handler) {
        self.identifiers = identifiers
        self.terminators = terminators
        self.allowMultipleMatches = allowMultipleMatches
        self.handler = handler
    }
}

public extension Matcher {
    /// Convenience API to initialize a matcher with a single
    /// identifier and terminator, rather than arrays of them.
    init(identifier: Identifier,
         terminator: Terminator,
         allowMultipleMatches: Bool = true,
         handler: @escaping Handler) {
        self.init(identifiers: [identifier],
                  terminators: [terminator],
                  allowMultipleMatches: allowMultipleMatches,
                  handler: handler)
    }
}

public extension StringProtocol where SubSequence == Substring {
    /// Scan this string for a single substring that appears between
    /// a single identifier and terminator, and return any found match.
    func firstSubstring(between identifier: Identifier,
                        and terminator: Terminator) -> Substring? {
        return firstSubstring(between: [identifier],
                              and: [terminator])
    }

    /// Scan this string for a single substring that appears between
    /// a set of identifiers and terminators, and return any found match.
    func firstSubstring(between identifiers: [Identifier],
                        and terminators: [Terminator]) -> Substring? {
        var match: Substring?

        scan(using: [
            Matcher(
                identifiers: identifiers,
                terminators: terminators,
                allowMultipleMatches: false,
                handler: { substring, _ in
                    match = substring
                }
            )
        ])

        return match
    }

    /// Scan this string for substrings appearing between a single
    /// identifier and terminator, and return all matches.
    func substrings(between identifier: Identifier,
                    and terminator: Terminator) -> [Substring] {
        return substrings(between: [identifier],
                          and: [terminator])
    }

    /// Scan this string for substrings appearing between a set of
    /// identifiers and terminators, and return all matches.
    func substrings(between identifiers: [Identifier],
                    and terminators: [Terminator]) -> [Substring] {
        var matches = [Substring]()

        scan(using: [Matcher(
            identifiers: identifiers,
            terminators: terminators,
            handler: { match, _ in
                matches.append(match)
            }
        )])

        return matches
    }

    /// Scan this string using a custom array of matchers, defined using
    /// the `Matcher` type, which gets to handle all matched substrings.
    func scan(using matchers: [Matcher]) {
        var activeSessions = [(Matcher, Identifier, ClosedRange<Index>)]()
        var partialSessions = [(Matcher, ClosedRange<Index>)]()
        var idleMatchers = matchers

        for index in indices {
            let noSessionsRemain = (
                activeSessions.isEmpty &&
                partialSessions.isEmpty &&
                idleMatchers.isEmpty
            )

            guard !noSessionsRemain else {
                return
            }

            activeSessions = activeSessions.compactMap { matcher, identifier, range in
                let range = range.lowerBound...index
                let match = self[range]

                for terminator in matcher.terminators {
                    guard match.hasSuffix(terminator.string) else {
                        continue
                    }

                    if terminator.isSuffix {
                        guard self.index(after: index) == endIndex else {
                            continue
                        }
                    }

                    let endIndex = self.index(range.upperBound,
                                              offsetBy: -terminator.string.count)

                    if endIndex >= range.lowerBound {
                        let match = self[range.lowerBound...endIndex]
                        let identifierLength = identifier.string.count
                        let lowerBound = self.index(range.lowerBound, offsetBy: -identifierLength)
                        matcher.handler(match, lowerBound...range.upperBound)

                        guard matcher.allowMultipleMatches else {
                            return nil
                        }
                    }

                    idleMatchers.append(matcher)
                    return nil
                }

                return (matcher, identifier, range)
            }

            partialSessions = partialSessions.compactMap { matcher, range in
                let range = range.lowerBound...index
                let match = self[range]

                for identifier in matcher.identifiers {
                    guard identifier.string.hasPrefix(match) else {
                        continue
                    }

                    guard identifier.string == match else {
                        return (matcher, range)
                    }

                    let nextIndex = self.index(after: index)
                    let range = nextIndex...nextIndex
                    activeSessions.append((matcher, identifier, range))
                    return nil
                }

                idleMatchers.append(matcher)
                return nil
            }

            idleMatchers = idleMatchers.filter { matcher in
                for identifier in matcher.identifiers {
                    if identifier.isPrefix {
                        guard index == startIndex else {
                            continue
                        }

                        guard !identifier.string.isEmpty else {
                            let range = index...index
                            activeSessions.append((matcher, identifier, range))
                            return false
                        }
                    }

                    if identifier.string.first == self[index] {
                        if identifier.string.count == 1 {
                            let nextIndex = self.index(after: index)
                            let range = nextIndex...nextIndex
                            activeSessions.append((matcher, identifier, range))
                        } else {
                            partialSessions.append((matcher, index...index))
                        }

                        return false
                    }
                }

                return true
            }
        }
    }
}
