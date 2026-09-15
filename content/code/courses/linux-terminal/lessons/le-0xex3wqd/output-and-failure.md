---
title: Cron mails you, until somebody stops it
version: 1
---

**Anything a cron job writes to stdout or stderr is mailed to you.** That is the
entire error-reporting mechanism, it is from 1975, and it is better than what
most people replace it with.

```
ana@vm:~$ grep "^Subject:" /var/mail/ana
Subject: Cron <ana@vm> report.sh (failed)
Subject: Cron <ana@vm> echo "ran at $(date + (failed)
Subject: Anacron job 'daily-report' on vm
Subject: Anacron job 'weekly-report' on vm
Subject: Cron <ana@vm> echo "ran at $(date + (failed)
Subject: Cron <ana@vm> report.sh (failed)
```

Six messages, from four jobs. **The subject line is the command**, and `(failed)`
means it exited non-zero. A job that succeeds quietly sends nothing at all.

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
Thursday is a record, not an alert. Section 225 is about the difference.

## How to know it ran

Cron logs every start and every finish, through syslog:

```
root@vm:~# grep CRON /var/log/syslog | tail -4
2026-09-15T12:38:01.113104+00:00 vm CRON[19857]: (ana) CMD ([19862] echo "plain ran at $(date +%T)" >> /home/ana/work/cron/plain.log)
2026-09-15T12:38:01.116771+00:00 vm CRON[19858]: (ana) END ([19860] echo "dow Tue only fired at $(date +%T)" >> /home/ana/work/cron/or3.log)
2026-09-15T12:38:01.117034+00:00 vm CRON[19857]: (ana) END ([19862] echo "plain ran at $(date +%T)" >> /home/ana/work/cron/plain.log)
2026-09-15T12:38:01.117359+00:00 vm CRON[19859]: (ana) END ([19861] echo "dom 13 OR dow Tue fired at $(date +%T)" >> /home/ana/work/cron/or.log)
```

**`CMD` is cron starting the job and `END` is the job finishing**, with the user
in brackets and the command as cron parsed it — note the `%T` there, unescaped in
the log because cron has already done its substitution.

| where to look | on what |
|---|---|
| `grep CRON /var/log/syslog` | Debian, Ubuntu |
| `journalctl -u cron` or `-u crond` | anything with systemd |
| `/var/log/cron` | Red Hat, SUSE |

**What the log does not tell you is whether the job worked** — `END` appears for
a job that exited 1 just as it does for one that exited 0. The log answers *did
it start*; the mail answers *did it work*; and you need both when a job that has
run every night for a year stops.

Changes to a crontab are logged too, which is the audit trail:

```
root@vm:~# grep -E "crontab\[" /var/log/syslog | tail -3
2026-09-15T12:36:37.464006+00:00 vm crontab[19813]: (root) LIST (ana)
2026-09-15T12:36:37.471514+00:00 vm crontab[19816]: (root) REPLACE (ana)
2026-09-15T12:38:25.419561+00:00 vm crontab[19902]: (ana) LIST (ana)
```

`REPLACE (ana)` is somebody installing a new crontab for `ana` — root, in that
line, and the `(root)` at the front says who. **That entry is often the answer to
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
