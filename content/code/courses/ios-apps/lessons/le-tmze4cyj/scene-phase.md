---
title: The scene phase: active, inactive, background
version: 1
---

**iOS tells a scene which of three phases it is in, and the app is expected to react.** SwiftUI
exposes the value as `scenePhase` in the environment, of type `ScenePhase`, and its three cases are
the whole vocabulary:

| phase | what it means, from Apple's documentation for `ScenePhase` |
|---|---|
| `active` | the scene is in the foreground and interactive |
| `inactive` | the scene is in the foreground but should pause its work: a banner or the app switcher is over it |
| `background` | the scene is not visible; the documentation says to expect the app to be terminated soon after |

The mistaken picture is that an app runs until the person closes it. **On iOS a person almost never
closes an app.** They go to the home screen, and the app moves to the background; from there, iOS may
suspend it, and may end the process to reclaim memory without asking it first. When the person comes
back to an app that was ended, it starts from nothing. So anything worth keeping has to be written
before that, and Apple's documentation for managing an app's life cycle names the moment: save data
upon leaving the foreground-active state.

## Reading it

Any view, or the `App` itself, reads the phase from the environment and reacts to a change with
`onChange(of:)`:

```swift
struct WeekView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Text("…")
            .onChange(of: scenePhase) { old, new in
                print("phase", old, "→", new)
            }
    }
}
```

**Where it is read changes what it means.** Apple's documentation is precise here: read inside a
view, the value is the phase of the scene that contains that view; read inside the `App`, it is an
aggregate over all the app's scenes, `active` if any of them is active and `background` only when
all of them are. On an iPhone with one window the two agree. On an iPad with two planner windows, one
in the background and one in front, a view in the first sees `background` and the `App` sees
`active`.

`onChange(of:)` gives the old and the new value to its closure, which is the form iOS 17 introduced.
The documentation warns that the closure may run on the main actor and should not do long work
there; saving the plan, in section 07, is a short write.

## The order a phone goes through them

Going to the home screen and coming back is not two moves but four: active to inactive, inactive to
background, and then background to inactive and inactive to active. **Pulling a banner down over the
app is two moves that never reach the background**, and that difference is the whole point of the
next section, where the decision that reacts to them is written in plain Swift and tested.

Nothing in this section was run for the course. It is written from Apple's documentation for
`ScenePhase` and `onChange(of:initial:_:)`, read on 30 October 2026, and the order of the moves is
the one Apple's documentation for managing an app's life cycle describes.
