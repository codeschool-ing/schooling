---
title: Deciding when to ask
version: 1
---

**The system decides when a refresh runs; the app decides what it asks for, and a good request is
half the result.** Asking for a refresh every fifteen minutes all day costs battery for nothing, and
the system learns to give such an app less. Asking once a day at the wrong hour leaves the plan stale
when it matters. The planner's rule is short enough to say in a sentence and to test:

- **when sessions are waiting to be sent**, ask again in fifteen minutes, because the person's work
  is not on the server yet;
- **otherwise**, ask for six in the morning, so the plan is fresh before the day's study starts.

## The rule, in the package

Save this as `Sources/PlannerCore/RefreshPolicy.swift`:

```swift
// Sources/PlannerCore/RefreshPolicy.swift
import Foundation

/// When to ask iOS for the next background refresh: soon when sessions are
/// waiting to be sent, otherwise at six in the morning, before the day's study.
public func nextRefresh(after now: Date, pending: Int, calendar: Calendar) -> Date {
    if pending > 0 {
        return now.addingTimeInterval(15 * 60)
    }
    return calendar.nextDate(after: now, matching: DateComponents(hour: 6, minute: 0),
                             matchingPolicy: .nextTime)!
}
```

**The six o'clock is found by the calendar, not by adding hours.** `nextDate(after:matching:)` asks
for the next moment whose hour is 6 and minute 0 in the calendar's own time zone. Adding "the hours
until six" to the current time would be right on most nights and wrong on the two nights a year when
the clocks change, and a test can show which.

## A program to try it

The package gains a fifth program, `background`, which this section starts and the next one grows. Replace
`Package.swift` with this, lesson 15's with one more line:

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
        .executableTarget(name: "fetch", dependencies: ["PlannerCore"]),
        .executableTarget(name: "repo", dependencies: ["PlannerCore"]),
        .executableTarget(name: "covers", dependencies: ["PlannerCore"]),
        .executableTarget(name: "background", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

Save this as `Sources/background/main.swift`. It takes a time zone and a moment, and prints the
refresh the rule would ask for with nothing waiting and with three sessions waiting:

```swift
// Sources/background/main.swift
import Foundation
import PlannerCore

let args = Array(CommandLine.arguments.dropFirst())
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: args[0])!
let format = ISO8601DateFormatter()
format.timeZone = calendar.timeZone
let now = format.date(from: args[1])!

for pending in [0, 3] {
    let next = nextRefresh(after: now, pending: pending, calendar: calendar)
    let minutes = Int(next.timeIntervalSince(now) / 60)
    print("\(pending) waiting: next refresh \(format.string(from: next)), in \(minutes) min")
}
```

Build it and ask about two evenings, one in São Paulo and one in Lisbon:

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (6.50 secs)
ana@vm:~/planner$ .build/debug/background America/Sao_Paulo 2026-10-21T22:30:00-03:00
0 waiting: next refresh 2026-10-22T06:00:00-03:00, in 450 min
3 waiting: next refresh 2026-10-21T22:45:00-03:00, in 15 min
ana@vm:~/planner$ .build/debug/background Europe/Lisbon 2026-10-24T22:30:00+01:00
0 waiting: next refresh 2026-10-25T06:00:00Z, in 510 min
3 waiting: next refresh 2026-10-24T22:45:00+01:00, in 15 min
```

**São Paulo at 22:30 on 21 October is 450 minutes from six o'clock, seven and a half hours.** Lisbon at
22:30 on 24 October is 510 minutes from it, eight and a half: the night of 24 to 25 October 2026 is
when Portugal's clocks go back an hour, and the calendar counted that hour. The `Z` at the end of the
Lisbon result is the formatter's way of writing an offset of zero, which is Lisbon's winter time. A
rule written as "now plus the hours until six" would have asked for five o'clock.
