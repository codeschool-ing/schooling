---
title: A stack of screens, and the back button that comes with it
version: 1
---

**On a phone, opening something pushes a screen on top of the one you were on, and going back pops
it.** The course list, then one course, then one session: three screens on a stack, with the back
button and the swipe from the left edge to undo the last push. `NavigationStack` is the SwiftUI view
that owns that stack. Nothing in this section was run for the course; it is written from Apple's
documentation for `NavigationStack` and `NavigationLink`, read on 30 October 2026.

```swift
// CourseListView.swift
struct CourseListView: View {
    @Environment(PlannerModel.self) private var model

    var body: some View {
        NavigationStack {
            List(model.plan.courses) { course in
                NavigationLink(course.title) {
                    CourseDetailView(course: course)
                }
            }
            .navigationTitle("Courses")
        }
    }
}
```

**`NavigationStack` goes once, at the root of what navigates**, not on every screen. Each screen
pushed onto it gets the navigation bar, a title from its own `.navigationTitle`, and a back button
labelled with the previous screen's title. Apple's examples put one stack at the root; another inside
a pushed screen is a second stack, with a path of its own, and nothing in the planner wants that.

The link above carries the destination view itself: `NavigationLink(course.title) {
CourseDetailView(…) }`. That form is the simplest and it has two limits. The stack only knows that
*some view* was pushed, so there is nothing to save when the app is closed and nothing a link from
outside the app can ask for. And SwiftUI may build the destination before anybody taps. Section 03
replaces it with links that carry a value instead, which is what the rest of the lesson builds on.

The older `NavigationView`, which you will meet in code written before iOS 16, is deprecated.
Apple's guide *Migrating to new navigation types* maps it onto the two views that replaced it,
`NavigationStack` for a stack and `NavigationSplitView` for the columns of an iPad.
