---
title: The ANR
version: 1
---

**An app's interface runs on one thread, the main thread, and anything slow done there freezes the
whole screen.** Every tap, every scroll and every frame waits for it. When the main thread is busy
for too long, Android says so with a dialog, *the app isn't responding*, offering to wait or to close
it. That is an **ANR**, *Application Not Responding*, and Google Play counts it like a crash.
*Read from Android's developer documentation on ANRs and on Android vitals, October 2026.*

## When Android declares one

| what was waiting | how long Android waits |
|---|---|
| an input event, a key press or a touch | 5 seconds |
| a broadcast receiver, in the foreground | 10 seconds |
| a service told to become a foreground service, calling `startForeground` | 5 seconds |

The first row is the common one. The person touched the screen and nothing answered for five
seconds; that is long enough for many of them to give up before the dialog even appears, so the
ANRs counted are fewer than the freezes people felt.

## How Google Play counts them

Android vitals reports a **user-perceived ANR rate**, the share of daily users who saw an ANR the
system showed them, and uses the same kind of threshold as for crashes, lesson 12:

| | overall | on one phone model |
|---|---|---|
| user-perceived ANR rate | 0.47% | 8% |

The overall threshold is less than half the crash threshold of 1.09%. Google treats a frozen app as
worse than a crashed one, which matches what people feel: a crash ends quickly, a freeze makes them
wait and then decide.

## What freezes a main thread

- **Disk on the main thread**: opening the planner's database, reading a large file, writing
  preferences synchronously.
- **Network on the main thread**, which Android forbids outright and throws an exception for, but
  a library wrapping it in a synchronous call can still do.
- **Long computation**: parsing a year of sessions, sorting thousands of rows, decoding a big image.
- **Waiting for a lock** held by another thread that is itself waiting for something slow.

The cure is always the same in principle, move the work off the main thread, and section "Off the
main thread" shows it on the three platforms.
