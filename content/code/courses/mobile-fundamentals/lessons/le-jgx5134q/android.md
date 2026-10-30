---
title: Android: six callbacks, and the process behind them
version: 1
---

**On Android the lifecycle belongs to an Activity, a screen-sized piece of the app, and the system
calls six methods on it as it moves between states.** The Activity reference lists them, and each
one is the system telling the app that something has already happened or is about to:

| callback | what it means | the state in this course |
|---|---|---|
| `onCreate` | the Activity is being built; it receives the state saved before, if there was any | not running → starting |
| `onStart` | it is becoming visible | starting |
| `onResume` | it is in front and receives the user's touches | **active** |
| `onPause` | it has lost the foreground; still visible, maybe partly | **inactive** |
| `onStop` | it is no longer visible at all | **background** |
| `onDestroy` | the Activity is about to be destroyed | finishing, or rebuilding |

Coming back from the background adds a seventh, `onRestart`, before `onStart` and `onResume`.

## The column that matters most

**The Activity reference marks three of these methods as "killable": after `onPause`, `onStop` or
`onDestroy` returns, the process may be killed "at any time without another line of its code being
executed".** That sentence is the whole of Android's side of this lesson. A stopped Activity is told
it is stopped, and then it may simply cease to exist. The reference says of `onStop` that next the
app will receive either `onRestart`, `onDestroy`, "or nothing", and it says of `onDestroy` that
there are situations where the system kills the hosting process without calling it, "or any others".

**`onDestroy` is therefore not a goodbye.** It runs when the user finishes the Activity, for example
by going back from it, and when the system rebuilds it for a configuration change such as rotating
the phone. It does not run when the process is killed to free memory, which is the case that loses
the user's work.

## Process, not Activity

**The system kills processes, not screens.** Android's guide to the Activity lifecycle says it
plainly: "The system never kills an activity directly to free up memory. Instead, it kills the
process the activity runs in, destroying not only the activity but everything else running in the
process as well." Everything in memory goes at once: the variables, the half-typed text, the list
that was loaded from the network.

How likely that is depends on the process's state, and the same guide gives the order:

| process state | the Activity in it | likelihood of being killed |
|---|---|---|
| foreground | resumed | lowest |
| visible, no focus | started or paused | low |
| background, invisible | stopped | higher |
| empty | destroyed | highest |

**The stopped app in the background is the ordinary victim.** Android's guide to processes calls a
process that is not currently needed a cached process, and says "the system is free to kill it as
needed when resources like memory are needed elsewhere", and that a well-running system "regularly
kills the cached apps". This course calls that state suspended: in memory, doing nothing, and next in
line.

## What the guide says about saving

**`onPause` is too short for saving, and `onStop` is where the heavy work goes.** The lifecycle guide
says `onPause` "is very brief and does not necessarily offer enough time to perform save operations",
and tells the developer not to use it to save user data, make network calls or run database
transactions; it points to `onStop` for "relatively CPU-intensive shutdown operations". So on
Android the last reliable moment is `onStop`, and the section after next turns that into a rule.

The Kotlin course after the fork, `android-apps`, builds these callbacks into a real app in its
lesson 2, if you take that route. Here they stay names, and the program in this lesson prints them.
