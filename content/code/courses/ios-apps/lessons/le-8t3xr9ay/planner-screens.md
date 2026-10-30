---
title: The planner's course screen, with one plan in it
version: 1
---

**The course screen now has everything this lesson is about: one owner, rows that change it through
bindings, and a total that is computed.** The four screens of the planner are the same on every
platform the `mobile` track builds it for: `CourseListView`, `CourseDetailView`, `SessionForm` and
`WeekView`. This section puts the first two together around one `@State`. Nothing in it was run; it
is written from Apple's documentation for `List`, `ForEach`, `Toggle` and `NavigationLink`, and from
the package's own types, which section 06 tested.

```schooling-example
{"language": "swift", "file": "CourseListView.swift", "parts": [{"code": "// CourseListView.swift\nimport SwiftUI\nimport PlannerCore\n\nstruct CourseListView: View {\n    @State private var plan: Plan\n    let today: String\n\n    init(plan: Plan, today: String) {\n        _plan = State(initialValue: plan)\n        self.today = today\n    }\n", "note": "The list is the owner. It is the first screen and nothing above it needs the plan, so this is the one `@State` in the app for now. Lesson 7 moves it into an observable model when a second screen does need it."}, {"code": "    var body: some View {\n        NavigationStack {\n            List(plan.courses) { course in\n                NavigationLink(course.title) {\n                    CourseDetailView(course: course, plan: $plan, today: today)\n                }\n            }\n            .navigationTitle(\"Courses\")\n        }\n    }\n}\n", "note": "Each course opens its detail screen, and the detail screen is handed `$plan`, a binding. Lesson 9 is about the navigation itself."}]}
```

```schooling-example
{"language": "swift", "file": "CourseDetailView.swift", "parts": [{"code": "// CourseDetailView.swift\nimport SwiftUI\nimport PlannerCore\n\nstruct CourseDetailView: View {\n    let course: Course\n    @Binding var plan: Plan\n    let today: String\n", "note": "No `@State` here. The detail screen changes the plan, so it takes a binding to the list's."}, {"code": "    var body: some View {\n        let total = plan.weekTotal(today: today)\n        List {\n            ForEach($plan.sessions) { $session in\n                if session.courseID == course.id {\n                    SessionRow(session: $session)\n                }\n            }\n            Text(\"This week: \\(total.done) of \\(total.planned) minutes\")\n        }\n        .navigationTitle(course.title)\n    }\n}\n", "note": "A binding per session, filtered to this course, and the week's total computed from the same plan in the same `body`. Ticking a row writes through `$session` and `$plan` into the list's state, and both screens are drawn again from it."}]}
```

**Follow one tap from the finger to the footer.** `SessionRow`'s `Toggle` writes `true` into its
`Binding<Bool>`. That binding was narrowed from `$session`, which was narrowed from `$plan`, which is
the list's `@State`; so the write lands in the one plan the app has. SwiftUI sees the state change
and runs the `body` of every view that read it. The row redraws ticked, and the footer computes
`weekTotal` again from the plan that now includes the tap. **No line of this code copies a number
from one place to another**, and so no line can forget to.

What the code does not do yet is keep the plan when the app is closed, share it with the week
screen without passing bindings through every level, or fetch it from a server. Lessons 7, 12 and 14
add those, one at a time, and the rule from section 02 stays the same through all three.
