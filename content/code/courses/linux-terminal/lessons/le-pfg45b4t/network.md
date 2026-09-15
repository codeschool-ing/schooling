---
title: The network, which is a device with a queue
version: 1
---

A network interface is a device with a queue, so the same three questions work:
how busy, how much is waiting, and how many errors.

## What is listening, and to whom

```
ana@vm:~$ ss -s
Total: 29
TCP:   18 (estab 13, closed 1, orphaned 0, timewait 1)

Transport Total     IP        IPv6
RAW       0         0         0
UDP       0         0         0
TCP       17        17        0
INET      17        17        0
FRAG      0         0         0
```

`ss -s` is the one-line summary: how many sockets, how many established, how
many in `TIME-WAIT`.

```
ana@vm:~$ ss -tulpn 2>/dev/null | head -8
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
tcp   LISTEN 0      512        127.0.0.1:42989      0.0.0.0:*
tcp   LISTEN 0      4096       127.0.0.1:45939      0.0.0.0:*
tcp   LISTEN 0      128          0.0.0.0:2024       0.0.0.0:*
tcp   LISTEN 0      128          0.0.0.0:2025       0.0.0.0:*
```

**`ss -tulpn` is the one to memorise**, and the letters spell out what it does:

| | |
|---|---|
| `-t` `-u` | TCP and UDP |
| `-l` | listening sockets only |
| `-p` | which process — needs privilege to see other users' |
| `-n` | numeric. **Do not resolve names**, which is what makes it instant |

`0.0.0.0:2025` is reachable from the network; `127.0.0.1:45939` is not. That
distinction is a security question as much as a performance one, and `ss -tulpn`
is how you answer "is this service actually exposed".

`ss` replaced `netstat`, which is in the `net-tools` package that most
distributions no longer install. The translations are direct: `netstat -tulpn`
is `ss -tulpn`, `netstat -s` is `ss -s`, `netstat -rn` is `ip route`.

## The two queues

The `Recv-Q` and `Send-Q` columns mean different things depending on the state,
which is the confusing part.

**On a `LISTEN` socket:**

| | |
|---|---|
| `Recv-Q` | connections **accepted by the kernel and not yet picked up** by the program |
| `Send-Q` | the backlog size — the maximum the first column can reach |

`Recv-Q` above zero on a listener means the application is not calling
`accept()` fast enough. `Recv-Q` equal to `Send-Q` means it is full, and new
connections are being dropped. **That is the single most useful number in this
section**: it says "the server is overloaded" with no ambiguity at all.

**On an established socket**, they are bytes: data received and not yet read by
the application, and data written by the application and not yet acknowledged by
the far end. A large `Send-Q` that is not draining is a slow or absent peer.

## Errors and drops

```
ana@vm:~$ ip -s link show eth0
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 02:fc:00:00:00:01 brd ff:ff:ff:ff:ff:ff
    RX:  bytes packets errors dropped  missed   mcast
     365057734  262464      0       6       0       0
    TX:  bytes packets errors dropped carrier collsns
     426949616  260028      0       0       0       0
```

**Six received packets dropped out of 262,464.** That is the `E` of the USE
method from section 177, and it is the number nobody looks at.

| | |
|---|---|
| `errors` | malformed frames, checksum failures. A cable or a card |
| `dropped` | the packet was fine and there was nowhere to put it. A **buffer** |
| `missed` | the card had no descriptor free. The driver could not keep up |

Six drops in a quarter of a million is noise. The same ratio at a million
packets a second is thousands per second, and it appears as occasional,
unreproducible slowness in an application that has no idea anything is wrong.

`cat /proc/net/dev` is the same counters, unformatted, and is what you parse in
a script.

## Per-connection detail

`ss -ti` adds the kernel's own view of every established connection — the
congestion window, the smoothed round-trip time, retransmits, the pacing rate.
It is one very wide line per socket, too wide to put in a page like this one,
and it is worth running once on a real connection to see what is there.

The two fields to look for in it are **`rtt`** — how far away the other end
actually is — and **`retrans`**, which counts retransmissions. Retransmits on a
local network mean something is broken; on the internet they are ordinary.

## Counters, not rates

Every number in this section except `ss -s` is a **counter since boot**. A large
number is not a problem and a growing one might be.

```sh
ip -s link show eth0 ; sleep 10 ; ip -s link show eth0     # subtract
sar -n DEV 1                                                # or let sysstat do it
sar -n EDEV 1                                               # the error counters, as rates
```

**`sar -n DEV 1` is the right tool**, because it does the subtraction for you:

```
ana@vm:~$ sar -n DEV 1 1 2>&1 | grep -E 'IFACE|eth0'
11:39:28        IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
11:39:29         eth0      2.00      3.00      0.13      0.19      0.00      0.00      0.00      0.00
```

Two packets a second in, three out, and an interface utilisation of zero. Those
are numbers you can act on; `RX packets 262464` is not. That is the whole subject
of the next section, and the network counters are where it bites hardest —
nobody has ever looked at a total since boot and known whether it was a lot.

And `netstat` really is gone on a current machine:

```
ana@vm:~$ which netstat || echo 'netstat: not installed'
netstat: not installed
```
