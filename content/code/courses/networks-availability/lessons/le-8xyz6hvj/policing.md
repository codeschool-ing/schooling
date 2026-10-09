---
title: A policer at the provider
version: 1
---

The shaper is removed, `sudo tc qdisc del dev eth1 root` on `hq`, and the limit moves to where a
provider would put it: the ISP's
router, on traffic arriving from `hq`. It is an `nftables` rule with the same rate and the same bucket,
and a different ending, `drop`:

```
ana@isp:~$ sudo nft add table ip contract && sudo nft add chain ip contract police "{ type filter hook forward priority 0; }"
ana@isp:~$ sudo nft add rule ip contract police iifname eth0 ip saddr 203.0.113.2 limit rate over 625 kbytes/second burst 16 kbytes counter drop
```

`limit rate over 625 kbytes/second burst 16 kbytes` matches whatever exceeds the bucket, and `counter
drop` counts it and throws it away. What fits passes untouched. The same upload:

```
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 8
Connecting to host 192.0.2.21, port 5201
[  5] local 192.168.10.20 port 47016 connected to 192.0.2.21 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  2.50 MBytes  20.9 Mbits/sec  330   45.2 KBytes       
[  5]   1.00-2.00   sec   640 KBytes  5.24 Mbits/sec    1   63.6 KBytes       
[  5]   2.00-3.00   sec   640 KBytes  5.24 Mbits/sec  283   48.1 KBytes       
[  5]   3.00-4.00   sec   640 KBytes  5.24 Mbits/sec    5   5.66 KBytes       
[  5]   4.00-5.00   sec   640 KBytes  5.24 Mbits/sec  304   59.4 KBytes       
[  5]   5.00-6.00   sec   640 KBytes  5.24 Mbits/sec    0   36.8 KBytes       
[  5]   6.00-7.00   sec   640 KBytes  5.24 Mbits/sec  323    129 KBytes       
[  5]   7.00-8.00   sec   640 KBytes  5.24 Mbits/sec   91   31.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-8.00   sec  6.88 MBytes  7.21 Mbits/sec  1337             sender
[  5]   0.00-8.00   sec  5.12 MBytes  5.37 Mbits/sec                  receiver

iperf Done.
```

**The retransmission column never settles.** 330 in the first second, then 1, 283, 5, 304, 0, 323 and
91, **1337 in all** against the shaper's 248. The `Cwnd` column shows why: 45.2, 63.6, 48.1, **5.66**,
59.4, 36.8, **129**, 31.1 KBytes. TCP grows its window until the policer drops a run of packets, cuts it,
and grows it again; with nothing to absorb a burst, every climb ends in a loss. The receiver still got
**5.37 Mbits/sec**. The policer's rule and the shaper's are written in different tools and units and are
not exactly the same rate, so read the two receiver lines as neighbours, not as a contest.

The ping, in its second terminal as before:

```
ana@laptop:~$ sleep 2; ping -c 5 -q 192.0.2.21 | tail -n 2
5 packets transmitted, 5 received, 0% packet loss, time 4085ms
rtt min/avg/max/mdev = 0.054/0.070/0.081/0.009 ms
```

**0.070 ms.** With the upload running, a ping went through as if the link were idle, because a policer
has no queue: a packet either fits the bucket and goes at once, or does not and is gone. These five
pings were lucky enough to find tokens. A voice packet that arrived during one of the upload's bursts
would not have been delayed; it would have been dropped, and a lost voice packet is a gap in somebody's
sentence.

The policer's own count:

```
ana@isp:~$ sudo nft list chain ip contract police
table ip contract {
	chain police {
		type filter hook forward priority filter; policy accept;
		iifname "eth0" ip saddr 203.0.113.2 limit rate over 625 kbytes/second burst 16 kbytes counter packets 1335 bytes 2002500 drop
	}
}
```

**1335 packets, 2,002,500 bytes**, exactly 1500 bytes each, the largest packet the link carries. The
drops fell on the upload's full-size packets, and there are two fewer of them than the sender's 1337
retransmissions, which is as close as two counters in two different programs are going to agree.

So the same rate, held two ways, gave opposite symptoms: **the shaper cost 22 ms of delay and almost no
loss, the policer cost no delay and a steady stream of loss.** Which of those a link should have depends
on who owns it.
