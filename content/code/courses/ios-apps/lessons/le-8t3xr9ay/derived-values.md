---
title: Compute it, do not store it
version: 1
---

**A value that can be computed from the source of truth is a second source of truth if you store
it.** It agrees on the day it is written and disagrees the first time a change reaches one and not
the other. In SwiftUI the computed version costs nothing extra: `body` runs again after every change
to state it read, so a total computed inside it, or in a computed property it reads, is always the
total of the plan on screen.

This runs on any computer, because the question is about Swift structs and not about SwiftUI. Copy lesson 1's
package into a directory of its own, `cp -r ~/planner ~/derived`, and add a test file beside lesson
1's. Save this as `Tests/PlannerCoreTests/DerivedTests.swift`:

```swift
// Tests/PlannerCoreTests/DerivedTests.swift
import Testing
@testable import PlannerCore

func samplePlan() -> Plan {
    Plan(
        courses: [Course(id: "sql", title: "SQL Databases"), Course(id: "mobile", title: "Mobile Fundamentals")],
        sessions: [
            StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true),
            StudySession(id: "s2", courseID: "mobile", date: "2026-10-20", minutes: 40, done: true),
            StudySession(id: "s3", courseID: "sql", date: "2026-10-23", minutes: 60),
        ]
    )
}

struct StoredTotal {
    var plan: Plan
    var total: WeekTotal

    init(plan: Plan) {
        self.plan = plan
        self.total = plan.weekTotal(today: "2026-10-21")
    }
}

struct DerivedTotal {
    var plan: Plan
    var total: WeekTotal { plan.weekTotal(today: "2026-10-21") }
}

@Test func aStoredTotalFollowsThePlan() throws {
    var screen = StoredTotal(plan: samplePlan())
    try screen.plan.markDone("s3")
    #expect(screen.total.done == 150)
}

@Test func aDerivedTotalFollowsThePlan() throws {
    var screen = DerivedTotal(plan: samplePlan())
    try screen.plan.markDone("s3")
    #expect(screen.total.done == 150)
}
```

`StoredTotal` is the first draft somebody writes when they think of a screen as a place that holds
numbers: work the total out once, keep it. `DerivedTotal` keeps only the plan and computes the total
whenever it is asked. Both tests mark `s3` done and expect 150 minutes, the 50 and 40 already done
plus its 60. **One of them fails, on purpose:**

```
ana@vm:~/derived$ swift test --filter TotalFollows
Building for debugging...
[Pre-planning 1 / 153]
[Starting]
Build complete! (0.67 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test aStoredTotalFollowsThePlan() started.
◇ Test aDerivedTotalFollowsThePlan() started.
✔ Test aDerivedTotalFollowsThePlan() passed after 0.001 seconds.
✘ Test aStoredTotalFollowsThePlan() recorded an issue at DerivedTests.swift:34:5: Expectation failed: screen.total.done == 150
↳ screen.total.done == 150 → false
↳   screen.total.done → 90
✘ Test aStoredTotalFollowsThePlan() failed after 0.001 seconds with 1 issue.
✘ Test run with 2 tests in 0 suites failed after 0.002 seconds with 1 issue.
Note: Some test targets reported failures:
  - PlannerCoreTests (Swift Testing)
```

`--filter TotalFollows` runs only the two tests whose names contain those words. Swift Testing says
which expectation failed, at which line, and **what the left-hand side actually was: 90**, the total
from before `s3` was marked. Nothing is wrong with the arithmetic; the stored number was simply never
told. In a SwiftUI view the same mistake looks like a screen whose list shows three sessions ticked
and whose footer still says 90.

Delete `StoredTotal` and its test once you have seen it fail. The rule it leaves is the one lesson 7
keeps for the observable model: **store what the person did, and compute what follows from it.**
