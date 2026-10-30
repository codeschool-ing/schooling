---
title: Debug and release
version: 1
---

Every build so far was a **debug** build: compiled fast, with no optimisation, and with checks that
help you while you work. A **release** build, `swift build -c release`, is what you ship: the
optimiser rewrites the code to run faster, and some of the checks go. **The two are not the same
program**, and the difference that bites is not speed.

## assert, which only debug keeps

The planner's library decides that a session must last at least a minute, and says so with
`assert`:

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public private(set) var minutes: [Int] = []
    public let goal: Int

    public init(goal: Int = 300) {
        self.goal = goal
    }

    public mutating func add(_ session: Int) {
        assert(session > 0, "a session lasts at least a minute")
        minutes.append(session)
    }

    public var total: Int { minutes.reduce(0, +) }
}
```

```
ana@vm:~/sw/l19/planner$ swift build 2>&1 | tail -1
Build complete! (5.83 secs)
ana@vm:~/sw/l19/planner$ .build/debug/plan 45 0 2>&1 | head -3
PlannerCore/Week.swift:11: Assertion failed: a session lasts at least a minute

*** Signal 4: Backtracing from 0x7fc8b6909fbf... done ***
```

The debug build stopped at the assertion and named the file, the line and the message, before the
crash report lesson 1 met; `head -3` keeps the start of it. Now the release build, of the same
source:

```
ana@vm:~/sw/l19/planner$ swift build -c release 2>&1 | tail -1
Build complete! (23.62 secs)
ana@vm:~/sw/l19/planner$ .build/release/plan 45 0
45 of 300 minutes
```

**The release build did not check, and printed a total that includes a session of zero minutes.**
`assert` is a check for the programmer: it costs nothing in release because it is not there. For a
condition that must hold in the shipped program too, Swift has `precondition`, which stays in
release builds, and `fatalError`, which always stops. The rule of thumb is about who made the
mistake: **`assert` for your own code's assumptions, `precondition` for what a caller passes in.**
A week that receives zero from a command line is the second kind, and this `assert` is the wrong
tool for it, which is worth one exercise in the drill.

Release also took longer to build: 23.6 seconds, against 5.8 for the debug build before it. The
comparison is not quite fair, and that is worth knowing too: the debug build had only one changed
file to compile, while the first release build compiled everything, the dependency included, and
spent the extra time optimising it.

## Size and speed

```
ana@vm:~/sw/l19/planner$ ls -l .build/debug/plan .build/release/plan
-rwxr-xr-x 1 ana ana 5167944 Oct 30 16:00 .build/debug/plan
-rwxr-xr-x 1 ana ana 3618736 Oct 30 16:00 .build/release/plan
```

The release executable is about 30% smaller, because the optimiser removed code it could prove
unused and the debug build keeps extra information for the debugger. Then the same work in each:
`seq 1 3000` produces the numbers 1 to 3000, and `$(…)` passes them to `plan` as three thousand
arguments:

```
ana@vm:~/sw/l19/planner$ time .build/debug/plan $(seq 1 3000)
4501500 of 300 minutes

real	0m2.261s
user	0m2.229s
sys	0m0.011s
ana@vm:~/sw/l19/planner$ time .build/release/plan $(seq 1 3000)
4501500 of 300 minutes

real	0m0.238s
user	0m0.226s
sys	0m0.008s
```

**About 2.3 seconds against 0.24**, the same arguments, the same result. Nearly all of it is the
argument parser checking three thousand words, and in debug every function call and every bounds
check runs exactly as written. Here release was about nine times faster, and the ratio changes
from one program to the next; the point is that a debug build's speed says little about what a
student will feel, and **a timing taken on a debug build should never be quoted**.

## When to build which

Work and test in debug: it compiles faster, it keeps `assert`, and a crash in it points at a line.
`swift test` builds debug by default for those reasons. Build release to measure speed and to ship,
and run the shipped program at least once before it goes out, because code that behaves differently
once optimised is rare and real, and `assert` above is the commonest way it happens.
