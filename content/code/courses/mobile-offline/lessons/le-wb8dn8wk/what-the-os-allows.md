---
title: What the system allows, and who decides when
version: 1
---

**An app does not run in the background when it wants to; it asks, and the system decides when,
for how long, and whether at all.** The belief this replaces is that a sync can be scheduled like a
timer: every fifteen minutes, on the minute. Neither Android nor iOS offers that. Both treat the
battery as the person's, not the app's, and both will postpone, shorten or skip a background run
to protect it.

*Everything in this lesson about Android and iOS comes from each platform's documentation and was
not run for this course; the last section is a program you run in Node.*

## Android

- **Doze.** When the phone is unplugged, still and dark for a while, the system suspends network
  access for apps and defers their jobs and alarms. It wakes briefly in **maintenance windows**
  to let deferred work run, and the windows grow further apart the longer the phone stays idle.
- **App Standby Buckets.** From Android 9, every app sits in a bucket chosen by how recently and
  how often the person uses it: *active*, *working set*, *frequent*, *rare*, and from Android 12
  *restricted*. The rarer the bucket, the less often the app's jobs are allowed to run. A planner
  opened every evening runs often; one opened once a month barely runs at all.
- **A force stop** from the app's settings page cancels its scheduled work until the person opens
  the app again. Some manufacturers add battery managers of their own that stop apps more readily
  than Android itself does, so the same app can behave differently on two brands of phone.

## iOS

- **No schedule.** An app asks for a refresh *no earlier than* a time, and the system picks the
  moment from what it has learnt: when the person usually opens the app, the battery, the network.
  It may be twenty minutes later or the next morning.
- **Two kinds of task.** An **app refresh** task gets about thirty seconds. A **processing** task
  may run for minutes, and usually runs when the phone is idle and charging, often overnight.
- **Swiping the app away** in the app switcher tells iOS the person wants it stopped: no background
  launches until they open it again. Turning off Background App Refresh in Settings, or Low Power
  Mode, has the same effect for refresh tasks.

## What follows for the planner

Three consequences, and the rest of the lesson builds on them.

| what the system does | what the sync must be able to do |
|---|---|
| runs it late, or not at all | never be the only path: sync also when the app opens and when the person saves |
| gives it seconds, then stops it | stop at any moment without losing what it already did |
| kills the process with no warning | resume next time from where it stopped, from what is on disk |

**Background sync is an extra, never the mechanism.** The outbox of lesson 8 drains whenever the
app is open and online; a background run only means the queue was shorter by the time the person
looked. A planner that showed stale data until the system happened to schedule it would be broken
on every phone in Doze.
