---
title: The watchdog, and the kill that leaves no report
version: 1
---

**iOS has no "not responding" dialog: it ends the app.** The system runs a **watchdog** that
monitors launch times and how responsive an app is, and terminates one that blocks its main thread
for too long. *Read from Apple's documentation on watchdog terminations and on jetsam event reports,
October 2026; not run.*

## The watchdog's signature

Apple's crash report for such a termination carries the code **`0x8badf00d`**, pronounced, in
Apple's own words, *ate bad food*, in its termination reason. The description says what the app was
doing when it ran out of time: **`scene-create`** means it did not draw its first frame in the time
allowed, which is a launch that took too long; `scene-update` means a running app stopped updating
its interface.

The report's backtrace shows what the main thread was doing at the moment of the kill, and Apple's
documentation warns that this can mislead: an app with 5 seconds allowed that spent 4 of them on one
task and the last second on another shows the second task in the backtrace. **The backtrace names
the last straw, not the load.**

## Jetsam: killed for memory

When a phone runs short of memory, the system first asks apps to free some, then ends apps to
reclaim it. That is a **jetsam event**. It leaves a **jetsam event report**, which differs from a
crash report in three ways Apple lists: it describes the memory of **every** app and process on the
device, it is JSON, and **it has no backtraces of your app's threads**.

Android has the equivalent: the **low-memory killer** ends background apps, and sometimes the
foreground one, with no exception thrown in your code.

## Why no crash reporter sees it

A crash reporter catches an exception or a signal and writes a report, lesson 12. A watchdog kill
and a memory kill send **`SIGKILL`**, the one signal no process can catch. There is no moment in
which the reporter can write anything. So the evidence is indirect:

- **The system's own reports**, the watchdog crash report and the jetsam event report, which reach
  App Store Connect and Xcode's Organizer from people who share diagnostics.
- **MetricKit** on iOS, which delivers the system's diagnostics to the app on its next launch,
  including hangs and terminations.
- **`ApplicationExitInfo`** on Android, available since Android 11, which tells the app on its next
  start why its previous process ended: a crash, an ANR, the low-memory killer, the person swiping
  it away.
- **A hang detector inside the app**, which notices a frozen main thread **before** the system kills
  it, from another thread that is still running. The next section builds one.
