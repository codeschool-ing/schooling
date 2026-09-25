---
title: cron, the older way
version: 1
---

Timers are the modern way on systemd distributions. **cron** is older than Linux itself, runs on every
Unix including macOS, and is what most existing scripts and tutorials use.

```
ana@server:~$ crontab -l
no crontab for ana
ana@server:~$ echo '30 18 * * 1-5 df -h / >> /home/ana/disk.log' | crontab -
ana@server:~$ crontab -l
30 18 * * 1-5 df -h / >> /home/ana/disk.log
ana@server:~$ ls /etc/cron.daily
apt-compat
dpkg
```

Each user has a **crontab**, a table of scheduled commands. `crontab -l` lists it, and `crontab -e`
opens it in an editor; here a line was piped in with `crontab -` to keep the transcript short.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"The five time fields of a crontab line, 30 18 star star 1-5, followed by the command. 30 is the minute, from 0 to 59. 18 is the hour, from 0 to 23. The star in the third field is any day of the month. The star in the fourth is any month. 1-5 is the day of the week, Monday to Friday. Read together: at 18:30, Monday to Friday, write the disk usage to disk.log.\"><defs><marker id=\"cr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"68\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">30</text><text x=\"68\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">minute</text><text x=\"68\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0 to 59</text><rect x=\"130\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"178\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">18</text><text x=\"178\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">hour</text><text x=\"178\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0 to 23</text><rect x=\"240\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"288\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">*</text><text x=\"288\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">day of the month</text><text x=\"288\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">any</text><rect x=\"350\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"398\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">*</text><text x=\"398\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">month</text><text x=\"398\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">any</text><rect x=\"460\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"508\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1-5</text><text x=\"508\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">day of the week</text><text x=\"508\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Monday to Friday</text><rect x=\"570\" y=\"20\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"635\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">df -h / &gt;&gt; …</text><text x=\"635\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the command</text><text x=\"20\" y=\"140\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">at 18:30, Monday to Friday, write the disk usage to disk.log</text></svg>", "caption": "Five fields, always in this order, and a star means every. Day of the week counts from Sunday as 0, which is why weekdays are 1-5."}
```

The system has its own schedules as well: files in **`/etc/cron.d`**, and scripts dropped into
`/etc/cron.daily`, `weekly` and `monthly`, which run once a day, week or month without anybody
writing a time. On this server `apt` and `dpkg`, lesson 11's tools, each keep a script there.

| | cron | systemd timer |
|---|---|---|
| where | `crontab -e`, `/etc/cron.d` | a `.timer` and a `.service` |
| the log | wherever the command sends it | the journal, with the service's name |
| a missed run while off | skipped | run at next boot, with `Persistent=true` |
| test it now | run the command by hand | `systemctl start` the service |
| on macOS | yes | no |

**Choose timers on a systemd server** for the journal and the missed-run behaviour; *read crontabs*
because every inherited server has some.
