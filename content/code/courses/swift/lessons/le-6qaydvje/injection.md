---
title: A protocol as a seam
version: 1
---

The planner reminds a student which sessions are today. "Today" comes from the computer's clock, so
the same code prints a different answer every day, and a test written on a Monday fails on a
Tuesday. **A protocol in place of a concrete dependency gives the code a seam**: the program passes
in the real thing, and a test, or a demonstration, passes in something it controls.

```swift
// Reminder.swift
import Foundation

protocol Clock {
    func now() -> Date
}

struct SystemClock: Clock {
    func now() -> Date { Date() }
}

struct FixedClock: Clock {
    let date: Date
    func now() -> Date { date }
}

struct StudySession {
    var title: String
    var day: DateComponents
}

struct Reminder {
    let clock: any Clock
    let calendar = Calendar(identifier: .gregorian)

    func today(_ sessions: [StudySession]) -> [String] {
        let now = calendar.dateComponents([.year, .month, .day], from: clock.now())
        return sessions.filter { $0.day == now }.map(\.title)
    }
}

let sessions = [
    StudySession(title: "Optionals", day: DateComponents(year: 2026, month: 11, day: 2)),
    StudySession(title: "Generics", day: DateComponents(year: 2026, month: 11, day: 2)),
    StudySession(title: "Protocols", day: DateComponents(year: 2026, month: 11, day: 3)),
]

let monday = DateComponents(calendar: Calendar(identifier: .gregorian),
                            year: 2026, month: 11, day: 2, hour: 9).date!
print("fixed: ", Reminder(clock: FixedClock(date: monday)).today(sessions))
print("system:", Reminder(clock: SystemClock()).today(sessions))
```

```
ana@vm:~/sw/l10$ swift Reminder.swift
fixed:  ["Optionals", "Generics"]
system: []
```

`Reminder` does not know which clock it has. It holds an `any Clock` and calls `now()`, lesson 9's
box at work, so either clock fits. With the fixed clock set to Monday 2 November 2026 it finds the
two sessions of that day. With the system clock it found none, because the day this transcript was
recorded, 30 October 2026, has no session in the list. **The code under test is the same in both
lines; only what was passed in differs.** `Foundation` is Apple's library of dates, calendars,
files and JSON, and it ships with the Linux toolchain too; lesson 20 lists where it differs.

## Why a protocol and not a flag

The alternative is a `Reminder` with a `var testDate: Date?` that it checks before asking the system.
That puts the test inside the product, and every new dependency, a store of sessions or a network
client, adds another flag. With a seam, the product has no idea a test exists. **The dependency is
named by what it does, `Clock`, and the code depends on that and nothing more**, which is section
03's rule applied to collaborators instead of data.

## Where it pays

Lesson 18 writes the tests that use this: a fake `Clock` that is Monday, a fake store that holds
three sessions, and assertions about what the reminder says. Lesson 14 does the same for a slow
server, with a fake one that answers instantly. On iOS the same seam is how a screen is shown in a
preview with sample data rather than with whatever is on the phone, which `ios-apps` uses throughout
and which is not run here. Each case is one protocol with one or two requirements, a real
implementation and a fake.
