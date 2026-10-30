---
title: Battery
version: 1
---

**An app that drains the battery is uninstalled, and the person rarely says why.** Battery use is
the hardest kind of performance to see, because it happens when nobody is looking at the app: in
the background, while the phone is in a pocket. *Read from Android's documentation on Android vitals
and wake locks, October 2026; not run.*

## What Android counts

A **wake lock** keeps the processor awake while the screen is off, so a task can finish. Held too
long, it stops the phone from sleeping. Android vitals reports **excessive partial wake locks**: a
session where the app's partial wake locks, added together, run for **two hours or more in 24
hours**. The bad behaviour threshold, as with crashes, is a share of sessions:

| | bad behaviour threshold |
|---|---|
| excessive partial wake locks | 5% of sessions |
| excessive battery usage | 1% |

**Excessive wakeups**, alarms that wake the phone too often, and **background network and Wi-Fi
scans** are reported too.

## What the planner does in the background

It syncs sessions with the server and schedules reminders. Both have cheap and expensive versions:

| | expensive | cheap |
|---|---|---|
| syncing | a timer that wakes every five minutes, on any network | the system's scheduler, **WorkManager** on Android and **BGTaskScheduler** on iOS, once an hour, when there is a network |
| reminders | an exact alarm per session, lesson 5 | an inexact alarm, or a scheduled local notification the system delivers |

The cheap versions let the **system** choose when to run, batching the work of many apps into one
wake-up. That is the whole idea: an app that asks the system is cheaper than an app that insists.

## iOS and React Native

iOS gives apps much less background time to begin with, and reports what they use in Xcode's
Organizer and in MetricKit's energy logs. React Native apps use the same native schedulers through
libraries such as Expo's background task module, so the same choice is made there, and the cost
shows up in the same native reports.
