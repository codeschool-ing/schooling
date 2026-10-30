---
title: Form and Section, and the screen they make
version: 1
---

**`SessionForm` is the planner's one screen where somebody types, and SwiftUI has a container made for
it.** `Form` groups controls for data entry, and Apple's documentation for it says what it does with
them: on iOS a form appears as a grouped list, rows in rounded groups with a heading over each, and the
same code on macOS lays out as aligned vertical stacks. You describe the fields and the platform
decides how a settings-like screen looks there. Nothing in this section was run for the course: there
is no Mac in its recording, and the code is written from Apple's documentation for `Form`, `Section`,
`Picker`, `DatePicker` and `TextField` as it stood on 30 October 2026.

## The screen

The form needs the courses to choose from and something to call when a session is ready. It keeps a
`SessionDraft`, section 04's type, as its state, and lesson 6 is where `@State` and the `$` in
`$draft.minutesText` were explained:

```swift
// SessionForm.swift
import SwiftUI
import PlannerCore

struct SessionForm: View {
    let courses: [Course]
    let onAdd: (StudySession) -> Void

    @State private var draft = SessionDraft(date: .now)
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Course") {
                Picker("Course", selection: $draft.courseID) {
                    Text("Choose one").tag(String?.none)
                    ForEach(courses) { course in
                        Text(course.title).tag(Optional(course.id))
                    }
                }
            }
            Section("When and how long") {
                DatePicker("Day", selection: $draft.date, displayedComponents: .date)
                TextField("Minutes", text: $draft.minutesText)
            }
        }
        .navigationTitle("New session")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    if let session = draft.session(id: UUID().uuidString, calendar: calendar) {
                        onAdd(session)
                        dismiss()
                    }
                }
            }
        }
    }
}
```

**Each `Section` is one group on the screen, and its string is the heading over it.** Two sections
here, because a person reads the form as two questions: which course, and when and for how long.

Three details carry more than they look:

- **The picker's selection is `String?`, so every tag is `String?` too.** `Text("Choose one")` is
  tagged `nil`, which is the draft's "no course yet", and each course is tagged
  `Optional(course.id)`. Apple's documentation for `Picker` asks that every tag's type match the
  selection's. The current documentation for `tag(_:includeOptional:)` adds that a plain
  `.tag(course.id)` writes the optional version as well, so it would match too; writing `Optional`
  says the type out loud, where a reader can see it.
- **`displayedComponents: .date`** shows the day and hides the time. The picker still binds a whole
  `Date`; section 05 is about turning it into the day the planner stores.
- **The Add button calls `draft.session(…)` and acts only if a session comes back.** The form makes no
  decision of its own about what is valid. That is why section 04 could test every rule without a
  screen, and why the same rules hold on Android and in React Native.

`@Environment(\.calendar)` is the calendar of the phone's settings, the one the person sees in the
picker. `dismiss` closes the sheet the form is presented in, which lesson 9 opened. The `id` is a
fresh `UUID`, because a session's id has to be unique and mean nothing, for the reasons lesson 8 gave.
