---
title: Computed properties
version: 1
---

A week's total minutes could be a stored property, updated every time a session is added. Then it
would be one more thing to keep in step, and the day somebody adds a session without updating the
total, the two disagree. **A computed property stores nothing: it runs code every time it is read**,
so it cannot disagree with the data it is computed from.

```schooling-example
{"language": "swift", "file": "Computed.swift", "parts": [{"code": "// Computed.swift\nstruct Week {\n    var sessions: [Int]\n    var goal = 300", "note": "Two stored properties: the minutes of each session and the week's goal, with a default."}, {"code": "    var total: Int { sessions.reduce(0, +) }\n    var remaining: Int { max(goal - total, 0) }\n}", "note": "Two computed properties. The type is required, and the braces hold the code that runs on each read. A body of one expression returns it without `return`."}, {"code": "struct StudySession {\n    var minutes: Int\n    var hours: Double {\n        get { Double(minutes) / 60 }\n        set { minutes = Int(newValue * 60) }\n    }\n}", "note": "A computed property with a getter and a setter. The setter receives the assigned value as `newValue` and writes it into the stored property."}, {"code": "var week = Week(sessions: [45, 30])\nprint(week.total, week.remaining)\nweek.sessions.append(60)\nprint(week.total, week.remaining)\nvar session = StudySession(minutes: 45)\nsession.hours = 1.25\nprint(session.minutes, session.hours)", "note": "Reading `total` after the append runs the code again, so the total follows the sessions with nobody updating it."}], "output": "75 225\n135 165\n75 1.25"}
```

Each read ran the code again: `total` became 135 after the third session without anybody touching
it. `remaining` never goes below zero, because `max` keeps the larger of its two arguments.

## Read-only, unless it says otherwise

A computed property with only a `get`, or with the body written directly in braces as `total` is,
is **read-only**. Assigning to it is refused, because there is nowhere to put the value:

```swift
// GetOnly.swift
struct Week {
    var sessions: [Int]
    var total: Int { sessions.reduce(0, +) }
}
var week = Week(sessions: [45, 30])
week.total = 200
```

```
ana@vm:~/sw/l06$ swiftc GetOnly.swift -o getonly
GetOnly.swift:7:6: error: cannot assign to property: 'total' is a get-only property
5 | }
6 | var week = Week(sessions: [45, 30])
7 | week.total = 200
  |      `- error: cannot assign to property: 'total' is a get-only property
8 | 
```

`hours` in `Computed.swift` has a `set` as well, and the setter receives the new value as
`newValue`. Setting a session's hours to 1.25 wrote 75 into `minutes`, the property that is actually
stored. **A setter translates; it does not store**: the value lives in `minutes` and `hours` is a
second way to read and write it.

## Property or method?

`total` could just as well be `func total() -> Int`, and lesson 5 wrote it that way. The convention
in Swift's own API guidelines is that a property reads as a fact about the value and is cheap; a
method reads as an action, and may cost something or take arguments. **Make it a property when the
caller should not have to care that it is computed.** A total of a week's minutes is a fact; reading
a file from disk is an action, however it is written.
