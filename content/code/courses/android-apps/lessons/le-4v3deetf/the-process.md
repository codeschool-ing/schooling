---
title: The process, and the day the system takes it away
version: 1
---

**An Android app is a Linux process, and the system kills it whenever it needs the memory.** Not
when the app crashes, not when the user closes it: when a phone with four apps open wants room
for a fifth, the ones in the background go, and their owners are not asked. `mobile-fundamentals`
lessons 4 and 5 describe this for both platforms; this section is what it means for an activity.

Every app starts the same way. Android keeps one process running from boot, called the **zygote**,
with the framework's classes already loaded, and a new app's process is a copy of it made with
`fork`. That is why an app starts in a fraction of a second although the framework is large. The
new process then creates the `Application` object, then the activity the user asked for.

## Process death, step by step

**Not run.** None of this can be shown on a computer without a device: Robolectric runs inside the
test's JVM, and that process is not killed. What follows is the sequence Google's documentation of
the activity lifecycle and of saved state describes, and the one `mobile-fundamentals` lesson 5
draws.

1. The user opens the planner, goes to a course, and presses Home. The activity stops and
   `onSaveInstanceState` writes its `Bundle`, the call section 04's rotation showed.
2. Some time later the system needs memory and kills the planner's process. **No callback runs**:
   not `onDestroy`, not anything. The process is simply gone, and every object in it with it.
3. The system keeps two things: the task, which remembers which activities were on the screen, and
   their saved `Bundle`s.
4. The user taps the planner in the recent apps list. A new process is forked, `ProcessWide.created`
   starts from 0 again, and the activity is created with the old `Bundle`: `saved state: true`, in
   a process that has never seen this activity before.

The user sees the screen they left. **That is the whole point, and it fails silently** when the
screen depended on something that lived only in memory: a list loaded in a field, a value in an
`object`, a cache. On the phone of whoever tests the app, with plenty of memory, it never happens;
on the phone of a student with a cheap device and twenty apps open, it happens every day.

On a device, Google's documentation reproduces it with the app in the background and
`adb shell am kill com.example.planner`, which kills the process the way the system would. Developer
options also have a setting, *Don't keep activities*, that destroys every activity as soon as it
stops. **Not run** here.

## What survives what

| where a value lives | rotation | Home, then back | process death | the user swipes the app away |
|---|---|---|---|---|
| a field of the activity | lost | kept | lost | lost |
| the saved `Bundle` | kept | kept | kept | lost |
| an `object`, or a `ViewModel` | kept | kept | lost | lost |
| a file or a database | kept | kept | kept | kept |

**Only the last row survives everything**, which is why lesson 15 puts the planner's sessions in a
database. The `Bundle` is for the small things that describe where the user was, an open course
or a half-typed name. It has a size limit: Google's documentation recommends keeping saved state under 50 kB, because
it travels between processes and a transaction that is too large throws
`TransactionTooLargeException`. Swiping the app out of the recent list is the user saying they are done, and even the
`Bundle` goes with it.
