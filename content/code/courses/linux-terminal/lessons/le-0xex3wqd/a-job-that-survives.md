---
title: Nine things a scheduled job needs, whatever started it
version: 2
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

The script needs logs to archive. Three days of a small application's logs,
named by date the way most applications name them:

```sh
mkdir -p ~/srv/app/logs ~/srv/archive && cd ~/srv/app/logs
for d in "$(date -d '2 days ago' +%F)" "$(date -d yesterday +%F)" "$(date +%F)"; do
  printf '%s 03:00:01 app started\n%s 03:00:02 app ready\n' "$d" "$d" > "app-$d.log"
done
```

And the script, in lesson 9's directory:

```sh
cd ~/work/scripts
cat > upload-logs.sh <<'END'
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
END
chmod +x upload-logs.sh
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
=== 2026-10-07 14:39:34 starting
=== 2026-10-07 14:39:35 archived logs-2026-10-06.tar.gz
=== 2026-10-07 14:39:35 starting
already done for 2026-10-06
ana@vm:~/work/scripts$ ls -l /home/ana/srv/archive/
total 4
-rw-rw-r-- 1 ana ana 159 Oct  7 14:39 logs-2026-10-06.tar.gz
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

Here is that line, on a one-minute schedule so it can be watched. The archive
and the log of the two runs above are deleted first, so that the first scheduled
run has work to do, and the crontab is replaced:

```sh
cd ~/work/cron
rm -f ~/srv/archive/* upload-logs.log
cat > survive.cron <<'END'
MAILTO=ana
PATH=/usr/local/bin:/usr/bin:/bin

# every minute (for this demonstration) — archive yesterday's logs.
# skip if the last run is still going; give up after 60 seconds.
* * * * * /usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh
END
crontab survive.cron
sleep 190
```

Three minutes later:

```
ana@vm:~/work/cron$ crontab -l
MAILTO=ana
PATH=/usr/local/bin:/usr/bin:/bin

# every minute (for this demonstration) — archive yesterday's logs.
# skip if the last run is still going; give up after 60 seconds.
* * * * * /usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh
ana@vm:~/work/cron$ cat upload-logs.log
=== 2026-10-07 14:40:02 starting
=== 2026-10-07 14:40:03 archived logs-2026-10-06.tar.gz
=== 2026-10-07 14:41:01 starting
already done for 2026-10-06
=== 2026-10-07 14:42:02 starting
already done for 2026-10-06
ana@vm:~/work/cron$ ls -l /home/ana/srv/archive/
total 4
-rw-rw-r-- 1 ana ana 159 Oct  7 14:40 logs-2026-10-06.tar.gz
```

```
root@vm:~# grep upload-logs /var/log/syslog | tail -4
2026-10-07T14:40:01.902937+00:00 vm CRON[5076]: (ana) CMD (/usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh)
2026-10-07T14:41:01.343089+00:00 vm CRON[5093]: (ana) CMD (/usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh)
2026-10-07T14:42:02.108397+00:00 vm CRON[5100]: (ana) CMD (/usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh)
```

**Three runs, one archive, and no mail at all.** The log distinguishes the run
that did the work from the two that correctly did nothing; syslog says cron
started the job each minute; and the mailbox did not grow, because
silence is what a working job looks like.

Which is the whole problem with the ninth item, below.

This crontab is a demonstration and runs every minute; once you have watched it,
`crontab -r` removes it — the one time that flag is exactly what you want.

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
