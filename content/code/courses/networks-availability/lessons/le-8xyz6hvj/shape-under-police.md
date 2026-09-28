---
title: Shape your side, just under the contract
version: 1
---

A provider sells a rate and polices it at its edge, because a policer needs nothing but a counter and
the provider has no reason to store a customer's excess. The customer cannot change that. What the
customer can change is **what arrives at the policer: if nothing arrives faster than the contract, the
policer never has anything to drop.** So the customer shapes its own uplink a little below the rate it
bought.

The lab puts both in place at once. The policer at the ISP stays at 625 kbytes a second, its counter
reset off screen by deleting the rule and adding it again. `hq` gets a shaper at **4500 kbit**, ten per
cent under the contract, and the upload runs again:

```
ana@hq:~$ sudo tc qdisc add dev eth1 root tbf rate 4500kbit burst 16kb latency 50ms
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 8 | tail -n 4
[  5]   0.00-8.00   sec  5.50 MBytes  5.77 Mbits/sec  208             sender
[  5]   0.00-8.02   sec  4.12 MBytes  4.31 Mbits/sec                  receiver

iperf Done.
ana@isp:~$ sudo nft list chain ip contract police | grep counter
		iifname "eth0" ip saddr 203.0.113.2 limit rate over 625 kbytes/second burst 16 kbytes counter packets 0 bytes 0 drop
```

**`packets 0 bytes 0`: the policer dropped nothing** for the whole eight seconds. The 208 retransmissions
did not happen at the ISP. They happened before it, at `hq`'s own shaper, the only other thing on the
path holding this upload back, as its first second did in the shaping section. The receiver got **4.31
Mbits/sec**, and 4.5 × 1448 ÷ 1514 is 4.30, so the shaper delivered almost exactly what it was set to: less
than the 5.37 the policer allowed, and that is the price. For it, the customer has:

- every packet the upload lost was lost in its own router, in a queue it controls;
- a queue that is its own, where lesson 18's classes can put a call in front of the upload;
- a link that behaves the same whatever the provider's policer does, as long as it keeps its contract.

**Shaping below the contract moves the bottleneck into your router**, and the bottleneck is the only
place QoS can act. Why below, rather than at the rate itself? Because they are two machines measuring separately.
Each counts bytes its own way, a frame with its Ethernet header or a packet without. Each has its own
bucket and its own clock, and a shaper set exactly at the contract leaves no room for the differences. Ten per cent is a common margin and not a rule; the right figure is the one at
which the provider's counter stays at zero.

| | where it belongs | what it protects |
|---|---|---|
| policer | the provider's edge, on what comes in | the provider's network, from customers over their contract |
| shaper | your router, on what goes out | your traffic, from a queue somebody else controls |

The same reasoning runs the other way for downloads, with the roles swapped: the queue that fills is the
provider's, and lesson 18 ended on exactly that problem. Shaping what arrives, a little under the line's
speed, turns that queue into yours as well. It is done with the same tools on an interface's incoming
side, and it was not run here.
