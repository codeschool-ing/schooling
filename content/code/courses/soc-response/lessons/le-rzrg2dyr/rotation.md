---
title: Rotation, without losing a line
version: 1
---

A log file that only grows eventually fills its disk, and a full disk stops the very logging that would
explain what happened. **Rotation** closes the current file at a fixed moment, renames it, starts a new
one, and deletes the oldest when there are more than the policy allows. On Linux it is `logrotate`, run
once a day by a timer. Put this in `/etc/logrotate.d/remote`:

```conf
/var/log/remote/*.log {
    daily
    rotate 400
    dateext
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

| directive | what it decides |
|---|---|
| `daily` | a new file every day, so one file is one day: easy to hash, easy to hand over |
| `rotate 400` | keep 400 old files, which with `daily` is a little over thirteen months, the ceiling in the first figure of this lesson |
| `dateext` | name the old file by its date (`gw.log-20261007`) instead of a number that shifts every day |
| `compress`, `delaycompress` | compress old files, but leave yesterday's uncompressed one more day in case something is still writing to it |
| `copytruncate` | copy the file and empty the original in place, so the writer keeps its file open |

`copytruncate` is a trade-off worth naming. The alternative, `create`, renames the file and asks the
writer to reopen; rsyslog does that on a signal, and Ubuntu's own rotation of `/var/log/syslog` works that
way. `copytruncate` needs no signal, at the price of a tiny window: a line written between the copy and the
truncation is lost. For a file that has to be complete, prefer `create` and the signal.

Force one rotation and look:

```
root@soc:~# ls -l /var/log/remote
total 4
-rw-r----- 1 syslog adm 399 Oct  7 04:51 gw.log
root@soc:~# logrotate -f /etc/logrotate.d/remote
root@soc:~# ls -l /var/log/remote
total 4
-rw-r----- 1 syslog adm   0 Oct  7 04:51 gw.log
-rw-r----- 1 syslog adm 399 Oct  7 04:51 gw.log-20261007
```

The day's lines, 399 bytes, are now `gw.log-20261007`, still owned by `syslog` and the `adm` group;
`gw.log` starts again from zero. **Hash the rotated file**, as in the previous section, before it is
compressed tomorrow: a file named for one day and hashed once is the unit that the next section hands from
person to person.
