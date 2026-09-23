---
title: `OnCalendar`, and the command that tells you when it will fire
version: 2
---

```localised
DayOfWeek Year-Month-Day Hour:Minute:Second
```

Everything is optional, `*` is any, and the whole thing has a checker — which
cron does not, and which is the best single argument for timers.

## `systemd-analyze calendar`

```
ana@vm:~/work/cron$ systemd-analyze calendar "Mon *-*-* 03:00:00"
Normalized form: Mon *-*-* 03:00:00
    Next elapse: Mon 2026-09-21 03:00:00 UTC
       From now: 5 days left
```

**Three lines, and the middle one is the answer.** Not "this parses" — *this is
the date it will actually run*. Run it before you install the timer, every time.

`--iterations` shows more than one:

```
ana@vm:~/work/cron$ systemd-analyze calendar --iterations=5 "*-*-* *:00/15:00"
Normalized form: *-*-* *:00/15:00
    Next elapse: Tue 2026-09-15 12:45:00 UTC
       From now: 14min left
   Iteration #2: Tue 2026-09-15 13:00:00 UTC
       From now: 29min left
   Iteration #3: Tue 2026-09-15 13:15:00 UTC
       From now: 44min left
   Iteration #4: Tue 2026-09-15 13:30:00 UTC
       From now: 59min left
   Iteration #5: Tue 2026-09-15 13:45:00 UTC
       From now: 1h 14min left
```

`*:00/15:00` is "minute 0, then every 15" — four times an hour, and the five
dates prove it rather than promising it.

## The syntax

| | |
|---|---|
| `*-*-* 03:00:00` | 03:00 every day |
| `03:00` | the same thing — the date part defaults to every day |
| `Mon..Fri 09:00` | weekdays at nine |
| `Sat,Sun 10:00` | a list of days |
| `*-*-01 00:00:00` | midnight on the first |
| `*-01-01 00:00:00` | new year |
| `*:0/10` | every ten minutes |
| `*-*-* *:00:00` | every hour, on the hour |
| `2026-12-25 08:00:00` | once, on a fixed date |
| `Mon *-*-* 03:00:00` | Mondays at three |

**Seconds exist.** `*:*:0/30` is every thirty seconds, which cron cannot express
at all.

## The shorthands, and what they expand to

```
ana@vm:~/work/cron$ systemd-analyze calendar daily weekly monthly
  Original form: daily
Normalized form: *-*-* 00:00:00
    Next elapse: Wed 2026-09-16 00:00:00 UTC
       From now: 11h left

  Original form: weekly
Normalized form: Mon *-*-* 00:00:00
    Next elapse: Mon 2026-09-21 00:00:00 UTC
       From now: 5 days left

  Original form: monthly
Normalized form: *-*-01 00:00:00
    Next elapse: Thu 2026-10-01 00:00:00 UTC
       From now: 2 weeks 1 day left
```

**`weekly` is Monday here**, where cron's `@weekly` is Sunday. They are not the
same schedule, and a job ported from one to the other moves by a day.

`hourly`, `daily`, `weekly`, `monthly`, `quarterly`, `yearly` and `minutely` all
exist, and all of them are **midnight exactly**, which is the busiest minute on
any machine — the reason `RandomizedDelaySec=` is in the previous section's
timer.

## Both day fields, which is where it differs from cron

```
ana@vm:~/work/cron$ systemd-analyze calendar "*-*-13 05:00:00" --iterations=3
Normalized form: *-*-13 05:00:00
    Next elapse: Tue 2026-10-13 05:00:00 UTC
       From now: 3 weeks 6 days left
   Iteration #2: Fri 2026-11-13 05:00:00 UTC
       From now: 1 month 28 days left
   Iteration #3: Sun 2026-12-13 05:00:00 UTC
       From now: 2 months 27 days left
```

The thirteenth of every month. Now add a weekday:

```
ana@vm:~/work/cron$ systemd-analyze calendar "Fri *-*-13" --iterations=2
  Original form: Fri *-*-13
Normalized form: Fri *-*-13 00:00:00
    Next elapse: Fri 2026-11-13 00:00:00 UTC
       From now: 1 month 28 days left
   Iteration #2: Fri 2027-08-13 00:00:00 UTC
       From now: 10 months 27 days left
```

**systemd ANDs the two day fields where cron ORs them** (section 04). `Fri
*-*-13` really is Friday the thirteenth — and the two dates it prints are nine
months apart, which is the same schedule cron would have run about sixty-four
times a year.

`systemd-analyze calendar` is how you find out which of those you wrote, in one
second, before it is a schedule anybody depends on.

## What it does when the answer is nothing

```
ana@vm:~/work/cron$ systemd-analyze calendar "*-02-30 03:00:00"; echo "exit $?"
Normalized form: *-02-30 03:00:00
    Next elapse: never
exit 0
ana@vm:~/work/cron$ systemd-analyze calendar "*-*-* 25:00:00"; echo "exit $?"
Failed to parse calendar specification '*-*-* 25:00:00': Invalid argument
exit 1
```

**The thirtieth of February parses, exits 0, and elapses `never`.** A 25th hour
does not parse at all and exits 1. So a script that checks the exit status catches
the second and misses the first: **the string to grep for is `never`**, not the
status.

A timer that never fires is the systemd equivalent of a cron line with a dot in
its file name: correct, installed, and dead.

Which is the argument for this whole section: **the expression and the dates it
produces are different things**, and only one of them is what you meant.
