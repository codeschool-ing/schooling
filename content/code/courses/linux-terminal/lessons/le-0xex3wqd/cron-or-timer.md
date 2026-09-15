---
title: Which one, on the machine you are actually on
version: 1
---

## Side by side

| | cron | systemd timer |
|---|---|---|
| **what it is** | one line | two files |
| **where** | every Unix, since 1975 | every systemd machine |
| **smallest interval** | one minute | one second |
| **calendar syntax** | five fields | richer, and **checkable** |
| **both day fields** | OR — section 213 | AND |
| **missed runs** | lost | `Persistent=true` |
| **overlapping runs** | yours to prevent | prevented |
| **output** | mailed, if there is an MTA | the journal |
| **environment** | four variables, no profile | whatever the unit says |
| **dependencies** | none | `After=`, `Requires=`, the whole graph |
| **jitter** | write it yourself | `RandomizedDelaySec=` |
| **checking it** | `crontab -e`'s syntax check | `systemd-analyze verify`, `calendar`, `list-timers` |
| **learning it** | ten minutes | an afternoon |

## The answer

**Use what the machine already uses.**

A server with fifteen jobs in `/etc/cron.d` does not want a sixteenth job that is
a timer, because the next person to look will find fifteen and not sixteen. A
machine where every service is a unit does not want one crontab line that nobody
will think to check.

Consistency beats the feature list, and it beats it easily.

## When to break that rule

**Reach for a timer** when any of these is true, because each one is a thing you
would otherwise write by hand and get wrong:

| | |
|---|---|
| the job must not overlap itself | section 223 |
| the machine is off some of the time | `Persistent=true` |
| the job needs the network, or a mount | `After=network-online.target` |
| the output matters and there is no MTA | the journal |
| it runs on a hundred machines at once | `RandomizedDelaySec=` |
| it needs to run more often than once a minute | seconds exist |

**Stay with cron** when:

| | |
|---|---|
| the machine has no systemd | Alpine, busybox, some containers, older Unix |
| the job is one line and is yours | `crontab -e`, thirty seconds |
| everything else here is already cron | consistency |
| a person who is not you has to read it | five fields beat forty settings |

## And the third answer

**If the machine is disposable, neither of them.**

A container that is rescheduled by an orchestrator should not have a cron daemon
in it — the job belongs to a Kubernetes `CronJob`, an ECS scheduled task, a cloud
scheduler, or the pipeline that the container is part of. Those give you what
this lesson has spent eight sections adding to cron by hand: a record of each
run, a retry policy, a timeout, an alert, and a definition that lives in a
repository rather than on one machine.

The trade is that the scheduler is now somebody else's system, with its own
failure modes and its own place to look.

**What does not change is section 225.** Whatever starts the job, the job still
has to be safe to run twice, to say something when it fails, and to stop when it
takes too long. That is the half of this lesson that outlives whichever
scheduler you are using this year.
