---
title: Pulling the cable, and measuring the gap
version: 1
---

A failover is only as good as the gap it leaves, and a gap can be measured. The laptop pings `web1` in
the data centre, beyond the gateway, five times a second: `-i 0.2`. `-D` puts a timestamp in front of each line, in seconds since 1970. `-O` prints a line for every reply that has not come back by the time the
next ping goes out, so a missing reply shows up as a line rather than as nothing. A little over two seconds in, `hq`'s
cable to the LAN was pulled. The cable is the pair `netlab.sh` named `hq-hq`, `hq`'s port on the
head-office switch, and pulling it is setting that end down, on the virtual machine:
`sudo ip -n wire link set hq-hq down`. Start the ping on `laptop`, then pull the cable:

```
ana@laptop:~$ ping -D -O -i 0.2 -c 40 -W 1 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 56(84) bytes of data.
[1790629864.207277] 64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.493 ms
[1790629864.408908] 64 bytes from 192.0.2.21: icmp_seq=2 ttl=62 time=0.115 ms
[1790629864.612831] 64 bytes from 192.0.2.21: icmp_seq=3 ttl=62 time=0.084 ms
[1790629864.816783] 64 bytes from 192.0.2.21: icmp_seq=4 ttl=62 time=0.086 ms
[1790629865.020829] 64 bytes from 192.0.2.21: icmp_seq=5 ttl=62 time=0.103 ms
[1790629865.224819] 64 bytes from 192.0.2.21: icmp_seq=6 ttl=62 time=0.089 ms
[1790629865.428812] 64 bytes from 192.0.2.21: icmp_seq=7 ttl=62 time=0.082 ms
[1790629865.632824] 64 bytes from 192.0.2.21: icmp_seq=8 ttl=62 time=0.088 ms
[1790629865.836849] 64 bytes from 192.0.2.21: icmp_seq=9 ttl=62 time=0.097 ms
[1790629866.040810] 64 bytes from 192.0.2.21: icmp_seq=10 ttl=62 time=0.081 ms
[1790629866.244818] 64 bytes from 192.0.2.21: icmp_seq=11 ttl=62 time=0.086 ms
[1790629866.448808] 64 bytes from 192.0.2.21: icmp_seq=12 ttl=62 time=0.085 ms
[1790629866.652789] 64 bytes from 192.0.2.21: icmp_seq=13 ttl=62 time=0.084 ms
[1790629867.060772] no answer yet for icmp_seq=14
[1790629867.264684] no answer yet for icmp_seq=15
[1790629867.468663] no answer yet for icmp_seq=16
[1790629867.672731] no answer yet for icmp_seq=17
[1790629867.876713] no answer yet for icmp_seq=18
[1790629868.080739] no answer yet for icmp_seq=19
[1790629868.284710] no answer yet for icmp_seq=20
[1790629868.488851] no answer yet for icmp_seq=21
[1790629868.692784] no answer yet for icmp_seq=22
[1790629868.896701] no answer yet for icmp_seq=23
[1790629869.100749] no answer yet for icmp_seq=24
[1790629869.304671] no answer yet for icmp_seq=25
[1790629869.508741] no answer yet for icmp_seq=26
[1790629869.712834] no answer yet for icmp_seq=27
[1790629869.916772] no answer yet for icmp_seq=28
[1790629869.916964] 64 bytes from 192.0.2.21: icmp_seq=29 ttl=62 time=0.156 ms
[1790629870.120873] 64 bytes from 192.0.2.21: icmp_seq=30 ttl=62 time=0.078 ms
[1790629870.324802] 64 bytes from 192.0.2.21: icmp_seq=31 ttl=62 time=0.090 ms
[1790629870.528765] 64 bytes from 192.0.2.21: icmp_seq=32 ttl=62 time=0.079 ms
[1790629870.732824] 64 bytes from 192.0.2.21: icmp_seq=33 ttl=62 time=0.092 ms
[1790629870.936905] 64 bytes from 192.0.2.21: icmp_seq=34 ttl=62 time=0.121 ms
[1790629871.140871] 64 bytes from 192.0.2.21: icmp_seq=35 ttl=62 time=0.081 ms
[1790629871.344805] 64 bytes from 192.0.2.21: icmp_seq=36 ttl=62 time=0.087 ms
[1790629871.548916] 64 bytes from 192.0.2.21: icmp_seq=37 ttl=62 time=0.155 ms
[1790629871.752815] 64 bytes from 192.0.2.21: icmp_seq=38 ttl=62 time=0.091 ms
[1790629871.956922] 64 bytes from 192.0.2.21: icmp_seq=39 ttl=62 time=0.108 ms
[1790629872.160908] 64 bytes from 192.0.2.21: icmp_seq=40 ttl=62 time=0.109 ms

--- 192.0.2.21 ping statistics ---
40 packets transmitted, 25 received, 37.5% packet loss, time 7954ms
rtt min/avg/max/mdev = 0.078/0.112/0.493/0.080 ms
```

Twelve replies arrive about 0.2 seconds apart, and the thirteenth at `1790629866.652789`. Then fifteen
pings in a row, 14 to 28, get no answer. Reply 29 arrives at `1790629869.916964`. **The gap from the last
reply before the failure to the first one after it is 3.264 seconds**, and ping's own summary agrees
from the other side: 40 sent, 25 received, 37.5% lost, which is those fifteen.

The two timestamps are 18:11:06.65 and 18:11:09.92 on the network's clock, São Paulo time, and the two
routers' logs put their own lines inside that window:

```
ana@hq2:~$ grep -E "Entering" /run/keepalived.log
Mon Sep 28 18:10:54 2026: (office) Entering BACKUP STATE (init)
Mon Sep 28 18:10:58 2026: (office) Entering MASTER STATE
Mon Sep 28 18:10:59 2026: (office) Entering BACKUP STATE
Mon Sep 28 18:11:09 2026: (office) Entering MASTER STATE
ana@laptop:~$ ip neigh show 192.168.10.1
192.168.10.1 dev eth0 lladdr 52:54:00:a8:0a:03 DELAY 
```

`hq2` became master at 18:11:09, the same second reply 29 came back. `hq`'s log, shown in the next
section, says it went into `FAULT` at 18:11:06, the second its cable came out: a router whose LAN
interface is down cannot serve that LAN, so keepalived gives the address up at once.

## Why 3.26 and not 3.61

The previous section worked out `hq2`'s master down interval as about 3.61 seconds, and the measured gap
is shorter. **The backup counts from the last advertisement it heard, not from the failure.** `hq`
advertised once a second, so its last advertisement left somewhere between zero and one second before the
cable was pulled, and `hq2`'s 3.61 seconds had already been running for that long. The gap a host sees is
therefore between about 2.61 and 3.61 seconds, plus the moment it takes the laptop to learn where the
address went, and 3.264 falls inside it. The same timers give a different gap every time the test is run.

No link in the lab has any delay. Every round trip in the ping is one computer talking to itself, 0.078
to 0.493 milliseconds, so none of the 3.264 seconds is the network. **It is all waiting**: the time VRRP
takes to be sure that a silence means a death.

## The laptop's side

The last command shows what changed for the laptop: its ARP entry for `192.168.10.1` now holds
`52:54:00:a8:0a:03`, `hq2`'s hardware address, where before the failure it held `hq`'s `:02`. The laptop did
nothing to cause that. It was still sending to the same gateway address, and something told it that
address now lived at a different MAC. **In keepalived's default mode the new master announces itself with
gratuitous ARP**, and the next section captures that announcement when `hq` comes back.

Fifteen lost pings is also a warning about what a failover looks like from above. A TCP connection would
have retransmitted into the gap and carried on, slower for a moment. A voice call would have lost three
seconds of speech. **A three-second gap is invisible to a web page and very audible on a phone call**,
which is why sub-second timers exist, and why lesson 14 asked what they cost.
