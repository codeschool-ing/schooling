---
title: What is running in the background
version: 1
---

Lesson 1 left `systemd` as the first process, PID 1, and said it starts everything else. **`systemctl`**
is how you talk to it. Services are its **units** of type `.service`:

```
ana@server:~$ systemctl list-units --type=service --state=running --no-pager --no-legend
  cron.service             loaded active running Regular background program processing daemon
  dbus.service             loaded active running D-Bus System Message Bus
  systemd-journald.service loaded active running Journal Service
  systemd-logind.service   loaded active running User Login Management
  systemd-resolved.service loaded active running Network Name Resolution
  user@1000.service        loaded active running User Manager for UID 1000
ana@server:~$ sudo systemctl status cron --no-pager -n 0
● cron.service - Regular background program processing daemon
     Loaded: loaded (/usr/lib/systemd/system/cron.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-09-25 11:20:56 -03; 3min 12s ago
       Docs: man:cron(8)
   Main PID: 5701 (cron)
     CGroup: /system.slice/cron.service
             └─5701 /usr/sbin/cron -f -P
```

Six services on this minimal server, each with a one-line description: `cron`, the classic scheduler of
section 05; `dbus`, how programs talk to each other; the journal, which collects every log; logins; name
resolution; and a manager for ana's own session.

`systemctl status` gives one service's full picture: *Loaded*, which file defines it and whether it is
*enabled*; *Active*, whether it runs now and since when; and its *Main PID*, the process you
would see in `ps`. The `-n 0` left out the log lines that `status` normally adds at the end; section 04
reads a service's log on purpose.

A desktop runs dozens of services, and each is a program that starts without anybody asking. The
question for each is the same as for installed software in lesson 11: **is somebody using it?**
