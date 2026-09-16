---
title: The machine that was off, and the job that runs once
version: 1
---

Cron has one assumption: **the machine is on.** A job scheduled for 03:00 on a
laptop that is shut at 03:00 does not run late — it does not run.

## anacron

```
ana@vm:~$ cat /etc/anacrontab
# /etc/anacrontab: configuration file for anacron

# See anacron(8) and anacrontab(5) for details.

SHELL=/bin/sh
HOME=/root
LOGNAME=root

# These replace cron's entries
1       5       cron.daily      run-parts --report /etc/cron.daily
7       10      cron.weekly     run-parts --report /etc/cron.weekly
@monthly        15      cron.monthly    run-parts --report /etc/cron.monthly
```

**Four fields, and not one of them is a clock time:**

| | |
|---|---|
| `1` | the period, in days |
| `5` | the delay in minutes after anacron starts |
| `cron.daily` | the **job identifier**, which is also a file name |
| `run-parts …` | the command |

anacron does not ask what time it is. It asks **how long since this job last
ran**, and the answer is a file:

```
/var/spool/anacron/cron.daily        # one line: the date it last ran
```

Two runs of a private anacrontab, a minute apart, say the whole thing:

```
ana@vm:~/work/cron$ cat myanacrontab
SHELL=/bin/sh
1       0       daily-report    echo "report for $(date +\%F)"
7       0       weekly-report   echo "weekly report"
ana@vm:~/work/cron$ anacron -T -t myanacrontab && echo "syntax ok"
syntax ok
ana@vm:~/work/cron$ anacron -d -n -t myanacrontab -S spool
Anacron 2.3 started on 2026-09-15
Will run job `daily-report'
Will run job `weekly-report'
Jobs will be executed sequentially
Job `daily-report' started
Job `daily-report' terminated (mailing output)
Job `weekly-report' started
Job `weekly-report' terminated (mailing output)
Normal exit (2 jobs run)
ana@vm:~/work/cron$ ls -l spool; cat spool/daily-report
total 8
-rw------- 1 ana ana 9 Sep 15 12:31 daily-report
-rw------- 1 ana ana 9 Sep 15 12:31 weekly-report
20260915
ana@vm:~/work/cron$ anacron -d -n -t myanacrontab -S spool
Anacron 2.3 started on 2026-09-15
Normal exit (0 jobs run)
```

**The first run does both jobs and writes the date. The second run does
nothing** — `Normal exit (0 jobs run)` — because both have already run today.
That file, `20260915`, is anacron's entire memory.

| | |
|---|---|
| `-T` | check the syntax of the anacrontab and exit |
| `-t file` | use this anacrontab instead of `/etc/anacrontab` |
| `-S dir` | use this spool directory |
| `-d` | stay in the foreground and say what it is doing |
| `-n` | run the due jobs **now**, ignoring the delay fields |
| `-f` | force: run them even if they already ran today |

**`anacron -T` is the `visudo` of scheduling** — it is the check you can run
before the file is live, and there is no equivalent for a crontab except
`crontab -e`'s.

## How it fits with cron

Look again at the system crontab from section 05:

```sh
25 6 * * * root test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.daily; }
```

**`test -x /usr/sbin/anacron ||`** — if anacron is installed, cron does *not* run
the daily jobs, because anacron will. And anacron itself is started by
`/etc/cron.d/anacron`, and by a systemd timer, and on some systems at boot.

The result is what you want on a laptop and is confusing the first time you read
it: `/etc/cron.daily` runs **once a day, at some point after the machine is
awake**, rather than at 06:25.

| | |
|---|---|
| server, always on | cron. anacron adds nothing |
| laptop, desktop, anything switched off | anacron, or a systemd timer with `Persistent=true` |
| a job whose *time* matters | cron or `OnCalendar` — anacron cannot promise one |

**anacron's granularity is a day.** Nothing hourly, nothing at a particular
minute. Section 12's `Persistent=true` is the same idea with a clock attached,
which is why anacron matters less on a systemd machine than it used to.

## `at`, which runs it once

```
ana@vm:~/work/cron$ cat at.log
12:35:00
ana@vm:~/work/cron$ atq
ana@vm:~/work/cron$ echo "atq printed nothing: the queue is empty"
atq printed nothing: the queue is empty
```

That is the result of `echo "date +%T >> at.log" | at now + 1 minute`, one minute
later: **it ran at 12:35:00 exactly, and then it was gone.** An `at` job is
consumed by running.

```
ana@vm:~/work/cron$ at 03:00 tomorrow <<< "/home/ana/bin/report.sh"
warning: commands will be executed using /bin/sh
job 2 at Wed Sep 16 03:00:00 2026
ana@vm:~/work/cron$ atq
2       Wed Sep 16 03:00:00 2026 a ana
ana@vm:~/work/cron$ atrm $(atq | cut -f1); atq; echo "removed, exit $?"
removed, exit 0
```

| | |
|---|---|
| `at 03:00 tomorrow` | reads the commands from stdin |
| `at -f script.sh 03:00` | or from a file |
| `atq` | what is queued |
| `atrm 2` | cancel job 2 |
| `at -c 2` | print the whole job, environment included |
| `batch` | run it when the machine is idle enough — a load threshold `atd` is started with |

**`warning: commands will be executed using /bin/sh`** is `at` telling you what
section 06 said: the same `/bin/sh`, the same missing profile.

But `at` does something cron does not: it **captures your current environment**
and replays it. `at -c` prints the job it will run, and the top of it is your
shell:

```
ana@vm:~$ at -c 3 | head -10
#!/bin/sh
# atrun uid=1001 gid=1002
# mail ana 0
umask 2
NVM_RC_VERSION=; export NVM_RC_VERSION
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64; export JAVA_HOME
GRADLE_HOME=/opt/gradle; export GRADLE_HOME
RBENV_SHELL=bash; export RBENV_SHELL
PWD=/home/ana; export PWD
LOGNAME=ana; export LOGNAME
```

**That is friendlier and no more reliable.** The job runs with whatever happened
to be set in the terminal you typed it in — including a `JAVA_HOME` from a
session you have forgotten — which is not a thing you chose and not a thing
anybody else can reproduce.

**Use it for "run this at four, once".** A migration, a restart during a window,
a reminder to a script. Anything that repeats belongs in one of the other three.

And `atd` has to be running, which on a minimal server it often is not —
`systemctl status atd` before you depend on it.
