---
title: Nine things a scheduled job needs, whatever started it
version: 1
---

This is the section that outlives the scheduler. Cron, a systemd timer, a
Kubernetes `CronJob`, Airflow — all of them start a program and walk away, and
everything below is about the program.

## The nine

| | |
|---|---|
| 1 | **absolute paths**, for the program and for every file it touches |
| 2 | **`set -euo pipefail`**, so a failure is a failure — lesson 9 |
| 3 | **a lock**, so it cannot run twice at once — section 14 |
| 4 | **a timeout**, so a hang is not permanent |
| 5 | **output that goes somewhere you will read** — section 07 |
| 6 | **a non-zero exit when it fails**, which is what everything else keys off |
| 7 | **idempotence**: running it twice does no harm |
| 8 | **a comment saying why it exists** |
| 9 | **somebody told when it stops** |

Eight of those are a line each. The ninth is the one that is actually hard.

## The shape

```sh
#!/bin/bash
# Archives yesterday's logs.
# Scheduled: 03:17 daily, ana's crontab. Safe to run by hand, safe to run twice.
set -euo pipefail

LOG=/home/ana/work/cron/upload-logs.log
exec >> "$LOG" 2>&1
echo "=== $(date '+%F %T') starting"

cd /home/ana/srv/app/logs

yesterday=$(date -d yesterday +%F)
archive="/home/ana/srv/archive/logs-$yesterday.tar.gz"

if [ -f "$archive" ]; then
    echo "already done for $yesterday"
    exit 0
fi

tar czf "$archive.tmp" "app-$yesterday".*
mv "$archive.tmp" "$archive"
echo "=== $(date '+%F %T') archived $(basename "$archive")"
```

And run twice, back to back:

```
ana@vm:~/work/scripts$ shellcheck upload-logs.sh && echo "shellcheck clean"
shellcheck clean
ana@vm:~/work/scripts$ ./upload-logs.sh; echo "exit $?"
exit 0
ana@vm:~/work/scripts$ ./upload-logs.sh; echo "exit $?"
exit 0
ana@vm:~/work/scripts$ cat /home/ana/work/cron/upload-logs.log
=== 2026-09-15 12:46:28 starting
=== 2026-09-15 12:46:28 archived logs-2026-09-14.tar.gz
=== 2026-09-15 12:46:28 starting
already done for 2026-09-14
ana@vm:~/work/scripts$ ls -l /home/ana/srv/archive/
total 4
-rw-r--r-- 1 ana ana 187 Sep 15 12:46 logs-2026-09-14.tar.gz
```

**Both runs printed nothing and exited 0**, which is what cron wants: no output,
no mail. The log says what happened, the second run says `already done`, and
there is exactly one archive — which is idempotence, demonstrated rather than
claimed.

Five things in the script are worth naming:

**`exec >> "$LOG" 2>&1`** redirects the rest of the script once, instead of a
`>>` on every line — which is why both runs above printed nothing to the
terminal. Cron has nothing to mail when it works.

**`cd` on its own line, under `set -e`.** Lesson 9's argument: if the directory
is gone, the script stops there rather than doing the work somewhere else.

**The `.tmp` and the `mv`.** A rename inside one filesystem is atomic, so a
reader never sees a half-written archive, and a job killed in the middle leaves a
`.tmp` rather than a corrupt file that looks finished.

**The `if [ -f "$archive" ]` guard** is what idempotence looks like in practice.
It is four lines and it is what makes a catch-up run, a retry, and somebody
running it by hand all safe.

**The comment naming the schedule.** The script is found by whoever is debugging
at three in the morning, and the crontab is not open in front of them.

## The crontab line it goes with

```sh
# 03:17 daily — archive yesterday's logs. Timeout 10m, skip if still running.
17 3 * * * /usr/bin/flock -E 0 -n /run/lock/upload-logs /usr/bin/timeout 600 /home/ana/bin/upload-logs.sh
```

Long, and every word of it is one of the nine.

Here is that line, on a one-minute schedule so it can be watched, after three
minutes:

```
ana@vm:~/work/cron$ crontab -l
MAILTO=ana
PATH=/usr/local/bin:/usr/bin:/bin

# every minute (for this demonstration) — archive yesterday's logs.
# skip if the last run is still going; give up after 60 seconds.
* * * * * /usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh
ana@vm:~/work/cron$ cat upload-logs.log
=== 2026-09-15 12:48:01 starting
=== 2026-09-15 12:48:01 archived logs-2026-09-14.tar.gz
=== 2026-09-15 12:49:01 starting
already done for 2026-09-14
=== 2026-09-15 12:50:01 starting
already done for 2026-09-14
ana@vm:~/work/cron$ ls -l /home/ana/srv/archive/
total 4
-rw-rw-r-- 1 ana ana 187 Sep 15 12:48 logs-2026-09-14.tar.gz
```

```
root@vm:~# grep upload-logs /var/log/syslog | tail -4
2026-09-15T12:49:01.514081+00:00 vm CRON[20499]: (ana) CMD ([20501] /usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh)
2026-09-15T12:49:01.525648+00:00 vm CRON[20499]: (ana) END ([20501] /usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh)
2026-09-15T12:50:01.529509+00:00 vm CRON[20531]: (ana) CMD ([20533] /usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh)
2026-09-15T12:50:01.542141+00:00 vm CRON[20531]: (ana) END ([20533] /usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh)
```

**Three runs, one archive, and no mail at all.** The log distinguishes the run
that did the work from the two that correctly did nothing; syslog says cron
started and finished the job each minute; and the mailbox did not grow, because
silence is what a working job looks like.

Which is the whole problem with the ninth item, below.

## The ninth: knowing when it stops

**Everything above tells you about a job that ran and failed. None of it tells
you about a job that never ran at all** — the daemon that was not started, the
crontab that was wiped, the container rebuilt without the file.

That failure is invisible by construction: silence is what success looks like.

The fix is to turn it around. **The job reports that it succeeded, and something
else complains when the report does not arrive.** A dead-man's switch:

```sh
# at the end of the script, after everything worked
curl -fsS --retry 3 https://monitor.example.com/ping/upload-logs > /dev/null
```

The monitor knows the job is meant to check in daily; if it does not, the monitor
is what raises the alarm — and it is somewhere else, so it survives the machine.
Hosted ones exist and a cron job on a second machine does the same thing.

**A file works too**, when there is no monitor:

```sh
date +%s > /var/lib/upload-logs/last-success
```

and something that already runs — the fleet's checks, the next job in the chain —
looks at how old it is.

## The rule underneath all nine

**Test the job the way it will run**, not the way you are running it.

Section 06's `env -i` for the environment; `sudo -u ana` for the account;
`systemctl start report.service` rather than the script by hand. A scheduled job
is different from the same command in your terminal in four ways — user,
environment, working directory, and terminal — and each of those has its own way
of failing at three in the morning.
