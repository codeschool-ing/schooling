---
title: Five things that run something later, and the one you should not write
version: 1
---

The job is always the same shape. Something has to happen at three in the
morning, or every ten minutes, or once on Tuesday — and you will not be there.

## The one you should not write

```sh
while true; do
    backup.sh
    sleep 3600
done
```

**It is the first thing everybody writes and it is wrong in five ways**, and the
first of them is measurable in fifteen seconds:

```sh
#!/bin/bash
# the "run it in a loop" pattern: work, then sleep
for i in 1 2 3; do
  date '+%T  cycle start'
  sleep 2                 # the work
  sleep 3                 # the interval
done
```

```
ana@vm:~/work/scripts$ ./drift.sh
12:33:41  cycle start
12:33:46  cycle start
12:33:51  cycle start
```

**The interval is three seconds and the cycles are five apart.** The work is
inside the loop, so every run pushes the next one later. An hourly backup that
takes four minutes runs at 03:00, then 03:04, then 03:08, and by the end of the
week it is running in the afternoon.

The other four:

| | |
|---|---|
| it dies with your terminal | lesson 6's hangup, unless you thought about `nohup` |
| it does not survive a reboot | and nothing restarts it |
| nobody knows it exists | it is not in any file a colleague would look in |
| there is no record | no log of when it ran, or whether it worked |

Every one of those is solved, once, by the schedulers below.

## The five

| | |
|---|---|
| **cron** | the classic. A line in a table, five time fields, on every Unix |
| **systemd timers** | two unit files, a richer calendar, the journal, and dependencies |
| **anacron** | for machines that are switched off at three in the morning |
| **`at`** | once, at a time you name, and then it is gone |
| the application's own | Kubernetes `CronJob`, Airflow, Jenkins, your database's scheduler |

This lesson is about the first four. The fifth matters and is somebody else's
documentation, except for one thing it shares with all of them, which is the
subject of section 16.

## Which of them is on this machine

```
ana@vm:~$ ls /etc/cron.d /etc/cron.daily
/etc/cron.d:
anacron  e2scrub_all  php  sysstat

/etc/cron.daily:
0anacron  apt-compat  dpkg  sysstat
```

**Cron is already running, and it is already running things**, which is true of
almost every Linux machine you will meet. `sysstat` — the tool lesson 11 used for
`iostat` and `mpstat` — collects its samples from a cron job, and `apt-compat`
is why your package lists are fresh in the morning.

You are not adding a scheduler to this machine. You are adding a line to one that
has been running since it was installed.

## What each section owes you

The rest of the lesson is cron for eight sections, because it is what is there
and because everything that goes wrong with it goes wrong quietly; systemd timers
for four, because it is what a new service is written with; and three at the end
on the part that is neither — locking, failure, and the job surviving its own
success.
