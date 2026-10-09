---
title: A tour of the lab
version: 2
---

This is what `netlab.sh up` built, seen from `ctl`, the machine you work on. Every machine has a
name in `example.net`, and every `/etc/hosts` in the lab lists them:

```
ana@ctl:~$ grep example.net /etc/hosts
192.0.2.10 ctl.example.net ctl
192.0.2.11 core1.example.net core1
192.0.2.12 edge1.example.net edge1
192.0.2.13 edge2.example.net edge2
192.0.2.21 nc1.example.net nc1
192.0.2.30 netbox.example.net netbox
192.0.2.40 tickets.example.net tickets
192.0.2.50 sw1.example.net sw1
```

| machine | what it is |
|---|---|
| `ctl` | the automation host, where you work: Python, the libraries, Ansible and Git |
| `core1`, `edge1`, `edge2` | routers: FRR for routing and the CLI, SSH to that CLI, a REST API and a gNMI port |
| `nc1` | a device managed only through its data model, over NETCONF and RESTCONF |
| `netbox` | NetBox, the source of truth of lesson 12 |
| `tickets` | the service desk that lesson 7's webhooks open tickets in |
| `pc1`, `pc2` | one computer on each branch's LAN, to test the network from |
| `sw1`, `h1` to `h3` | an OpenFlow switch and three computers plugged into it, for lesson 15 |

`ctl` has one interface, on the management network:

```
ana@ctl:~$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 
eth0@if494       UP             192.0.2.10/24 
ana@ctl:~$ python --version
Python 3.12.3
ana@ctl:~$ pip list 2>/dev/null | grep -iE "^(netmiko|napalm|nornir|ncclient|pygnmi|jinja2|pynetbox) "
Jinja2             3.1.6
napalm             5.2.0
ncclient           0.7.0
netmiko            4.8.0
nornir             3.6.0
pygnmi             0.8.15
pynetbox           7.8.0
```

**The routers run FRRouting**, the open-source routing suite that also runs inside several
commercial products. Its CLI is modelled on Cisco's, and it really routes: OSPF runs between the
three, and `edge1` has learnt the other branch through `core1`:

```
ana@ctl:~$ ssh netops@edge1 "show version" | head -1
FRRouting 8.4.4 (edge1) on Linux(6.18.44-fc-v77).
ana@ctl:~$ ssh netops@edge1 "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
203.0.113.251     1 Full/-          36.144s           33.854s 198.51.100.1    eth1:198.51.100.2                    0     0     0

ana@ctl:~$ ssh netops@edge1 "show ip route ospf"
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   192.0.2.0/24 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:25
O   198.51.100.0/30 [110/10] is directly connected, eth1, weight 1, 00:00:46
O>* 198.51.100.4/30 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:26
O   203.0.113.0/26 [110/10] is directly connected, eth2, weight 1, 00:00:46
O>* 203.0.113.64/26 [110/30] via 198.51.100.1, eth1, weight 1, 00:00:26
O>* 203.0.113.251/32 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:25
O>* 203.0.113.253/32 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:25
```

**What is real and what was written for the course.** The network operating systems people
automate at work are licensed, so no vendor image runs here. Everything the lessons import or talk
to is real open-source software: FRR, OpenSSH, Clixon for `nc1`, NetBox, Ansible and every Python
library shown above. There are three exceptions, written for this course and printed whole in the
lesson that starts each one. The routers' REST API and gNMI port are a program that answers from FRR and
the kernel, because FRR has neither: `devapid.py`, in lesson 2. The NAPALM driver for FRR is
another, because NAPALM ships none: `napalm_frr.py`, in lesson 8. The service desk is the third,
because the ticketing systems people use are too large to install for one lesson: `deskd.py`, in
lesson 7. Each is modelled on the pattern real products follow, and the lessons teach the pattern.
`nc1` also needs a short plugin that checks a RESTCONF password, because Clixon leaves that to the
product built on it. Lesson 3 prints it too.

The addresses are the ranges reserved for documentation, `192.0.2.0/24`, `198.51.100.0/24` and
`203.0.113.0/24`, and the names end in `example.net`. **Nothing in the lab reaches the internet.**

**When something does not answer**, check it in the order the packets travel: can `ctl` reach
the address at all, is the port open, and is the login accepted by hand?

```
ana@ctl:~$ ping -c 1 edge1
PING edge1.example.net (192.0.2.12) 56(84) bytes of data.
64 bytes from edge1.example.net (192.0.2.12): icmp_seq=1 ttl=64 time=0.349 ms

--- edge1.example.net ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.349/0.349/0.349/0.000 ms
ana@ctl:~$ nc -vz edge1 22
Connection to edge1 (192.0.2.12) 22 port [tcp/ssh] succeeded!
```

`ping` answered, and `nc -vz` connected to port 22 without sending anything. The third question is
an interactive `ssh netops@edge1`, which the next section opens. **A script that fails in any of those
three places fails for a reason that is not in the script**, and no change to the script fixes it.
