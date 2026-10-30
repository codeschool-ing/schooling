---
title: What iOS allows in the background
version: 1
---

**An iPhone app does not keep running when it leaves the screen.** That is the belief to drop first,
because it comes from computers, where a program in a window you cannot see is still a program
running. On iOS, an app that goes to the background is suspended within seconds: still in memory,
using no processor at all, and liable to be removed from memory altogether when another app needs
the room. Lesson 2's scene phase is the app's last chance to save before that happens.

Whatever runs later runs because the system **gives** the app time, and it gives that time on its own
terms. This lesson is about asking for it well. Nothing in it that touches the system was run: it is
Apple's `BackgroundTasks` framework and SwiftUI's `backgroundTask` modifier, written from Apple's
documentation read on 30 October 2026. The two decisions the app makes, when to ask and what to do
when time runs out, are plain Swift, and sections 06 and 07 run them.

## The ways to get time

Apple's article *Choosing Background Strategies for Your App* lists them. The ones that matter for a
study planner:

| what the app needs | what to ask for | how much time, per the documentation |
|---|---|---|
| finish something the person started, like saving | `beginBackgroundTask` while going to the background | a limited time; the expiration handler says when it is up |
| refresh its data now and then | a `BGAppRefreshTask` | up to 30 seconds, when the system chooses |
| heavy maintenance, best done overnight on the charger | a `BGProcessingTask` | minutes, when the system chooses |
| an upload or download that may be long | a background `URLSession` | the transfer continues while the app is suspended |
| a job the person starts and watches, like an export | a `BGContinuedProcessingTask`, iOS 26 and later | it continues, with its progress shown to the person |
| news from the server at irregular times | a background push | up to 30 seconds, rate-limited |

**"When the system chooses" is the phrase to take seriously.** An app asks for a refresh no earlier
than a date; the documentation for `earliestBeginDate` says the system does not guarantee launching
the task at that date, only that it will not begin sooner. Apple's development guide adds that the
delay between scheduling a task and its launch can be many hours. The system weighs battery, network,
how often the person opens the app and the time of day, and the app has no say in that.

## What that means for the planner

The planner has two jobs it would like done while it is not on screen. **Sending sessions added
offline**, so that the server has them before the person next opens the app on another device. And
**refreshing the plan**, so that the app opens on this morning's data rather than last night's.
Neither is urgent to the second, both are small, and both are exactly what an app refresh task is
for. Section 03 asks for one; section 06 decides when; section 07 makes the work survive being cut
off after its 30 seconds, or after three.
