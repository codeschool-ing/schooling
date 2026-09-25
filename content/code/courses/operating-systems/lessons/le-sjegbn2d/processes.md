---
title: Finding a process and stopping it
version: 1
---

A `sleep` was left running in the background for this section, to have something to find.

```
ana@server:~$ ps -eo pid,user,comm --sort=pid | head -6
    PID USER     COMMAND
      1 root     systemd
     17 root     systemd-journal
     41 systemd+ systemd-resolve
     48 root     cron
     49 message+ dbus-daemon
ana@server:~$ pgrep -a sleep
5401 sleep 600
PS /home/ana> Get-Process -Name sleep | Select-Object Id, ProcessName

  Id ProcessName
  -- -----------
5401 sleep

PS /home/ana> Get-Process | Measure-Object | Select-Object Count

Count
-----
   12
```

- `ps` lists processes; `-eo` chooses the columns. The first lines are lesson 1's first process,
  `systemd`, and the services it started.
- `pgrep -a` finds processes by name and prints their ID and command line.
- `Get-Process -Name` found the same process, with the same ID, from PowerShell, and **counted 12**
  on the whole machine. A desktop runs hundreds; this is a minimal server.

Stopping it takes the ID:

```
ana@server:~$ kill 5401
ana@server:~$ pgrep -a sleep || echo "no sleep left"
no sleep left
```

`kill` sends a request to stop, and a well-behaved program tidies up and exits. `kill -9` is the one
that cannot be refused, lesson 1's signals, and is for a process that ignored the polite one.

In the Command Prompt:

```sh
tasklist /FI "IMAGENAME eq notepad.exe"
taskkill /PID 4312
taskkill /IM notepad.exe /F
```

`tasklist` is the list and `taskkill` the stop, by ID or by name; `/F` forces it, like `-9`. In
PowerShell on Windows, `Get-Process` and **`Stop-Process -Id`** work exactly as here.
