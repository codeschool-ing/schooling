---
title: Cron mails you, until somebody stops it
version: 2
---

**Anything a cron job writes to stdout or stderr is mailed to you.** That is the
entire error-reporting mechanism, it is from 1975, and it is better than what
most people replace it with.

```
ana@vm:~$ grep "^Subject:" /var/mail/ana | sort | uniq -c
      6 Subject: Cron <ana@vm> echo "ran at $(date +
      6 Subject: Cron <ana@vm> report.sh
```

**Two jobs, one message a minute each, for as long as they were broken.** The
subject line is the command, and the body is whatever it printed.

**Output is what cron mails, not failure.** A job that fails without printing
anything sends nothing: `false` in a crontab exits 1 every minute and the mailbox
never hears of it. And a job that succeeds noisily sends a message every time it
runs. That is why section 06's fix sent `report.sh`'s output to a
file: it now works, and it would otherwise mail `report ran` every minute.

## The line that hides everything

```sh
0 3 * * * /home/ana/bin/backup.sh >/dev/null 2>&1
```

**You will see this in every runbook and it is usually wrong.** It throws away
stdout *and* stderr, so:

- a job that fails every night for six months tells nobody;
- the error that would have named the problem is gone;
- and the only evidence left is that the backups are not there.

It is written because the job is chatty and the mail is noise, which is a real
problem with a better answer:

```sh
# keep the output, put it where you can read it
0 3 * * * /home/ana/bin/backup.sh >> /var/log/backup.log 2>&1

# or: say nothing when it works, mail when it does not
0 3 * * * /home/ana/bin/backup.sh > /tmp/backup.out 2>&1 || cat /tmp/backup.out
```

**The second one is the shape to learn.** `||` runs only on a non-zero exit, and
`cat` puts the output on stdout, where cron mails it. Silence means success;
mail means read it.

For that to work the job has to **exit non-zero when it fails**, which is lesson
9's whole argument for `set -euo pipefail` and for checking the exit status of
the things you call.

## `MAILTO`

```sh
MAILTO=ops@example.com          # send it somewhere else
MAILTO=""                       # send it nowhere — the same as >/dev/null, once
MAILTO=ana                      # the default: the crontab's owner
```

It is a line in the crontab and it applies to **every job below it**, so a
`MAILTO=""` at the top of the file silences the file.

Two things about it that matter more than they look:

**The mail has to go somewhere.** A machine with no mail transfer agent installed
— which is most containers and many cloud images — has nowhere to put it, and the
message is dropped. Cron says so in the system log rather than to you.

**`MAILTO` is not monitoring.** A mail that arrives at 03:04 and is read on
Thursday is a record, not an alert. Section 16 is about the difference.

## How to know it ran

Cron logs every job it starts, through syslog:

```
root@vm:~# grep CRON /var/log/syslog | tail -4
2026-10-07T14:35:01.962380+00:00 vm CRON[4813]: (root) CMD (command -v debian-sa1 > /dev/null && debian-sa1 1 1)
2026-10-07T14:35:02.033012+00:00 vm CRON[4814]: (ana) CMD (echo "ran at $(date +%H:%M)" >> /home/ana/work/cron/pct.log)
2026-10-07T14:35:02.046340+00:00 vm CRON[4815]: (ana) CMD (/home/ana/work/cron/heartbeat.sh)
2026-10-07T14:35:02.080983+00:00 vm CRON[4817]: (ana) CMD (report.sh >> /home/ana/work/cron/report.log 2>&1)
```

**`CMD` is cron starting the job**, with the user in brackets and the command as
cron parsed it — note the `%` there, unescaped in the log because cron has
already done its substitution.

| where to look | on what |
|---|---|
| `grep CRON /var/log/syslog` | Debian, Ubuntu |
| `journalctl -u cron` or `-u crond` | anything with systemd |
| `/var/log/cron` | Red Hat, SUSE |

**What the log does not tell you is whether the job worked.** On Ubuntu it
records the start and nothing else — not when the job ended, not how. The log
answers *did it start*; the output, mailed or in a file, answers *did it work*;
and you need both when a job that has run every night for a year stops.

Changes to a crontab are logged too, which is the audit trail:

```
root@vm:~# grep -E "crontab\[" /var/log/syslog | tail -3
2026-10-07T14:31:57.411126+00:00 vm crontab[4736]: (ana) REPLACE (ana)
2026-10-07T14:33:09.341222+00:00 vm crontab[4795]: (ana) REPLACE (ana)
2026-10-07T14:35:39.573063+00:00 vm crontab[4825]: (ana) LIST (ana)
```

`REPLACE (ana)` is somebody installing a new crontab for `ana`, and the name in
brackets at the front says who did it: `(ana)` in these lines, because the
account changed its own, and `(root)` when an administrator runs
`crontab -u ana`. **That entry is often the answer to
"when did this job change?"**

## The failure nobody catches

A job that runs, exits 0, and does nothing.

```sh
0 3 * * * cd /srv/app && ./backup.sh >> /var/log/backup.log 2>&1
```

If `/srv/app` is gone, `cd` fails, `&&` stops, and **the whole line exits
non-zero** — so this one is fine, and cron mails you. Change the `&&` to a `;`
and it is not: the `cd` fails, the script runs in the wrong directory, and the
exit status is the script's.

**`&&` between a `cd` and the command it is for.** Every time.
