---
title: One thread draws the screen and answers the finger
version: 1
---

**An app starts with one thread, and that thread both draws the screen and receives every touch.**
The common picture is the opposite: a phone has several processor cores, so surely an app
does its work on all of them at once. It can, but only if it asks. Everything the system hands
the app, a tap, a scroll, a lifecycle callback from lesson 4, arrives on one thread, and every
change to what is on screen has to be made from that same thread. Android calls it the *main
thread* or the *UI thread*; on iOS it is the main thread, and Swift names the part of a program
that runs on it the *main actor*.

## A loop that goes round once per frame

The main thread runs a loop. It waits for something to happen, runs the code that answers it,
works out where everything on screen goes, and draws. Then it waits again. Android's
documentation on processes and threads walks through one touch on a button in exactly those
steps. The UI thread passes the touch to the button, the button marks itself pressed and asks to be
redrawn, and the request goes into a queue that the same thread empties on its next turn.

**So your code runs in the gaps between frames.** A handler that returns in a millisecond leaves
the loop free to draw the next frame on time. A handler that runs for half a second keeps the
loop from turning for half a second: no frame is drawn, and the touches that arrive meanwhile
wait in the queue. The finger moves, and the list under it does not.

## Why there is only one

Drawing from two threads at once would mean two pieces of code changing the same view at the
same moment, and the toolkits are not built for that. **Android states it as two rules**: do not
block the UI thread, and do not touch the UI toolkit from any other thread. Its documentation
says plainly that the toolkit is not thread-safe. Apple's toolkits make the same demand, and
Swift's compiler can check it: code marked as belonging to the main actor runs on the main
thread, and a call into it from elsewhere has to wait its turn.

The two rules pull in opposite directions, and the rest of this lesson lives between them. Slow
work must leave the main thread, and its result must come back to it before it reaches the
screen.

## React Native has two threads that matter, and each is single

A React Native app has the same native main thread, which draws the native views and receives
touches. Your JavaScript, the React components and the code that answers a press, runs on
**a separate JavaScript thread**. React Native's own documentation on performance says what follows from that. A scroll view keeps scrolling while
the JavaScript thread is busy, because the scrolling happens on the main thread. A button that changes its look in JavaScript
stops answering, because the touch is waiting for a thread that is not free.

**And the JavaScript thread is one thread.** JavaScript runs one function at a time on it, so a
long loop in one handler holds up every other handler, every timer and every render. That is the
same shape as the main thread of a native app, one level up. It is also why this lesson's
experiment can run on Node.js. Node runs JavaScript on one thread with an event loop, the same
way, and a long synchronous function stops its timers in exactly the way it would stop a frame.
Node.js is a model of the rule here, not a phone, and the section that runs it says where the
model stops.
