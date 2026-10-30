---
title: Links that carry a value, and one place that decides the screen
version: 1
---

**A link can push a value instead of a view, and the stack looks up which view to show for that
value.** The link says *show course `sql`*; one `navigationDestination` modifier says *a course id
is shown by `CourseDetailView`*. The two halves meet through the value's type. Nothing here was run;
it is written from Apple's documentation for `NavigationLink(_:value:)` and
`navigationDestination(for:destination:)`.

The values are the planner's routes. This lesson's package adds the type, and section 04 builds and
tests it on any computer:

```swift
public enum Route: Hashable, Codable, Sendable {
    case course(id: String)
    case session(id: String)
    case week(day: String)
}
```

```swift
// CourseListView.swift
NavigationStack {
    List(model.plan.courses) { course in
        NavigationLink(course.title, value: Route.course(id: course.id))
    }
    .navigationTitle("Courses")
    .navigationDestination(for: Route.self) { route in
        switch route {
        case .course(let id): CourseDetailView(courseID: id)
        case .session(let id): SessionDetailView(sessionID: id)
        case .week(let day): WeekView(day: day)
        }
    }
}
```

**A route carries ids, never the course or the session itself.** The detail screen looks the course
up in the model when it is shown, so it always shows the course as it is now; a route that carried
a copy of the `Course` would show the one that existed when the link was tapped. It is lesson 6's
rule about one source of truth, applied to navigation, and it is what makes section 05 possible: an
id can be saved and read back, a copy of the data goes stale on disk.

**Why `Hashable`:** `NavigationStack` keeps its values in a collection and compares them, so the
value type must be `Hashable`. `Codable` is for section 05.

Put `navigationDestination` inside the stack, on a view that is always there, such as the root
list. Apple's documentation warns against putting it inside a lazy container such as a `List`'s
rows, where it may not be loaded when the stack needs it.
