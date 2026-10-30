---
title: The main actor
version: 1
---

Every app has one thread that draws the screen and receives taps, and on Apple's platforms, as on
Android, **the interface may only be touched from that thread**. Change a label from anywhere else and
the result is undefined: a screen that flickers, or a crash a long way from the line that caused it.
Swift models that thread as an actor, **`MainActor`**, and anything marked `@MainActor` is isolated to
it in exactly the way `minutes` was isolated to `WeekTotal`.

SwiftUI and UIKit mark their views and view controllers `@MainActor`, so the compiler stops you from
updating the screen from a background task. Neither framework exists on Linux, and this lesson does
not run them. What it can run is the rule itself, on a class of its own standing in for a screen:

```swift
// Screen.swift
@MainActor
final class WeekScreen {
    var title = "This week"
    func show() { print("screen: \(title)") }
}

func loadTitle() async -> String {
    try? await Task.sleep(for: .milliseconds(100))
    return "135 of 300 minutes"
}

func refreshFromAnywhere(_ screen: WeekScreen) async {
    let title = await loadTitle()
    screen.title = title
}
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Screen.swift -o screen
Screen.swift:15:12: error: main actor-isolated property 'title' can not be mutated from a nonisolated context
 2 | @MainActor
 3 | final class WeekScreen {
 4 |     var title = "This week"
   |         `- note: mutation of this property is only permitted within the actor
 5 |     func show() { print("screen: \(title)") }
 6 | }
   :
13 | func refreshFromAnywhere(_ screen: WeekScreen) async {
14 |     let title = await loadTitle()
15 |     screen.title = title
   |            |- error: main actor-isolated property 'title' can not be mutated from a nonisolated context
   |            `- note: consider declaring an isolated method on 'MainActor' to perform the mutation
16 | }
17 | 
```

`refreshFromAnywhere` is not isolated to any actor, which the compiler calls **nonisolated**, so it
may run on any thread, and the title belongs to the main actor. Refused, with a note that points at
the fix: do the mutation in code that is isolated to the main actor.

```swift
// ScreenFixed.swift
@MainActor
final class WeekScreen {
    var title = "This week"
    func show() { print("screen: \(title)") }
}

func loadTitle() async -> String {
    try? await Task.sleep(for: .milliseconds(100))
    return "135 of 300 minutes"
}

@MainActor
func refresh(_ screen: WeekScreen) async {
    let title = await loadTitle()
    screen.title = title
    screen.show()
}

let screen = WeekScreen()
await refresh(screen)
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 ScreenFixed.swift -o screenfixed && ./screenfixed
screen: 135 of 300 minutes
```

**`refresh` is `@MainActor`, so it runs on the main actor and may touch the screen directly.** The
slow part, `loadTitle`, is nonisolated and runs wherever the system puts it; at the `await` the main
actor is free to draw and answer taps, and when the title arrives `refresh` resumes on the main actor
to set it. That is the shape of nearly every screen update in an app: load away from the main actor,
then set on it.

The top level of a program runs on the main actor too, which is why both errors of section 03
mentioned it, and why `let screen = WeekScreen()` at the top level needed no `await`.

## A Task inherits its actor, and a detached task does not

Lesson 14 promised one difference between `Task { … }` and `Task.detached { … }`. Here it is, from a
button handler that runs on the main actor, as handlers do:

```swift
// Inherit.swift
@MainActor
final class WeekScreen {
    var title = "This week"
}

@MainActor
func buttonTapped(_ screen: WeekScreen) {
    Task {
        screen.title = "refreshing"
    }
    Task.detached {
        screen.title = "refreshing"
    }
}
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Inherit.swift -o inherit
Inherit.swift:13:16: error: main actor-isolated property 'title' can not be mutated from a nonisolated context
 2 | @MainActor
 3 | final class WeekScreen {
 4 |     var title = "This week"
   |         `- note: mutation of this property is only permitted within the actor
 5 | }
 6 | 
   :
11 |     }
12 |     Task.detached {
13 |         screen.title = "refreshing"
   |                |- error: main actor-isolated property 'title' can not be mutated from a nonisolated context
   |                `- note: consider declaring an isolated method on 'MainActor' to perform the mutation
14 |     }
15 | }
```

**Only the detached task is refused.** A plain `Task` started on the main actor runs on the main actor,
so its body may set the title as `buttonTapped` itself may. A detached task inherits nothing and is
nonisolated, so the same line is a mutation from a nonisolated context. That inheritance is what makes
`Task { … }` the right bridge from a handler, and why `Task.detached` is rarely what you want.
