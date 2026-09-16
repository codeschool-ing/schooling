---
title: Six places a cron job can be, and which one to use
version: 1
---

Your crontab is one of six. A job that "is not in cron" is usually in one of the
other five.

| | who owns it | has a user field |
|---|---|---|
| `crontab -e` | you | no |
| `/etc/crontab` | root, by hand | **yes** |
| `/etc/cron.d/*` | root, usually a package | **yes** |
| `/etc/cron.hourly/`, `.daily/`, `.weekly/`, `.monthly/` | root | n/a — they are scripts |
| `/var/spool/cron/crontabs/*` | the spool behind `crontab -e` | no |
| systemd timers | root, or you | n/a |

## `/etc/crontab`, which explains the rest

```
ana@vm:~$ cat /etc/crontab
# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
# You can also override PATH, but by default, newer versions inherit it from the environment
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed
17 *    * * *   root    cd / && run-parts --report /etc/cron.hourly
25 6    * * *   root    test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.daily; }
47 6    * * 7   root    test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.weekly; }
52 6    1 * *   root    test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.monthly; }
```

**Those four lines are how `/etc/cron.daily` works.** There is no magic: a cron
job runs `run-parts`, and `run-parts` runs every executable in the directory.

Read the `test -x /usr/sbin/anacron ||` too. **If anacron is installed, the daily
job does nothing here**, because anacron will run those directories instead —
section 09.

**The sixth field is a user name.** `/etc/crontab` and `/etc/cron.d` have one and
your own crontab does not, which is the single commonest mistake when copying a
line from one to the other: paste a `/etc/cron.d` line into `crontab -e` and the
user name is read as the command.

## `/etc/cron.d`, where packages put things

```
ana@vm:~$ cat /etc/cron.d/sysstat
# The first element of the path is a directory where the debian-sa1
# script is located
PATH=/usr/lib/sysstat:/usr/sbin:/usr/sbin:/usr/bin:/sbin:/bin

# Activity reports every 10 minutes everyday
5-55/10 * * * * root command -v debian-sa1 > /dev/null && debian-sa1 1 1

# Additional run at 23:59 to rotate the statistics file
59 23 * * * root command -v debian-sa1 > /dev/null && debian-sa1 60 2
```

That is lesson 11's `sar` data being collected, every ten minutes, by a file the
`sysstat` package dropped here. **This is where to put a job that belongs to a
service rather than to a person** — one file, one subject, removable by deleting
it, and it survives `crontab -r`.

Two rules the directory enforces, and both bite:

**The file name may not contain a dot.** `run-parts` and cron both skip
`backup.sh` and `myjob.cron`; name it `backup`. It is the same rule as
`/etc/cron.daily`, and a job that silently never runs is usually this:

```
root@vm:~# ls /etc/cron.d
anacron  dotted.job  e2scrub_all  php  plainjob  sysstat
root@vm:~# cat /home/ana/work/cron/plain.log
plain ran at 12:38:01
root@vm:~# cat /home/ana/work/cron/dotted.log
cat: /home/ana/work/cron/dotted.log: No such file or directory
root@vm:~# run-parts --test /tmp/claude-0/rp
/tmp/claude-0/rp/alpha
```

Two files, identical except for the name. **`plainjob` ran. `dotted.job` never
ran at all**, and nothing anywhere complained. The last line is `run-parts`
making the same judgement in a directory holding an `alpha` and a `beta.sh`: only
the first one appears.

**The file needs its `PATH` set**, exactly as `sysstat` does above, because the
environment is not yours — section 06.

## The `run-parts` directories

```
ana@vm:~$ run-parts --test /etc/cron.daily
/etc/cron.daily/0anacron
/etc/cron.daily/apt-compat
/etc/cron.daily/dpkg
/etc/cron.daily/sysstat
```

**`--test` prints what would run and runs nothing**, which is the way to check
that your script is actually in the set before waiting a day to find out.

To add a job: put an **executable** script in the directory, with no dot in its
name. That is the whole interface — no time fields, because the directory is the
time.

They run in the order `run-parts` prints, which is why `0anacron` is called
`0anacron`.

## Which one to use

| | |
|---|---|
| your own job, your own account | `crontab -e` |
| a service's job, on a machine you configure | a file in `/etc/cron.d` |
| something that just needs to happen daily | a script in `/etc/cron.daily` |
| a job with dependencies, or that needs the journal | a systemd timer |
| never | `/etc/crontab` edited by hand |

The last one is a preference with a reason: `/etc/crontab` is a package's file,
and a package upgrade can prompt you about your changes to it. `/etc/cron.d` is
built for what you are doing.
