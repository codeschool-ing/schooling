---
title: The environment, for what a whole subtree needs
version: 1
---

**The environment is a set of values a view hands to everything below it, read by any descendant
that asks and ignored by every view that does not.** SwiftUI already uses it for its own settings:
the colour scheme, the Dynamic Type size lesson 19 is about, the locale, and actions such as
`dismiss`. A view reads one with `@Environment` and a key path:

```swift
@Environment(\.colorScheme) private var colorScheme
@Environment(\.dismiss) private var dismiss
```

Since iOS 17, an observable object can be put in the environment by its type, and that is how the
planner's model reaches the screens without passing through the views between them. Nothing in this
section was run; it is written from Apple's documentation for `View.environment(_:)` and
`Environment`.

```swift
// PlannerApp.swift
@main
struct PlannerApp: App {
    @State private var model = PlannerModel(plan: Plan(), today: "2026-10-21")

    var body: some Scene {
        WindowGroup {
            CourseListView()
                .environment(model)
        }
    }
}
```

```swift
// WeekView.swift
struct WeekView: View {
    @Environment(PlannerModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let week = model.week
        Form {
            TextField("Any day of the week", text: $model.today)
            LabeledContent("Done", value: "\(week.done) of \(week.planned) min")
        }
    }
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" data-fig=\"l07-env\" aria-label=\"PlannerApp holds one PlannerModel in @State and puts it in the environment at the root. Below it, a tree of views: CourseListView and WeekView read the model from the environment; a NavigationStack and a plain container between them read nothing and take no argument; CourseDetailView, further down, reads the model too. Only the views that ask for the model take it out; the ones in between never mention it.\"><defs><marker id=\"l07-env-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l07-env-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-env-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l07-env-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"230\" y=\"16\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">PlannerApp</text><text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">@State model  ·  .environment(model)</text><rect x=\"60\" y=\"90\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"180\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">NavigationStack</text><rect x=\"420\" y=\"90\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">WeekView</text><rect x=\"60\" y=\"170\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CourseListView</text><rect x=\"420\" y=\"170\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a plain VStack</text><rect x=\"60\" y=\"240\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CourseDetailView</text><path d=\"M300 66 L180 88\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-env-ah-wire)\"></path><path d=\"M420 66 L540 88\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-env-ah-wire)\"></path><path d=\"M180 130 L180 168\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-env-ah-wire)\"></path><path d=\"M540 130 L540 168\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-env-ah-wire)\"></path><path d=\"M180 210 L180 238\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-env-ah-wire)\"></path><rect x=\"330\" y=\"234\" width=\"14\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"352\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">reads @Environment(PlannerModel.self)</text><rect x=\"330\" y=\"262\" width=\"14\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"352\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never mentions the model</text></svg>", "caption": "The model is put in the environment once, at the root. The views that ask for it take it out; the views between them take no argument and never mention it."}
```

**`.environment(model)` on the root puts the model in reach of every view below it**, and
`@Environment(PlannerModel.self)` takes it out where it is needed. `CourseListView()` no longer takes
an argument, and neither does any view between it and the ones that read the model.

**The convenience has a price, and it is paid at run time.** A view that asks for
`PlannerModel.self` when no ancestor provided one does not fail to compile. Apple's documentation for
`Environment` says that **SwiftUI throws an exception** when a view retrieves an object by type and
the object is not in the environment, and the app stops. The commonest way to meet that is a preview
built without the `.environment(model)` line. Where the object may genuinely be absent, the same page
shows asking for an optional, `@Environment(PlannerModel.self) private var model: PlannerModel?`, and
handling `nil`. Lesson 20 writes previews that supply the model.

Two rules keep it honest:

- **put an object in the environment when many views at different depths need it**, the planner's
  model being the case;
- **pass it as a property when one child needs it.** A property is visible in the initialiser, the
  compiler insists on it, and a reader can see where the data comes from.
