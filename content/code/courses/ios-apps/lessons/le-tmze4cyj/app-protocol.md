---
title: The App protocol, and the program that never returns
version: 1
---

**A SwiftUI app is a value that describes the app, and SwiftUI is the program that runs it.** That is
the opposite of lesson 1's `week`, where `main.swift` ran from its first line to its last and the
process ended. An app's entry point describes what should be on the screen, hands that description
to the system, and the system keeps the process alive, drawing, reacting and asking again, until the
person or iOS ends it.

Here is the planner's entry point, the file lesson 1 section 06 first showed. Nothing in this
section was run for the course; it is written from Apple's documentation for `App`, read on 30
October 2026:

```swift
// PlannerApp.swift
import SwiftUI
import PlannerCore

@main
struct PlannerApp: App {
    var body: some Scene {
        WindowGroup {
            CourseListView()
        }
    }
}
```

Three things in it carry the weight.

**`@main` marks the one entry point of the program.** Apple's documentation says the `App` protocol
supplies a default `main()` that the system calls to launch the app, and that a program may have
exactly one entry point among all its files. In lesson 1's package, `week` had a `main.swift`
instead; a target can have one or the other, never both.

**`struct PlannerApp: App` is a value type.** It holds no window and no screen. SwiftUI creates it,
reads its `body`, and may read that `body` again; lesson 3 is about why a `body` runs more than once
and why that is cheap.

**`var body: some Scene` is a computed property that returns scenes, not views.** A scene is the
next level down, and section 03 is about it. `some Scene` means "one particular type that conforms
to `Scene`, which the compiler knows and you do not have to write"; lesson 3 section 03 takes `some`
apart.

## Where state that belongs to the whole app goes

An `App` can hold state that every scene shares, because it is created once for the life of the
process. Apple's documentation shows a model created in the `App` and handed to its scenes through
the environment. The planner does exactly that from lesson 7, when its plan moves into an
`@Observable` model; until then, the plan is created further down, in the first screen.

## Main actor, by default

Apple's documentation adds a sentence that matters for the `swift` course's lesson 15: a type that
conforms to `App` in its own declaration inherits `@MainActor` isolation from the protocol. **Every
property and method of `PlannerApp` runs on the main actor**, the one that draws the screen, unless
you say otherwise. Most interface code wants exactly that. Lesson 12 is where the planner has work
that should not happen there, and moves it off.
