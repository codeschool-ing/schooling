---
title: Connections on Windows and macOS
version: 1
---

Every system can list its connections and listeners, and the states are the same words:

```sh
netstat -ano                                   # Windows: every connection and listener, with the process id
Get-NetTCPConnection -State Listen             # Windows PowerShell: TCP listeners
Get-NetUDPEndpoint                             # Windows PowerShell: UDP sockets
Test-NetConnection 192.0.2.80 -Port 3306       # Windows PowerShell: TcpTestSucceeded True or False
lsof -nP -iTCP -sTCP:LISTEN                    # macOS: TCP listeners and their programs
netstat -an -p tcp                             # macOS: every TCP connection and its state
```

**None of these were run for this lesson.** `netstat -ano` is the one to remember on Windows: `-a`
for all, `-n` for numbers rather than names, `-o` for the process id, which Task Manager's *Details*
tab turns into a program name. Its states are spelled out: `LISTENING`, `ESTABLISHED`, `TIME_WAIT`.

`Test-NetConnection` with `-Port` answers the refused-or-dropped question of section 07 the slow way:
`TcpTestSucceeded : False` both times, but a dropped port takes much longer to say so. On a Mac,
`lsof -nP -iTCP -sTCP:LISTEN` is the closest thing to `ss -tlpn`: every listening TCP socket and the
program that holds it.
