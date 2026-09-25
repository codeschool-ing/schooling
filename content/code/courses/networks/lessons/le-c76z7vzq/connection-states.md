---
title: What ss says about a connection
version: 1
---

A connection has a **state** on each end, and `ss` shows it. Here the laptop holds an SSH connection
to the web server open, and each side is asked:

```
ana@laptop:~$ ss -tn
State Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
ESTAB 0      0      192.168.10.20:43624   192.0.2.80:22         
ana@www:~$ ss -tn
State Recv-Q Send-Q Local Address:Port Peer Address:Port Process
ESTAB 0      0         192.0.2.80:22    203.0.113.2:43624       
ana@laptop:~$ ss -tan state time-wait
Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
0      0      192.168.10.20:60918   192.0.2.80:80         
0      0      192.168.10.20:43624   192.0.2.80:22         
```

`ESTAB`, established, on both, and the two lines describe the same connection from each end. The
laptop sees itself as `192.168.10.20:43624`. **The server sees `203.0.113.2:43624`: the office's
public address, lesson 2's NAT**, with the same port, because the router had no reason to change it.

When the connection was closed, it did not disappear from the laptop. `TIME-WAIT` is the state the
side that closed first stays in, for 60 seconds on Linux, so a late packet from the old connection
cannot be mistaken for part of a new one on the same ports. The earlier web connection is there
too, for the same reason. A server showing thousands of `TIME-WAIT` lines is a busy server, not a
broken one.

The states worth recognising:

| state | means |
|---|---|
| `LISTEN` | a server waiting for connections |
| `SYN-SENT` | a client that sent SYN and has heard nothing yet |
| `ESTAB` | open, data can flow |
| `TIME-WAIT` | closed here, waiting out stray packets |
| `CLOSE-WAIT` | the other side closed, and this program has not |

`SYN-SENT` that lasts is a connection that nobody answers: section 07. `CLOSE-WAIT` that piles up is a
program that forgets to close its connections, a bug in the program rather than the network.
