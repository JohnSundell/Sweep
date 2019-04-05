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
    /// The identifiers to look for when scanning. When any
    /// of the identifiers are found, a matching session begins.
    public var identifiers: [Identifier]
    /// The terminators that end a matching session, causing the
    /// substring between any of the found terminators and the
    /// identifier that started the session to be passed to the
    /// matcher's handler.
    public var terminators: [Terminator]
    /// The handler to be called when a match was found. A match
    /// is considered found when a substring appears between any
    /// of the matcher's identifiers and its terminators.
    public var handler: (Substring) -> Void

    /// Create a new matcher with the desired parameters. See
    /// the documentation for each property for more information.
    public init(identifiers: [Identifier],
                terminators: [Terminator],
                handler: @escaping (Substring) -> Void) {
        self.identifiers = identifiers
        self.terminators = terminators
        self.handler = handler
    }
}

public extension Matcher {
    /// Convenience API to initialize a matcher with a single
    /// identifier and terminator, rather than arrays of them.
    init(identifier: Identifier,
         terminator: Terminator,
         handler: @escaping (Substring) -> Void) {
        self.init(identifiers: [identifier],
                  terminators: [terminator],
                  handler: handler)
    }
}

public extension StringProtocol where SubSequence == Substring {
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
            handler: { matches.append($0) }
        )])

        return matches
    }

    /// Scan this string using a custom array of matchers, defined using
    /// the `Matcher` type, which gets to handle all matched substrings.
    func scan(using matchers: [Matcher]) {
        typealias Session = (matcher: Matcher, range: ClosedRange<Index>)

        var activeSessions = [Session]()
        var partialSessions = [Session]()
        var idleMatchers = matchers

        for index in indices {
            activeSessions = activeSessions.compactMap {
                let matcher = $0.matcher
                let range = $0.range.lowerBound...index
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
                        let range = range.lowerBound...endIndex
                        matcher.handler(self[range])
                    }

                    idleMatchers.append(matcher)
                    return nil
                }

                return (matcher, range)
            }

            partialSessions = partialSessions.compactMap {
                let matcher = $0.matcher
                let range = $0.range.lowerBound...index
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
                    activeSessions.append((matcher, range))
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
                    }

                    if identifier.string.first == self[index] {
                        if identifier.string.count == 1 {
                            let nextIndex = self.index(after: index)
                            activeSessions.append((matcher, nextIndex...nextIndex))
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
