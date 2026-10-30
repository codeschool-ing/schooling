---
title: The container, and where the store is
version: 1
---

**A `ModelContainer` is the store itself: the schema, the file on disk, and the coordination of every
read and write.** Apple's documentation for it says an app that uses SwiftData requires at least one,
and that whenever a fetch runs or a context saves, the container performs the actual read or write.
Nothing in this section was run; it follows that documentation and the documentation for the
`modelContainer` modifiers, read on 30 October 2026.

## One line in the app

The documentation recommends creating it with the SwiftUI modifier, because then every window of the
app shares the same container:

```swift
// PlannerApp.swift, with a store
import SwiftUI
import SwiftData

@main
struct PlannerApp: App {
    var body: some Scene {
        WindowGroup {
            CourseListView()
        }
        .modelContainer(for: [CourseRecord.self, SessionRecord.self])
    }
}
```

**That line does three things**, according to the documentation for `modelContainer(for:)`: it creates
the container for those two types, it stores the data persistently on disk unless asked otherwise, and
it puts a **model context** for that container into the scene's environment, where every `@Query` and
every `@Environment(\.modelContext)` below finds it. The documentation also notes that the container is
created once: values passed to the modifier after the first time are ignored.

## The context

A `ModelContext` is where changes are made before they are stored: `insert`, `delete`, and plain
assignments to a record's properties. The context the modifier creates is the container's
`mainContext`, which runs on the main actor, the same one SwiftUI's views run on, and which saves by
itself, as section 07 explains.

```swift
// SessionForm's onAdd, with a store
@Environment(\.modelContext) private var context

func add(_ session: StudySession, to course: CourseRecord) {
    let record = SessionRecord(sessionID: session.id, date: session.date,
                               minutes: session.minutes, done: session.done)
    record.course = course
    context.insert(record)
}
```

Apple's documentation for `insert(_:)` says the record is registered with the context "so it can
include the model in the next save operation", and gets a temporary identifier until then. The record
appears in every query at once, because queries read the context and not the file.

## A store that forgets on purpose

The same modifier takes `inMemory: true`, and the documentation is exact about it: data stored only in
memory, "for the lifetime of the app's process". **That is the store for previews and for tests**: a
preview that wrote to the real file would leave sample sessions in the student's plan, and a test that
read it would pass or fail by what the last run left behind. Lesson 20 builds both kinds on this.

A `ModelConfiguration` is the longer form, for anything the modifier does not say: a store in an App
Group container that a widget can also read, or a second store kept apart from the first. The planner
needs neither.
