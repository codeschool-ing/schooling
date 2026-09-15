---
title: `journalctl`, and a log that survives a reboot
version: 1
---

**The same note as section 79 applies here.** This machine runs a container supervisor as process
one, so there is no journal to read and no transcript to take. The commands below are the ones to
know, the output shapes are described rather than pasted, and section 77 explains why.

## Where a service's output goes

Section 76 said a daemon has no terminal, so every line it writes has to be collected by something.
On a systemd machine that something is **the journal**: systemd captures the standard output and
standard error of everything it starts, and stores it.

That is the design decision worth naming, because it changes how you write a service:
**`ExecStart=` should print to the screen, not to a file.** No log path, no rotation, no
permissions on a log directory. The unit prints; the journal collects.

`/var/log/` still exists and plenty of software still writes there directly. On a modern machine
you look in both, and `journalctl` first.

## The binary log, and the argument about it

The journal is **not a text file.** It is a structured, indexed, binary format, and this is the part
of systemd that the Unix tradition objects to hardest — section 77 named it.

What it buys is real: every line carries fields as data rather than as text somebody has to parse
back out. The service, the PID, the user, the priority, the boot it belongs to. That is why
`journalctl -u nginx --since '1 hour ago' -p err` is one command instead of `grep` plus `awk` plus a
date-handling problem.

What it costs is that `cat` and `grep` no longer work on your logs. You go through a tool, and if
the tool or the file is broken you have a harder afternoon than a text file would have given you.

Both halves are true. It is on your machine either way.

## The six flags that do the work

```
journalctl -u nginx                     # one service
journalctl -u nginx -f                  # and follow it, like tail -f
journalctl -u nginx -n 50               # the last 50 lines
journalctl -u nginx --since '1 hour ago'
journalctl -u nginx -p err              # this priority and worse
journalctl -b                           # this boot, everything, in order
```

**`-u` and `-f` together are the pair you will type most.** One terminal following the service,
another provoking it — the same shape as lesson 3 section 43's `tail -f`, which is deliberate.

`--since` and `--until` take ordinary English as well as timestamps: `'10 min ago'`,
`'yesterday'`, `'2026-09-14 09:00'`. That is worth more than it sounds when somebody says *it broke
around nine*.

`-p` takes the syslog priorities, and asking for one gives you it **and everything more serious**:

| | |
|---|---|
| `0` emerg, `1` alert, `2` crit | rare, and bad |
| `3` err | the one you ask for |
| `4` warning | |
| `5` notice, `6` info | the normal chatter |
| `7` debug | off unless somebody turned it on |

## `-b` is the one people do not know

```
journalctl -b        # this boot
journalctl -b -1     # the previous boot
journalctl --list-boots
```

**This is how you find out why a machine rebooted**, and how you read a failure that happened during
boot before you could log in.

It is also the answer to the cascade section 79 ended on: a service that failed because something
else failed shows you its own confusion, and `journalctl -b` shows the boot in order, so the first
failure is above the second.

## Whose journal, and why you may see nothing

By default a non-root user sees **their own** messages and not the system's. Two groups change that,
and being in either is enough:

| | |
|---|---|
| `systemd-journal` | full read access to the journal |
| `adm` | the same, on Debian and Ubuntu |

**An empty `journalctl -u nginx` as an ordinary user usually means permission, not absence.** Try it
with `sudo` before you conclude the service said nothing.

## It may not survive a reboot, and that is a setting

```
journalctl --disk-usage
```

If `/var/log/journal/` exists, the journal is **persistent** and survives reboots. If it does not,
the journal lives in `/run/log/journal/` — on a tmpfs, in memory — and **is gone at the next boot.**

Debian and Ubuntu have shipped persistent by default for years; some minimal images and most
containers do not. The fix is one directory:

```
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
```

`journalctl --vacuum-time=30d` and `--vacuum-size=500M` prune it, and
`SystemMaxUse=` in `/etc/systemd/journald.conf` sets the ceiling so it never becomes lesson 3
section 48's full disk.

## Two more worth having

```
journalctl -k                          # kernel messages only — dmesg, with timestamps you can read
journalctl -u nginx -o json-pretty     # every field of every entry
```

`-o json-pretty` is the one that makes the binary format's point. You get `_PID`, `_UID`,
`_SYSTEMD_UNIT`, `_HOSTNAME`, `_TRANSPORT` and a dozen more as named values — things that in a text
log would have to be parsed back out of a line somebody formatted by hand.

## What to run when something is broken

Four commands, in this order, and they are the whole of ordinary diagnosis:

```
systemctl --failed
systemctl status thatservice
journalctl -u thatservice -n 50
journalctl -b -p err
```

**The first two are usually enough.** The third is when the status block's ten lines were not, and
the fourth is when the cause is somewhere else on the machine.
