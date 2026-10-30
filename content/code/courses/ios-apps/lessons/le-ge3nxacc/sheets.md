---
title: Sheets, for a task that comes back
version: 1
---

**A sheet is a screen that slides up over the current one for a task the person finishes or
abandons, and then it goes away and leaves them where they were.** Adding a session is the planner's
case: from a course's screen, the person taps *Add*, fills in a date and a length, and either saves
or cancels. Pushing the form onto the stack would put it in the back history, where it does not
belong. Nothing in this section was run; it is written from Apple's documentation for
`sheet(isPresented:onDismiss:content:)`, `sheet(item:onDismiss:content:)` and `DismissAction`.

```swift
// CourseDetailView.swift
struct CourseDetailView: View {
    let courseID: String
    @Environment(PlannerModel.self) private var model
    @State private var adding = false

    var body: some View {
        List(model.plan.sessions(of: courseID)) { session in
            SessionRow(session: session)
        }
        .toolbar {
            Button("Add") { adding = true }
        }
        .sheet(isPresented: $adding) {
            SessionForm(courseID: courseID)
        }
    }
}
```

**`adding` is the one piece of state this screen owns**, lesson 6's `@State` used as intended:
nothing else needs to know whether the form is open. The sheet shows while it is `true`, and SwiftUI
sets it back to `false` when the sheet goes, whichever way it went.

The form closes itself with the `dismiss` action from the environment:

```swift
// SessionForm.swift
struct SessionForm: View {
    let courseID: String
    @Environment(\.dismiss) private var dismiss
    @Environment(PlannerModel.self) private var model

    var body: some View {
        NavigationStack {
            Form { /* lesson 10 */ }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { save(); dismiss() } }
                }
        }
    }

    private func save() { /* lesson 10 */ }
}
```

**The sheet has its own `NavigationStack`**, and that is not the nesting section 02 warned about: a
sheet is a separate presentation, and a stack inside it is what gives the form its own bar for
*Cancel* and *Save*.

When a sheet shows one item, a session to edit, `sheet(item:)` takes an optional `Identifiable`
value: the sheet shows when it is not `nil` and is handed the value, and it is set back to `nil` on
dismissal. That puts *which* session in the state that also decides *whether*, which is one fact in
one place again.

A person can also swipe a sheet down. Apple's documentation for `interactiveDismissDisabled(_:)`
shows how to stop that while a form has unsaved changes, so a half-typed session is not lost to a
stray swipe; lesson 10 uses it.
