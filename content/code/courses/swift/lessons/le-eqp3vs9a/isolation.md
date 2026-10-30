---
title: One call at a time, until it awaits
version: 1
---

Section 03 said an actor runs one call at a time. **The exact rule is one call at a time between
suspension points.** When a method on an actor reaches an `await`, it gives the actor up, and another
call waiting in line may run before the first one resumes. This is called **reentrancy**, and it is a
deliberate choice: an actor that stayed locked across every `await` would sit idle while it waited for
a network, and two actors waiting on each other would never move again.

The cost is a bug that looks impossible. The planner books study time against a weekly budget of free
minutes. It checks there is room, saves the booking to a server, then takes the minutes:

```swift
// Booking.swift
actor WeekPlan {
    var free = 100

    func book(_ minutes: Int, for course: String) async -> Bool {
        guard free >= minutes else {
            print("\(course): refused, \(free) free")
            return false
        }
        await saveToServer(course)
        free -= minutes
        print("\(course): booked \(minutes), \(free) free")
        return true
    }

    func saveToServer(_ course: String) async {
        try? await Task.sleep(for: .milliseconds(100))
    }
}

let plan = WeekPlan()
async let a = plan.book(80, for: "Swift")
async let b = plan.book(80, for: "Kotlin")
_ = await (a, b)
print("free at the end: \(await plan.free)")
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Booking.swift -o booking && ./booking
Swift: booked 80, 20 free
Kotlin: booked 80, -60 free
free at the end: -60
```

**Two bookings of 80 minutes against 100 free, both accepted, and the budget at −60.** It compiled in
the Swift 6 mode, and there is no data race in it: every read and write of `free` happened on the
actor, one at a time. The bug is in the order. The first call checked `free`, found 100, and reached
`await saveToServer`, where it gave the actor up. The second call ran, checked `free`, still found
100, and reached the same `await`. Each then resumed and subtracted.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l15-reentrancy\" aria-label=\"Six steps on one actor in time order. Swift checks that 80 of 100 minutes are free, then awaits the server and gives the actor up. Kotlin checks, still sees 100, and awaits too. Swift resumes and subtracts, leaving 20; Kotlin resumes and subtracts, leaving minus 60.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">on the actor, in time order</text><text x=\"30\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"50\" y=\"50\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Swift</text><rect x=\"150\" y=\"50\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">free &gt;= 80?  100</text><text x=\"395\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">check</text><text x=\"30\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"50\" y=\"81\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Swift</text><rect x=\"150\" y=\"81\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"265\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await saveToServer</text><text x=\"395\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gives the actor up</text><text x=\"30\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"50\" y=\"112\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Kotlin</text><rect x=\"150\" y=\"112\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">free &gt;= 80?  100</text><text x=\"395\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">check, still 100</text><text x=\"30\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><rect x=\"50\" y=\"143\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Kotlin</text><rect x=\"150\" y=\"143\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"265\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await saveToServer</text><text x=\"395\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gives the actor up</text><text x=\"30\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><rect x=\"50\" y=\"174\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Swift</text><rect x=\"150\" y=\"174\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">free -= 80  → 20</text><text x=\"395\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resumes</text><text x=\"30\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><rect x=\"50\" y=\"205\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Kotlin</text><rect x=\"150\" y=\"205\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">free -= 80  → -60</text><text x=\"395\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resumes</text><text x=\"560\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">both checks saw 100</text><text x=\"560\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">before either subtracted</text></svg>", "caption": "Reentrancy in Booking.swift: each await let the other booking in between its check and its subtraction."}
```

## Finish the change before the await

**Treat every `await` inside an actor as a place where the actor's state may change under you.** A
check made before it is a check of the past. The repair is to make the check and the change one
uninterrupted piece, with no `await` between them, and to do the slow part afterwards:

```swift
// Reserved.swift
actor WeekPlan {
    var free = 100

    func book(_ minutes: Int, for course: String) async -> Bool {
        guard free >= minutes else {
            print("\(course): refused, \(free) free")
            return false
        }
        free -= minutes
        await saveToServer(course)
        print("\(course): booked \(minutes), \(free) free")
        return true
    }

    func saveToServer(_ course: String) async {
        try? await Task.sleep(for: .milliseconds(100))
    }
}

let plan = WeekPlan()
async let a = plan.book(80, for: "Swift")
async let b = plan.book(80, for: "Kotlin")
_ = await (a, b)
print("free at the end: \(await plan.free)")
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Reserved.swift -o reserved && ./reserved
Kotlin: refused, 20 free
Swift: booked 80, 20 free
free at the end: 20
```

Two lines swapped places. The minutes are now **reserved** before the save, so the second booking
sees 20 free and is refused. Which of the two courses wins is a matter of which call reached the actor
first, and it may differ on your machine; what cannot happen any more is both winning. A real planner
would also give the minutes back if the save failed, which is lesson 12's error handling inside an
actor method, and the same rule applies to it: decide, then await.
