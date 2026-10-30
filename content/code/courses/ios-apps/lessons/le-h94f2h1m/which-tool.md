---
title: Which tool, for which state
version: 1
---

**Lessons 6 and 7 have given you six ways to hand a view its data, and the choice between them is a
question about ownership.** Who creates the value, who changes it, and how far away is the view that
reads it. The table says it once:

| the view… | the data is… | write |
|---|---|---|
| only reads it | a value | `let session: StudySession` |
| owns it, and nobody else needs it | a value | `@State private var expanded = false` |
| changes a value its parent owns | a value | `@Binding var session: StudySession` |
| creates a shared model | an `@Observable` class | `@State private var model = PlannerModel(…)` |
| reads or calls a model it was handed | an `@Observable` class | `let model: PlannerModel` |
| needs bindings into a model it was handed | an `@Observable` class | `@Bindable var model: PlannerModel` |
| reads a model many views at many depths need | an `@Observable` class | `@Environment(PlannerModel.self) private var model` |

**Two questions settle almost every case.** First: is this a value or an object? A value
— a session, a draft being typed, a flag — goes in `@State` with its owner and travels by
`let` or `@Binding`. An object holds state that outlives one screen and that several screens share.
Second: who creates it? Whoever creates it holds it in `@State`, value or object, and is the only one
that does.

In the planner that comes out as four decisions. `PlannerApp` creates `PlannerModel` and puts it in
the environment. `CourseListView`, `CourseDetailView` and `WeekView` read it from there. `SessionRow`
takes a `@Binding` to one session, or a plain value plus a closure. And `SessionForm`, lesson 10,
keeps its draft in its own `@State` until the person saves, because a half-typed session belongs to
nobody else yet.

**What is never on the list** is a second owner: a child that copies a value it was given into its
own `@State`, or a view that makes its own `PlannerModel()` instead of receiving the one the app
created. Both compile, both work on the first screen, and both give the app two plans.
