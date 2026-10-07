---
title: A shaper on hq's uplink
version: 1
---

First, how fast the network's uplink is with nothing in the way. An `iperf3` upload from the laptop to `web1`:

```
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 3 | tail -n 4
[  5]   0.00-3.00   sec  1.02 GBytes  2.91 Gbits/sec  513             sender
[  5]   0.00-3.00   sec  1.02 GBytes  2.91 Gbits/sec                  receiver

iperf Done.
```

**2.91 Gbits/sec**, which is one computer copying memory between its own network namespaces, not a link
anybody would buy; the 513 retransmissions are TCP finding even that limit by going past it. Now `hq`
gets a shaper on `eth1`, `tc`'s token bucket filter, `tbf`, with the rate and bucket of the last section,
and the same upload runs for eight seconds:

```
ana@hq:~$ sudo tc qdisc add dev eth1 root tbf rate 5mbit burst 16kb latency 50ms
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 8
Connecting to host 192.0.2.21, port 5201
[  5] local 192.168.10.20 port 51978 connected to 192.0.2.21 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  1.75 MBytes  14.7 Mbits/sec  248   14.1 KBytes       
[  5]   1.00-2.00   sec   640 KBytes  5.24 Mbits/sec    0   14.1 KBytes       
[  5]   2.00-3.00   sec   640 KBytes  5.24 Mbits/sec    0   14.1 KBytes       
[  5]   3.00-4.00   sec   640 KBytes  5.25 Mbits/sec    0   17.0 KBytes       
[  5]   4.00-5.00   sec   640 KBytes  5.24 Mbits/sec    0   14.1 KBytes       
[  5]   5.00-6.00   sec   640 KBytes  5.24 Mbits/sec    0   17.0 KBytes       
[  5]   6.00-7.00   sec   640 KBytes  5.24 Mbits/sec    0   14.1 KBytes       
[  5]   7.00-8.00   sec   640 KBytes  5.24 Mbits/sec    0   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-8.00   sec  6.12 MBytes  6.42 Mbits/sec  248             sender
[  5]   0.00-8.02   sec  4.50 MBytes  4.70 Mbits/sec                  receiver

iperf Done.
```

Read the columns one second at a time. **In the first second TCP sent too much and lost 248 packets**:
it starts fast, the shaper's queue filled past its limit, and the excess was dropped. From then on the
retransmission column reads **0 for seven seconds**. The connection settled to the rate, and nothing had
to be thrown away, because the shaper held each packet until its tokens arrived.

Two lines at the bottom disagree, and the receiver is the one to believe. The sender counts what the
program wrote into its socket, including the first second's 1.75 MBytes that were still queued, so its
**6.42 Mbits/sec** is not a speed anything travelled at. The receiver counts what arrived: **4.70
Mbits/sec**. That is below 5 for an honest reason. The shaper counts whole Ethernet frames, 1514 bytes,
and each carries 1448 bytes of the file after the IP and TCP headers and their options, so the most
the file can reach is 5 × 1448 ÷ 1514, about **4.78 Mbit/s**. The per-second column, for its part, is
counted at the sender in the blocks `iperf3` writes, which is why it reads a flat `640 KBytes`.

## What the queue costs

A shaper removes loss by adding waiting, and the waiting can be measured. This ping ran in a second
terminal, started together with the upload and two seconds into it, as its own `sleep 2` says:

```
ana@laptop:~$ sleep 2; ping -c 5 -q 192.0.2.21 | tail -n 2
5 packets transmitted, 5 received, 0% packet loss, time 4007ms
rtt min/avg/max/mdev = 20.932/21.989/22.950/0.805 ms
```

**22 ms on average**, against 0.08 ms on an idle link in lesson 18. That is the queue, and the upload's
own columns account for it. The `Cwnd` column says TCP kept about **14.1 KBytes** in flight, and in
steady state that is roughly what sits in the shaper's queue: 14.1 × 1024 × 8 = 115,507 bits, which at
5,000,000 bits a second take **23 ms** to leave. The ping waited behind the upload's window.

The shaper keeps its own score:

```
ana@hq:~$ tc -s qdisc show dev eth1
qdisc tbf 8012: root refcnt 5 rate 5Mbit burst 16Kb lat 50ms 
 Sent 5048683 bytes 3356 pkt (dropped 248, overlimits 10246 requeues 0) 
 backlog 0b 0p requeues 0
```

`dropped 248`, the first second's losses, and the same number as the retransmissions. `overlimits 10246`
counts the times a packet was ready and the bucket was not, which is the shaper doing its job, not a
fault. `backlog 0b 0p` is the queue after the upload ended: empty.
