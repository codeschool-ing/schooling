---
title: One test, many arguments
version: 1
---

**Seven tests that differ only in their input are one test with seven arguments.** Written as seven
functions, they are seven copies to keep in step, and the eighth case somebody thinks of is the one
nobody adds. Swift Testing takes the inputs as a list: `@Test(arguments:)` runs the function once per
element, and reports each run as a **test case** of its own.

`mondayOf` is the planner's one piece of calendar arithmetic, and it is exactly the code where the
cases matter more than the code. Save this as `Tests/PlannerCoreTests/MondayTests.swift`:

```swift
// Tests/PlannerCoreTests/MondayTests.swift
import Testing
@testable import PlannerCore

@Test("Every day of a week finds the same Monday", arguments: [
    "2026-10-19", "2026-10-20", "2026-10-21", "2026-10-22",
    "2026-10-23", "2026-10-24", "2026-10-25",
])
func sameMonday(day: String) {
    #expect(mondayOf(day) == "2026-10-19")
}

@Test("A week that crosses a boundary", arguments: [
    ("2027-01-01", "2026-12-28"),  // New Year's Day, a Friday
    ("2028-03-01", "2028-02-28"),  // the day after a leap day
    ("2026-11-01", "2026-10-26"),  // a Sunday, and a new month
])
func crossing(day: String, monday: String) {
    #expect(mondayOf(day) == monday)
}
```

The first test takes every day of one week. The second takes pairs, and Swift Testing passes a pair's
two halves as the function's two parameters. **The three pairs are the boundaries**: a week that
starts in one year and ends in the next, a week with the 29th of February in it, and a Sunday at the
start of a month. A calendar bug lives at a boundary, and these are the three the planner meets.

```
ana@vm:~/l20$ swift test --filter "sameMonday|crossing" 2>&1 | grep -E "^(✔|✘)"
✔ Test "A week that crosses a boundary" with 3 test cases passed after 0.002 seconds.
✔ Test "Every day of a week finds the same Monday" with 7 test cases passed after 0.002 seconds.
✔ Test run with 2 tests in 0 suites passed after 0.002 seconds.
```

## Watching it fail

A test that has never failed has not been shown to test anything. Break `mondayOf` on purpose, by
changing the `5` in `(weekday + 5) % 7` to a `6`, and run the same tests:

```
ana@vm:~/l20$ sed -i 's/(weekday + 5) % 7/(weekday + 6) % 7/' Sources/PlannerCore/Days.swift
ana@vm:~/l20$ swift test --filter crossing 2>&1 | grep -E "^(✘|↳)"
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
✘ Test "A week that crosses a boundary" recorded an issue with 2 arguments day → "2027-01-01", monday → "2026-12-28" at MondayTests.swift:19:5: Expectation failed: mondayOf(day) == monday
↳ mondayOf(day) == monday → false
↳   mondayOf(day) → "2026-12-27"
↳   monday → "2026-12-28"
✘ Test "A week that crosses a boundary" recorded an issue with 2 arguments day → "2028-03-01", monday → "2028-02-28" at MondayTests.swift:19:5: Expectation failed: mondayOf(day) == monday
↳ mondayOf(day) == monday → false
↳   mondayOf(day) → "2028-02-27"
↳   monday → "2028-02-28"
✘ Test "A week that crosses a boundary" recorded an issue with 2 arguments day → "2026-11-01", monday → "2026-10-26" at MondayTests.swift:19:5: Expectation failed: mondayOf(day) == monday
↳ mondayOf(day) == monday → false
↳   mondayOf(day) → "2026-11-01"
↳   monday → "2026-10-26"
✘ Test "A week that crosses a boundary" with 3 test cases failed after 0.002 seconds with 3 issues.
✘ Test run with 1 test in 0 suites failed after 0.002 seconds with 3 issues.
ana@vm:~/l20$ swift test --filter sameMonday 2>&1 | grep -E "^✘ Test .* failed after"
✘ Test "Every day of a week finds the same Monday" with 7 test cases failed after 0.002 seconds with 7 issues.
✘ Test run with 1 test in 0 suites failed after 0.002 seconds with 7 issues.
ana@vm:~/l20$ sed -i 's/(weekday + 6) % 7/(weekday + 5) % 7/' Sources/PlannerCore/Days.swift
```

**Each failing case is named by its argument**, and under it the `↳` lines take the comparison
apart: the expression, then the value of each side. That is what the `#expect` macro buys over a
plain `==` that returns `false`. The wrong formula is one day out everywhere. Most days land on the
Sunday before their Monday, and a Sunday, `2026-11-01`, decides it is its own Monday. All seven days
of the week fail too, and the second command says so in one line. The last command puts the `5` back.
