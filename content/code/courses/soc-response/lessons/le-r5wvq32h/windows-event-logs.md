---
title: Windows: channels and events
version: 1
---

Windows has no `/var/log`. It has **channels**, each a binary `.evtx` file under
`C:\Windows\System32\winevt\Logs`, and every entry in them is an **event** with a number that says what
kind of thing happened. Nothing in this section was run on the course's lab, which is Linux; the
commands are the ones to type on a Windows machine of your own, in PowerShell opened as administrator.

Three channels have existed since the beginning, and a fourth group grew around them:

| channel | what writes to it |
|---|---|
| **Security** | the operating system's audit: logons, privilege use, accounts and groups changed, the log itself cleared. Only what the **audit policy** asks for |
| **System** | Windows components and drivers: services installed, started, stopped, the clock changed |
| **Application** | programs: a database, an antivirus, an installer |
| **Applications and Services Logs** | one channel per component, such as `Microsoft-Windows-PowerShell/Operational` or, if installed, `Microsoft-Windows-Sysmon/Operational` |

**The Security channel records only what the audit policy enables**, and a fresh installation does not
enable process creation, for instance. Checking that policy is the first thing to do on a Windows
estate, because an event that was never audited cannot be found later:

```
auditpol /get /category:*
Get-WinEvent -LogName Security -MaxEvents 5
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=(Get-Date).AddDays(-1)}
wevtutil qe Security /c:5 /rd:true /f:text
```

Every event carries the same frame: the **channel**, the **provider** (the component that wrote it), the
**event id**, a **level** (information, warning, error, critical), the **time** in UTC, the **computer**,
and then an `EventData` section whose fields depend on the id. Event Viewer shows that frame as a form;
`Get-WinEvent` returns it as objects, and `.ToXml()` shows the raw fields.

Two details catch people. The Security channel has a **maximum size** and, by default, overwrites the
oldest events when full. On a busy domain controller that can be hours, which is why Windows logs are
forwarded off the machine (Windows Event Forwarding, or an agent) rather than read in place. And the event
**time is stored in UTC** and displayed in the viewer's local zone, so two analysts in two cities reading
the same event see two different clocks.
