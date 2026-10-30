---
title: '@Observable: a class SwiftUI can watch'
version: 1
---

**When several screens need the same state, the state moves out of any one view and into an object
they all share.** Lesson 6 kept the plan in `CourseListView`'s `@State` and passed bindings down.
That works for one screen and its children. The planner has four screens, and the week screen sits
beside the course list rather than under it; threading `$plan` through every view between them
would make each one carry a value it never uses.

The tool is the `@Observable` macro, from the **Observation** framework. It arrived with iOS 17,
and it is part of the Swift toolchain rather than of SwiftUI, which means **it runs on Linux**. So
the planner's model can be written, built and watched on any computer, and only the views that read
it need a Mac.

Lesson 6 section 07 showed what goes wrong with an ordinary class in `@State`: a change inside it
reaches nobody. `@Observable` is the cure. It rewrites each stored property of the class so that
reading it records who read it, and writing it tells those readers.

## The model

Add one file to the package, `Sources/PlannerCore/PlannerModel.swift`. Make a copy of lesson 1's
package for this lesson, `cp -r ~/planner ~/observe`, and save it there:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/PlannerModel.swift", "parts": [{"code": "// Sources/PlannerCore/PlannerModel.swift\nimport Observation\n\n@MainActor @Observable\npublic final class PlannerModel {\n    public var plan: Plan\n    public var today: String\n    @ObservationIgnored public var lastSaved: String?\n", "note": "`@Observable` makes `plan` and `today` observable: reading either is recorded, writing either is announced. `@ObservationIgnored` opts `lastSaved` out, for state no screen draws. `@MainActor` says the model is used from the main thread, where SwiftUI's views run, and the Swift 6 compiler holds every caller to it."}, {"code": "    public init(plan: Plan, today: String) {\n        self.plan = plan\n        self.today = today\n    }\n\n    public var week: WeekTotal { plan.weekTotal(today: today) }\n", "note": "The week's total is computed, as lesson 6 section 06 argued. A computed property is not tracked itself; what is tracked is what it reads, `plan` and `today`."}, {"code": "    public func add(_ session: StudySession) throws(PlanError) {\n        try plan.add(session)\n    }\n\n    public func markDone(_ id: String) throws(PlanError) {\n        try plan.markDone(id)\n    }\n}\n", "note": "The changes go through the model, which hands them to lesson 1's `Plan`. The rules stay in the value type and the model only holds it, so the tests from lesson 1 still cover them."}]}
```

**The plan is still a value.** The model holds one `Plan`, and a change to any session assigns a new
`plan` as far as Observation is concerned. That is simple, and section 03 shows what it costs.

The package needs a program to drive the model, so this lesson's manifest has a second executable
target, `track`. Replace `Package.swift` with this; the only new line is the one naming `track`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Planner",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(name: "week", dependencies: ["PlannerCore"]),
        .executableTarget(name: "track", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

`platforms` matters here for the first time. Apple's documentation lists the Observation framework
from iOS 17 and macOS 14, and this line is what promises the compiler that the package never runs on
anything older, so on a Mac it accepts `@Observable` without asking for an availability check. On
Linux the line is still ignored.
