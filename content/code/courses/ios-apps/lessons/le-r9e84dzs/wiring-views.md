---
title: Wiring it to the screens
version: 1
---

**Everything above runs without a screen, and that is why it could be tested.** On a Mac, the
screens get the repository and read from it, and the code that does it is short because the
repository already decided everything hard. This section is SwiftUI, written from Apple's
documentation for the `Observable` macro, `task` and `refreshable`, and **it was not run**.

## One object for the screens to watch

The repository is an actor, and SwiftUI draws on the main actor, so a view does not read the
repository directly. It reads lesson 7's `PlannerModel`, an `@Observable` class that holds the plan
the screens draw and asks the repository on their behalf:

```swift
// PlannerModel+Repository.swift
import Observation
import PlannerCore

@MainActor
@Observable
final class PlannerModel {
    private(set) var plan = Plan()
    private(set) var waiting = 0
    private(set) var notice: String?
    let repository: PlannerRepository

    init(repository: PlannerRepository) {
        self.repository = repository
    }

    func show() async {
        plan = await repository.plan
        waiting = await repository.pendingCount
    }

    func refresh() async {
        await show()                                  // what the device has, at once
        do throws(APIError) {
            try await repository.refresh()
            notice = nil
        } catch {
            notice = error.message                    // say so, and keep the plan
        }
        await show()
    }

    func add(_ s: StudySession) async {
        do throws(PlanError) {
            let refused = try await repository.add(s)
            notice = refused.isEmpty ? nil : "The server did not keep \(refused.joined(separator: ", "))."
        } catch {
            notice = "\(error)"
        }
        await show()
    }
}
```

Lesson 7 is where `PlannerModel` is built and explained; this is the shape it takes once a repository
stands behind it. **`show` is called first in `refresh`**, so the screen draws what the device has
before the network has answered, which is section 04's promise reaching the glass.

## The screen

`CourseListView` from lesson 12 no longer holds a `Loadable`. It draws the model's plan, which is
never empty because of the network, and a line above it when there is something to say:

```swift
// CourseListView.swift
import SwiftUI
import PlannerCore

struct CourseListView: View {
    let model: PlannerModel

    var body: some View {
        List {
            if let notice = model.notice {
                Text(notice).font(.footnote)
            }
            if model.waiting > 0 {
                Text("\(model.waiting) not yet sent").font(.footnote)
            }
            ForEach(model.plan.courses) { course in
                Text(course.title)
            }
        }
        .task { await model.refresh() }
        .refreshable { await model.refresh() }
    }
}
```

`refreshable` adds pull-to-refresh to the list, and the system shows its spinner for as long as the
closure runs. **The offline state is now a line of text over a working list, not a screen of its own**,
and that difference is what the repository bought. Lesson 12's error screen still has a place: the
first launch, when the device has nothing at all to show.
