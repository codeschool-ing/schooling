---
title: Language modes, and turning the checks on
version: 1
---

Everything this lesson refused, it refused in the **Swift 6 language mode**. The same compiler has a
**Swift 5 mode**, and section 02 showed what that costs: `Race.swift` compiled without a word and
counted wrong. **The language mode is a setting of the compiler, not a version of it.** Swift 6.4.2
compiles both, and which one applies is decided per module.

| how you compile | language mode, unless you say otherwise |
|---|---|
| `swift File.swift` or `swiftc File.swift` | Swift 5 |
| `swiftc -swift-version 6 File.swift` | Swift 6 |
| a package whose manifest starts `// swift-tools-version: 6.0` or later | Swift 6, for every target |
| a package at tools version 5.x | Swift 5 |

The modes exist because Swift 6's checks would refuse a great deal of code written before them, and
a project of thousands of files cannot be fixed in one afternoon. So a project moves when it is ready,
one module at a time.

## A package decides for you

Lesson 19 is about packages; here is the smallest one, holding `Race.swift`'s code as its `main.swift`.
Its manifest declares tools version 6.0:

```swift
// swift-tools-version: 6.0
// Package.swift
import PackageDescription

let package = Package(
    name: "Race",
    targets: [
        .executableTarget(name: "Race")
    ]
)
```

```swift
// Sources/Race/main.swift
final class WeekTotal {
    var minutes = 0
    func add(_ m: Int) { minutes += m }
}

func countWeek() async -> Int {
    let week = WeekTotal()
    await withTaskGroup(of: Void.self) { group in
        for _ in 1...8 {
            group.addTask {
                for _ in 1...100_000 {
                    week.add(1)
                }
            }
        }
    }
    return week.minutes
}

for _ in 1...3 {
    print("expected 800000, got \(await countWeek())")
}
```

```
ana@vm:~/sw/l15/race$ swift build 2>&1 | grep -E '^/[^ ]+[.]swift:|^error: Build|^Build'
Building for debugging...
/home/ana/sw/l15/race/Sources/Race/main.swift:11:19: error: passing closure as a 'sending' parameter risks causing data races between code in the current isolation context and concurrent execution of the closure [#RegionIsolation::SendingClosureRisksDataRace]
error: Build failed
```

`swift build` prints a great deal, including the whole command line of the compiler that failed, so
the `grep` keeps the two kinds of line worth reading: those that start with a path to a `.swift` file,
which are diagnostics, and the verdict. **The same error as section 02, with nobody asking for it**,
because tools version 6.0 means Swift 6 mode.

A target that is not ready can be held back, in the manifest, where everybody sees it:

```swift
// swift-tools-version: 6.0
// Package.swift
import PackageDescription

let package = Package(
    name: "Race",
    targets: [
        .executableTarget(
            name: "Race",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
```

```
ana@vm:~/sw/l15/race$ swift build 2>&1 | grep -E '^/[^ ]+[.]swift:|^error: Build|^Build'
Building for debugging...
Build complete! (1.51 secs)
ana@vm:~/sw/l15/race$ swift run Race 2>/dev/null
expected 800000, got 547351
expected 800000, got 431104
expected 800000, got 719980
```

It builds, it runs, and it is wrong again. **`.swiftLanguageMode(.v5)` is a debt written down**: a
target that says it has not yet been checked. Moving it to Swift 6 means removing the line and fixing
what the compiler then reports, which is the work this lesson has been showing.

## What `swift package init` turns on

`swift package init`, the command lesson 19 starts every package with, writes a manifest of its own,
and it carries one more setting than the manifests above:

```
ana@vm:~/sw/l15/week$ swift package init --type library --name Week
Creating library package: Week
Creating Package.swift
Creating .gitignore
Creating Sources
Creating Sources/Week/Week.swift
Creating Tests/
Creating Tests/WeekTests/
Creating Tests/WeekTests/WeekTests.swift
ana@vm:~/sw/l15/week$ grep -n -A2 swiftSettings Package.swift
20:            swiftSettings: [
21-                .enableUpcomingFeature("ApproachableConcurrency"),
22-            ],
--
27:            swiftSettings: [
28-                .enableUpcomingFeature("ApproachableConcurrency"),
29-            ],
ana@vm:~/sw/l15/week$ head -1 Package.swift
// swift-tools-version: 6.4
```

The manifest is at tools version 6.4, so its targets are in Swift 6 mode, and each target also has
`.enableUpcomingFeature("ApproachableConcurrency")`. An **upcoming feature**
is a change planned for a future language mode that a module can adopt early, one name at a time.
`ApproachableConcurrency` is a bundle of several, added in Swift 6.2, that change some defaults so that
code which runs on one actor needs fewer annotations. It does not switch any check off: a race is
still an error. When a manifest of yours carries it, the language is the Swift 6 mode with those
defaults, and the Swift documentation on concurrency lists what each of the features does.

**What to do with all of this.** Write new code in the Swift 6 mode, which a package at tools version 6
or later gives you without asking. Keep `-swift-version 6` on the command
line when you try a concurrent program with `swiftc`. And read a Swift 6 concurrency error the way
this lesson did: it names what crosses, from where to where, and what else can still reach it.
