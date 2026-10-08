---
title: The environment is not yours, and that is why it worked in your shell
version: 2
---

**This is the section.** More scheduled jobs fail here than everywhere else in
this lesson put together, and they fail in the way that is hardest to notice:
nothing happens.

## What cron actually gives you

Ask it. One more line in the crontab of section 03: a job whose whole work is
to write down the environment it was given.

```sh
cd ~/work/cron
(crontab -l; echo '* * * * * env > /home/ana/work/cron/cronenv.txt') | crontab -
sleep 70
```

```
ana@vm:~/work/cron$ cat cronenv.txt
HOME=/home/ana
LOGNAME=ana
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
LANG=C.UTF-8
SHELL=/bin/sh
PWD=/home/ana
ana@vm:~/work/cron$ echo "$PATH"
/home/ana/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
```

**Six variables, and that is all a cron job starts with.**

| | |
|---|---|
| `SHELL=/bin/sh` | not bash. `dash`, on Debian and Ubuntu |
| `PATH=…` | the system's default, which Ubuntu's cron takes from `/etc/environment` |
| `HOME=/home/ana` | this one is right |
| `LOGNAME=ana` | and so is this |

Put the two `PATH` lines side by side. Cron's has the system directories and
**not `/home/ana/bin`**, which your login added, nor anything your `~/.bashrc`
adds. Other distributions' cron start from a shorter one still — `/usr/bin:/bin`
is common — so a job that relies on the `PATH` at all is relying on the
distribution.

**No `~/.bashrc`, no `~/.profile`, no `/etc/profile`.** Lesson 9's startup files
are for interactive and login shells, and a cron job is neither. Anything you put
in them — a `PATH` line, a `source venv/bin/activate`, an alias, a proxy
variable, `JAVA_HOME` — is absent.

That is what happened to the second line of section 03's crontab. `report.sh`
lives in `~/bin`, and cron mailed this back:

```
ana@vm:~/work/cron$ sed -n '/^Subject: Cron <ana@vm> report.sh/,/not found/p' /var/mail/ana | head -11
Subject: Cron <ana@vm> report.sh
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: quoted-printable
X-Cron-Env: <SHELL=/bin/sh>
X-Cron-Env: <HOME=/home/ana>
X-Cron-Env: <LOGNAME=ana>
Message-Id: <20261007142803.68121402CC@vm>
Date: Wed,  7 Oct 2026 14:28:02 +0000 (UTC)

/bin/sh: 1: report.sh: not found
```

**The subject line is the command, and the body is what it printed** — the
shell, saying it looked for `report.sh` in cron's `PATH` and did not find it. The
`X-Cron-Env` headers list part of the environment the job had; the file above is
the whole of it.

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

The file the job wrote is exactly the environment cron gives, so use it:

```
ana@vm:~/work/cron$ which report.sh
/home/ana/bin/report.sh
ana@vm:~/work/cron$ env -i $(cat cronenv.txt) /bin/sh -c 'report.sh'; echo "exit $?"
/bin/sh: 1: report.sh: not found
exit 127
ana@vm:~/work/cron$ env -i $(cat cronenv.txt) /bin/sh -c '/home/ana/bin/report.sh'; echo "exit $?"
report ran
exit 0
```

`env -i` starts with an empty environment and adds back the six variables cron
wrote down. **The first line finds the script. The second one, run the way cron
runs it, does not** — the same `report.sh: not found` as the mail, and `127`,
which is the shell's exit status for *I could not find that*. The third gives
the absolute path and works.

**If it works under `env -i`, it will work at three in the morning.** Ten
seconds, instead of a night of waiting to find out.

## The percent sign, which is not a percent sign

The second broken job was this line:

```sh
* * * * * echo "ran at $(date +%H:%M)" >> /home/ana/work/cron/pct.log
```

and this is the subject line and the body of what cron sent back:

```
ana@vm:~/work/cron$ grep -m1 '^Subject: Cron <ana@vm> echo' /var/mail/ana; grep -m1 'Syntax error' /var/mail/ana
Subject: Cron <ana@vm> echo "ran at $(date +
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

The three jobs again, with all three fixes made — a `PATH` line for the job that
needs one, the percent signs escaped, and the output of `report.sh` sent to a
file. Installing it replaces the whole crontab, the extra lines of sections 04
and 06 included:

```sh
cd ~/work/cron
cat > fixed.cron <<'END'
MAILTO=ana
PATH=/home/ana/bin:/usr/local/bin:/usr/bin:/bin

* * * * * /home/ana/work/cron/heartbeat.sh
* * * * * report.sh >> /home/ana/work/cron/report.log 2>&1
* * * * * echo "ran at $(date +\%H:\%M)" >> /home/ana/work/cron/pct.log
END
crontab fixed.cron
sleep 150
```

```
ana@vm:~/work/cron$ crontab -l
MAILTO=ana
PATH=/home/ana/bin:/usr/local/bin:/usr/bin:/bin

* * * * * /home/ana/work/cron/heartbeat.sh
* * * * * report.sh >> /home/ana/work/cron/report.log 2>&1
* * * * * echo "ran at $(date +\%H:\%M)" >> /home/ana/work/cron/pct.log
ana@vm:~/work/cron$ cat pct.log
ran at 14:34
ran at 14:35
ana@vm:~/work/cron$ cat report.log
report ran
report ran
ana@vm:~/work/cron$ tail -3 beat.log
2026-10-07 14:33:02 heartbeat, pid 4779
2026-10-07 14:34:01 heartbeat, pid 4803
2026-10-07 14:35:02 heartbeat, pid 4819
```

Three jobs, three files, one a minute, on the minute. **And no new mail** —
which is the subject of the next section, and the reason a silent cron is not
the same as a working one.
