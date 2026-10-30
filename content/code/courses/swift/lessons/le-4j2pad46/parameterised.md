---
title: One test, many cases
version: 1
---

The progress test of section 03 checks one week: 45 minutes, 15%. The interesting weeks are the
edges: nothing done, the goal met exactly, the goal passed. The XCTest way is one method per case,
four methods that differ in two numbers. **Swift Testing takes the cases as arguments**, and runs
the same function once for each:

```swift
// Tests/PlannerCoreTests/ProgressTests.swift
import Testing
@testable import PlannerCore

@Suite struct ProgressTests {
    @Test("Progress for a 300-minute goal", arguments: [
        (0, 0),
        (45, 15),
        (300, 100),
        (450, 100),
    ])
    func progress(minutes: Int, expected: Int) {
        var week = Week()
        week.add(StudySession(course: "swift", minutes: minutes, done: true))
        #expect(week.progress == expected)
    }
}
```

Each element of `arguments` is one **test case**, and a tuple of two values fills the function's two
parameters in order. `--filter` runs only the tests whose name matches what follows it, here the
suite's:

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest --filter ProgressTests 2>&1 | grep -v frontend
Building for debugging...
[Pre-planning 1 / 95]
[Planning deferred tasks]
[6 / 16] PlannerCoreTests-product
[13 / 16] PlannerCoreTests-product
[17 / 19] PlannerCoreTests-test-runner
[20 / 20] PlannerCoreTests-test-runner
Build complete! (1.90 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite ProgressTests started.
◇ Test "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 0, expected → 0 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 45, expected → 15 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 300, expected → 100 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 450, expected → 100 to "Progress for a 300-minute goal" started.
✘ Test "Progress for a 300-minute goal" recorded an issue with 2 arguments minutes → 450, expected → 100 at ProgressTests.swift:15:9: Expectation failed: week.progress == expected
↳ week.progress == expected → false
↳   week.progress → 150
↳   expected → 100
✘ Test "Progress for a 300-minute goal" with 4 test cases failed after 0.001 seconds with 1 issue.
✘ Suite ProgressTests failed after 0.001 seconds with 1 issue.
✘ Test run with 1 test in 1 suite failed after 0.001 seconds with 1 issue.
Note: Some test targets reported failures:
  - PlannerCoreTests (Swift Testing)
```

**Three cases passed and one failed, and the failure names its arguments**: `minutes → 450,
expected → 100`, and below them `week.progress → 150`. The test claimed that a student who studied
450 minutes is at 100%, and the code says 150%. Neither is wrong as arithmetic, and that
is the point of an edge case: it makes you decide. A progress bar that runs off its track is the
wrong picture of a good week, so the planner caps it:

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

    public var progress: Int { min(total * 100 / goal, 100) }
}
```

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest --filter ProgressTests 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[2 / 7] PlannerCore
[5 / 11] PlannerCore
[9 / 12] PlannerCoreTests-product
[13 / 15] PlannerCoreTests-test-runner
[14 / 16] PlannerCoreTests-test-runner
[16 / 16] PlannerCoreTests-test-runner
Build complete! (1.54 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite ProgressTests started.
◇ Test "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 0, expected → 0 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 45, expected → 15 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 300, expected → 100 to "Progress for a 300-minute goal" started.
◇ Test case passing 2 arguments minutes → 450, expected → 100 to "Progress for a 300-minute goal" started.
✔ Test "Progress for a 300-minute goal" with 4 test cases passed after 0.003 seconds.
✔ Suite ProgressTests passed after 0.008 seconds.
✔ Test run with 1 test in 1 suite passed after 0.008 seconds.
```

Four cases, one function, and the summary counts them: `with 4 test cases passed`.

## Cases as data, and how they combine

Arguments can be any collection whose elements the framework can describe, and the cases can be run
on their own. Two details are worth knowing before writing many:

- **One collection, one parameter, or a tuple per case**, as above. The tuple keeps each input next
  to its expected output, which is how a reader checks the table.
- **Two collections make every combination.** `arguments: [0, 45], [60, 300]` with two parameters
  runs four cases, each value of the first with each value of the second. When the two lists are
  meant to go together in pairs, `zip(minutesList, expectedList)` passes the pairs instead.

**A case that fails is still only one case**: the other three ran, passed and were reported, and
the failure says which inputs broke. A single XCTest method looping over the same table would run
every row too, and its failure would name the line of the assertion and not the row, leaving you
to work out which pair of numbers was the problem.
