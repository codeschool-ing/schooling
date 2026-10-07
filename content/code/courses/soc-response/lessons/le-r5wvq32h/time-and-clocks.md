---
title: Time, zones and clocks
version: 1
---

An investigation is a timeline, and a timeline built from records that disagree about time is fiction.
Three things go wrong, and each has a cheap prevention.

**The zone.** The machine this course was recorded on runs in São Paulo time, three hours behind UTC:

```
root@soc:~# date
Wed Oct  7 04:34:57 -03 2026
root@soc:~# date -u
Wed Oct  7 07:34:57 UTC 2026
root@soc:~# date -d '2026-09-17T02:33:07-03:00' -u
Thu Sep 17 05:33:07 UTC 2026
root@soc:~# date -d 'Sep 17 02:33:07'
Thu Sep 17 02:33:07 -03 2026
```

The third command takes a time stamp written with its offset, `-03:00`, and converts it to UTC
unambiguously: **05:33:07**. The fourth takes the same moment written the old syslog way, as `fw.log`
writes it in lesson 1, with no year and no zone. `date` filled both gaps from the machine it ran on: the
year **2026** and the zone `-03`. Here that guess is right. Read on a machine set to UTC it would be three
hours off; read in January about a December night it would be a year off. **A record without its zone is
read in the reader's zone**, and nobody notices.

**The clock.** Two machines whose clocks differ by forty seconds will put an attacker's login on one after
the file copy it caused on the other. Every machine in an estate synchronises to the same time source
with NTP: on Ubuntu, `systemd-timesyncd` or `chrony`, checked with `timedatectl` (not run here, for the
same reason as `journalctl`). A SIEM that records both the time an event says it happened and the time it
received it can show the drift; the difference between those two fields is worth a dashboard of its own.

**The precision.** Lesson 1 already met this: `ts` stamps to the second, `tcpdump` to the microsecond,
rsyslog to the microsecond with the offset. Joining a one-second record to a microsecond one is joining to
a window, not to a point.

The rule that follows is simple to state. **Store and compare in UTC; show in local time; never accept a
record without its offset if you can configure it to carry one.** Windows already stores UTC. Ubuntu
24.04's rsyslog already writes the offset. Network equipment is where the old format survives longest,
and a line saying `Sep 17 02:33:07` is a line somebody has to annotate by hand with the zone of the
device that wrote it, which is exactly the kind of step that is skipped at three in the morning.
