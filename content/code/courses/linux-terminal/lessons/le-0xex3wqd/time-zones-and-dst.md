---
title: Whose three in the morning, and the two nights a year it goes wrong
version: 1
---

"Run it at three" has a hidden question in it, and the answer is not the one you
would guess.

## Cron uses the machine's time zone

Not yours, not the customer's, not the one in your calendar invitation. The
machine's — `/etc/localtime`, which `timedatectl` sets.

```sh
timedatectl                     # what this machine thinks the time is
cat /etc/timezone               # Debian and Ubuntu keep the name here
date                            # and the zone is in the output
```

**Most servers are UTC and that is the right default**, precisely because it
removes this question. A fleet in UTC has one three in the morning.

## `CRON_TZ` is not portable, and the way it fails is silent

The advice you will find is to put `CRON_TZ` at the top of the crontab. On Red
Hat's cron — `cronie` — that works and reschedules the lines below it. On
Debian and Ubuntu's vixie cron, **it is not a directive at all**:

```
ana@vm:~/work/cron$ crontab -l
MAILTO=""
CRON_TZ=America/New_York
* * * * * echo "CRON_TZ=[$CRON_TZ]  ran at $(date -u +\%H:\%M) UTC" >> /home/ana/work/cron/tzenv2.log
30 8 * * * echo "08:30 New York?" >> /home/ana/work/cron/tz830.log
ana@vm:~/work/cron$ date -u "+%H:%M UTC"; TZ=America/New_York date "+%H:%M %Z"
12:45 UTC
08:45 EDT
ana@vm:~/work/cron$ cat tzenv2.log
CRON_TZ=[America/New_York]  ran at 12:45 UTC
```

**Read the last line twice.** The variable reached the job — it is right there in
the output, `CRON_TZ=[America/New_York]`. And the job ran at **12:45 UTC**, on
the UTC minute, on a machine where New York was four hours behind.

So on this cron, `CRON_TZ` is an ordinary environment variable: exported into the
job, ignored by the scheduler. A line written for `08:30 New York` runs at 08:30
UTC — three and a half hours early in summer, and nothing warns you.

**The portable way is to do the conversion yourself**, once, in the crontab, with
a comment:

```sh
# 03:00 America/New_York = 07:00 UTC in summer, 08:00 in winter.
# This runs at 07:00 UTC year round, so it is 02:00 local for half the year.
0 7 * * * /home/ana/bin/nightly.sh
```

Ugly, honest, and it is a written record of a decision instead of an assumption.

Or use a systemd timer, which supports the zone in the expression itself:

```
ana@vm:~$ systemd-analyze calendar "*-*-* 03:00:00 America/New_York"
Normalized form: *-*-* 03:00:00 America/New_York
    Next elapse: Wed 2026-09-16 07:00:00 UTC
       From now: 18h left
```

**Three in the morning in New York, printed back as 07:00 UTC** — and it will
print 08:00 in the winter, because it is following the zone rather than an
offset. That one line does what the crontab comment above only documents.

## The two nights a year

A machine in a zone with daylight saving has one night where an hour does not
happen and one where an hour happens twice. Here is what that does to a job
scheduled at 02:30, run through `systemd-analyze calendar` in New York, starting
from the Friday before the spring change:

```
ana@vm:~/work/cron$ TZ=America/New_York systemd-analyze calendar --iterations=4 --base-time=2026-03-06 "*-*-* 02:30:00"
Normalized form: *-*-* 02:30:00
    Next elapse: Fri 2026-03-06 02:30:00 EST
       (in UTC): Fri 2026-03-06 07:30:00 UTC
       From now: 6 months 10 days ago
   Iteration #2: Sat 2026-03-07 02:30:00 EST
       (in UTC): Sat 2026-03-07 07:30:00 UTC
       From now: 6 months 9 days ago
   Iteration #3: Mon 2026-03-09 02:30:00 EDT
       (in UTC): Mon 2026-03-09 06:30:00 UTC
       From now: 6 months 7 days ago
   Iteration #4: Tue 2026-03-10 02:30:00 EDT
       (in UTC): Tue 2026-03-10 06:30:00 UTC
       From now: 6 months 6 days ago
```

**Count the dates: the 6th, the 7th, the 9th.** Sunday the 8th is missing
entirely, because at 02:00 that night the clocks went to 03:00 and 02:30 never
existed. The job does not run late. It does not run.

And in the autumn:

```
ana@vm:~/work/cron$ TZ=America/New_York systemd-analyze calendar --iterations=4 --base-time=2026-10-31 "*-*-* 01:30:00"
Normalized form: *-*-* 01:30:00
    Next elapse: Sat 2026-10-31 01:30:00 EDT
       (in UTC): Sat 2026-10-31 05:30:00 UTC
       From now: 1 month 15 days left
   Iteration #2: Sun 2026-11-01 01:30:00 EDT
       (in UTC): Sun 2026-11-01 05:30:00 UTC
       From now: 1 month 16 days left
   Iteration #3: Mon 2026-11-02 01:30:00 EST
       (in UTC): Mon 2026-11-02 06:30:00 UTC
       From now: 1 month 17 days left
```

01:30 happens twice on 1 November, once in EDT and once in EST. **systemd runs it
once** — the EDT one — and the `(in UTC)` line is how you can tell which. Cron's
behaviour in that hour depends on the implementation, and on some of them the job
runs twice.

## What to actually do

| | |
|---|---|
| set servers to UTC | and stop having this problem |
| schedule outside 01:00–03:00 | in any zone that changes, that window is the one that breaks |
| write the zone in a comment | on every line where local time was the point |
| make the job idempotent | section 225, and the reason a double run is survivable |

**"Outside 01:00–03:00" is the cheap fix nobody applies.** A report at 04:15
local runs 365 times a year in every zone on earth; the same report at 02:15 runs
364 times in New York and 366 in the year the rule changes.
