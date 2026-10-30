---
title: Swift Testing, with one macro for every check
version: 1
---

XCTest gives every kind of check a function of its own, and each function has to be told what it
is comparing. **Swift Testing has one check, `#expect`, and it takes an ordinary Swift expression**:
`#expect(week.total == 45)`. When the expression is false, the framework prints the expression and
the value of every part of it, so a failure explains itself without an assertion message. It
arrived with Swift 6 in 2024, ships in the same toolchain, and runs in the same `swift test`.

The planner gains a percentage, for the bar a screen will draw:

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

    public var progress: Int { total / goal * 100 }
}
```

and the tests are written in the new framework, in a file of their own in the same test target:

```schooling-example
{"language": "swift", "file": "Tests/PlannerCoreTests/WeekTests.swift", "parts": [
{"code": "import Testing\n@testable import PlannerCore", "note": "The module is `Testing`. Both frameworks can live in one test target, and `swift test` runs both."},
{"code": "@Suite(\"A week of study\")\nstruct WeekTests {", "note": "A suite is any type holding tests, here a struct. `@Suite` is optional and gives it a name for the output. Each test gets a fresh instance, so no test sees another's leftovers."},
{"code": "    @Test(\"Only finished sessions count\")\n    func total() {\n        var week = Week()\n        week.add(StudySession(course: \"swift\", minutes: 45, done: true))\n        week.add(StudySession(course: \"swift\", minutes: 30))\n        #expect(week.total == 45)\n    }", "note": "A test is any function marked `@Test`; the name no longer has to start with `test`, and the string is how the output names it."},
{"code": "    @Test(\"Progress is a percentage of the goal\")\n    func progress() {\n        var week = Week()\n        week.add(StudySession(course: \"swift\", minutes: 45, done: true))\n        #expect(week.progress == 15)\n    }", "note": "45 minutes of a 300-minute goal is 15%."},
{"code": "    @Test func firstSessionIsTheOneAdded() throws {\n        var week = Week()\n        week.add(StudySession(course: \"kotlin\", minutes: 20))\n        let first = try #require(week.sessions.first)\n        #expect(first.course == \"kotlin\")\n    }\n}", "note": "`#require` is `#expect` that stops the test when it fails. Given an optional it hands back the unwrapped value, so the next line works with a plain `StudySession`; given `nil` it records the failure and throws, which is why the test is marked `throws`."}
]}
```

`swift test --disable-xctest` runs only this framework's tests:

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest 2>&1 | grep -v frontend
Building for debugging...
[Provisioning 4 / 4]
[Planning 1 / 95]
[Planning deferred tasks]
[6 / 20] PlannerCore
[14 / 26] PlannerCore
[16 / 26] PlannerCoreTests-product
[19 / 25] PlannerCoreTests-product
[23 / 26] PlannerCoreTests-product
[27 / 29] PlannerCoreTests-test-runner
[28 / 30] PlannerCoreTests-test-runner
[31 / 31] PlannerCoreTests-test-runner
Build complete! (2.18 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite "A week of study" started.
◇ Test "Only finished sessions count" started.
◇ Test firstSessionIsTheOneAdded() started.
◇ Test "Progress is a percentage of the goal" started.
✔ Test "Only finished sessions count" passed after 0.001 seconds.
✔ Test firstSessionIsTheOneAdded() passed after 0.001 seconds.
✘ Test "Progress is a percentage of the goal" recorded an issue at WeekTests.swift:16:9: Expectation failed: week.progress == 15
↳ week.progress == 15 → false
↳   week.progress → 0
✘ Test "Progress is a percentage of the goal" failed after 0.001 seconds with 1 issue.
✘ Suite "A week of study" failed after 0.001 seconds with 1 issue.
✘ Test run with 3 tests in 1 suite failed after 0.001 seconds with 1 issue.
Note: Some test targets reported failures:
  - PlannerCoreTests (Swift Testing)
```

**The failure prints the expression, then the value of each piece of it**: `week.progress == 15`
was false because `week.progress` was `0`. Nothing in the test asked for that second line;
`#expect` is a **macro**, which lesson 16 described from the outside, and at compile time it
rewrote the comparison into code that records both sides. The cause is lesson 1's integer division:
`45 / 300` is 0, and 0 times 100 is still 0.

The symbols at the start of each line are the framework's: `◇` a test or suite that started, `✔`
one that passed, `✘` one that failed, and `↳` a detail of the line above. The tests ran **in
parallel**, which is Swift Testing's default, so their lines interleave and their order changes
from run to run. A test that depends on running after another is a test with a bug in it, and
parallel running finds those.

Multiply before dividing:

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

    public var progress: Int { total * 100 / goal }
}
```

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[2 / 7] PlannerCore
[5 / 11] PlannerCore
[9 / 12] PlannerCoreTests-product
[13 / 15] PlannerCoreTests-test-runner
[16 / 16] PlannerCoreTests-test-runner
Build complete! (1.66 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite "A week of study" started.
◇ Test "Only finished sessions count" started.
◇ Test "Progress is a percentage of the goal" started.
◇ Test firstSessionIsTheOneAdded() started.
✔ Test "Only finished sessions count" passed after 0.001 seconds.
✔ Test "Progress is a percentage of the goal" passed after 0.001 seconds.
✔ Test firstSessionIsTheOneAdded() passed after 0.001 seconds.
✔ Suite "A week of study" passed after 0.001 seconds.
✔ Test run with 3 tests in 1 suite passed after 0.001 seconds.
```

## The differences that matter

| | XCTest | Swift Testing |
|---|---|---|
| a test is | a method named `test…` in an `XCTestCase` subclass | any function marked `@Test` |
| a check is | one of a family of `XCTAssert…` functions | `#expect(expression)`, or `#require` to stop |
| a failure shows | the two values you passed | the expression and every value in it |
| runs | one after another, unless asked | in parallel, unless asked |
| arguments | none; one method per case | `@Test(arguments:)`, section 04 |

**New tests in this course are written with Swift Testing**, and XCTest stays worth reading: most
iOS projects written before 2024 use it throughout, and the tests that drive an app's screens, which
`ios-apps` meets, are written with XCTest's UI testing classes.
