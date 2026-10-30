---
title: package, between internal and public
version: 1
---

The planner package has two modules, and some code in one is meant for the other and for nobody
else: a debugging summary that `plan` prints and that no outside user of the library should come to
depend on. `internal` is too narrow, because `plan` is a different module. `public` is too wide,
because every package that imports `PlannerCore` would get it. **`package`, added in Swift 5.9, is
the level in between: visible to every module of the same package, and to nothing outside it.**

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public private(set) var minutes: [Int] = []
    public var total: Int { minutes.reduce(0, +) }

    public init() {}

    public mutating func add(_ session: Int) {
        guard session > 0 else { return }
        minutes.append(session)
    }

    package func summary() -> String {
        "\(minutes.count) sessions, \(total) minutes"
    }
}
```

`plan`, in the same package, uses it:

```swift
// Sources/plan/main.swift
import PlannerCore

var week = Week()
week.add(45)
week.add(60)
print(week.summary())
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[3 / 6] PlannerCore
[7 / 8] PlannerCore
[14 / 17] plan-product
[18 / 18] plan-product
Build complete! (1.06 secs)
ana@vm:~/sw/l17/planner$ .build/debug/plan
2 sessions, 105 minutes
```

## From another package

A second package, `report`, sits beside `planner` in the same directory and depends on it by path,
the way a package uses a library on the same disk:

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "report",
    dependencies: [
        .package(path: "../planner"),
    ],
    targets: [
        .executableTarget(
            name: "report",
            dependencies: [.product(name: "PlannerCore", package: "planner")]
        ),
    ]
)
```

```swift
// Sources/report/main.swift
import PlannerCore

var week = Week()
week.add(45)
print(week.summary())
```

```
ana@vm:~/sw/l17/report$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Constructing description]
[Planning deferred tasks]
[25 / 36] PlannerCore
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/report/Sources/report/main.swift:6:12: error: 'summary' is inaccessible due to 'package' protection level
4 | var week = Week()
5 | week.add(45)
6 | print(week.summary())
  |            `- error: 'summary' is inaccessible due to 'package' protection level
7 | 

/home/ana/sw/l17/planner/Sources/PlannerCore/Week.swift:13:18: note: 'summary()' declared here
11 |     }
12 | 
13 |     package func summary() -> String {
   |                  `- note: 'summary()' declared here
14 |         "\(minutes.count) sessions, \(total) minutes"
15 |     }
error: Build failed
```

Same call, same library, and this time it is refused: `'summary' is inaccessible due to 'package'
protection level`. **The boundary is the package**, the directory with one `Package.swift`, and
`report` has its own. Everything public from section 04 still works from `report`; only the name
meant for the planner's own modules is held back.

## Where package earns its place

Before Swift 5.9 the only way to share code between two modules of one package was `public`, and
a large package published dozens of names its users were never meant to call, often with a comment
asking them not to. **`package` turns that comment into a rule the compiler enforces.** It suits
test helpers shared between targets, a shared logger, and the plumbing between a library and the
command-line tool beside it, which is exactly the shape lesson 19's package takes.

That completes the six levels, and one rule holds them together: **nothing can be used from further
away than the things it mentions**. A member of an `internal` type is never usable outside the
module, whatever its own keyword says, and a `public` function may not take or return an `internal`
type, because a caller outside the module could not name it. The compiler refuses that declaration
rather than publish half of it.
