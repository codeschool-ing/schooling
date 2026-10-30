---
title: Turning the phone builds a new activity
version: 1
---

**When the configuration changes, the system destroys the activity and creates a new one.** The
configuration is everything about the device a resource could depend on: orientation, screen size,
language, dark mode, font scale. Lesson 1 section 07 showed folders like `values-pt` and
`values-night` chosen by it. The simplest way to make sure every resource is chosen again is to
start the screen again, and that is what Android does by default.

The second test of section 03 turns the phone, which is what `scenario.recreate()` does:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --rerun --tests "*LifecycleTest.rotation" 2>&1 | grep -E "STANDARD_OUT|Lifecycle:|  --|^BUILD"
LifecycleTest > rotation STANDARD_OUT
    D/Lifecycle: onCreate: instance 1 in this process, saved state: false
    D/Lifecycle: onStart
    D/Lifecycle: onResume
    -- the user turns the phone
    D/Lifecycle: onPause
    D/Lifecycle: onStop
    D/Lifecycle: onSaveInstanceState
    D/Lifecycle: onDestroy: finishing false, configuration change true
    D/Lifecycle: onCreate: instance 2 in this process, saved state: true
    D/Lifecycle: onStart
    D/Lifecycle: onResume
BUILD SUCCESSFUL in 18s
```

Read it as two lives. The first instance goes down through `onPause` and `onStop`, saves its state,
and is destroyed with `configuration change true`, which is the system saying it will make
another straight away. Then **a different object** starts: `instance 2 in this process`, and this
time `saved state: true`. The `Bundle` that `onSaveInstanceState` filled is handed to the new
`onCreate`.

## What crosses, and what does not

Three kinds of value, three different fates, in that one rotation:

- **A field of the activity is lost.** It belonged to the object that was destroyed. A list of
  sessions kept in `private val sessions = mutableListOf<StudySession>()` is empty again after the
  turn.
- **What went into the `Bundle` comes back.** It was written by the old instance and read by the new
  one. The framework saves some things there for you, the text in a native text field among them,
  and lesson 4's `rememberSaveable` puts Compose state there.
- **What lives outside the activity is untouched.** `ProcessWide.created` went from 1 to 2 because
  the object holding it is the same: rotation replaces the activity and keeps the process.
  Lesson 10's `ViewModel` is built on this fact.

Before Compose and `ViewModel`, the first item was the most common Android bug there was: fill a
form, turn the phone, and the form is empty. The cure was code in every activity to put each field
into the `Bundle` and take it out again, and lesson 4 shows how much of that is now one word.

## Opting out, and why not to

An activity can declare in the manifest that it handles a change itself:
`android:configChanges="orientation|screenSize"`. The system then calls `onConfigurationChanged` on
the existing instance instead of rebuilding it. It looks like the cure and it is a trap: **only the
changes listed are handled**, so the same activity is still rebuilt when the language or dark mode
changes, and any resource that depended on the orientation is now your job to reload. Google's
documentation recommends it only for activities that genuinely cannot be rebuilt, a video player
being the usual example. This course does not use it, and lesson 4 makes it unnecessary.
