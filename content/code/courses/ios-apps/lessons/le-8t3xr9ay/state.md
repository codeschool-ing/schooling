---
title: '@State: storage the view owns'
version: 1
---

**A SwiftUI view is a struct, and SwiftUI throws it away and makes a new one every time its parent's
`body` runs.** So a view cannot keep anything in an ordinary stored property: the next copy would
start again from the initial value. `@State` is how a view asks SwiftUI to keep a value for it
**outside the struct**, for as long as the view is on screen, and to run `body` again whenever the
value changes.

Nothing in this section was run for the course: SwiftUI has no Linux version, and the code is
written from Apple's documentation for `State`, read on 30 October 2026.

```swift
// CourseDetailView.swift
import SwiftUI
import PlannerCore

struct CourseDetailView: View {
    let course: Course
    @State private var plan: Plan

    init(course: Course, plan: Plan) {
        self.course = course
        _plan = State(initialValue: plan)
    }

    var body: some View {
        let total = plan.weekTotal(today: "2026-10-21")
        List {
            ForEach(plan.sessions.filter { $0.courseID == course.id }) { session in
                Text("\(session.date) · \(session.minutes) min\(session.done ? " · done" : "")")
            }
            Text("\(total.done) of \(total.planned) minutes this week")
        }
        .navigationTitle(course.title)
    }
}
```

Three things in it are rules rather than style.

**`private`.** Apple's documentation says to declare state private, because the view owns it and
nothing outside should set it. A parent that wants to give the view a starting value passes it to
the initialiser, as above, and the view decides what to do with it.

**`_plan = State(initialValue: plan)`.** The underscore names the property wrapper itself rather
than the value inside it. That line runs every time the parent makes a new copy of the struct, and
**SwiftUI uses the initial value only the first time the view appears**. After that, the storage it
kept wins. Section 07 shows the trap that follows from that.

**Value types.** `Plan` is a struct, so changing `plan.sessions[0].done` assigns a new `plan` as far
as `@State` is concerned, and SwiftUI sees the change. A class held in `@State` is a different
matter: changing one of its properties changes nothing `@State` can see. Lesson 7 is about classes
SwiftUI can observe.

## What `body` reads

`body` reads `plan` twice, for the list and for the total. When `plan` changes, SwiftUI runs `body`
again and compares the new description with the old one, and the list and the total change together
because they were both computed from the same value. **There is no line anywhere that updates the
total**, and that is the design: there is nothing to forget.
