---
title: ss: what is listening, and who is connected
version: 1
---

On the far end of every connection is a program listening on a port. `ss` lists them, and the
connections already made:

```
ana@www:~$ sudo ss -tlnp
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                                                     
LISTEN 0      32        192.0.2.80:21        0.0.0.0:*    users:(("vsftpd",pid=110849,fd=3))                         
LISTEN 0      128       192.0.2.80:22        0.0.0.0:*    users:(("sshd",pid=110831,fd=4))                           
LISTEN 0      511          0.0.0.0:443       0.0.0.0:*    users:(("nginx",pid=110812,fd=6),("nginx",pid=110811,fd=6))
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=110812,fd=5),("nginx",pid=110811,fd=5))
ana@laptop:~$ ss -tnp
State Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
ESTAB 0      0      192.168.10.20:48548   192.0.2.80:80   users:(("nc",pid=111540,fd=3))
ana@laptop:~$ netstat -tn
bash: line 1: netstat: command not found
```

On `www`, `-tlnp` means TCP, listening, numbers rather than names, and the process. nginx listens on
80 and 443 on every address, `0.0.0.0`; sshd and vsftpd listen only on `192.0.2.80`. On the laptop,
`-tnp` without `-l` shows established connections instead: one `ESTAB` from a local port to
`192.0.2.80:80`, owned by `nc`. Lesson 3 read the same table for the states of a connection.

**`netstat` is the older tool for the same job**, and on this Ubuntu it is not even installed: it
belongs to the `net-tools` package, which modern distributions leave out. It is still what Windows and
macOS have, and `netstat -tlnp` on a Linux that has it prints almost the same table. On Linux, `ss` is
the one to learn.
