---
title: A data race, and a total that is wrong
version: 1
---

Lesson 14 ran work side by side and every answer was right, because each task kept to its own data.
**A data race is two threads touching the same memory at the same time, with at least one of them
writing.** It does not crash, as a rule, and it does not announce itself: it produces a number that
is wrong by an amount that changes every time you run the program.

Here is the planner's week total, a class from lesson 5 with one `var`, added to by eight tasks at
once, a hundred thousand minutes each:

```swift
// Race.swift
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
ana@vm:~/sw/l15$ swiftc Race.swift -o race && ./race
expected 800000, got 677275
expected 800000, got 800000
expected 800000, got 800000
```

**It compiled without a word, and the first run lost 122,725 minutes.** The machine the course was
recorded on has four processor cores, so up to four of the eight tasks ran at the same instant.
`minutes += m` looks like one step and is three: read `minutes`, add one, write it back. When two
threads both read 41, both add one and both write 42, one minute is lost, and the first run lost that
many of them.

**The other two runs came out right, and that is the worst thing about a data race.** The same
program, with no change in between, gave a wrong answer and then two right ones, in one run of the program. Run it on
your machine and the numbers will differ again. A test of this program could pass on Tuesday and fail
on Thursday, and nothing in the output points at the line responsible.

## The same file in Swift 6

Lesson 1 measured that `swiftc` compiles in the **Swift 5 language mode** unless told otherwise, and
in that mode the compiler checks very little about concurrency. `-swift-version 6` turns on the
Swift 6 mode, and the Swift 6 mode treats a data race as an error:

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Race.swift -o race
Race.swift:11:19: error: passing closure as a 'sending' parameter risks causing data races between code in the current isolation context and concurrent execution of the closure [#RegionIsolation::SendingClosureRisksDataRace]
 9 |     await withTaskGroup(of: Void.self) { group in
10 |         for _ in 1...8 {
11 |             group.addTask {
   |                   `- error: passing closure as a 'sending' parameter risks causing data races between code in the current isolation context and concurrent execution of the closure [#RegionIsolation::SendingClosureRisksDataRace]
12 |                 for _ in 1...100_000 {
13 |                     week.add(1)
   |                          `- note: closure captures 'week' which is accessible to code in the current isolation context
14 |                 }
15 |             }

[#RegionIsolation]: <https://docs.swift.org/compiler/documentation/diagnostics/region-isolation>
[#SendingClosureRisksDataRace]: <https://docs.swift.org/compiler/documentation/diagnostics/sending-closure-risks-data-race>
```

The error is in the vocabulary of the rest of this lesson, and it is worth reading slowly. `addTask`
takes its closure as a **`sending`** parameter: the closure leaves the current context and runs
concurrently with it. The note says why that is unsafe here: the closure **captures `week`**, which
the code outside the closure can also reach. Two places can reach one `WeekTotal`, and `WeekTotal`
has a `var` and no protection. **The compiler found the race by reading the program**, which is
something no test of `Race.swift` can do reliably.

The next three sections are the three ways out: give the state to an **actor**, which section 03
does; make what crosses between tasks **`Sendable`**, which section 05 explains; or keep the work on
one actor, the **main actor**, section 06.
