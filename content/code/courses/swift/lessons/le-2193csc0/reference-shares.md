---
title: A class is shared
version: 1
---

The same program with `class` instead of `struct` gives different numbers, and the difference is
the whole point. **A class variable holds a reference**, an address where the instance lives, and
assigning it copies the address. Two names then reach one instance, and a change made through either
is seen through both:

```swift
// Shares.swift
final class StudySession {
    var course: String
    var minutes: Int
    init(course: String, minutes: Int) {
        self.course = course
        self.minutes = minutes
    }
}
let monday = StudySession(course: "Swift", minutes: 45)
let tuesday = monday
tuesday.minutes = 60
print(monday.minutes, tuesday.minutes)

func extend(_ session: StudySession) {
    session.minutes += 15
}
extend(monday)
print(monday.minutes, tuesday.minutes)

let week = [monday, tuesday]
week[0].minutes = 0
print(monday.minutes, tuesday.minutes, week[1].minutes)
```

```
ana@vm:~/sw/l05$ swift Shares.swift
60 60
75 75
0 0 0
```

**Every number in every line is the same**, because there was only ever one session. `tuesday =
monday` made a second name for it, not a second session. The function `extend` received the
reference, and changing the instance through it changed the caller's instance, with no `inout` and
no `&` to warn the reader. The array holds two references to that one instance, so setting the first
element's minutes to 0 also set the second's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l05-value-reference\" aria-label=\"Two panels. On the left, a struct: monday and tuesday are two separate boxes, one holding minutes 45 and the other minutes 60, because assignment copied the value. On the right, a class: monday and tuesday are two name tags with arrows to one shared box holding minutes 60, because assignment copied the reference.\"><defs><marker id=\"l05-vr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">value type: struct</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">reference type: class</text><path d=\"M355 12 L355 248\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"60\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">monday</text><rect x=\"54\" y=\"98\" width=\"92\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">minutes: 45</text><rect x=\"200\" y=\"60\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tuesday</text><rect x=\"214\" y=\"98\" width=\"92\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">minutes: 60</text><text x=\"170\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tuesday = monday copies the value</text><text x=\"170\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">two values, each changed on its own</text><rect x=\"390\" y=\"60\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"440\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">monday</text><path d=\"M490 75 L578 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-vr-ah)\"></path><rect x=\"390\" y=\"112\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"440\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tuesday</text><path d=\"M490 127 L578 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-vr-ah)\"></path><rect x=\"580\" y=\"76\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">minutes: 60</text><text x=\"540\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tuesday = monday copies the reference</text><text x=\"540\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">two names, one instance on the heap</text></svg>", "caption": "Assignment copies what the name holds. A struct name holds the value, so a copy is a second value; a class name holds a reference, so a copy is a second way to reach the same instance."}
```

## `let` means something smaller here

`monday`, `tuesday` and `week` are all `let`, and the program changed minutes through each of them.
That is not a contradiction. **For a class, `let` fixes the reference, not the instance**: `monday`
will always point at the same session, and that session's `var` properties can still change. Lesson
1 said that `let` and immutability coincide for numbers and text; for a class they come apart.
`monday = StudySession(course: "Kotlin", minutes: 30)` would be refused, because that changes the
reference.

## When sharing is what you want

Sharing is not a defect. A planner screen and a statistics screen that should both show a
session's minutes, and both see a change at once, want exactly one session between them, and a
class gives them that. The cost is the one this program shows: any code holding the reference can
change what everybody else sees, at any moment, and the reader of one line cannot tell. Section 08
weighs the two.
