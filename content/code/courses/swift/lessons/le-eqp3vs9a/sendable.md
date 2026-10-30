---
title: Sendable, what may cross
version: 1
---

An actor protects what is inside it. What travels between tasks and actors still needs a rule,
because a value passed into a task is then reachable from two places. **`Sendable` is the protocol
for a type whose values are safe to share across concurrent code**, and the compiler decides most of
it for you from what the type is made of.

**A value type made of `Sendable` parts is `Sendable` already.** A `struct` of `String`s and `Int`s is
copied when it is passed, as lesson 5 showed, so the task gets a copy nobody else can reach. A class
with a `var` is the opposite: passing it hands over a reference to the same object, and both sides can
write. This program sends one of each into a detached task:

```swift
// Sendables.swift
struct StudySession {
    let course: String
    var minutes: Int
}

final class Draft {
    var note = ""
}

func save(_ session: StudySession) async {
    print("saved \(session.course), \(session.minutes) minutes")
}

func keep(_ draft: Draft) async {
    print("kept \"\(draft.note)\"")
}

func start() async {
    let session = StudySession(course: "Swift", minutes: 45)
    let draft = Draft()
    let saving = Task.detached { await save(session) }
    let keeping = Task.detached { await keep(draft) }
    draft.note = "chapter 3"
    await saving.value
    await keeping.value
}

await start()
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Sendables.swift -o sendables && ./sendables
Sendables.swift:23:24: error: sending value of non-Sendable type '() async -> ()' risks causing data races [#RegionIsolation::SendingRisksDataRace]
21 |     let draft = Draft()
22 |     let saving = Task.detached { await save(session) }
23 |     let keeping = Task.detached { await keep(draft) }
   |                        |- error: sending value of non-Sendable type '() async -> ()' risks causing data races [#RegionIsolation::SendingRisksDataRace]
   |                        `- note: Passing value of non-Sendable type '() async -> ()' as a 'sending' argument to static method 'detached(name:priority:operation:)' risks causing races in between local and caller code
24 |     draft.note = "chapter 3"
   |                `- note: access can happen concurrently
25 |     await saving.value
26 |     await keeping.value

[#RegionIsolation]: <https://docs.swift.org/compiler/documentation/diagnostics/region-isolation>
[#SendingRisksDataRace]: <https://docs.swift.org/compiler/documentation/diagnostics/sending-risks-data-race>
```

**One error, and it is about the draft, not the session.** `StudySession` crossed without comment.
The closure holding `draft` is the problem, and the second note says exactly why: `draft.note =
"chapter 3"` on line 24 runs while the detached task may be reading the same object. The compiler
did not refuse classes as such. It refused a class **used on both sides** of the boundary.

## Handing a value over

That last point is the Swift 6 compiler's **region-based isolation** at work: it tracks which values
are reachable from which context, and lets a non-`Sendable` value cross when the code that sent it
never touches it again. Write the note first and stop using `draft` after the hand-over, and the same
types compile:

```swift
// Handover.swift
struct StudySession {
    let course: String
    var minutes: Int
}

final class Draft {
    var note = ""
}

func save(_ session: StudySession) async {
    print("saved \(session.course), \(session.minutes) minutes")
}

func keep(_ draft: Draft) async {
    print("kept \"\(draft.note)\"")
}

func start() async {
    let session = StudySession(course: "Swift", minutes: 45)
    let draft = Draft()
    draft.note = "chapter 3"
    let saving = Task.detached { await save(session) }
    let keeping = Task.detached { await keep(draft) }
    await saving.value
    await keeping.value
}

await start()
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Handover.swift -o handover && ./handover
saved Swift, 45 minutes
kept "chapter 3"
```

**Sending is a hand-over, and the compiler checks that the hand-over is real.** The draft now has one
owner at a time: `start` until the task is created, the task afterwards.

## Declaring it, and the class that can

A type that is shared for real, held by several tasks at once, has to be `Sendable` itself. For a
`struct` or an `enum` the compiler infers it inside a module; a type made `public` for other modules,
which lesson 17 is about, writes `: Sendable` so that the promise is part of its interface. A class may
declare it only when it is `final` and every stored property is a `let` of a `Sendable` type, so that
nothing about it can change after it is made:

```swift
// Course.swift
final class Course: Sendable {
    let name: String
    var goal: Int
    init(name: String, goal: Int) {
        self.name = name
        self.goal = goal
    }
}
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Course.swift -o course
Course.swift:4:9: error: stored property 'goal' of 'Sendable'-conforming class 'Course' is mutable
 2 | final class Course: Sendable {
 3 |     let name: String
 4 |     var goal: Int
   |         `- error: stored property 'goal' of 'Sendable'-conforming class 'Course' is mutable
 5 |     init(name: String, goal: Int) {
 6 |         self.name = name
```

Change `var goal` to `let goal` and it compiles. A class whose state really must change and be shared
is what an actor is for.

**`@unchecked Sendable` exists**, and it switches the check off: it is a promise, written by you, that
the class protects its own state, with a lock for example, and the compiler believes it. Libraries
that predate Swift 6 use it on types they made safe by hand. In your own code, every `@unchecked` is a
place where the compiler stopped looking and a race can come back, so treat it as you treat lesson 2's
`!`.
