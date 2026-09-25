---
title: Layer 4: a port, and whether anybody is listening
version: 1
---

Layer 3 brings a packet to the machine. **Layer 4 brings it to a program**, and the program is named
by a **port**, a number from 1 to 65535. A server program *listens* on a port; `ss -tln` lists the
TCP ports that something is listening on:

```
ana@www:~$ ss -tln
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      128       192.0.2.80:22        0.0.0.0:*          
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*          
LISTEN 0      511          0.0.0.0:443       0.0.0.0:*          
ana@laptop:~$ nc -zv 192.0.2.80 443
Connection to 192.0.2.80 443 port [tcp/https] succeeded!
ana@laptop:~$ nc -zv 192.0.2.80 8080
nc: connect to 192.0.2.80 port 8080 (tcp) failed: Connection refused
```

The web server listens on three: 22 for SSH, 80 for HTTP and 443 for HTTPS. `0.0.0.0` means every
address the machine has; `192.0.2.80:22` means that one address only. These numbers are conventions,
listed in `/etc/services`, and nothing stops a program from listening elsewhere, which is why a web
address sometimes carries `:8080`.

From the laptop, `nc -zv` tries to open a connection and reports how it went. Port 443 answered.
**Port 8080 was *refused*: the machine is there, and it said no.** Nothing listens on 8080, so the
server's system answered the attempt with a refusal straight away. That is different from no answer
at all, a *timeout*, which usually means a firewall dropped the attempt somewhere on the way. Lesson 3
takes both apart.

A refusal is good news in one way. The link, the address and the route all worked, because the
refusal came back through them. The fault is at layer 4 or above, on that machine.
