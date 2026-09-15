---
title: Timers that count from an event, and the one that catches up
version: 1
---

`OnCalendar=` is a clock. The other half of the `[Timer]` section is not: it
counts **from something that happened**, and it is what cron has no equivalent
for at all.

| | counts from |
|---|---|
| `OnBootSec=` | the machine finished booting |
| `OnStartupSec=` | systemd itself started |
| `OnActiveSec=` | this timer was activated |
| `OnUnitActiveSec=` | the last time **its service** was started |
| `OnUnitInactiveSec=` | the last time its service **finished** |

## The pattern you will write most often

```ini
[Timer]
OnBootSec=15min
OnUnitActiveSec=1h
```

**Fifteen minutes after boot, and every hour after each run.** Two lines, and
they solve two things at once:

`OnBootSec=15min` keeps the job away from the boot storm. A machine coming up has
a great deal to do, and a report generator competing with it is a poor use of the
first minute.

`OnUnitActiveSec=1h` is **an hour after the last run started, not on the hour** —
so a job that takes twenty minutes runs at 03:00, 04:00, 05:00, and a job that
takes ninety minutes runs at 03:00, 04:30, 06:00. It cannot pile up the way
section 223's cron job can.

And `OnUnitInactiveSec=1h` is the stricter version: an hour after it **finished**,
which guarantees a full hour of quiet between runs.

## `Persistent=true`

```ini
[Timer]
OnCalendar=daily
Persistent=true
```

**The answer to "the machine was off at three in the morning".** systemd writes
down when the timer last fired; with `Persistent=true` it compares that against
the clock at boot, and if a run was missed it runs the job immediately.

It is anacron, built in, with a clock — which is why a systemd machine needs
anacron much less than it used to.

Two things about it worth knowing before you turn it on:

**It runs once, not once per miss.** A laptop closed for a week comes back and
runs the daily job once, not seven times. That is what you want for a report and
not what you want for anything that processes a queue by date.

**"Immediately" means at boot**, along with everything else that was waiting —
which is the reason to pair it with `RandomizedDelaySec=` on a fleet.

## `RandomizedDelaySec=` and `AccuracySec=`

```ini
[Timer]
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=30m
AccuracySec=1s
```

**`RandomizedDelaySec=30m`** adds a random delay between zero and thirty minutes,
fixed per machine per timer. Two hundred machines with the same unit file stop
being two hundred simultaneous requests at 03:00.

**`AccuracySec=`** is the opposite knob and it surprises people: its default is
**one minute**, which means a timer set for 03:00:00 may fire at 03:00:43.
systemd is deliberately coalescing timers so the processor can stay asleep. If
you actually need the second, `AccuracySec=1s` says so — and on a laptop it costs
battery, which is the whole reason for the default.

**Between them, those two settings are why a timer is not just cron with more
files.** One deliberately spreads work out; the other deliberately clumps it
together; and cron can express neither.

## A timer that is only a timer

```ini
[Timer]
OnCalendar=*-*-* 04:00:00
Unit=cleanup.service
```

`Unit=` breaks the name convention, which is how one service gets two schedules —
a `cleanup-nightly.timer` and a `cleanup-weekly.timer`, both starting
`cleanup.service`. **There is no way to do that in cron except by writing the
command twice.**

## Where they are written down

```sh
/etc/systemd/system/          # yours, and it wins
/run/systemd/system/          # runtime, gone at reboot
/usr/lib/systemd/system/      # the package's
~/.config/systemd/user/       # yours, for --user timers
```

Same order as lesson 5's services, for the same reason: a file in
`/etc/systemd/system` shadows the package's, so an upgrade does not undo your
change and your change does not disappear with the package.

For one setting rather than a whole file, `systemctl edit report.timer` writes a
drop-in under `/etc/systemd/system/report.timer.d/` — and it opens the editor of
lesson 12's section 205 to do it.
