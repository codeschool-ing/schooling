---
title: Waiting for an idle app
version: 1
---

**Detox's one idea is that a test should never have to wait on its own.** Before every action and
every expectation, Detox waits until the app is idle, and only then taps or looks. Lesson 15 waited
explicitly, element by element, from outside. Lesson 16 let Espresso wait for the main thread and
then had to teach it about the load. Detox goes further than either, because a React Native app
has more places for work to hide, and Detox watches them for you.

The wrong picture is of Detox as Appium for React Native: a driver from outside, faster to set up.
It is closer to Espresso, and on Android it is built on Espresso. Detox puts a small library into
the app, which talks to the test over a WebSocket. The library can see what the app is doing.

## What "idle" means to Detox

Detox's documentation lists what it waits for. On both platforms, the app is busy while any of
these is true:

| the app is busy while | an example in the app of this lesson |
|---|---|
| the main thread has work queued | the list being drawn after an answer |
| a network request is in flight | `fetch` asking boxoffice for the shows |
| a JavaScript timer is about to fire | a `setTimeout` waiting to run |
| an animation is running | a list scrolling into place |
| the JavaScript thread is busy, or React Native is still passing work between JavaScript and the native side | the state update after the answer arrives |

The second row is the one that lesson 16 needed an idling resource for. **Detox knows about the
network on its own.** The request to boxoffice keeps the app busy until its answer is in and the
list is drawn. The spec of section 05 has no wait in it at all.

## Three ways to wait, compared

| | Appium (lesson 15) | Espresso (lesson 16) | Detox |
|---|---|---|---|
| **who waits** | the test, explicitly | Espresso, for the main thread | Detox, for everything above |
| **what you write** | `waitForDisplayed({ timeout })` on each element | nothing, until work leaves the main thread; then an idling resource | nothing, until the app is never idle; then section 06 |
| **failure when the app is slow** | a timeout naming the element | a timeout naming the idling resource | a timeout listing what kept the app busy |
| **failure when the app never settles** | none: the test does not care | rare | the test hangs until its own timeout |

Read the last row with care, because it is the price of the idea. A test that waits for an idle
app cannot run against an app that is never idle, however correct the screen is. That is the
subject of section 06.

**Gray box has the same price here as in lesson 16.** Detox knows the app well enough to wait for
it. A test can switch that knowledge off, which section 06 has to do. Switch it off for the
part of the app that never settles, and never for a whole suite because one test was slow.
