---
title: The retain cycle
version: 1
---

A planner has courses, and each course has study sessions. It is natural to let a course hold its
sessions and to let each session know its course, so that a screen showing one session can print the
course's name. **Written with two ordinary properties, that is two objects holding each other, and
neither is ever freed.**

```swift
// Cycle.swift
final class Course {
    let name: String
    var sessions: [StudySession] = []
    init(name: String) { self.name = name; print("\(name): course created") }
    deinit { print("\(name): course freed") }
}

final class StudySession {
    let minutes: Int
    var course: Course?
    init(minutes: Int) { self.minutes = minutes }
    deinit { print("\(minutes)-minute session freed") }
}

func plan() {
    let swift = Course(name: "Swift")
    let session = StudySession(minutes: 45)
    swift.sessions.append(session)
    session.course = swift
    print("plan() is returning")
}

plan()
print("the program goes on")
```

```
ana@vm:~/sw/l11$ swift Cycle.swift
Swift: course created
plan() is returning
the program goes on
```

**Two `deinit` lines are missing, and nothing else says so.** The program printed what it was asked
to, ran to the end and exited with no error. Inside `plan()`, the local name `swift` held the course
and `session` held the session. When `plan()` returned, both names went away and each object's count
dropped by one, but it did not reach zero: the course is still held by the session's `course`
property, and the session is still held by the course's `sessions` array.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 175\" role=\"img\" data-fig=\"l11-cycle\" aria-label=\"Two diagrams side by side. Left, a retain cycle: a Course box and a StudySession box, a strong arrow from course to session through sessions, and a strong arrow back from session to course. Dashed arrows from plan locals are crossed out, since plan has returned. Caption: each keeps the other alive, deinit never runs. Right, the same two boxes, but the arrow back from session to course is dashed and labelled weak; the course is freed, then the session.\"><defs><marker id=\"l11-cycle-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-cycle-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l11-cycle-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">a retain cycle</text><text x=\"180\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">plan() has returned: its two local names are gone</text><rect x=\"25\" y=\"70\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Course</text><rect x=\"215\" y=\"70\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"280\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">StudySession</text><path d=\"M145 82 L213 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-cycle-ah-phosphor)\"></path><text x=\"179\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sessions</text><path d=\"M215 100 L147 100\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-cycle-ah-amber)\"></path><text x=\"179\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">course (strong)</text><text x=\"180\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">each keeps the other alive: deinit never runs</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">weak breaks it</text><text x=\"540\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">plan() has returned: its two local names are gone</text><rect x=\"385\" y=\"70\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"445\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Course</text><rect x=\"575\" y=\"70\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">StudySession</text><path d=\"M505 82 L573 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-cycle-ah-phosphor)\"></path><text x=\"539\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sessions</text><path d=\"M575 100 L507 100\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l11-cycle-ah-wire)\"></path><text x=\"539\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">course (weak)</text><text x=\"540\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the course is freed, then the session</text></svg>", "caption": "Left, Cycle.swift after plan() returns: the two objects point at each other, so neither count reaches zero and nothing is freed. Right, Weak.swift: the arrow back to the course is weak and does not count, so the course goes first and the session follows."}
```

That is a **retain cycle**: a loop of strong references with nothing outside it pointing in. No line
of the program can reach either object again, because the only references to them are each other's.
And ARC frees an object when its count is zero, not when it is unreachable, so they stay in memory
until the process ends.

## Why a leak this small matters

A hundred-odd bytes are nothing, and section 07 measures them: 112. The leak is never the size of the
first two objects. In an app, the
object in a cycle is a screen with everything it holds: its course, its sessions, the images it
loaded and a timer it started. Open that screen twenty times in a session and there are twenty
copies in memory, each still running its timer. On a phone, the system ends an app that uses too much
memory, and the person using it sees an app that closes itself.

**The cycle needs no mistake in any one line.** Each property, read alone, is right: a course has
sessions, a session belongs to a course. What is wrong is the pair, and that is why the compiler
does not warn about it. Section 04 shows the one word that fixes it, and section 07 shows how to find
a cycle when you did not see it being written.

Some programs never leak this way: a cycle needs at least two class instances, or a class instance
and a closure (section 06), so structs holding structs cannot form one.
