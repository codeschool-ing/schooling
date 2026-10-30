---
title: The frame budget, and the thread that spends it
version: 1
---

**A phone redraws its screen 60 to 120 times a second, and every redraw has to be finished on one
thread, the main thread, before the next one is due.** At 60 Hz that leaves 16.7 milliseconds per
frame; at 90 Hz, 11.1; at 120 Hz, 8.3. The same thread also receives every touch. Anything else that
runs there, a query, a JSON parse, a file read, spends that budget, and a frame that misses it is
dropped. The person sees the list stutter while they scroll.

The wrong picture is that a fast database makes this a non-issue. A query that takes 4 ms on the
developer's new phone with a hundred rows takes 40 on a five-year-old phone with three years of
sessions, which is lesson 3's twenty thousand. **The question is never whether the query is fast,
but which thread waits for it.**

## What each platform does when the main thread stops

| | what it measures | what happens |
|---|---|---|
| Android | an input event not handled within 5 seconds | the system shows "App isn't responding" and offers to close it: an ANR |
| Android | `StrictMode`, in a debug build | reports each disk read or write on the main thread, as it happens |
| Room | a query on the main thread | refuses with `IllegalStateException`, unless the builder says `allowMainThreadQueries()` |
| iOS | launching, resuming or suspending for too long | the watchdog ends the app; its crash report carries the code `0x8badf00d` |
| React Native | the JavaScript thread busy | touches queue up and JavaScript-driven animations freeze, while native ones keep running |

Five seconds sounds generous, and it is the limit for the app being killed, not for the person
noticing. Somebody notices a dropped frame; an ANR is what they report in the store.

## The two ways out

There are two answers, and this lesson does both.

**Move the work off the main thread.** The query runs elsewhere and the screen keeps drawing while
it does; the answer arrives as a callback, a `Flow`, an `await`. The next two sections show what
"elsewhere" is in Node and on each platform.

**Do less of it.** A list showing fifty rows has no use for twenty thousand. Reading one screen's
worth, and the next when the person scrolls, keeps each query small enough that even a slow phone
finishes it inside a frame. That is paging, the last section, and it has a trap of its own.

The two are not alternatives. A query off the main thread that reads twenty thousand rows still
makes the person wait for the list, only without the stutter; a small query on the main thread is
still a disk read on the thread that draws. The planner does both, which is what Room and SwiftData
nudge you towards anyway.
