---
title: A class becomes stored data with one macro
version: 1
---

**This lesson is read, not practised, and it says so first.** SwiftData exists only in Apple's SDKs:
there is no Linux version, and section 05 shows the compiler on the course's machine refusing
`import SwiftData`. Everything SwiftData does in this lesson is written from Apple's documentation for
the framework as it stood on 30 October 2026, and none of it was run. Section 05 is the one part with a
capture, because the predicates a query is made of come from Foundation and run anywhere.

## What SwiftData is for

Apple's documentation introduces SwiftData as the framework that adds "managed persistence" to an app:
the app describes its model classes in Swift, and SwiftData stores them on the device, fetches them,
tells SwiftUI when they change and, if the app asks, syncs them through iCloud. It is built on Core
Data's storage, which the documentation calls "proven persistence technology", without Core Data's
model files. For the planner it answers one question: where the courses and sessions live between one
launch and the next, so the app opens on the plan the student left.

## The planner's two records

A class becomes something SwiftData stores when the `@Model` macro is attached to it. The planner's
are in the app target, because they import SwiftData:

```swift
// Records.swift
import Foundation
import SwiftData
import PlannerCore

@Model
final class CourseRecord {
    @Attribute(.unique) var courseID: String
    var title: String
    @Relationship(deleteRule: .cascade, inverse: \SessionRecord.course)
    var sessions: [SessionRecord] = []

    init(courseID: String, title: String) {
        self.courseID = courseID
        self.title = title
    }
}

@Model
final class SessionRecord {
    @Attribute(.unique) var sessionID: String
    var date: String
    var minutes: Int
    var done: Bool
    var course: CourseRecord?

    init(sessionID: String, date: String, minutes: Int, done: Bool = false) {
        self.sessionID = sessionID
        self.date = date
        self.minutes = minutes
        self.done = done
    }
}
```

Apple's documentation for `Model()` says what the macro adds when the app is built: conformance to
`PersistentModel`, which SwiftData uses to examine the class and generate its schema, and to
`Observable`, which is the same observation lesson 7 described. **So a record is something SwiftUI
already knows how to watch**: change `record.done` and every view that read it runs again, with no
`@Published` and no notification of your own.

## Why records, and not lesson 1's types

The planner already has `Course` and `StudySession`, and the obvious move is to put `@Model` on them.
**It cannot be done, and it should not be wanted.** `@Model` is attached to a class, and lesson 1's
types are structs, values that copy, which is what lets a test build a plan and compare it. More
importantly, they live in the package that builds on Linux, and the moment `PlannerCore` imports
SwiftData it stops building anywhere but on Apple's systems, taking every test of the course with it.

So the app has two shapes of the same data. **The records are how it is stored; the values are how it
is reasoned about**, tested and shown. Converting between them is a few lines, and lesson 14 puts them
behind a repository so that no screen has to know which it holds:

```swift
// Records.swift, continued
extension SessionRecord {
    /// The planner's value for this record, or nil for a session that lost its course.
    var value: StudySession? {
        guard let course else { return nil }
        return StudySession(id: sessionID, courseID: course.courseID, date: date, minutes: minutes, done: done)
    }
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l13-two-shapes\" aria-label=\"Two columns. On the left, inside the app target, which builds only on a Mac: CourseRecord and SessionRecord, classes with the Model macro, joined by a relationship, stored by SwiftData in a file on the device. On the right, inside the PlannerCore package, which builds anywhere: the values Course and StudySession, joined by courseID. An arrow labelled value goes from the records to the values, and another labelled insert goes back.\"><defs><marker id=\"l13-two-shapes-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l13-two-shapes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-two-shapes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l13-two-shapes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the app target: a Mac only</text><rect x=\"50\" y=\"64\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">@Model CourseRecord</text><rect x=\"50\" y=\"160\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">@Model SessionRecord</text><path d=\"M170 110 L170 156\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-two-shapes-ah-amber)\"></path><text x=\"180\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a relationship</text><text x=\"170\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stored by SwiftData,</text><text x=\"170\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in a file on the device</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">PlannerCore: anywhere</text><rect x=\"430\" y=\"64\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">struct Course</text><rect x=\"430\" y=\"160\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">struct StudySession</text><path d=\"M550 156 L550 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-two-shapes-ah-phosphor)\"></path><text x=\"560\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">courseID, text</text><text x=\"550\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tested by swift test,</text><text x=\"550\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shown by the screens</text><path d=\"M322 172 L398 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-two-shapes-ah-paper-dim)\"></path><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.value</text><path d=\"M398 196 L322 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-two-shapes-ah-paper-dim)\"></path><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">insert</text></svg>", "caption": "Two shapes of the same sessions. The records are how the app stores them; the values are how it reasons about them, and only the values build on Linux."}
```

`courseID` and `sessionID` are the planner's own ids, the ones the server and the other platforms use.
SwiftData gives every record an identifier of its own as well, `persistentModelID`, which means
nothing outside this one store. **A store's internal identifier is never what crosses to the server**:
the same session on a second phone has a different one.

The date stays text, `2026-10-21`, for lesson 1's reason: a day is not an instant, and Apple's
documentation for the framework lists `String` among the types SwiftData stores as they are.
