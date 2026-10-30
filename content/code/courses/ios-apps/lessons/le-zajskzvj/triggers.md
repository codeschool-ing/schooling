---
title: Triggers, and the hour that moves
version: 1
---

**A local notification is scheduled with a trigger, and the trigger is where time zones and clock
changes decide whether the reminder arrives when the student expects it.** The User Notifications
framework offers three: after an interval (`UNTimeIntervalNotificationTrigger`), at a date and time
(`UNCalendarNotificationTrigger`), and on entering or leaving a place (`UNLocationNotificationTrigger`).
The planner reminds a student of a session on the evening before, so it uses the calendar trigger. The
framework itself does not run on Linux. **The arithmetic that decides when does**, and this section
runs it.

## The reminder, as date components

Apple's documentation for `UNCalendarNotificationTrigger` says it takes `DateComponents` that specify
"only the time values that you want the system to use" to find the matching date and time. So the
planner works out components and the system does the rest. This lesson's package is lesson 1's in
`~/l17`, with one more source file and one more program. Copy lesson 1's five files, and replace
`Package.swift` with this one:

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
        .executableTarget(name: "remind", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

Save this as `Sources/PlannerCore/Reminders.swift`:

```swift
// Sources/PlannerCore/Reminders.swift
import Foundation

private let days: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

/// When to remind the student of a session planned for `day`: the evening before, at `hour`.
/// The components carry no time zone, so they mean that hour wherever the phone is.
public func reminder(forDay day: String, at hour: Int) -> DateComponents {
    let p = day.split(separator: "-").compactMap { Int($0) }
    let date = days.date(from: DateComponents(year: p[0], month: p[1], day: p[2]))!
    let before = days.dateComponents([.year, .month, .day], from: days.date(byAdding: .day, value: -1, to: date)!)
    return DateComponents(year: before.year, month: before.month, day: before.day, hour: hour, minute: 0)
}
```

**The components carry no time zone, on purpose.** A session is planned for a day, lesson 1's
`2026-10-23`, and "the evening before at seven" means seven o'clock wherever the student is that
evening. The day arithmetic uses a UTC calendar, for lesson 1's reason, and only on whole days; the
hour is left for the phone's own calendar to place.

Then a program that prints the reminders for lesson 1's two sessions still to do, and then a daily
reminder at eight in the morning, in Lisbon, across the night of 25 October 2026, when Portugal's
clocks go back an hour. Save it as `Sources/remind/main.swift`:

```swift
// Sources/remind/main.swift
import Foundation
import PlannerCore

// The two sessions of lesson 1's plan that are not done yet
for (id, day) in [("s3", "2026-10-23"), ("s4", "2026-10-27")] {
    let c = reminder(forDay: day, at: 19)
    print(id, day, "-> remind on", c.year!, c.month!, c.day!, "at", c.hour!)
}

// A daily 08:00 reminder in Lisbon, across the night the clocks go back (25 October 2026)
var lisbon = Calendar(identifier: .gregorian)
lisbon.timeZone = TimeZone(identifier: "Europe/Lisbon")!
let show = DateFormatter()
show.dateFormat = "EEE dd MMM HH:mm zzz"
show.locale = Locale(identifier: "en_GB")
show.timeZone = lisbon.timeZone

let first = lisbon.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 8))!
var byComponents = first
var byInterval = first
print("components hour 8".padding(toLength: 26, withPad: " ", startingAt: 0) + "every 86400 seconds")
for _ in 0..<5 {
    print(show.string(from: byComponents).padding(toLength: 26, withPad: " ", startingAt: 0) + show.string(from: byInterval))
    byComponents = lisbon.nextDate(after: byComponents, matching: DateComponents(hour: 8, minute: 0),
                                   matchingPolicy: .nextTime)!
    byInterval = byInterval.addingTimeInterval(86_400)
}
```

And two tests beside lesson 1's, as `Tests/PlannerCoreTests/ReminderTests.swift`:

```swift
// Tests/PlannerCoreTests/ReminderTests.swift
import Foundation
import Testing
@testable import PlannerCore

@Test func theReminderIsTheEveningBefore() {
    let c = reminder(forDay: "2026-10-23", at: 19)
    #expect([c.year, c.month, c.day, c.hour] == [2026, 10, 22, 19])
}

@Test func theEveningBeforeTheFirstIsInTheMonthBefore() {
    let c = reminder(forDay: "2026-11-01", at: 19)
    #expect([c.year, c.month, c.day] == [2026, 10, 31])
    #expect(c.timeZone == nil)
}
```

```
ana@vm:~/l17$ swift build
Building for debugging...
[Pre-planning 1 / 124]
[Planning deferred tasks]
[31 / 47] PlannerCore
[38 / 50] week-product
[39 / 50] week-product
[40 / 50] week-product
[46 / 54] remind-product
[46 / 54] PlannerCore
[51 / 56] PlannerCore
[56 / 56] remind-product
Build complete! (6.49 secs)
ana@vm:~/l17$ .build/debug/remind
s3 2026-10-23 -> remind on 2026 10 22 at 19
s4 2026-10-27 -> remind on 2026 10 26 at 19
components hour 8         every 86400 seconds
Fri 23 Oct 08:00 WEST     Fri 23 Oct 08:00 WEST
Sat 24 Oct 08:00 WEST     Sat 24 Oct 08:00 WEST
Sun 25 Oct 08:00 WET      Sun 25 Oct 07:00 WET
Mon 26 Oct 08:00 WET      Mon 26 Oct 07:00 WET
Tue 27 Oct 08:00 WET      Tue 27 Oct 07:00 WET
ana@vm:~/l17$ swift test 2>&1 | grep "✔"
✔ Test theEveningBeforeTheFirstIsInTheMonthBefore() passed after 0.003 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.003 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.003 seconds.
✔ Test theReminderIsTheEveningBefore() passed after 0.003 seconds.
✔ Test run with 4 tests in 0 suites passed after 0.004 seconds.
```

**The left column is what date components give; the right is what a fixed interval gives.** Both
start at 08:00 on Friday, Western European Summer Time. On Sunday the clocks go back, and a reminder
that adds 86,400 seconds a day now arrives at 07:00, an hour early, every day until the clocks change
again. The components ask for "hour 8" and get it on both sides of the change. `nextDate(after:matching:)`
is the calendar answering the same question the trigger asks of its components; the trigger's own
scheduling on the phone was not run.

That is the argument against `UNTimeIntervalNotificationTrigger` for anything a person expects at a time
of day. Its documentation says a repeating interval must be at least 60 seconds, and nothing about
clocks: an interval is a duration, and a day is not always 86,400 seconds long. The second test pins
the other edge, the evening before 1 November, which is in October.
