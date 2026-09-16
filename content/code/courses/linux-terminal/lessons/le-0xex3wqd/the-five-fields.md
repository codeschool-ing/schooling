---
title: The five fields, and the one rule that is an OR
version: 1
---

```
*  *  *  *  *  command
│  │  │  │  │
│  │  │  │  └── day of week   0-7   (0 and 7 are both Sunday)
│  │  │  └───── month         1-12
│  │  └──────── day of month  1-31
│  └─────────── hour          0-23
└────────────── minute        0-59
```

**The smallest unit is one minute.** Nothing in cron runs more often than that,
and a job that needs to is a job for a service that stays running — or for
section 12's systemd timer, which can do seconds.

| what you write | what it means |
|---|---|
| `*` | every value |
| `5` | exactly 5 |
| `1,15,30` | a list |
| `9-17` | a range |
| `*/10` | every tenth value — 0, 10, 20, 30, 40, 50 |
| `9-17/2` | a step inside a range — 9, 11, 13, 15, 17 |
| `mon`, `jan` | names, in the last two fields, case-insensitive |

## Read these until they are obvious

| | |
|---|---|
| `0 3 * * *` | 03:00 every day |
| `*/15 * * * *` | every fifteen minutes |
| `0 */4 * * *` | every four hours, on the hour |
| `30 2 * * 0` | 02:30 on Sundays |
| `0 9 1 * *` | 09:00 on the first of the month |
| `0 9 * * 1-5` | 09:00 on weekdays |
| `15 14 1 * *` | 14:15 on the first of the month |
| `0 0 1 1 *` | midnight on the first of January |

**`*/15` in the minute field means four times an hour, not every fifteen
minutes.** It is `0,15,30,45` — so a job that starts at 12:50 does not next run
at 13:05, it runs at 13:00. The step counts from zero, not from now.

## The rule that surprises everybody

**If both the day-of-month and the day-of-week fields are restricted, cron runs
the job when *either* matches.** Everywhere else in the line the fields are ANDed
together. These two are ORed.

That is worth measuring rather than believing. Three jobs, installed on a
Tuesday that was not the thirteenth:

```
ana@vm:~/work/cron$ date "+today is %A %F"
today is Tuesday 2026-09-15
ana@vm:~/work/cron$ crontab -l | tail -3
* * 13 * 2 echo "dom 13 OR dow Tue fired at $(date +\%T)" >> /home/ana/work/cron/or.log
* * 13 * 1 echo "dom 13 OR dow Mon fired at $(date +\%T)" >> /home/ana/work/cron/or2.log
* * * * 2 echo "dow Tue only fired at $(date +\%T)" >> /home/ana/work/cron/or3.log
ana@vm:~/work/cron$ cat or.log
dom 13 OR dow Tue fired at 12:37:01
dom 13 OR dow Tue fired at 12:38:01
ana@vm:~/work/cron$ cat or2.log
cat: or2.log: No such file or directory
ana@vm:~/work/cron$ cat or3.log
dow Tue only fired at 12:37:01
dow Tue only fired at 12:38:01
```

**The first job ran on the fifteenth**, because it is a Tuesday — the day of the
month never matched and did not have to. **The second did not run at all**,
because neither the thirteenth nor Monday was true. The third is the control: a
plain weekday restriction does what you expect.

So `0 3 13 * 5` is **not** "3am on Friday the thirteenth". It is *the thirteenth
of every month, and also every Friday* — around 64 runs a year where you wanted
one or two.

**There is no way to write "Friday the thirteenth" in five fields.** The way it
is done:

```sh
0 3 13 * *  [ "$(date +\%u)" = 5 ] && /home/ana/bin/job.sh
```

Restrict one field in cron, and test the other in the command.

## The shortcuts

| | |
|---|---|
| `@yearly`, `@annually` | `0 0 1 1 *` |
| `@monthly` | `0 0 1 * *` |
| `@weekly` | `0 0 * * 0` |
| `@daily`, `@midnight` | `0 0 * * *` |
| `@hourly` | `0 * * * *` |
| `@reboot` | once, when cron starts |

**`@reboot` is not a schedule and it is the one worth a warning.** It runs when
*cron* starts, which is usually but not always near boot, it does not run if cron
is restarted without the machine rebooting — and it is not how a program that
should always be running gets started. That is a systemd service (lesson 5),
which restarts it when it dies, logs it, and orders it after the things it needs.

## Two habits

**Write the schedule as a comment above the line**, in words:

```sh
# 03:15 every day — rotate and upload yesterday's logs
15 3 * * * /home/ana/bin/upload-logs.sh
```

Cron's syntax is readable in one direction and not the other; the comment is
what somebody reads at three in the morning when the job is the suspect.

**Do not schedule everything on the hour.** Every machine you own running its
backup at `0 3 * * *` is a thundering herd against one file server. Pick a minute
with no meaning — `17 3 * * *` — which is why `/etc/crontab` runs its hourly jobs
at 17 minutes past.
