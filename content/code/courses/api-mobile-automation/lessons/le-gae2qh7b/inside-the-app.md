---
title: A test that runs inside the app
version: 1
---

**An Espresso test is not a program that looks at the app; it is code running in the app's own
process.** Gradle packs the tests into a second APK, the *test APK*, installs it on the device
beside the app, and asks Android to start the app under the control of the test APK's
**instrumentation**, a runner Android has for exactly this. From that moment the test and the app
share one process, one memory and one main thread. Lesson 14 called this an *instrumented test*;
Espresso is Google's library for writing the screen-touching kind.

The usual first picture is of Espresso as Appium written in Kotlin: another way to tap buttons
from outside. Everything that makes it different comes from being inside instead:

| | Appium (lesson 15) | Espresso |
|---|---|---|
| **where the test runs** | your computer, in its own process | the device, in the app's process |
| **how it finds a view** | asks the accessibility tree, through a driver | holds the app's views and searches them directly |
| **what it can name** | what the screen shows | that, and the app's own classes: `R.id.refresh`, the `Show` objects behind the list, `Shows.baseUrl` |
| **language** | any with a client | Kotlin or Java, the app's own |
| **other apps** | yes: a permission dialog, the settings screen | no: only this app's windows (lesson 21) |
| **waiting** | the test waits, explicitly | Espresso waits for the main thread before every step |

## Gray box

A test that sees only the screen is called *black box*; one that reads the code is *white box*.
Espresso is **gray box**: it acts through the screen as a person would, tapping and reading what is
drawn, and it may also reach into the app when that makes the test better. The tests of this lesson
do it twice. One picks a row of the list by the `Show` object it holds, rather than by its position
on the screen. Another sets `Shows.baseUrl` to an address nobody answers, which no person holding
the phone could do, to see what the app does when boxoffice is gone.

That reach has a price. A test that knows the app's classes breaks when they are renamed, and it
can put the app in a state no user could reach and then report a defect nobody would ever meet.
**Use it to set up a situation a person could be in, never to skip the screen being tested.**

## What Espresso waits for, and what it does not

Android draws everything on one thread, the **main thread**, which handles taps, runs the
activity's code and redraws the screen, one message at a time. Before each action and each check,
Espresso waits until that thread's queue has nothing left to do. A tap that opens a new screen, a
list the main thread is still filling: Espresso waits for them without being told, and that is why
an Espresso test rarely needs a wait written into it.

**It waits for the main thread and for nothing else** of yours. (It also watches the pool of
background workers that Android's old `AsyncTask` class used, which new code no longer touches.)
Work that runs on a thread the app started itself is invisible to it. Tickets loads its shows on a
thread of its own, because Android forbids network calls on the main thread (lesson 14), so while
the request is out, the main thread is idle and Espresso considers the app ready. Section 05 is
about what that does to a test, and how to fix it.
