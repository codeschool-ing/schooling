---
title: '@Bindable: a binding into somebody else''s model'
version: 1
---

**A control needs a `Binding`, and a plain reference to an observable object cannot make one.**
`TextField` wants `Binding<String>`, `Toggle` wants `Binding<Bool>`. Lesson 6 made bindings with `$`
on a `@State` or `@Binding` property; a view that holds the model as `let model` has no `$model` to
use. `@Bindable` is the wrapper that adds one. Nothing in this section was run; it is written from
Apple's documentation for `Bindable`.

The planner's week screen lets the person move `today`, to look at another week:

```swift
// WeekView.swift
import SwiftUI
import PlannerCore

struct WeekView: View {
    @Bindable var model: PlannerModel

    var body: some View {
        let week = model.week
        Form {
            TextField("Any day of the week", text: $model.today)
            LabeledContent("Monday", value: week.monday)
            LabeledContent("Planned", value: "\(week.planned) min")
            LabeledContent("Done", value: "\(week.done) min")
        }
        .navigationTitle("This week")
    }
}
```

**`@Bindable` neither owns nor watches.** It holds the same reference `let` would, and adds the
projected value: `$model.today` is a `Binding<String>` that reads and writes the model's `today`. The
watching is still Observation's, through `body` reading `model.week`. Typing in the field writes
`today`, and section 03's first scene is what happens next: every view that read `today` draws again.

A real screen would not let a person type a day as text and trust it; lesson 10 replaces this field
with a `DatePicker` and checks what comes back before it reaches `mondayOf`, which stops the program
on a string that is not a day.

**When a view only needs a binding for a moment**, inside `body`, it can make one there instead of
changing its property:

```swift
var body: some View {
    @Bindable var model = model
    TextField("Any day of the week", text: $model.today)
}
```

Apple's documentation shows this form for a model the view read from the environment, which is
section 06's subject.
