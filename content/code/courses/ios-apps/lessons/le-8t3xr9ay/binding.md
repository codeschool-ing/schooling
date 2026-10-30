---
title: '@Binding: writing to storage you do not own'
version: 1
---

**A child view that changes a value it does not own is handed a binding to it.** A binding is not a
copy and not the storage: it is a pair of operations, read the value and write the value, that reach
back to wherever the owner keeps it. SwiftUI's controls are built on it. A `Toggle` takes
`isOn: Binding<Bool>`, a `TextField` takes `text: Binding<String>`, and neither has any idea whether
the value lives in `@State`, in an observable object or somewhere else.

Nothing in this section was run for the course; it is written from Apple's documentation for
`Binding` and `Toggle`. Here is a row of the planner's course screen that marks a session done:

```swift
// SessionRow.swift
import SwiftUI
import PlannerCore

struct SessionRow: View {
    @Binding var session: StudySession

    var body: some View {
        Toggle(isOn: $session.done) {
            Text("\(session.date) · \(session.minutes) min")
        }
    }
}
```

**The dollar sign is the projected value.** On a `@State` property or a `@Binding` property, `$name`
is a `Binding` to it. `$session.done` goes one step further: a binding to the `done` field inside the
session, made from the binding to the whole session. `Binding` supports that through Swift's
dynamic member lookup with key paths, which is why `$plan.sessions[2].done` is also a binding.

The parent hands one binding per row. `ForEach` accepts a binding to a collection and gives the
closure a binding to each element:

```swift
// in CourseDetailView's body
List {
    ForEach($plan.sessions) { $session in
        SessionRow(session: $session)
    }
}
```

`{ $session in` declares the closure's parameter as a binding and, inside, `session` reads the value
and `$session` is the binding again. When the person flips a toggle, the write goes through two
bindings into the parent's `@State`, the parent's `body` runs again, and the total under the list is
recomputed from the same plan. **The child never held a copy of `done`, so there is no copy to fall
behind.**

A binding can also be made from scratch, with `Binding(get:set:)`, and `Binding.constant(true)` is
one that ignores writes, which is how a preview shows a row without a parent. Section 05 builds the
type itself.
