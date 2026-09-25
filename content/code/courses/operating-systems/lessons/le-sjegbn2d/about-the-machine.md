---
title: Which machine is this?
version: 1
---

The first questions in any ticket: which machine, how big, how long has it been up.

```
ana@server:~$ hostname
server
ana@server:~$ nproc
4
ana@server:~$ uptime -p
up 1 hour, 42 minutes
PS /home/ana> [Environment]::MachineName
server
PS /home/ana> [Environment]::ProcessorCount
4
```

`hostname` is the same word on all three systems. `nproc` counts processors; **`uptime`** says how long
since the last start, and a PC that "is slow" with an uptime of forty days has an answer before any
other command. PowerShell asked .NET for the same two facts, **`[Environment]::MachineName`** and
**`ProcessorCount`**, which is why those lines work unchanged on Windows.

On Windows, PowerShell:

```sh
hostname
$env:COMPUTERNAME
systeminfo | Select-String "OS Name", "Total Physical Memory"
(Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
(Get-CimInstance Win32_OperatingSystem).LastBootUpTime
```

**None of the Windows commands in this lesson were run for it.** `systeminfo` prints a long page of
text, and `Select-String` picks lines out of it, the same job as `grep` in section 04. The last line
answers the uptime question on Windows: the date and time of the last boot.

On a Mac most of the Linux commands work as they are. The exceptions are few, and worth having in one
place:

```sh
sysctl -n hw.ncpu                 # nproc does not exist on macOS
top -o cpu                        # sort by CPU; Linux top uses other keys
ifconfig                          # macOS still uses it; Linux uses ip
sw_vers                           # the version, lesson 4
```
