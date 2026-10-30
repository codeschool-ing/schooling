---
title: The decision, as plain Swift you can test
version: 1
---

**The phase is SwiftUI's; what the planner does about it is the planner's.** `ScenePhase` lives in
SwiftUI, so it cannot be compiled on Linux. The decision it drives can be, if it is written against
a type of the planner's own: three phases, and three things the planner may do when the phase
changes. That decision then goes into the package from lesson 1, where `swift test` can hold it.

Two rules come from Apple's documentation for managing an app's life cycle. **Leaving the active
phase means save**: the documentation says to save data upon leaving the foreground-active state,
and from the background iOS may end the process without another word. **Coming back to active after
the background means refresh**, because the day may have changed while the app was away and with it
the week the totals belong to. A banner pulled down over the app makes it inactive for a moment:
saving then is a short write and harmless, and refreshing would be waste.

## A first attempt, and the test that catches it

The obvious version reads only the phase it is moving to. Save this as
`Sources/PlannerCore/Lifecycle.swift` in the `planner` package from lesson 1:

```swift
// Sources/PlannerCore/Lifecycle.swift
/// The three phases SwiftUI reports for a scene, as a type of the planner's
/// own, so the decision can be tested without SwiftUI.
public enum Phase: Sendable {
    case active, inactive, background
}

public enum PhaseAction: Equatable, Sendable {
    case nothing
    case save     // the app may not come back from the background
    case refresh  // the day, and the week, may have changed while it was away
}

public struct Lifecycle: Sendable {
    public private(set) var phase: Phase

    public init(phase: Phase) {
        self.phase = phase
    }

    public mutating func move(to new: Phase) -> PhaseAction {
        defer { phase = new }
        switch (phase, new) {
        case (.active, .inactive), (.active, .background):
            return .save
        case (_, .active):
            return .refresh
        default:
            return .nothing
        }
    }
}
```

And the two journeys a phone actually takes, as tests. Save this as
`Tests/PlannerCoreTests/LifecycleTests.swift`:

```swift
// Tests/PlannerCoreTests/LifecycleTests.swift
import Testing
@testable import PlannerCore

/// Start active, move through `phases`, and return what each move decided.
func replay(_ phases: [Phase]) -> [PhaseAction] {
    var life = Lifecycle(phase: .active)
    return phases.map { life.move(to: $0) }
}

@Test func aBannerSavesAndDoesNotRefresh() {
    #expect(replay([.inactive, .active]) == [.save, .nothing])
}

@Test func goingHomeSavesOnceAndComingBackRefreshes() {
    #expect(replay([.inactive, .background, .inactive, .active])
            == [.save, .nothing, .nothing, .refresh])
}
```

```
ana@vm:~/l02/planner$ swift test 2>&1 | grep -v "^\[" | grep -v "^Test Suite\|Executed 0 tests"
Building for debugging...
Build complete! (3.15 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test aBannerSavesAndDoesNotRefresh() started.
◇ Test mondayIsTheStartOfTheWeek() started.
◇ Test goingHomeSavesOnceAndComingBackRefreshes() started.
◇ Test aSessionForNoCourseIsRefused() started.
✔ Test goingHomeSavesOnceAndComingBackRefreshes() passed after 0.001 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.001 seconds.
✘ Test aBannerSavesAndDoesNotRefresh() recorded an issue at LifecycleTests.swift:12:5: Expectation failed: replay([.inactive, .active]) == [.save, .nothing]
↳ replay([.inactive, .active]) == [.save, .nothing] → false
↳   replay([.inactive, .active]) → [PlannerCore.PhaseAction.save, PlannerCore.PhaseAction.refresh]
↳   [.save, .nothing] → [PlannerCore.PhaseAction.save, PlannerCore.PhaseAction.nothing]
✔ Test mondayIsTheStartOfTheWeek() passed after 0.001 seconds.
✘ Test aBannerSavesAndDoesNotRefresh() failed after 0.001 seconds with 1 issue.
✘ Test run with 4 tests in 0 suites failed after 0.001 seconds with 1 issue.
Note: Some test targets reported failures:
  - PlannerCoreTests (Swift Testing)
```

The two `grep`s drop the build's progress lines and the empty XCTest report lesson 1 explained, so
what is left is Swift Testing's own report.

**The failure names the expression, its two sides and the line.** The banner test expected
`.nothing` second and got `.refresh`, because the first version refreshes on every return to active,
and a banner is a return to active. The journey home passed, which is the trap: the code is
right for the case its author pictured and wrong for the commoner one.

## The version that remembers

What was missing is a fact about the past: whether the scene went to the background since it was
last active. Replace `Sources/PlannerCore/Lifecycle.swift` with this:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/Lifecycle.swift", "parts": [{"code": "// Sources/PlannerCore/Lifecycle.swift\n/// The three phases SwiftUI reports for a scene, as a type of the planner's\n/// own, so the decision can be tested without SwiftUI.\npublic enum Phase: Sendable {\n    case active, inactive, background\n}\n\npublic enum PhaseAction: Equatable, Sendable {\n    case nothing\n    case save     // the app may not come back from the background\n    case refresh  // the day, and the week, may have changed while it was away\n}\n", "note": "The same two types. `Phase` mirrors SwiftUI's `ScenePhase` case for case, and section 07 shows the lines that turn one into the other."}, {"code": "public struct Lifecycle: Sendable {\n    public private(set) var phase: Phase\n    private var wasInBackground = false\n\n    public init(phase: Phase) {\n        self.phase = phase\n    }\n", "note": "One more piece of state, private: whether the background happened since the last time the scene was active. `private(set)` lets a caller read the phase and not set it."}, {"code": "    public mutating func move(to new: Phase) -> PhaseAction {\n        defer { phase = new }\n        if new == .background { wasInBackground = true }\n        switch (phase, new) {\n        case (.active, .inactive), (.active, .background):\n            return .save\n        case (_, .active) where wasInBackground:\n            wasInBackground = false\n            return .refresh\n        default:\n            return .nothing\n        }\n    }\n}\n", "note": "The switch is over the pair, old phase and new. `case (_, .active) where wasInBackground` is a pattern with a condition: any move to active, but only after the background. `defer` sets the new phase after the switch has read the old one."}]}
```

```
ana@vm:~/l02/planner$ swift test 2>&1 | grep -v "^\[" | grep -v "^Test Suite\|Executed 0 tests"
Building for debugging...
Build complete! (1.66 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test goingHomeSavesOnceAndComingBackRefreshes() started.
◇ Test aBannerSavesAndDoesNotRefresh() started.
◇ Test mondayIsTheStartOfTheWeek() started.
◇ Test aSessionForNoCourseIsRefused() started.
✔ Test aBannerSavesAndDoesNotRefresh() passed after 0.001 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.001 seconds.
✔ Test goingHomeSavesOnceAndComingBackRefreshes() passed after 0.001 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.001 seconds.
✔ Test run with 4 tests in 0 suites passed after 0.001 seconds.
```

Four tests, as in the first run, because lesson 1's two are in the same package and run with these. **Nothing in
these files imports SwiftUI**, and that is what let them run here. The app's half, which turns
`ScenePhase` into `Phase` and acts on the answer, is in section 07.
