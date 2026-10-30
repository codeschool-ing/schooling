---
title: What runs here, and where the wall is
version: 1
---

**SwiftData does not build on Linux, and the compiler on this course's machine says so in one line.**
The two pieces a query is made of do run, because they are not SwiftData's: `#Predicate` and
`SortDescriptor` belong to Foundation, which ships with Swift on every platform. This section shows
both: the wall, and the part of the query that is on this side of it.

## The wall

Save this one line as `swiftdata.swift`, in a directory `~/l13`, and run it:

```swift
// swiftdata.swift
import SwiftData
```

```
ana@vm:~/l13$ swift swiftdata.swift
swiftdata.swift:2:8: error: no such module 'SwiftData'
1 | // swiftdata.swift
2 | import SwiftData
  |        `- error: no such module 'SwiftData'
3 | 
```

`no such module` is the compiler looking for the framework among the modules it was given and finding
nothing. On a Mac with Xcode the same file compiles, because SwiftData is in the macOS and iOS SDKs.
**There is no package to install that changes this**, which is why everything in this lesson outside
this section is read.

## A query's parts, on lesson 1's values

`@Query(filter:sort:)` takes a `Predicate` and a sort, and both can be built and evaluated against
plain values. Use lesson 1's package again, in `~/l13`: copy its five files, and replace `Package.swift`
with this one, which adds a program called `query`:

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
        .executableTarget(name: "query", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

Save this as `Sources/query/main.swift`. Its sessions are lesson 1's five, after `week` added `s5` and
marked it done:

```swift
// Sources/query/main.swift
import Foundation
import PlannerCore

let sessions = [
    StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true),
    StudySession(id: "s2", courseID: "mobile", date: "2026-10-20", minutes: 40, done: true),
    StudySession(id: "s3", courseID: "sql", date: "2026-10-23", minutes: 60),
    StudySession(id: "s4", courseID: "mobile", date: "2026-10-27", minutes: 45),
    StudySession(id: "s5", courseID: "mobile", date: "2026-10-22", minutes: 30, done: true),
]

// What a course's screen asks for: its sessions, latest first
let course = "mobile"
let ofCourse = #Predicate<StudySession> { $0.courseID == course }
let latestFirst = SortDescriptor(\StudySession.date, order: .reverse)
print(try sessions.filter(ofCourse).sorted(using: latestFirst).map(\.id))

// And what the week screen asks for: everything not done yet, in any course
let toDo = #Predicate<StudySession> { !$0.done }
print(try sessions.filter(toDo).sorted(using: latestFirst).map { "\($0.id) \($0.date) \($0.minutes) min" })

// Days are YYYY-MM-DD text, so a range of them is a comparison of strings
let week = #Predicate<StudySession> { $0.date >= "2026-10-19" && $0.date <= "2026-10-25" }
print(try sessions.filter(week).map(\.id))
```

```
ana@vm:~/l13$ swift build
Building for debugging...
[Constructing description]
[Planning deferred tasks]
[30 / 46] PlannerCore
[40 / 52] query-product
[43 / 52] week-product
[46 / 53] PlannerCore
[52 / 55]
[55 / 55] query-product
Build complete! (5.34 secs)
ana@vm:~/l13$ .build/debug/query
["s4", "s5", "s2"]
["s4 2026-10-27 45 min", "s3 2026-10-23 60 min"]
["s1", "s2", "s3", "s5"]
```

**These are the predicates section 04's screens hand to SwiftData**, written against `StudySession`
instead of `SessionRecord`. The mobile course's sessions come back latest first, `s4`, `s5`, `s2`; the
two not done, `s4` and `s3`, come from both courses. The third line is lesson 1's choice paying off a
second time: because a day is `YYYY-MM-DD` text, "this week" is two string comparisons, which a store
can answer without calling any code of yours.

## The predicate that is refused

The planner already knows how to find a week: lesson 1's `mondayOf`. It is tempting to filter by it.
The `echo` below adds one that does to the end of `Sources/query/main.swift`, and the `grep` keeps the
one line of the compiler's long report that says why:

```
ana@vm:~/l13$ echo 'let thisWeek = #Predicate<StudySession> { mondayOf($0.date) == "2026-10-19" }' >> Sources/query/main.swift
ana@vm:~/l13$ swift build 2>&1 | grep -m1 "Global functions"
/home/ana/l13/Sources/query/main.swift:26:43: error: Global functions are not supported in this predicate (from macro 'Predicate')
ana@vm:~/l13$ sed -i '$d' Sources/query/main.swift
ana@vm:~/l13$ swift build 2>&1 | tail -1
Build complete! (0.87 secs)
```

**The refusal comes at compile time**, from the macro, before anything runs. A predicate has to be
describable to a store that knows nothing of Swift functions, so a call to one of your own is rejected
where it is written, in the words above. Inside SwiftData the same rule holds, with the same macro, and
the honest fix is the one the third line of the output already used: compare the stored text, and work
out the two days in ordinary Swift before building the predicate.

`sed -i '$d'` deletes the last line of the file again, so the package builds.
