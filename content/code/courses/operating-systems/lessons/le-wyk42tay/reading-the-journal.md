---
title: Reading the journal
version: 1
---

On systemd distributions, every service's output, the kernel's messages and the system's own events go
to one place, **the journal**, and `journalctl` reads it:

```
ana@server:~$ sudo journalctl --disk-usage
Archived and active journals take up 39.6M in the file system.
ana@server:~$ sudo journalctl -u cron -n 3 --no-pager
Sep 25 11:42:08 server (cron)[41]: cron.service: Referenced but unset environment variable evaluates to an empty string: EXTRA_OPTS
Sep 25 11:42:08 server cron[41]: (CRON) INFO (pidfile fd = 3)
Sep 25 11:42:08 server cron[41]: (CRON) INFO (Running @reboot jobs)
ana@server:~$ sudo journalctl -b -p err --no-pager -o cat | cut -c1-90 | tail -2
```

- `--disk-usage`: the journal keeps history, here 39.6 MB of it, and trims itself as it grows.
- `-u cron -n 3`: the last three lines from one unit. Each line has *when*, *which machine*,
  *which program and process*, and *what*. `-u` is the filter you will use most, after lesson 14.
  The first line is a warning about an unset variable, `EXTRA_OPTS`, which cron does not need: **a
  warning in the log is not necessarily the problem you are looking for**, and deciding that is part of
  the skill.
- `-b -p err`: only this boot (`-b`), only errors and worse (`-p err`); `-o cat` drops the date
  columns and `cut` keeps 90 characters. It printed **nothing**: this server was started just before the
  recording, and nothing since has been recorded as an error. An empty answer is still an answer, and
  section 03 is a failure that never reaches this list.

| filter | shows |
|---|---|
| `-u NAME` | one unit |
| `-b`, `-b -1` | this boot, the previous boot |
| `-p err` | this priority and worse: `emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, `debug` |
| `--since "1 hour ago"` | a time window, also `--until` |
| `-f` | new lines as they arrive, like `tail -f` |
| `-x` | adds explanations for known messages |

`-b -1` deserves a note. After an unexpected restart, the interesting lines are in the **previous** boot,
the last ones it wrote before it stopped.

Some programs still write their own log files to **`/var/log`**, and lesson 12's `tail` and `grep` read
them. On a full Ubuntu installation, `/var/log/syslog` and `/var/log/auth.log` also exist; this minimal
server keeps everything in the journal.
