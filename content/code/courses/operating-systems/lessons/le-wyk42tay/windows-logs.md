---
title: Windows: Event Viewer and the repair tools
version: 1
---

Windows keeps its record in **Event Viewer**, `eventvwr.msc`. The logs that matter first are under
*Windows Logs*:

| log | what goes there |
|---|---|
| **System** | Windows itself: drivers, services, shutdowns |
| **Application** | programs: crashes, errors they report |
| **Security** | sign-ins and audited actions, lesson 10's record |

Each event has a **level** (*Critical*, *Error*, *Warning*, *Information*), a **source**, and an **Event
ID**, a number that means the same thing on every Windows PC and is what to search for. Two worth
knowing: **41** from *Kernel-Power* means the PC restarted without shutting down cleanly, the reception
PC's symptom; **7000** from the *Service Control Manager* means a service failed to start.

```sh
Get-WinEvent -LogName System -MaxEvents 5
Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddDays(-1)}
Get-WinEvent -FilterHashtable @{LogName='System'; Id=41} -MaxEvents 3   # unexpected shutdowns
perfmon /rel                                                             # Reliability Monitor
```

**None of the Windows commands were run for this lesson.** **Reliability Monitor**, the last line, draws
the same events as a timeline with a stability score per day, and is the fastest answer to *since when,
and what changed?*: the day the line drops usually has an update or a new program installed on it.

## When Windows' own files are damaged

```sh
sfc /scannow                                     # check Windows' own files, replace damaged ones
DISM /Online /Cleanup-Image /RestoreHealth       # repair the store sfc copies from
chkdsk C: /scan                                  # check the file system while running
```

`sfc` compares Windows' system files with known-good copies and replaces the damaged ones; `DISM`
repairs the store those copies come from, so it runs first when `sfc` cannot fix everything. `chkdsk`
checks the file system itself. All three need an elevated Terminal, lesson 10's *Run as administrator*.
