/**
 *  Sweep
 *  Copyright (c) John Sundell 2019
 *  Licensed under the MIT license (see LICENSE.md)
 */

import Foundation

/// Type used to define a custom string scanning matcher,
/// which gets all substrings that appear between a set of
/// identifiers and terminators passed to its handler.
public struct Matcher {
    /// The identifiers to look for when scanning. When either
    /// of the identifiers are found, a matching session begins.
    public var identifiers: Set<String>
    /// The terminators that end a matching session, causing the
    /// substring between any of the found terminators and the
    /// identifier that started the session to be passed to the
    /// matcher's handler.
    public var terminators: Set<String>
    /// The handler to be called when a match was found. A match
    /// is considered found when a substring appears between any
    /// of the matcher's identifiers and its terminators.
    public var handler: (Substring) -> Void

    /// Create a new matcher with the desired parameters. See
    /// the documentation for each property for more information.
    public init(identifiers: Set<String>,
                terminators: Set<String>,
                handler: @escaping (Substring) -> Void) {
        self.identifiers = identifiers
        self.terminators = terminators
        self.handler = handler
    }
}

public extension Matcher {
    /// Convenience API to initialize a matcher with a single
    /// identifier and matcher, rather than sets of them.
    init(identifier: String,
         terminator: String,
         handler: @escaping (Substring) -> Void) {
        self.init(identifiers: [identifier],
                  terminators: [terminator],
                  handler: handler)
    }
}

public extension StringProtocol where SubSequence == Substring {
    /// Scan this string for substrings appearing between a single
    /// identifier and terminator, and return all matches.
    func substrings(between identifier: String,
                    and terminator: String) -> [Substring] {
        return substrings(between: [identifier], and: [terminator])
    }

    /// Scan this string for substrings appearing between a set of
    /// identifiers and terminators, and return all matches.
    func substrings(between identifiers: Set<String>,
                    and terminators: Set<String>) -> [Substring] {
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
                    guard !match.hasSuffix(terminator) else {
                        let endIndex = self.index(range.upperBound, offsetBy: -terminator.count)

                        if endIndex > range.lowerBound {
                            let range = range.lowerBound...endIndex
                            matcher.handler(self[range])
                        }

                        idleMatchers.append(matcher)
                        return nil
                    }
                }

                return (matcher, range)
            }

            partialSessions = partialSessions.compactMap {
                let matcher = $0.matcher
                let range = $0.range.lowerBound...index
                let match = self[range]

                for identifier in matcher.identifiers {
                    guard identifier.hasPrefix(match) else {
                        continue
                    }

                    guard identifier == match else {
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
                    if identifier.first == self[index] {
                        if identifier.count == 1 {
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
