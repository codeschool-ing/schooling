---
title: XCTest, the framework that came first
version: 1
---

A test is a small program that uses your code the way a caller would and **states what should
come out**. When the statement is false, the test fails, names the line, and says what it got
instead. Run the tests after every change and a mistake shows up minutes after you made it, in a
function you remember writing, rather than weeks later on a student's screen.

Swift has two test frameworks, and both ship inside the toolchain lesson 1 installed. **XCTest** is
the older one, from the days of Objective-C, and it is still in every iOS project you will open.
**Swift Testing** arrived in 2024 and is section 03's subject. This lesson writes the same tests in
both, so you can read either when you meet it.

## A package with a test target

Tests live in a package, beside the code they test. This one has the planner's library and a test
target that depends on it:

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "planner",
    targets: [
        .target(name: "PlannerCore"),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

The library holds a study session and a week of them. A week counts only the sessions that are
done, and says how many minutes are left before the goal:

```swift
// Sources/PlannerCore/Week.swift
public struct StudySession: Equatable, Sendable {
    public let course: String
    public let minutes: Int
    public var done: Bool

    public init(course: String, minutes: Int, done: Bool = false) {
        self.course = course
        self.minutes = minutes
        self.done = done
    }
}

public struct Week: Sendable {
    public private(set) var sessions: [StudySession] = []
    public let goal: Int

    public init(goal: Int = 300) { self.goal = goal }

    public mutating func add(_ session: StudySession) {
        sessions.append(session)
    }

    public var total: Int {
        sessions.filter(\.done).map(\.minutes).reduce(0, +)
    }

    public var remaining: Int { goal - total }
}
```

## Two XCTest tests

```schooling-example
{"language": "swift", "file": "Tests/PlannerCoreTests/WeekXCTests.swift", "parts": [
{"code": "import XCTest\n@testable import PlannerCore", "note": "`@testable` lets the tests see the module's `internal` names as well as its public ones. Lesson 17's access levels still hold for every other importer."},
{"code": "final class WeekXCTests: XCTestCase {", "note": "An XCTest suite is a class that inherits from `XCTestCase`. The runner finds it by looking for subclasses."},
{"code": "    func testTotalCountsOnlyDoneSessions() {\n        var week = Week()\n        week.add(StudySession(course: \"swift\", minutes: 45, done: true))\n        week.add(StudySession(course: \"swift\", minutes: 30))\n        XCTAssertEqual(week.total, 45)\n    }", "note": "A test is a method whose name starts with `test`, takes nothing and returns nothing. Arrange a week, act on it, then assert: `XCTAssertEqual` compares two values and fails the test if they differ."},
{"code": "    func testRemainingNeverGoesBelowZero() {\n        var week = Week(goal: 60)\n        week.add(StudySession(course: \"swift\", minutes: 90, done: true))\n        XCTAssertEqual(week.remaining, 0)\n    }\n}", "note": "The second states a rule the code was never told: a student who studies more than the goal has zero minutes left, not a negative number."}
]}
```

The first build of a package with tests compiles the test frameworks' support code too, so it is
slow once. `swift build --build-tests` does that on its own, and `--disable-swift-testing` asks
`swift test` to run the XCTest tests only:

```
ana@vm:~/sw/l18/planner$ swift build --build-tests 2>&1 | tail -1
Build complete! (9.20 secs)
ana@vm:~/sw/l18/planner$ swift test --disable-swift-testing 2>&1 | grep -v frontend
Building for debugging...
[Pre-planning 1 / 95]
[Planning deferred tasks]
Build complete! (0.81 secs)
Test Suite 'All tests' started at 2026-10-30 15:26:21.343
Test Suite 'Debug-linux-x86_64.xctest' started at 2026-10-30 15:26:21.344
Test Suite 'WeekXCTests' started at 2026-10-30 15:26:21.344
Test Case 'WeekXCTests.testRemainingNeverGoesBelowZero' started at 2026-10-30 15:26:21.344
/home/ana/sw/l18/planner/Tests/PlannerCoreTests/WeekXCTests.swift:13: error: WeekXCTests.testRemainingNeverGoesBelowZero : XCTAssertEqual failed: ("-30") is not equal to ("0") - 
Test Case 'WeekXCTests.testRemainingNeverGoesBelowZero' failed (0.002 seconds)
Test Case 'WeekXCTests.testTotalCountsOnlyDoneSessions' started at 2026-10-30 15:26:21.347
Test Case 'WeekXCTests.testTotalCountsOnlyDoneSessions' passed (0.001 seconds)
Test Suite 'WeekXCTests' failed at 2026-10-30 15:26:21.347
	 Executed 2 tests, with 1 failure (0 unexpected) in 0.003 (0.003) seconds
Test Suite 'Debug-linux-x86_64.xctest' failed at 2026-10-30 15:26:21.347
	 Executed 2 tests, with 1 failure (0 unexpected) in 0.003 (0.003) seconds
Test Suite 'All tests' failed at 2026-10-30 15:26:21.347
	 Executed 2 tests, with 1 failure (0 unexpected) in 0.003 (0.003) seconds
Note: Some test targets reported failures:
  - PlannerCoreTests (XCTest)
```

**Read the failure line first, the one that says `error`.** It gives the file and line of the
assertion, the test's name, and what was compared: `("-30") is not equal to ("0")`. The week had a
goal of 60 and 90 minutes done, and `remaining` answered −30, which a screen would show as "−30
minutes left". The other test passed. The rest of the output is the runner's bookkeeping, a
started and a finished line for each test and three summaries that say the same thing at three
levels: the class, the bundle of tests, and the whole run.

## Fix the code, not the test

A failing test is either a mistake in the code or a mistake in the test, and the test is only worth
having if you decide which before touching anything. Here the test states the rule the planner
wants, so the code changes: `remaining` becomes `max(goal - total, 0)`.

```swift
// Sources/PlannerCore/Week.swift
public struct StudySession: Equatable, Sendable {
    public let course: String
    public let minutes: Int
    public var done: Bool

    public init(course: String, minutes: Int, done: Bool = false) {
        self.course = course
        self.minutes = minutes
        self.done = done
    }
}

public struct Week: Sendable {
    public private(set) var sessions: [StudySession] = []
    public let goal: Int

    public init(goal: Int = 300) { self.goal = goal }

    public mutating func add(_ session: StudySession) {
        sessions.append(session)
    }

    public var total: Int {
        sessions.filter(\.done).map(\.minutes).reduce(0, +)
    }

    public var remaining: Int { max(goal - total, 0) }
}
```

```
ana@vm:~/sw/l18/planner$ swift test --disable-swift-testing 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[2 / 9] PlannerCore
[5 / 11] PlannerCore
[9 / 12] PlannerCoreTests-product
[13 / 15] PlannerCoreTests-test-runner
[16 / 16] PlannerCoreTests-test-runner
Build complete! (1.36 secs)
Test Suite 'All tests' started at 2026-10-30 15:26:23.628
Test Suite 'Debug-linux-x86_64.xctest' started at 2026-10-30 15:26:23.629
Test Suite 'WeekXCTests' started at 2026-10-30 15:26:23.629
Test Case 'WeekXCTests.testRemainingNeverGoesBelowZero' started at 2026-10-30 15:26:23.629
Test Case 'WeekXCTests.testRemainingNeverGoesBelowZero' passed (0.001 seconds)
Test Case 'WeekXCTests.testTotalCountsOnlyDoneSessions' started at 2026-10-30 15:26:23.631
Test Case 'WeekXCTests.testTotalCountsOnlyDoneSessions' passed (0.0 seconds)
Test Suite 'WeekXCTests' passed at 2026-10-30 15:26:23.631
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'Debug-linux-x86_64.xctest' passed at 2026-10-30 15:26:23.631
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'All tests' passed at 2026-10-30 15:26:23.631
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
```

`XCTAssertEqual` is one of a family: `XCTAssertTrue`, `XCTAssertNil`, `XCTAssertThrowsError` and a
dozen more, each a function with its own name for its own kind of check. That family is the main
thing Swift Testing set out to replace, as section 03 shows.
