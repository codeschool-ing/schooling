---
title: What is scheduled on this machine, and did it run
version: 1
---

Two questions, and you will ask them on a machine you did not set up.

## Everything that is scheduled

```sh
crontab -l                                  # yours
sudo crontab -u www-data -l                 # somebody else's
sudo ls -la /var/spool/cron/crontabs/       # who has one at all
cat /etc/crontab                            # the system one
ls -la /etc/cron.d/ /etc/cron.*ly/          # packages, and the run-parts dirs
systemctl list-timers --all                 # every timer, enabled or not
sudo atq                                    # one-shot jobs waiting
```

**Seven places.** Nothing prints them all, and a job you cannot find is usually
in the one you did not check — most often `/etc/cron.d`, because nobody put it
there by hand.

A first pass that catches most of it:

```sh
sudo grep -rs --include='*' '' /etc/cron.d /etc/crontab /var/spool/cron
```

## `systemctl list-timers`

This machine cannot run it, and says so plainly:

```
ana@vm:~/work/cron/units$ systemctl list-timers --all
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

PID 1 in this container is not systemd — the same limit lesson 5 hit, for the
same reason, and the same honesty applies here: **what follows is a drawing of
that command's output, not a capture.**

```
NEXT                        LEFT     LAST                        PASSED  UNIT             ACTIVATES
Tue 2026-09-15 13:00:00 UTC 14min    Tue 2026-09-15 12:00:00 UTC 45min   sysstat-collect… sysstat-collect.service
Wed 2026-09-16 00:00:00 UTC 11h      Tue 2026-09-15 00:00:12 UTC 12h     logrotate.timer  logrotate.service
Wed 2026-09-16 03:00:00 UTC 14h      Tue 2026-09-15 03:00:19 UTC 9h      report.timer     report.service
Wed 2026-09-16 06:12:44 UTC 17h      Tue 2026-09-15 06:12:44 UTC 6h      apt-daily.timer  apt-daily.service
-                           -        -                           -       systemd-tmpfile… systemd-tmpfiles-clean.service

5 timers listed.
```

**`NEXT` and `LAST` are the two columns worth the command.** A timer whose `LAST`
is older than its period did not run, and that is a fact you can act on. The
dashes on the last row are a timer that is loaded but has never fired.

`--all` includes the ones that are not active; without it you see only the live
ones, and a disabled timer is exactly what you are looking for when a job has
stopped.

## Did it run?

| | |
|---|---|
| `grep CRON /var/log/syslog` | cron, on Debian and Ubuntu |
| `journalctl -u cron` | cron, through the journal |
| `journalctl -u report.service` | one timer's job, output included |
| `journalctl -u report.service --since yesterday` | since when |
| `systemctl status report.timer` | when it fires next |
| `systemctl status report.service` | how the last run ended |

**The journal is the timer's advantage over cron here.** A cron job's output goes
to mail — if there is an MTA, if somebody reads it. A timer's job runs under
systemd, so **stdout and stderr go to the journal**, with the unit name, the
timestamp and the exit status, and they are there in a week when you want them.

## A checklist for "it did not run"

In this order, because each one is cheaper than the next:

1. **Is it in the crontab you think?** `crontab -l`, on the account you think.
   `sudo crontab -u deploy -l` is the answer more often than it should be.
2. **Is the daemon running?** `systemctl status cron`, `systemctl status atd`. A
   container that never started cron is a whole class of this.
3. **Did cron try?** `grep CRON /var/log/syslog`. A `CMD` line means the job
   started and the problem is inside it; no line at all means the schedule is
   wrong or cron never read the file.
4. **Is the schedule what you meant?** Section 213's OR rule, `*/15` counting
   from zero, and for a timer, `systemd-analyze calendar` on the exact string.
5. **Is the file named right?** A dot in a `/etc/cron.d` name, or a missing
   final newline, and the file is ignored without a word.
6. **Is it the environment?** `env -i` from section 215, which reproduces the
   failure in your terminal in ten seconds.
7. **Is it still running from last time?** Section 223. `ps -ef | grep` the
   command, and look at how long it has been there.

**Steps 3 and 6 between them cover most of it**, and they are both ten seconds.
The reason the list is in this order is that everybody starts at step 6 and the
answer is usually step 1.
