/**
 *  Sweep
 *  Copyright (c) John Sundell 2019
 *  Licensed under the MIT license (see LICENSE.md)
 */

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [testCase(SweepTests.allTests)]
}
#endif
