---
title: XCTest, which every Xcode project already has
version: 1
---

**XCTest is the framework iOS projects have tested with since before Swift existed, and a new Xcode
project still has it.** The UI tests of section 06 are XCTest and nothing else, and most projects
you join will have thousands of XCTest unit tests written before Swift Testing arrived. Both
frameworks run in the same `swift test`, side by side, which is why lesson 1's output printed two
reports.

The same two checks lesson 1 made, written as XCTest. Save this as
`Tests/PlannerCoreTests/LegacyTests.swift`:

```swift
// Tests/PlannerCoreTests/LegacyTests.swift
import XCTest
@testable import PlannerCore

final class LegacyTests: XCTestCase {
    func testMondayOfASunday() {
        XCTAssertEqual(mondayOf("2026-10-25"), "2026-10-19")
    }

    func testASessionForNoCourseIsRefused() {
        var plan = Plan(courses: [Course(id: "sql", title: "SQL Databases")])
        XCTAssertThrowsError(try plan.add(
            StudySession(id: "s1", courseID: "art", date: "2026-10-19", minutes: 30)
        ))
        XCTAssertTrue(plan.sessions.isEmpty)
    }
}
```

Four differences carry most of the rest:

| | XCTest | Swift Testing |
|---|---|---|
| a test is | a method whose name starts with `test`, in a subclass of `XCTestCase` | any function marked `@Test` |
| an expectation | one function per kind: `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertThrowsError` | `#expect` with any Boolean expression |
| a fixture | `setUp()` and `tearDown()` methods | the suite's `init`, or its stored properties |
| running in parallel | off by default | on by default |

```
ana@vm:~/l20$ swift test --filter LegacyTests 2>&1 | grep -E "^(Test Case|Test Suite .LegacyTests|	 Executed)" | head -6
Test Suite 'LegacyTests' started at 2026-10-30 15:44:57.851
Test Case 'LegacyTests.testASessionForNoCourseIsRefused' started at 2026-10-30 15:44:57.851
Test Case 'LegacyTests.testASessionForNoCourseIsRefused' passed (0.001 seconds)
Test Case 'LegacyTests.testMondayOfASunday' started at 2026-10-30 15:44:57.852
Test Case 'LegacyTests.testMondayOfASunday' passed (0.202 seconds)
Test Suite 'LegacyTests' passed at 2026-10-30 15:44:58.054
```

**XCTest prints a line when each test starts and when it ends**, with the class and method names, and
a summary per suite. The method name is the only name a test has, which is why XCTest names read as
camel-case sentences.

There is no reason to rewrite XCTest tests that work. Write new ones in Swift Testing, and leave the
UI tests where they are: Swift Testing does not drive an app's interface.
