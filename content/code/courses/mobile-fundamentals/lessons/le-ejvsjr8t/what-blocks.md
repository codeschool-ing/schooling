---
title: What blocks the main thread, and how each system complains
version: 1
---

**The main thread is blocked by any work that takes longer than a frame, and in an app that work
comes in two kinds: computing and waiting.** Computing is the processor busy on your code. Waiting
is the thread doing nothing at all while a disk or the network answers. The second is the one
people miss, because the code is short and the processor is idle, and the frame is lost just the
same.

| kind | in the study planner | why it is slow |
|---|---|---|
| computing | parsing a year of sessions downloaded as one large JSON document | the parser reads every character before it returns |
| computing | sorting or grouping thousands of sessions for the week view | a sort compares items many times over |
| waiting | reading the saved plan from a file on the device | storage answers in its own time, and a busy phone is slower |
| waiting | fetching the course list from a server | a network can take seconds, or never answer (lesson 14) |

**Apple's documentation lists the same things.** Its page on watchdog terminations names
synchronous networking and processing large amounts of data, *such as large JSON files*, among
the usual ways an app blocks its main thread. Android's guide to ANRs shows a sort written inside
a Compose function that draws a list, where it runs again every time the list is drawn.

## Android: StrictMode, an exception, and the ANR dialog

Android gives a developer two warnings before a user sees anything. **StrictMode** is a developer
tool that an app switches on in its debug build; its documentation says it is used mostly to
catch accidental disk or network access on the main thread, and it can write each one to the
log as it happens. Network access is caught even without it: an app that opens a network
connection on the main thread gets a `NetworkOnMainThreadException`, which Android has thrown for
every app targeting its Honeycomb release or later.

**The user's warning is the ANR dialog.** Android's documentation on ANRs says that one is
triggered when the app has not responded to an input event, a key press or a touch, within 5
seconds. The dialog lets the user wait or close the app, and Android's guide to processes and
threads adds that the user might go on to uninstall it.

## iOS: the watchdog

iOS has no dialog. **It has a watchdog**: a part of the system that watches how long an app takes
to launch and to answer, and terminates one that does not. Apple's documentation says that a
crash report from a watchdog termination carries the code `0x8badf00d`, read as "ate bad food". The report's description also says whether the app failed to draw its first frame in time or
stopped updating its interface because the main thread was too busy. The documentation does not
publish one fixed limit for an app that is already running, and this lesson does not invent one.

To the user, the two look different and mean the same. On Android the app asks to be closed; on
iOS it vanishes. Both are the system telling the developer that the main thread was held far
past its budget.

## React Native: one busy JavaScript thread

In React Native the warning signs are the JavaScript thread's. **A long loop in one handler holds
up every other handler, every timer and every render**, because one thread runs them all, and the
documentation's example of 200 ms of work dropping 12 frames is that thread. Parsing a large
response with `JSON.parse` and sorting a long array are as synchronous in a React Native app as
in any JavaScript program; they run to the end before anything else on that thread does. And the
native main thread can still be blocked underneath, by native code that a library runs there.

Lesson 14 is about a request that never returns. Here the point is narrower: wherever that
request waits, it must not wait on the thread that draws.
