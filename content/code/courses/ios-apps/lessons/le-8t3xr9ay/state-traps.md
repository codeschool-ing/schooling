---
title: Three ways state goes wrong
version: 1
---

**Most `@State` bugs are one of three, and each looks like SwiftUI ignoring you.** None of them is.
Each follows from the two facts in section 03: the struct is made again on every parent update, and
the storage is kept by SwiftUI and initialised once. Nothing here was run for the course; the
behaviour described is the one Apple's documentation for `State` gives.

## The initial value that never updates

```swift
struct WeekView: View {
    @State private var plan: Plan
    init(plan: Plan) { _plan = State(initialValue: plan) }
    var body: some View {
        let total = plan.weekTotal(today: "2026-10-21")
        Text("\(total.done) of \(total.planned) minutes")
    }
}
```

The parent passes a plan, and later passes a different one. The new struct runs its initialiser
with the new plan, and **SwiftUI keeps the storage it already had**, because the view is still on
screen and its state survives. The text shows the old plan's numbers. The fix is not to make this
view the owner: if the parent owns the plan, the child takes `let plan: Plan` to read it, or
`@Binding var plan: Plan` to change it. `@State` is for state that starts with the view and belongs
to it, like whether a section is expanded or what is typed into a field before it is saved.

## Two owners of one fact

A parent with `@State var plan` and a child with its own `@State var plan`, initialised from the
parent's, have two plans. The child's changes stay in the child. The symptom is a screen that shows
a change, and a screen behind it that does not have it when you go back. The question to ask of
every `@State` is **who else needs this value**; if the answer is anybody, the state belongs higher
up, and the others get a binding or a plain value.

## A class in `@State`

```swift
final class Draft { var minutes = 30 }

struct SessionForm: View {
    @State private var draft = Draft()
    var body: some View {
        Stepper("\(draft.minutes) minutes", value: Binding(get: { draft.minutes }, set: { draft.minutes = $0 }))
    }
}
```

The stepper writes `draft.minutes`, and the number on screen does not move. `@State` watches its
value, and the value is a reference to the object; changing a property of the object leaves the
reference the same, so nothing tells SwiftUI to run `body` again. **Keep value types in `@State`,** a
`struct Draft`, and the same code works. A class SwiftUI can watch is lesson 7's `@Observable`.

All three have the same cure: decide which view owns the value, give it `@State` there, and give
everybody else a value to read or a binding to write.
