---
title: Launching, being ended, and coming back
version: 1
---

**An app that was ended in the background and opened again starts from nothing, and the person should
not be able to tell.** They left it on a course's detail screen with a session half typed; iOS
reclaimed the memory; they tap the icon and expect to be where they were. Two different things have
to survive for that, and SwiftUI gives each its own place.

| what | example | where it goes |
|---|---|---|
| the data | the plan: courses and sessions | written to disk by the app, at the moment section 05 decided to save |
| where the person was | which course was open, which tab, what was typed in a field | `@SceneStorage`, which SwiftUI saves and restores per scene |

**Mixing the two is the common mistake.** `@SceneStorage`, Apple's documentation says, is for small
values: it makes no guarantee about when or how often the value is saved, and it is destroyed when
the scene is, for example when a person removes the app's window from the iPad's switcher. A plan
kept there could vanish with a window. Data the person would miss goes in a file or a database, which
lessons 13 and 14 build; `@SceneStorage` keeps only what is cheap to lose.

## Wiring the decision into the app

Section 05 wrote the decision in plain Swift. This is the app's half: read the phase, turn it into the
planner's `Phase`, and act on what `Lifecycle` answers. Nothing here was run for the course:

```swift
// PlannerApp.swift
import SwiftUI
import PlannerCore

extension Phase {
    init(_ phase: ScenePhase) {
        switch phase {
        case .active: self = .active
        case .inactive: self = .inactive
        case .background: self = .background
        @unknown default: self = .inactive
        }
    }
}

@main
struct PlannerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var lifecycle = Lifecycle(phase: .active)

    var body: some Scene {
        WindowGroup {
            CourseListView()
        }
        .onChange(of: scenePhase) { _, new in
            switch lifecycle.move(to: Phase(new)) {
            case .save: print("save the plan")        // lesson 14 writes it
            case .refresh: print("recompute the week") // lesson 6 shows it
            case .nothing: break
            }
        }
    }
}
```

**`@unknown default` is there because `ScenePhase` belongs to Apple and may gain a case in a later
iOS.** The compiler asks for it on a switch over an enum from another module that may grow, and
mapping an unknown phase to `inactive` means "do nothing for now" rather than a crash. Because the
`onChange` is on the `App`, the phase it sees is the aggregate over every window, which is what
deciding when to save the shared plan needs.

The two `print` lines stand for work later lessons do. They also make the decision visible: on a Mac,
Xcode's console would show one line per move, and the sequence would match the tests of section 05.

## What the launch itself does

On a cold launch iOS starts the process, SwiftUI creates `PlannerApp`, reads its `body`, and the
scene goes from nothing to active. **There is no separate launch callback to put work in**, and
lesson 12 shows where loading data belongs instead: in a task attached to the view that needs it, so
it starts when the view appears and is cancelled if the view goes away first.
