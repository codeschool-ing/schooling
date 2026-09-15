---
title: The environment is not yours, and that is why it worked in your shell
version: 1
---

**This is the section.** More scheduled jobs fail here than everywhere else in
this lesson put together, and they fail in the way that is hardest to notice:
nothing happens.

## What cron actually gives you

A job was scheduled as `report.sh` — a script in `~/bin`, which is on this
account's `PATH`. Cron mailed this back:

```
Subject: Cron <ana@vm> report.sh (failed)
MIME-Version: 1.0
Content-Type: text/plain; charset=US-ASCII
Content-Transfer-Encoding: quoted-printable
X-Cron-Env: <SHELL=/bin/sh>
X-Cron-Env: <HOME=/home/ana>
X-Cron-Env: <PATH=/usr/bin:/bin>
X-Cron-Env: <LOGNAME=ana>
Message-Id: <20260915123115.CCA069827E@vm>
Date: Tue, 15 Sep 2026 12:31:01 +0000 (UTC)

/bin/sh: 1: report.sh: not found
```

**Cron puts its own environment in the headers**, and there it is:

| | |
|---|---|
| `SHELL=/bin/sh` | not bash. `dash`, on Debian and Ubuntu |
| `PATH=/usr/bin:/bin` | four directories short of yours |
| `HOME=/home/ana` | this one is right |
| `LOGNAME=ana` | and so is this |

**No `~/.bashrc`, no `~/.profile`, no `/etc/profile`.** Lesson 9's startup files
are for interactive and login shells, and a cron job is neither. Anything you put
in them — a `PATH` line, a `source venv/bin/activate`, an alias, a proxy
variable, `JAVA_HOME` — is absent.

That is why the job works when you paste it into your terminal and fails at
three in the morning. **You are testing it in a different program.**

## Three fixes, in order of how well they work

```sh
# 1. absolute paths, everywhere
* * * * * /home/ana/bin/report.sh

# 2. set PATH at the top of the crontab
PATH=/home/ana/bin:/usr/local/bin:/usr/bin:/bin
* * * * * report.sh

# 3. make the job a script that sets up its own world
* * * * * /home/ana/bin/report-wrapper.sh
```

**Absolute paths are the one that never surprises anybody.** The `PATH` line
works and is invisible to somebody reading one line of your crontab. The wrapper
is what you want when the job needs more than a path — a virtualenv, a
`cd`, credentials from a file.

## Test it the way cron will run it

```
ana@vm:~/work/cron$ which report.sh
/home/ana/bin/report.sh
ana@vm:~/work/cron$ env -i SHELL=/bin/sh PATH=/usr/bin:/bin HOME=$HOME LOGNAME=$USER /bin/sh -c 'report.sh'; echo "exit $?"
/bin/sh: 1: report.sh: not found
exit 127
ana@vm:~/work/cron$ env -i SHELL=/bin/sh PATH=/usr/bin:/bin HOME=$HOME LOGNAME=$USER /bin/sh -c '/home/ana/bin/report.sh'; echo "exit $?"
report ran
exit 0
```

`env -i` starts with an empty environment and adds back exactly the four
variables cron's own headers listed. **The first line finds the script. The
second one, run the way cron runs it, does not** — the same
`/bin/sh: 1: report.sh: not found`, and `127`, which is the shell's exit status
for *I could not find that*.

**If it works under `env -i`, it will work at three in the morning.** Ten
seconds, instead of a night of waiting to find out.

## The percent sign, which is not a percent sign

The second broken job was this line:

```sh
* * * * * echo "ran at $(date +%H:%M)" >> /home/ana/work/cron/pct.log
```

and this is what cron sent back:

```
Subject: Cron <ana@vm> echo "ran at $(date + (failed)
...
/bin/sh: 1: Syntax error: end of file unexpected (expecting ")")
```

**Read the subject line.** The command cron ran was `echo "ran at $(date +` and
nothing else — because **in a crontab, an unescaped `%` ends the command**.
Everything after the first `%` becomes the job's standard input, and the newlines
you did not type are the remaining `%` signs.

So the shell got an unterminated `$(`, and said so.

```sh
* * * * * echo "ran at $(date +\%H:\%M)" >> /home/ana/work/cron/pct.log
```

**A backslash before every `%`.** It bites `date`, `find -printf`, `awk` format
strings, and every `printf` in a crontab line.

It has a use — `%` is how you pipe input into a job in one line — and the use is
rarer than the accident by a wide margin. **The habit that avoids it entirely is
to put anything with a `%` in a script** and schedule the script.

## The fixed crontab, and what it produced

```
ana@vm:~/work/cron$ crontab -l
MAILTO=ana
PATH=/home/ana/bin:/usr/local/bin:/usr/bin:/bin

* * * * * /home/ana/work/cron/heartbeat.sh
* * * * * report.sh >> /home/ana/work/cron/report.log 2>&1
* * * * * echo "ran at $(date +\%H:\%M)" >> /home/ana/work/cron/pct.log
ana@vm:~/work/cron$ cat pct.log
ran at 12:33
ran at 12:34
ana@vm:~/work/cron$ cat report.log
report ran
report ran
ana@vm:~/work/cron$ tail -3 beat.log
2026-09-15 12:32:01 heartbeat, pid 19067
2026-09-15 12:33:01 heartbeat, pid 19166
2026-09-15 12:34:01 heartbeat, pid 19232
```

Three jobs, three files, one a minute, on the minute. **And no mail arrived** —
which is the subject of the next section, and the reason a silent cron is not the
same as a working one.
