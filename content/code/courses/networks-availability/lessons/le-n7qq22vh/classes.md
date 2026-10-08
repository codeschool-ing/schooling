---
title: Classes, queues and a scheduler
version: 1
---

A router that honours a mark needs three things, and on Linux each is a separate line of `tc`. **A
classifier decides which class a packet belongs to, each class gets a queue of its own, and a scheduler
decides which queue sends next.** The one-queue setup is removed first, with `sudo tc qdisc del dev eth1 root`
on `hq`, and this one is built in its place:

```
ana@hq:~$ sudo tc qdisc add dev eth1 root handle 1: htb default 20 && sudo tc class add dev eth1 parent 1: classid 1:1 htb rate 5mbit
ana@hq:~$ sudo tc class add dev eth1 parent 1:1 classid 1:10 htb rate 1mbit ceil 5mbit prio 0 && sudo tc class add dev eth1 parent 1:1 classid 1:20 htb rate 4mbit ceil 5mbit prio 1
ana@hq:~$ sudo tc qdisc add dev eth1 parent 1:10 pfifo limit 100 && sudo tc qdisc add dev eth1 parent 1:20 pfifo limit 100
ana@hq:~$ sudo tc filter add dev eth1 parent 1: protocol ip prio 1 u32 match ip dsfield 0xb8 0xfc flowid 1:10
```

Four commands, read in the order a packet meets them:

| piece | what it says |
|---|---|
| `u32 match ip dsfield 0xb8 0xfc flowid 1:10` | a packet whose DSCP is EF goes to class `1:10`; the mask `0xfc` compares the six DSCP bits and ignores the two ECN bits |
| `htb default 20` | a packet no filter claims goes to `1:20` |
| `pfifo limit 100`, twice | each class has its own queue of 100 packets |
| `1:1 htb rate 5mbit` | the whole link, 5 Mbit/s, shared by the two classes below it |
| `1:10 ... rate 1mbit ceil 5mbit prio 0` | voice: 1 Mbit/s guaranteed, may borrow up to the whole link, offered first |
| `1:20 ... rate 4mbit ceil 5mbit prio 1` | everything else: 4 Mbit/s guaranteed, may borrow what voice leaves |

HTB, hierarchical token bucket, is the scheduler. Every class is first given its `rate`; whatever is
left over is lent to classes that want more, up to their `ceil`, and **the class with the lower `prio`
number is offered it first and sent from first**. So a packet in `1:10` never waits in the queue of
`1:20`. It waits only behind other voice packets, and there are very few of those.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 850 244\" role=\"img\" aria-label=\"The HTB built on hq&#x27;s eth1. Packets from the office meet a classifier, a u32 filter on the DSCP field. EF goes to class 1:10, voice, rate 1mbit ceil 5mbit prio 0; the rest goes to class 1:20, everything else, rate 4mbit ceil 5mbit prio 1. Each class has its own queue, pfifo limit 100: the voice queue holds one packet, the other is full. Both feed class 1:1, the link at rate 5mbit, which sends from 1:10 first.\"><defs><marker id=\"t18-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">packets from the office</text><path d=\"M80 30 L80 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><rect x=\"20\" y=\"100\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">classifier</text><text x=\"85.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">u32 dsfield</text><path d=\"M150 116 C 180 116, 180 68, 206 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><path d=\"M150 140 C 180 140, 180 192, 206 192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><text x=\"170\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">EF</text><text x=\"166\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the rest</text><rect x=\"208\" y=\"40\" width=\"240\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"328.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">voice: 1:10</text><text x=\"328.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">rate 1mbit ceil 5mbit prio 0</text><rect x=\"208\" y=\"164\" width=\"240\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"328.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">everything else: 1:20</text><text x=\"328.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">rate 4mbit ceil 5mbit prio 1</text><path d=\"M448 68 L470 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><rect x=\"472\" y=\"48\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"617\" y=\"54\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M448 192 L470 192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><rect x=\"472\" y=\"172\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"617\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"600\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"583\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"566\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"549\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"532\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"515\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"498\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"481\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"557\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pfifo limit 100</text><text x=\"557\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pfifo limit 100</text><path d=\"M642 68 C 668 68, 668 118, 690 124\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><path d=\"M642 192 C 668 192, 668 144, 690 138\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><rect x=\"692\" y=\"104\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"762.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the link: 1:1</text><text x=\"762.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">rate 5mbit</text><text x=\"762\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sends from 1:10 first</text></svg>", "caption": "Classify, queue, schedule: the three steps of this section as tc built them. The upload fills its own queue and no longer stands in front of the voice packets."}
```

## The same two pings, again

The same upload runs, the same `iperf3` in a second shell, and the same two pings follow it, one
unmarked and one marked EF:

```
ana@laptop:~$ ping -c 5 -q 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 21.792/62.909/221.092/79.098 ms
ana@laptop:~$ ping -c 5 -q -Q 0xb8 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 0.053/0.065/0.092/0.014 ms
```

The unmarked ping is where it was, up to **221 ms**, because it shares class `1:20` with the upload. The
marked one came back in **0.065 ms** on average, the same as on an idle link. The link is exactly as
full as before; the voice packets simply no longer stand in its queue.

`tc -s` counts what went where, and the counts agree:

```
ana@hq:~$ tc -s class show dev eth1 | grep -A 1 -E "^class htb 1:(10|20)"
class htb 1:10 parent 1:1 leaf 8010: prio 0 rate 1Mbit ceil 5Mbit burst 1600b cburst 1600b 
 Sent 490 bytes 5 pkt (dropped 0, overlimits 0 requeues 0) 
--
class htb 1:20 parent 1:1 leaf 8011: prio 1 rate 4Mbit ceil 5Mbit burst 1600b cburst 1600b 
 Sent 6279565 bytes 4171 pkt (dropped 163, overlimits 4158 requeues 0) 
```

Class `1:10` sent **5 packets, 490 bytes**: the five marked pings, 98 bytes each on the wire, 84 of IP
and 14 of Ethernet. It dropped nothing and was never over its limit. Class `1:20` carried the upload,
4171 packets, and **dropped 163**. The drops did not go away; they stayed where the bulk traffic is,
which is the only place they can go on a link that is full.

## Priority is not starvation

Why give the voice class a rate at all, when it could simply go first? Because a class that always goes
first and has no limit can take the whole link. If every packet in the office were marked EF, a strict
priority queue would send nothing else, ever. Here the guarantees prevent that: `1:20` is promised
**4 Mbit/s whatever happens in `1:10`**, so the worst a flood of EF can do is take the one megabit it is
guaranteed and whatever `1:20` is not using. Routers from other vendors reach the same result another way. Cisco's low-latency queueing, for instance, polices its priority queue to a fixed rate; it was not run here. Either way, **the priority class is kept small on purpose**, sized for the calls the office
really makes.
