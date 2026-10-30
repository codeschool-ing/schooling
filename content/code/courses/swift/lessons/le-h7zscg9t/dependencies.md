---
title: A dependency from GitHub
version: 1
---

`plan` reads its arguments by hand and ignores anything that is not a number. A real command-line
tool has options, a `--help` page and errors that say what was wrong, and writing that well is a
project of its own. **Apple publishes one as a package, `swift-argument-parser`**, and depending on
it is two lines of the manifest.

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
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.0"),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(
            name: "plan",
            dependencies: [
                "PlannerCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
```

The `dependencies` list at the top says **which packages** to fetch, by the address of their git
repository and the versions acceptable. The target's own `dependencies` says **which of their
products** this module uses: a package can offer several, and `ArgumentParser` is the one this
target imports. The two lists are separate because they answer different questions, and forgetting
the second is the usual reason for `no such module 'ArgumentParser'`.

`from: "1.6.0"` means **1.6.0 or anything later before 2.0.0**. Section 05 is about what that
range promises and how it is pinned.

## The program, rewritten

```schooling-example
{"language": "swift", "file": "Sources/plan/Plan.swift", "parts": [
{"code": "import ArgumentParser\nimport PlannerCore", "note": "Two imports: the dependency's product, and the package's own library."},
{"code": "@main\nstruct Plan: ParsableCommand {\n    static let configuration = CommandConfiguration(\n        abstract: \"Add up a week of study sessions.\"\n    )", "note": "The command is a type conforming to `ParsableCommand`, marked `@main` as in section 02. The `abstract` becomes the first line of the help page."},
{"code": "    @Option(help: \"Minutes the week should reach.\")\n    var goal = 300\n\n    @Argument(help: \"The minutes of each session.\")\n    var minutes: [Int]", "note": "Each input is a property with a property wrapper from lesson 16. `@Option` is a named `--goal`, with its default; `@Argument` is positional, and an `[Int]` collects every number given. The parser converts each word to the property's type, or refuses it."},
{"code": "    func run() {\n        var week = Week(goal: goal)\n        for session in minutes {\n            week.add(session)\n        }\n        print(\"\\(week.total) of \\(week.goal) minutes\")\n    }\n}", "note": "`run()` is called once everything has parsed, with every property already filled in."}
]}
```

The program moves out of `main.swift`, because a target with an `@main` type cannot also have one.
**`swift package resolve` fetches the dependency** without building anything, which separates the
download from the compile:

```
ana@vm:~/sw/l19/planner$ rm Sources/plan/main.swift
ana@vm:~/sw/l19/planner$ swift package resolve
Fetching https://github.com/apple/swift-argument-parser
[1/19320] Fetching swift-argument-parser
Fetched https://github.com/apple/swift-argument-parser (1.39s)
Computing version for https://github.com/apple/swift-argument-parser
Computed https://github.com/apple/swift-argument-parser at 1.8.2 (1.67s)
Creating working copy for https://github.com/apple/swift-argument-parser
Working copy of https://github.com/apple/swift-argument-parser resolved at 1.8.2
```

SwiftPM cloned the repository, looked at its tags, and chose the newest version that `from:
"1.6.0"` allows: **1.8.2**. The working copy is a checkout of that tag, kept under `.build`. The
first build compiles the dependency too, which is why it is slower than any build of the planner
alone:

```
ana@vm:~/sw/l19/planner$ swift build 2>&1 | tail -1
Build complete! (7.66 secs)
ana@vm:~/sw/l19/planner$ .build/debug/plan 45 30 60
135 of 300 minutes
ana@vm:~/sw/l19/planner$ .build/debug/plan --goal 120 45 30 60
135 of 120 minutes
ana@vm:~/sw/l19/planner$ .build/debug/plan --help
OVERVIEW: Add up a week of study sessions.

USAGE: plan [--goal <goal>] <minutes> ...

ARGUMENTS:
  <minutes>               The minutes of each session.

OPTIONS:
  --goal <goal>           Minutes the week should reach. (default: 300)
  -h, --help              Show help information.

ana@vm:~/sw/l19/planner$ .build/debug/plan 45 forty; echo $?
Error: The value 'forty' is invalid for '<minutes>'
Help:  <minutes>  The minutes of each session.
Usage: plan [--goal <goal>] <minutes> ...
  See 'plan --help' for more information.
64
```

The parser did three jobs nobody wrote: it converted three words into an `[Int]`, wrote a help page
from the property names and the `help:` strings, and refused `forty` with a message that names the
argument, then exited with **64**, the conventional status for a command used wrongly, so a script
calling `plan` can tell a typo from a crash.

## What a dependency costs

**Every dependency is code you did not write and will build, ship and update.** `swift-argument-
parser` is a reasonable one: it comes from Apple, it is small, it has no dependencies of its own, and
it replaces work that is easy to get wrong. The question to ask of any other is the same list:
who maintains it, how much does it bring with it, and what would replacing it cost. `swift package
show-dependencies` in section 05 answers the second at a glance.
