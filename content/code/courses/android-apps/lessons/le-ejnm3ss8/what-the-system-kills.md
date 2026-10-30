---
title: What the system still decides
version: 1
---

**WorkManager guarantees that work runs; Android decides when, and on a real phone that can be
much later than a test suggests.** Everything in sections 03 to 06 ran in a test where the test
driver said "now". On a phone the system says it, and it balances your planner against the battery,
every other app and what the student is doing. This section describes what that looks like.

**Not run.** None of what follows was observed for this course: it needs a phone or an emulator,
and lesson 1 section 02 says why the recording machine had neither. It is taken from Google's
documentation for WorkManager and for Android's power management, read on 30 October 2026.

## Delays you do not control

- **Doze.** A phone left still, unplugged and with the screen off enters Doze after a while, and
  background work waits for short maintenance windows that grow further apart the longer it stays
  still. Your six-hour sync can run hours late overnight. That is the point of Doze, and the reason
  WorkManager exists is that it waits correctly rather than not at all.
- **App standby buckets.** Android sorts apps by how recently and often the student uses them, from
  *active* to *rarely used*, and gives each bucket a different allowance of background work. An app
  the student opens daily runs its jobs close to schedule; one they have not opened for weeks can wait
  a day.
- **Battery saver**, when the student turns it on, restricts background work further, and
  `setRequiresBatteryNotLow` adds the planner's own restraint on top.

## Kills that WorkManager survives, and the one it does not

| what happens | what WorkManager does |
|---|---|
| the system ends the process to free memory | the request is in its database; the system restarts the work when it is eligible |
| the student swipes the app away from recent apps | the same: the process ends, the request stays |
| the phone reboots | its boot receiver, the `RECEIVE_BOOT_COMPLETED` of section 06, reschedules everything |
| **the student presses Force stop in the app's settings** | **every job is cancelled and nothing runs until the student opens the app again** |

Force stop is the student saying "this app may do nothing until I start it", and Android honours it
completely. It is also what some phone makers' own battery managers do to apps on their own
initiative, which is why a sync can stop on one brand of phone and work on another. There is nothing
in code that overrides it, and nothing should.

## Watching it on a device

On a phone with developer options, Google's documentation shows how to see what WorkManager has
asked the system for: `adb shell dumpsys jobscheduler` lists the app's jobs with their constraints,
and Android Studio's **Background Task Inspector** shows each request, its state and its chain. To
make Doze happen without waiting, `adb shell dumpsys deviceidle force-idle` puts a connected phone
into it at once. **Not run**, like the rest of this section.

## What to take from it

Write workers as if they will run late, more than once, and sometimes after the student has changed
the data. That is the same discipline `mobile-offline`, the course after this one, builds into a
whole design: its lesson 8 puts operations in an outbox and its lesson 10 makes sending one twice
harmless. A worker that sends "everything not yet sent", rather than "the session added at 09:14",
is already most of the way there.
