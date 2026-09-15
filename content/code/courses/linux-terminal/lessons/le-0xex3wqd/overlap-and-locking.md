---
title: The job that is still running when the next one starts
version: 1
---

```sh
*/5 * * * * /home/ana/bin/sync.sh
```

Five minutes is plenty. Then the remote end gets slow, one run takes seven
minutes, and **cron starts the next one anyway** — because cron has no idea the
first is still going.

At eleven minutes there are three. At an hour there are twelve, each one slower
than the last because they are competing for the same disk, and the machine is
now doing nothing else. **This is the single most common way a scheduled job
takes a server down**, and it never happens in testing, because in testing the
job is fast.

## `flock`, which is one word

```
ana@vm:~/work/cron$ flock -n job.lock -c 'sleep 8; echo "long job finished"' & sleep 1; echo started
started
ana@vm:~/work/cron$ flock -n job.lock -c 'echo "second job ran"'; echo "exit $?"
exit 1
ana@vm:~/work/cron$ flock -w 20 job.lock -c 'echo "third job waited, then ran"'; echo "exit $?"
long job finished
third job waited, then ran
exit 0
```

Three runs against one lock file, and all three behaviours are in those six
lines.

**The first holds the lock for eight seconds.** The second asks for it with `-n`
— *do not wait* — and does not get it: no output, `exit 1`, gone. The third asks
with `-w 20` — *wait up to twenty seconds* — and you can watch it happen: the
long job's output appears first, then the third job runs.

| | |
|---|---|
| `flock -n file -c 'cmd'` | run it, or give up immediately |
| `flock -w 30 file -c 'cmd'` | run it, or give up after thirty seconds |
| `flock file -c 'cmd'` | wait as long as it takes |

In a crontab:

```sh
*/5 * * * * /usr/bin/flock -n /tmp/sync.lock /home/ana/bin/sync.sh
```

**`-n` is the right default for a repeating job.** A run that is skipped will
happen again in five minutes; a run that queues will still be queued at midnight.

## The exit status is the trap

`flock -n` exits **1** when it could not get the lock — which looks exactly like
a job that failed. On a machine with monitoring, a slow afternoon becomes an
afternoon of alerts about a job that is working correctly.

```sh
*/5 * * * * /usr/bin/flock -n /tmp/sync.lock /home/ana/bin/sync.sh || [ $? -eq 1 ]
```

Clumsy. `flock -E 0 -n` is the clean version: **`-E` sets the exit status used
when the lock is busy**, so `-E 0` says "skipping is not a failure".

```
ana@vm:~/work/cron$ flock -n job.lock -c 'sleep 6' & sleep 1; echo held
held
ana@vm:~/work/cron$ flock -E 0 -n job.lock -c 'echo ran'; echo "exit $?"
exit 0
```

**`ran` was never printed and the status is 0.** The lock was busy, the command
did not run, and nothing is reported as broken.

```sh
*/5 * * * * /usr/bin/flock -E 0 -n /tmp/sync.lock /home/ana/bin/sync.sh
```

Then a non-zero status means the job itself failed, which is what you wanted the
status to mean.

## Why not a PID file

The thing everybody writes instead:

```sh
[ -f /tmp/sync.pid ] && exit 0
echo $$ > /tmp/sync.pid
trap 'rm -f /tmp/sync.pid' EXIT
```

**It is wrong in two ways and both of them bite.** The check and the write are
two operations, so two jobs starting in the same second can both pass the check.
And a job killed with `SIGKILL` (lesson 6) never runs its trap, so the file
outlives it — and the job never runs again until somebody deletes it by hand.

`flock` has neither problem: the lock belongs to the file descriptor, and **the
kernel releases it when the process dies**, however it dies.

## systemd gets this for free

```sh
systemctl start report.service     # while report.service is already running
```

Nothing happens. **A `.service` that is active is not started again** — the
timer's activation is a no-op, and the journal records it. There is no lock file
to write, to leak, or to get wrong.

That is the strongest practical argument in this lesson for a timer over a
crontab line, and it is worth more than the calendar syntax.

## Two more things a long job needs

**A timeout**, so that a job that hangs is not still there tomorrow:

```sh
*/5 * * * * /usr/bin/flock -E 0 -n /tmp/sync.lock timeout 240 /home/ana/bin/sync.sh
```

`timeout 240` kills it after four minutes. In a unit file it is
`TimeoutStartSec=4min`, and `RuntimeMaxSec=` for the whole run.

**And a reason to be idempotent.** Locking stops two copies at once; it does not
stop the same work being done twice, by a retry, by a catch-up run, or by
somebody running it by hand while it is scheduled. The question to answer before
you schedule anything is *what happens if this runs twice?* — and the only
comfortable answer is "nothing".
