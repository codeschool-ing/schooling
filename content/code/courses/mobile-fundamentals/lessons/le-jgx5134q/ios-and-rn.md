---
title: iOS scene phases, suspension, and React Native's AppState
version: 1
---

**iOS describes the same lifecycle with three phases and one silent state.** A SwiftUI app reads the
phase of its scene, one window of its interface, from `scenePhase`, which has three values, and
UIKit's older delegate methods report the same moves in more detail:

| scene phase | Apple's description | the state in this course |
|---|---|---|
| `.active` | in the foreground and receiving events | **active** |
| `.inactive` | "in the foreground but should pause its work" | **inactive** |
| `.background` | "isn't currently visible in the UI" | **background** |
| none | suspended: in memory, not executing | **suspended** |

**There is no phase for suspended, because a suspended app runs no code to observe it.** Apple's
guide to the background says that when the user leaves an app, it "moves to the background state
briefly before UIKit suspends it", and that UIKit can disconnect a background or suspended scene "at
any time to reclaim its resources". The documentation of `.background` is blunter: "Expect an app
that enters the background phase to terminate."

## Inactive is the interruption

**`.inactive` is what a phone call, the notification centre or the app switcher does to an app
that stays on screen.** Apple's guide says the system deactivates an app "when it needs to interrupt
them temporarily", for example to show system alerts, and reactivates it when the panel is
dismissed. Leaving for the home screen passes through it too: the documented sequence is
`applicationWillResignActive`, then `applicationDidEnterBackground`, then a snapshot of the screen
for the app switcher, and then the app "may be suspended".

**Apple asks for the save earlier than Android does.** Its guide to running in the background says to
use deactivation, the move to `.inactive`, to "save user data to disk and close any open files", and
the move to the background to free memory and hide sensitive information. And
`applicationWillTerminate`, the method whose name sounds like a goodbye, is described as "generally
not called" for apps that support background execution when the user quits, because the app simply
moves to the background. A suspended app that the system terminates is told nothing.

## React Native: one listener for both

**React Native reports the lifecycle through `AppState`, with three values.** Its documentation
lists them:

| AppState | React Native's description | on which platform |
|---|---|---|
| `active` | running in the foreground | both |
| `background` | in another app, on the home screen, or on Android behind another Activity | both |
| `inactive` | transitioning between foreground and background, or interrupted, for example by an incoming call | iOS only |

**`inactive` exists on iOS alone**, because Android has no single equivalent that React Native
reports. A React Native app listens for the `change` event and receives the new value; the screen
code is the same on both phones, and the one line that differs is whether `inactive` ever arrives.
There is nothing for suspended or killed, for the same reason as on iOS: no code runs to hear it.

## Three vocabularies, one model

| this course | Android | iOS | React Native |
|---|---|---|---|
| active | resumed | `.active` | `active` |
| inactive | paused | `.inactive` | `inactive`, iOS only |
| background | stopped | `.background` | `background` |
| suspended | cached process | suspended | nothing |
| not running | no process | not running | nothing |

The next section puts that table into a program, so that you can feed it an afternoon and read what
each platform would have said.
