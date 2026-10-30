---
title: Three kinds of state, and where each one lives
version: 1
---

**A screen holds three kinds of state, and each one has a different place to live and a different
reason to survive.** The common mistake is to treat them as one: either everything is saved, which is
slow and fills the place meant for small things, or nothing is, and the user loses their place
every time the system takes the process away. Sorting them first makes the rest of this lesson
mechanical.

| kind | in the planner | how long it must last | where it lives |
|---|---|---|---|
| **data** | the courses, the sessions, which are done | until the user deletes it | persistent storage: a database or files on the device |
| **UI state** | which course is open, how far the list is scrolled, a half-typed session | until the user comes back to this screen | saved state, kept by the system for the app |
| **ephemeral** | a ripple under the finger, an animation halfway through | nothing; it is redrawn | memory only |

## Data

**Data is what the user would be upset to lose even after closing the app on purpose.** A session
the user added, the fact that it is done, a course they enrolled in. It belongs on the device's disk,
in a database or a file, written when it changes rather than on the way out, and read again on every
launch. That is lesson 16's subject in this course, and `mobile-offline` spends twenty lessons on it.
In this lesson the plan is a constant in the program, standing in for that database: it survives the
kill because it was never only in memory.

## UI state

**UI state is where the user was, and what they had started.** It only matters if the user comes
back to this screen, and it has to look, when they do, as if nothing happened. Android's guide to
saving UI state puts the expectation in one line: a user expects the app's UI state "to remain the
same if they temporarily switch to a different app and then come back", and when the system
destroyed the app in between, saving and restoring is what makes that destruction "transparent to
the user". Three pieces of it are typical:

- what was selected: the open course, the tab, the item in a list. Saved as an id.
- where the user was: a scroll position, an expanded section. Saved as a number or a flag.
- what they had typed and not submitted: the half-filled form. Saved as the raw strings, even
  when they are not valid yet, because "4" on the way to "45" is exactly what the user expects to
  find.

**The draft is the piece users notice.** Losing a scroll position is irritating; losing three
sentences somebody typed is the bug report that says "the app deleted my work".

## Ephemeral

**Some state is cheaper to rebuild than to save.** A pressed button's highlight, a list's loading
spinner, a value computed from the data, such as the week's total. Saving `weekTotal`'s answer would
be saving a copy of something the data already says, and the copy can go stale. Recompute it.

## The question that sorts them

For any piece of state, ask what the user expects after two events: the system kills the app while
it is in the background, and the user swipes the app away on purpose.

| | after a kill by the system | after the user closes it |
|---|---|---|
| data | still there | still there |
| UI state | restored | gone, and that is correct: they chose a fresh start |
| ephemeral | rebuilt | rebuilt |

**The middle row is the one this lesson is about.** UI state survives the system and not the user,
and the platforms' tools are built around exactly that line, as the section after next shows.
