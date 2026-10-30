---
title: A module is the boundary that counts
version: 1
---

A **module** is a unit of code compiled together and imported by name: the standard library is the
module `Swift`, Apple's frameworks are modules called `Foundation` and `SwiftUI`, and every target
of a Swift package is a module of its own. **The default level, `internal`, stops at the module's
edge.** Section 02 never met that edge, because both files went into one program. This section
splits the planner into two modules and watches the edge appear.

Lesson 19 is about packages properly. For now, a package is a directory with a `Package.swift`
describing it and a `Sources` directory holding one subdirectory per module. This one has two: a
library, `PlannerCore`, which holds the planner's types, and an executable, `plan`, which uses them.

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "planner",
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(name: "plan", dependencies: ["PlannerCore"]),
    ]
)
```

The library's one file declares a week with nothing marked:

```swift
// Sources/PlannerCore/Week.swift
struct Week {
    var minutes: [Int] = []
    var total: Int { minutes.reduce(0, +) }
}
```

and the executable imports the library and uses it:

```swift
// Sources/plan/main.swift
import PlannerCore

var week = Week()
week.minutes.append(45)
print(week.total)
```

`swift build` builds every module of the package. When a build fails it prints, before the error,
the entire command it gave the compiler, one line of about 2,500 characters. **Every package
transcript in this course passes the output through `grep -v frontend`**, which drops that line and
the line announcing it, and keeps everything else:

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Pre-planning 1 / 95]
[Constructing 1 / 192]
[25 / 37] PlannerCore
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/planner/Sources/plan/main.swift:4:12: error: cannot find 'Week' in scope
2 | import PlannerCore
3 | 
4 | var week = Week()
  |            `- error: cannot find 'Week' in scope
5 | week.minutes.append(45)
6 | print(week.total)
error: Build failed
```

**`cannot find 'Week' in scope`, in a file that imports the module `Week` lives in.** `Week` is
`internal`, so outside `PlannerCore` it does not exist at all; the compiler cannot even say that it
is hidden, because from `plan` there is nothing to see. The lines in brackets before the error are
the build's progress, and their numbers change from one run to the next.

## public, and the initialiser nobody wrote

Mark the struct and its two members `public`:

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public var minutes: [Int] = []
    public var total: Int { minutes.reduce(0, +) }
}
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[6 / 13] PlannerCore
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/planner/Sources/plan/main.swift:4:12: error: 'Week' initializer is inaccessible due to 'internal' protection level
2 | import PlannerCore
3 | 
4 | var week = Week()
  |            `- error: 'Week' initializer is inaccessible due to 'internal' protection level
5 | week.minutes.append(45)
6 | print(week.total)

PlannerCore.Week.init:2:10: note: 'init()' declared here
1 | struct Week {
2 | internal init()}
  |          `- note: 'init()' declared here
3 | 
error: Build failed
```

The type is visible now, and something else is not. **A struct's memberwise initialiser, the one
Swift writes for you, is `internal`**, whatever the struct is marked. The note shows it: the compiler
prints the declaration it generated, `internal init()`, in a file that does not exist, named after
the type. The rule is deliberate: making a type public should not also publish a way to build it
that you never wrote and might want to change. **A public type that other modules create needs a
public `init` written by hand:**

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public var minutes: [Int] = []
    public var total: Int { minutes.reduce(0, +) }

    public init() {}
}
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[7 / 14] plan-product
[10 / 16] PlannerCore
[14 / 17] plan-product
[18 / 18] plan-product
Build complete! (3.57 secs)
ana@vm:~/sw/l17/planner$ .build/debug/plan
45
```

The build succeeded, and `.build/debug/plan` is where `swift build` leaves the executable.

## What public costs

Everything marked `public` is a promise to every module that imports yours. Inside the module you
can rename `minutes` and fix every use in the same commit; outside, somebody else's code depends on
the name, and renaming it breaks a build you cannot see. **So `public` is decided member by member,
not type by type**, and the compiler's default of `internal` is the safe starting point: a library
publishes only what somebody wrote `public` on.

That is also why the same planner, built as one module in an app, needs none of these words: an
app's code is all `internal`, all in one module, and nobody imports it. Access levels start to
matter at the first `import` of your own code, which in the iOS app of `ios-apps` happens as soon as
the model moves into a package of its own.
