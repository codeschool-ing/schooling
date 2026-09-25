---
title: Windows: Services and Task Scheduler
version: 1
---

Windows keeps the same two ideas under different names.

## Services

**`services.msc`** lists every service with its **Status** (running or stopped, systemd's *now*) and
its **Startup type**, systemd's *at boot*:

| startup type | means |
|---|---|
| **Automatic** | starts at boot, like `enabled` |
| **Automatic (Delayed Start)** | starts shortly after boot, so login is faster |
| **Manual** | starts when something asks for it |
| **Disabled** | never starts, like `disable` |

```sh
Get-Service | Where-Object Status -eq Running
Get-Service -Name Spooler | Select-Object Name, Status, StartType
Stop-Service -Name Spooler
Start-Service -Name Spooler
Set-Service -Name Spooler -StartupType Manual     # disable is -StartupType Disabled
sc.exe query Spooler                              # the older tool, same service
```

**None of the Windows commands were run for this lesson.** The Spooler is the print queue; restarting it
is the classic cure for a stuck print job, and lesson 17 meets it again.

## Scheduled tasks

**Task Scheduler**, `taskschd.msc`, is the timer. A task has **triggers** (a time, logon, startup, an
event), **actions** (a program to run), and **conditions** (only on mains power, only when idle). *Run
whether user is logged on or not* is the setting that makes a nightly job work at two when nobody is
there.

```sh
schtasks /Create /TN "Office backup" /TR "C:\Scripts\backup.cmd" /SC WEEKLY /D MON,TUE,WED,THU,FRI /ST 02:00
schtasks /Query /TN "Office backup"
Get-ScheduledTask | Where-Object State -eq Ready | Select-Object -First 5 TaskName
```

## Startup apps

What starts when a **person** signs in is separate from services: *Settings > Apps > Startup*, or the
*Startup apps* tab of Task Manager, which also estimates each one's **startup impact**. It is the first
place to look on a PC that is slow to become usable after login.
