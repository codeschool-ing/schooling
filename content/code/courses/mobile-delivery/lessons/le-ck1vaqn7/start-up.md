---
title: Start-up time
version: 1
---

**The first thing anybody experiences of an app is how long it takes to open, and it is measured
from the tap to the first useful screen.** Both platforms measure it on people's phones and report
it to you, and both distinguish three kinds of start, because they cost very different amounts.
*Read from Android's developer documentation on app start-up time, October 2026, and Apple's on
reducing launch time.*

| | what has to happen | how often |
|---|---|---|
| **cold start** | the system creates the process, loads the code, runs the app's initialisation, draws the first screen | after a reboot, after the system killed the app for memory, the first time each day for many people |
| **warm start** | the process is gone or the screen was destroyed, but some state survives | after a while in the background |
| **hot start** | the app was in the background, intact; it only comes to the front | switching between apps |

Android's documentation recommends always optimising for the cold start, because improving it
improves the other two.

## The two numbers Android reports

- **Time to initial display (TTID)**: from the launch to the first frame drawn. Android measures it
  for every app automatically.
- **Time to full display (TTFD)**: from the launch to the moment the app says its content is ready,
  which it does by calling `reportFullyDrawn()`. For the planner, that is the week with its sessions
  and its total, not an empty frame with a spinner.

TTID can be made short by drawing a skeleton quickly; TTFD is what the person actually waited for.
**Report both**, so that a fast skeleton cannot hide a slow week.

## What makes a cold start slow

- **Work in `Application.onCreate`, the app's `init`, or React Native's first render**: libraries
  initialised eagerly, a crash reporter, analytics, remote config, all before the first frame.
- **Reading the database on the main thread** to show the first screen, lesson 14.
- **Loading code**: a large JavaScript bundle to parse, or many dynamic frameworks to link on iOS.
  React Native's **Hermes** compiles JavaScript to bytecode at build time, so the phone skips the
  parsing on every start.

## The same metric on the other platforms

On iOS, **Xcode's Organizer** shows launch times from people who share diagnostics, and
**MetricKit** delivers the same measurements to the app itself. The watchdog of lesson 14 is the
extreme case: a launch so slow that the system ends it. React Native apps are measured by the
native platform underneath, so the numbers come from the same two places.
