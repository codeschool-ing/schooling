---
title: ObservableObject, the way it was done before iOS 17
version: 1
---

**Most SwiftUI code written before 2023, and much written since, uses an older mechanism, and you
will read it long before you stop meeting it.** It is the `ObservableObject` protocol from the
Combine framework, with `@Published` properties, and four wrappers to go with it. Combine exists only
on Apple systems, so none of this compiles on Linux and none of it was run for the course; it is
written from Apple's guide *Migrating from the Observable Object protocol to the Observable macro*.

```swift
import Combine
import SwiftUI

final class OldPlannerModel: ObservableObject {
    @Published var plan = Plan()
    @Published var today = "2026-10-21"
}

struct OldWeekView: View {
    @ObservedObject var model: OldPlannerModel
    var body: some View {
        Text("\(model.plan.weekTotal(today: model.today).done) min")
    }
}
```

**The difference that matters is what a view is subscribed to.** With `ObservableObject`, a view that
holds the object is subscribed to the whole object: the class announces *something will change* before
any `@Published` property is written, and every view holding it runs `body` again, whatever it read.
Section 03's scenes would have redrawn all three screens for every change, `lastSaved` included unless
it was left unpublished. With `@Observable`, as measured there, a view is subscribed to what its
`body` read.

The wrappers map across like this:

| before iOS 17 | with Observation |
|---|---|
| `@StateObject var model = Model()` | `@State var model = Model()` |
| `@ObservedObject var model: Model` | `let model: Model`, or `@Bindable` for bindings |
| `@EnvironmentObject var model: Model` | `@Environment(Model.self) var model` |
| `.environmentObject(model)` | `.environment(model)` |

**`@StateObject` and `@ObservedObject` are the pair people confuse**, and the confusion is lesson 6's
first trap with an object in it. `@StateObject` creates and keeps; `@ObservedObject` only watches one
it was handed. Writing `@ObservedObject var model = Model()` creates a new model every time the parent
redraws, and the screen loses everything it had. The Observation spelling cannot make that mistake
quietly in the same way, because ownership is always `@State`.

Apple's guide converts an app one class at a time, and both kinds can live in one app while that
happens. For a new app with iOS 17 as its floor, as the planner has, `@Observable` is what to write.
