---
title: What is scheduled on this machine, and did it run
version: 2
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

```
ana@vm:~$ systemctl list-timers --all
NEXT                                 LEFT LAST                              PASSED UNIT                           ACTIVATES
Wed 2026-10-07 14:40:00 UTC           40s Wed 2026-10-07 14:30:01 UTC     9min ago sysstat-collect.timer          sysstat-collect.service
Wed 2026-10-07 15:31:43 UTC         52min Wed 2026-10-07 14:34:48 UTC 4min 31s ago anacron.timer                  anacron.service
Wed 2026-10-07 15:32:38 UTC         53min Wed 2026-10-07 14:11:30 UTC    27min ago fwupd-refresh.timer            fwupd-refresh.service
Thu 2026-10-08 00:00:00 UTC            9h Wed 2026-10-07 13:18:17 UTC            - dpkg-db-backup.timer           dpkg-db-backup.service
Thu 2026-10-08 00:00:00 UTC            9h Wed 2026-10-07 13:18:17 UTC            - logrotate.timer                logrotate.service
Thu 2026-10-08 00:07:00 UTC            9h -                                      - sysstat-summary.timer          sysstat-summary.service
Thu 2026-10-08 03:01:02 UTC           12h -                                      - report.timer                   report.service
Thu 2026-10-08 04:17:01 UTC           13h Wed 2026-10-07 13:18:17 UTC            - apt-daily.timer                apt-daily.service
Thu 2026-10-08 06:11:38 UTC           15h Wed 2026-10-07 13:18:17 UTC            - motd-news.timer                motd-news.service
Thu 2026-10-08 06:18:06 UTC           15h Wed 2026-10-07 13:18:17 UTC            - apt-daily-upgrade.timer        apt-daily-upgrade.service
Thu 2026-10-08 10:23:07 UTC           19h Wed 2026-10-07 13:18:17 UTC            - man-db.timer                   man-db.service
Thu 2026-10-08 13:58:57 UTC           23h Wed 2026-10-07 13:58:57 UTC    40min ago update-notifier-download.timer update-notifier-download.service
Thu 2026-10-08 14:08:38 UTC           23h Wed 2026-10-07 14:08:38 UTC    30min ago systemd-tmpfiles-clean.timer   systemd-tmpfiles-clean.service
Sun 2026-10-11 03:10:52 UTC        3 days Wed 2026-10-07 13:18:17 UTC            - e2scrub_all.timer              e2scrub_all.service
Mon 2026-10-12 01:21:44 UTC        4 days Wed 2026-10-07 13:18:17 UTC            - fstrim.timer                   fstrim.service
Sat 2026-10-17 13:44:00 UTC 1 week 2 days Wed 2026-10-07 13:18:17 UTC            - update-notifier-motd.timer     update-notifier-motd.service
-                                       - -                                      - apport-autoreport.timer        apport-autoreport.service
-                                       - -                                      - snapd.snap-repair.timer        snapd.snap-repair.service
-                                       - -                                      - ua-timer.timer                 ua-timer.service

19 timers listed.
```

**`NEXT` and `LAST` are the two columns worth the command.** A timer whose `LAST`
is older than its period did not run, and that is a fact you can act on.
`report.timer` from section 12 is there, waiting for 03:01:02 with a dash for
`LAST`, because it has never fired; `anacron.timer` is section 09's anacron,
started by systemd. The three rows of dashes at the bottom are timers that are
loaded and not active.

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

Section 12's `report.timer` will not fire until three in the morning, but its
service can be started by hand, which is the test section 12 recommended — and
then everything in that table has something to say:

```
ana@vm:~$ sudo systemctl start report.service
ana@vm:~$ journalctl -u report.service --no-pager | tail -4
Oct 07 14:58:41 vm systemd[1]: Starting report.service - Nightly report...
Oct 07 14:58:42 vm report.sh[5547]: report ran
Oct 07 14:58:42 vm systemd[1]: report.service: Deactivated successfully.
Oct 07 14:58:42 vm systemd[1]: Finished report.service - Nightly report.
ana@vm:~$ systemctl show report.service -p Result -p ExecMainStatus -p TriggeredBy
Result=success
ExecMainStatus=0
TriggeredBy=report.timer
```

**The journal has the run**: systemd starting it, the script's own output under
its name and process id — `report.sh[5547]: report ran` — and the service
finishing. `systemctl show` says how the last run ended, `Result=success` with
an exit status of 0, and which timer starts it. That is everything a cron job's mail would have said, and more,
with no mail system involved.

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
4. **Is the schedule what you meant?** Section 04's OR rule, `*/15` counting
   from zero, and for a timer, `systemd-analyze calendar` on the exact string.
5. **Is the file named right?** A dot in a `/etc/cron.d` name, or a missing
   final newline, and the file is ignored without a word.
6. **Is it the environment?** `env -i` from section 06, which reproduces the
   failure in your terminal in ten seconds.
7. **Is it still running from last time?** Section 14. `ps -ef | grep` the
   command, and look at how long it has been there.

**Steps 3 and 6 between them cover most of it**, and they are both ten seconds.
The reason the list is in this order is that everybody starts at step 6 and the
answer is usually step 1.
