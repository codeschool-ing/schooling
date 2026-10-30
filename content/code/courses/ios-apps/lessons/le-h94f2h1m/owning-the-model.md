---
title: Who creates the model, and who only reads it
version: 1
---

**An observable object needs an owner exactly as a value in `@State` does, and the owner is the view
that creates it.** It holds the model in `@State`; every other view receives a plain reference and
reads from it. Nothing in this section was run for the course; it is written from Apple's article
*Managing model data in your app* and the documentation for `Observable` and `State`, as they stood
on 30 October 2026.

```swift
// PlannerApp.swift
import SwiftUI
import PlannerCore

@main
struct PlannerApp: App {
    @State private var model = PlannerModel(plan: Plan(), today: "2026-10-21")

    var body: some Scene {
        WindowGroup {
            CourseListView(model: model)
        }
    }
}
```

**`@State` here does not watch the object; it keeps it alive.** Lesson 2 showed that `App` is a
struct like a view, made again when SwiftUI wants. Without `@State`, every new copy of `PlannerApp`
would create a new `PlannerModel` and the plan would be lost. With it, SwiftUI keeps the first
instance for the life of the scene. The watching is Observation's job, and it happens in whichever
`body` reads a property.

The views that receive the model take it as an ordinary property:

```swift
// CourseListView.swift
import SwiftUI
import PlannerCore

struct CourseListView: View {
    let model: PlannerModel

    var body: some View {
        NavigationStack {
            List(model.plan.courses) { course in
                NavigationLink(course.title) {
                    CourseDetailView(model: model, course: course)
                }
            }
            .navigationTitle("Courses")
        }
    }
}
```

**`let`, with no wrapper at all.** The model is a class, so every view holds a reference to the same
instance, and reading `model.plan.courses` inside `body` is what subscribes this view, as section 03
measured. The detail screen gets the same reference and its writes, `model.markDone(…)`, reach the
one plan; the list redraws because it read `plan`.

The cost of passing it this way is the one that motivated the lesson: a view in the middle of the
tree that needs nothing still has to take `model` to hand it on. Section 06 removes that.
