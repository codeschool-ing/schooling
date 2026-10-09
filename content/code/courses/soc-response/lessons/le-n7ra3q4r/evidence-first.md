---
title: Evidence first
version: 1
---

Every containment action changes the system it touches. Isolating a host ends its connections; switching a
server off empties its memory; resetting a password rewrites the file that held the old one. **Whatever an
action destroys has to be written down before the action**, or it is gone for good. RFC 3227, the guideline
for collecting evidence that has been cited since 2002, gives the order: **the order of volatility**, what
lasts least first.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The order of volatility from RFC 3227, most volatile first: CPU registers and cache; routing and ARP tables, the process list, open connections and memory; temporary file systems; disk; remote logs and monitoring data; backups and archives. Collect in that order, because each layer lasts longer than the one above it.\"><rect x=\"20\" y=\"10\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">CPU registers, cache</text><text x=\"560\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nanoseconds</text><rect x=\"20\" y=\"56\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">routing and ARP tables, process list, open connections, memory</text><text x=\"560\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seconds to minutes</text><rect x=\"20\" y=\"102\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">temporary file systems</text><text x=\"560\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">until reboot</text><rect x=\"20\" y=\"148\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">disk</text><text x=\"560\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">until overwritten</text><rect x=\"20\" y=\"194\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">remote logs, monitoring data</text><text x=\"560\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the retention policy</text><rect x=\"20\" y=\"240\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">backups, archives</text><text x=\"560\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">months to years</text></svg>", "caption": "Collect from the top down: what lasts least goes first."}
```

For a response, the top rows are the ones that matter, because nothing else holds them. A process list or a
table of open connections exists only while the machine runs; the disk will still be there tomorrow. So the
habit, before touching any host in scope, is three things written down together: **when** the state was
read, **what** it was, and a **hash** of the file that holds it, so that nobody can later claim it was
edited. On the lab, one folder and four commands:

```
root@soc:~# mkdir ir
root@soc:~# date -Is > ir/when.txt; for h in gw files; do ip netns exec $h ss -tan > ir/$h-ss.txt; done
root@soc:~# cat ir/when.txt ir/files-ss.txt
2026-10-07T20:39:24-03:00
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      128    192.168.20.10:22        0.0.0.0:*          
root@soc:~# sha256sum ir/*
4b985e28ce680289950ee3d9ac852f704843e819af47f5d78351e0b82f0817f4  ir/files-ss.txt
a15d29fb4781dbadf0a64a578fde398d2faafe6a509e7ad075dbd3ac6d0f4faa  ir/gw-ss.txt
fc75ec741d666a9b5c86bb1b9f8d0f248b8410058812bc92dc9501e49f9091f2  ir/when.txt
```

`ss -tan` lists every TCP socket in the host's network namespace. On `files` there is only `sshd` waiting
for connections, because nothing is connected to the lab right now: the point here is the habit, not the
content. On a real server after a real intrusion, the same file would list whatever was still connected, and
it is the only record of it that will ever exist once containment starts.

`sha256sum` gives each file its fingerprint. Copy those three lines into the incident record, `INC-2026-014`,
with the name of whoever ran the commands. Lesson 16 does the same thing for whole disks, and lesson 17 for
memory, which needs tools of its own. Here, the rule is only the order: **collect, then act**.

There is a limit to it. If data is leaving right now, waiting an hour to image a server is an hour more of
data leaving. Collecting the volatile state takes a minute; that minute is nearly always worth it, and the
hour sometimes is not. That judgement belongs to the incident lead, and the last section of this lesson is
about how it is made.
