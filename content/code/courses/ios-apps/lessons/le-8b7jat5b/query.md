---
title: '@Query: a fetch that keeps itself up to date'
version: 1
---

**`@Query` is a property whose value is the result of a fetch, and which SwiftUI keeps current.**
Apple's documentation for SwiftData describes it: SwiftData performs the fetch when the view appears,
and tells SwiftUI about any later change to the fetched records so the view can update. A session
inserted by `SessionForm` appears in the list behind it with no code to refresh anything. Nothing in
this section was run; section 05 runs the two parts of a query that do not need SwiftData.

## Every course

```swift
// CourseListView.swift
import SwiftUI
import SwiftData

struct CourseListView: View {
    @Query(sort: \CourseRecord.title) private var courses: [CourseRecord]

    var body: some View {
        NavigationStack {
            List(courses) { course in
                NavigationLink(course.title, value: course.courseID)
            }
            .navigationTitle("Courses")
        }
    }
}
```

`sort: \CourseRecord.title` orders the result by a key path; with no filter, the query returns every
record of the type. The list is built from `courses` like any array, and lesson 8's rules about
identity apply: a `@Model` class is `Identifiable` through `persistentModelID`, which is stable for the
life of a stored record.

## One course's sessions, latest first

A query whose filter depends on something the view was given is written in the view's initialiser,
because a property wrapper's arguments cannot read the view's other properties:

```swift
// CourseDetailView.swift
import SwiftUI
import SwiftData

struct CourseDetailView: View {
    let course: CourseRecord
    @Query private var sessions: [SessionRecord]

    init(course: CourseRecord) {
        self.course = course
        let id = course.courseID
        _sessions = Query(filter: #Predicate<SessionRecord> { $0.course?.courseID == id },
                          sort: \SessionRecord.date, order: .reverse)
    }

    var body: some View {
        List(sessions) { session in
            LabeledContent(session.date, value: "\(session.minutes) min")
        }
        .navigationTitle(course.title)
    }
}
```

**The predicate is not a closure SwiftUI calls on each record.** `#Predicate` is a macro: it turns the
expression into a description that SwiftData can hand to its store, so the filtering happens where the
data is rather than after every record has been loaded into memory. That is why `id` is copied into a
local constant first, and why a predicate accepts only what can be described that way. Section 05 shows
the compiler refusing one that cannot.

## Changing what a query sees

A query has no `refresh()`. It sees the context, so changing the context is enough:

| the student | the code | the query |
|---|---|---|
| adds a session | `context.insert(record)` | the new session is in the list |
| marks one done | `record.done = true` | the row shows it done |
| swipes one away | `context.delete(record)` | the row goes |

Apple's documentation for `delete(_:)` adds the case worth knowing: a record that was inserted and not
yet saved is simply discarded.
