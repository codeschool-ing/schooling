---
title: Targets, and the products other people use
version: 1
---

A **target** is a module the package builds. A **product** is what the package offers to the
outside: an executable somebody can run, or a library another package can depend on, each made of
one or more targets. **Targets are how you organise your code; products are what you promise to
others**, and lesson 17's `report` package could import `PlannerCore` only because the planner
declared it as a product.

The planner gets a manifest written by hand, with both kinds:

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "planner",
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
        .executable(name: "plan", targets: ["plan"]),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(name: "plan", dependencies: ["PlannerCore"]),
    ]
)
```

The tools version is 6.2 rather than the 6.4 `init` wrote, which lets anybody with a Swift 6.2
toolchain or later build the package; nothing in it needs 6.4. The library is lesson 17's week, and
the executable reads minutes from the command line:

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public private(set) var minutes: [Int] = []
    public let goal: Int

    public init(goal: Int = 300) {
        self.goal = goal
    }

    public mutating func add(_ session: Int) {
        minutes.append(session)
    }

    public var total: Int { minutes.reduce(0, +) }
}
```

```swift
// Sources/plan/main.swift
import PlannerCore

var week = Week()
for argument in CommandLine.arguments.dropFirst() {
    if let session = Int(argument) {
        week.add(session)
    }
}
print("\(week.total) of \(week.goal) minutes")
```

`CommandLine.arguments` is the list of words the program was started with, the program's own name
first, which is why `dropFirst()` skips one. `swift package describe` prints what SwiftPM
understood from the manifest, and it is the first thing to look at when a build does something you
did not expect:

```
ana@vm:~/sw/l19/planner$ swift package describe
Name: planner
Manifest display name: planner
Path: /home/ana/sw/l19/planner
Tools version: 6.2
Dependencies:
Platforms:
Products:
    Name: PlannerCore
    Type:
        Library:
            automatic
    Targets:
        PlannerCore

    Name: plan
    Type:
        Executable: nil
    Targets:
        plan

Targets:
    Name: plan
    Type: executable
    C99name: plan
    Module type: SwiftTarget
    Path: Sources/plan
    Sources:
        main.swift
    Target dependencies:
        PlannerCore
    Product memberships:
        plan

    Name: PlannerCore
    Type: library
    C99name: PlannerCore
    Module type: SwiftTarget
    Path: Sources/PlannerCore
    Sources:
        Week.swift
    Product memberships:
        PlannerCore
        plan
```

Read the two lists against each other. The **products** are the two the manifest declared. The
**targets** each have a path, the sources found there, and **product memberships**: `PlannerCore` is
a member of both products, because the executable depends on it and is linked with it. Nothing in
the manifest named a source file. **SwiftPM finds sources by convention**, every `.swift` file under
`Sources/<target name>`, and a file put anywhere else is not part of the build.

```
ana@vm:~/sw/l19/planner$ swift build 2>&1 | tail -1
Build complete! (3.84 secs)
ana@vm:~/sw/l19/planner$ ls .build/debug
PackageFrameworks
PlannerCore.o
PlannerCore.swiftmodule
libPlannerCore.a
plan
ana@vm:~/sw/l19/planner$ .build/debug/plan 45 30 60
135 of 300 minutes
```

`.build/debug/` holds the results: `plan`, the program, and `libPlannerCore.a`, the library as a
static archive that was linked into it. A library product is not a program, and nothing runs it on
its own; it exists for other targets and other packages to link.

## When to split a target

One target is the right size for most small programs. Split when two parts have different
audiences: the model the iOS app and the command-line tool will both use is one target, and each
program on top of it is another. **The split is also a boundary**, and lesson 17 showed what it
costs: everything the second target uses must be `public` or `package` in the first. A split that
forces half a target to become public was in the wrong place.
