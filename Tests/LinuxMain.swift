import XCTest

import pystrTests

var tests = [XCTestCaseEntry]()
tests += pystrTests.allTests()
XCTMain(tests)
