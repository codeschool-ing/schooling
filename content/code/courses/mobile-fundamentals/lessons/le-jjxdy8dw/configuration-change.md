---
title: Rotation on Android, and the other way to lose a screen
version: 1
---

**On Android the process is not the only thing the system takes away: turning the phone destroys
the Activity and builds a new one, with the process still alive.** That surprises most people who meet
it, because nothing about rotating a phone sounds like an ending. It is called a configuration
change, and it is the reason an Android developer meets lost state on the first afternoon rather
than after a week in production.

## What happens when the phone turns

Android's Activity guide says that when a configuration change occurs, such as rotation or entering
multi-window mode, "the system destroys the activity by default", and that it then creates a new
instance in the new configuration and calls `onCreate` on it. Everything held in the old instance's
fields goes with it. The `onDestroy` from lesson 4 runs this time, because the system itself is doing
the rebuilding; the process, and everything outside the Activity, survives.

**So Android has two ways to lose UI state, with two different cures.**

| what happened | the process | the Activity | what the user sees without a cure |
|---|---|---|---|
| the phone was turned | alive | destroyed and rebuilt at once | the form empties as the screen turns |
| the app was killed in the background | gone | gone | the form is empty when they come back |

**iOS has no equivalent of the first row.** Turning an iPhone tells the views that their size has
changed, and they lay themselves out again; nothing is destroyed. A React Native app runs in one
Android Activity that its template configures to handle these changes itself, so its JavaScript
keeps running through a rotation. On those two, only the second row is a danger. Lesson 8 is about
what a turned screen does to a layout; this section is only about what it does to state.

## Memory that survives a rotation, and memory that does not

Android's guide to saving UI state compares its three options along exactly these two rows, and the
table is worth having whole:

| option | where it is kept | survives a configuration change | survives the system killing the process | survives the user closing the screen |
|---|---|---|---|---|
| ViewModel | in memory | yes | no | no |
| saved state | serialised, held by the system | yes | yes | no |
| persistent storage | on disk or the network | yes | yes | yes |

**A ViewModel is the cure for rotation and not for the kill.** It is an object that Android keeps in
memory across the rebuild and hands to the new Activity, so a list loaded from the network does not
load again because the phone turned. But the guide is explicit that "ViewModels are destroyed during
a system-initiated process death": it lives in the process, and the process is what the kill takes.

**Saved state is the cure for both**, at a price. The guide describes it as limited "only for primitive
types and simple, small objects such as String", slow to write because it is serialised, and kept
"outside of your process" by the system. That is how it survives the kill: it was never inside the
process that died. It is also why the guide's own advice is to store in it "a minimal amount of
data necessary, such as an ID". The last section of this lesson measures what happens when that
advice is ignored.

**Persistent storage is for data**, the first row of the previous section's table, and it survives
even the user closing the screen on purpose, which UI state should not.

## A rotation is a free test

**Every Android developer has a rehearsal of process death in their hand.** A rotation rebuilds the
Activity the same way a relaunch after a kill does, so an app that keeps its form through a turn has
at least written the restore path. It has not proved the save path, because a ViewModel can carry a
rotation alone. The kill has to be tested on its own, and the program in this lesson's round trip does
exactly that, without a phone.
