---
title: QoS does nothing until a queue forms
version: 1
---

QoS is usually sold as a way to make important traffic faster, or to reserve bandwidth for it. On an
idle link it does neither, because there is nothing to be faster than. **Quality of service only
decides who waits when packets arrive faster than a link can send them**, and that happens in one
place: the queue in front of the slowest link on the path.

The lab has no slow link. Every cable in it is a virtual one on one computer. A ping from the laptop
to `web1` in the data centre comes back in a fraction of a millisecond, which measures that computer
talking to itself and nothing else:

```
ana@laptop:~$ ping -c 5 -q 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 0.077/0.161/0.321/0.085 ms
```

So the lesson makes one. `hq`'s link to the ISP, `eth1`, becomes a 5 Mbit/s link with a queue of 100
packets in front of it, the shape of a small office's upload. The first command builds it with `tc`,
Linux's traffic control tool, and the second shows what it built:

```
ana@hq:~$ sudo tc qdisc add dev eth1 root handle 1: htb default 20 && sudo tc class add dev eth1 parent 1: classid 1:20 htb rate 5mbit && sudo tc qdisc add dev eth1 parent 1:20 pfifo limit 100
ana@hq:~$ tc qdisc show dev eth1; tc class show dev eth1
qdisc htb 1: root refcnt 5 r2q 10 default 0x20 direct_packets_stat 0 direct_qlen 1000
qdisc pfifo 800f: parent 1:20 limit 100p
class htb 1:20 root leaf 800f: prio 0 rate 5Mbit ceil 5Mbit burst 1600b cburst 1600b 
ana@laptop:~$ ping -c 5 -q 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 0.094/0.106/0.129/0.014 ms
```

`rate 5Mbit` is the link's new speed and `pfifo ... limit 100p` is the queue: first in, first out, at
most 100 packets. The ping after it is **0.106 ms**, the same as before. A 5 Mbit/s link is slow for a
file and fast for five pings, so the queue was empty each time and there was nothing to wait behind.

## One upload changes everything

Now the laptop uploads to `web1`, with an `iperf3` started in the background and not shown, and two
seconds later the same ping runs again:

```
ana@laptop:~$ ping -c 5 -q 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 23.031/65.122/221.652/78.297 ms
```

The fastest reply took **23 ms** and the slowest **221 ms**, about two thousand times the ping before it.
Nothing about the ping changed. It joined the back of the queue, behind whatever the upload had put
there, and waited its turn. The arithmetic says how bad a full queue is: 100 packets of 1514 bytes, the
1500 of IP plus 14 of Ethernet, are 1,211,200 bits, and at 5 Mbit/s they take **242 ms** to drain. The
221 ms reply met a queue that was nearly full.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 230\" role=\"img\" aria-label=\"A queue drawn as a row of slots in front of a 5 Mbit/s link. The slots are full of the upload&#x27;s packets, and one ping waits at the back. A full queue is 100 packets of 1514 bytes, 1,211,200 bits, which takes 0.242 seconds to drain at 5 Mbit/s. Measured during the upload, five pings took from 23 to 221 milliseconds.\"><defs><marker id=\"q18-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hq, eth1: one queue for everything</text><rect x=\"30\" y=\"44\" width=\"500\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"36\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"56.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"77.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"97.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"118.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"138.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"159.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"179.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"200.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"220.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"241.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"261.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"282.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"302.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"323.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"343.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"364.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"384.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"405.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"425.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"446.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"466.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"487.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"507.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><path d=\"M530 66 L578 66\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#q18-ah)\"></path><rect x=\"580\" y=\"44\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the link: 5 Mbit/s</text><text x=\"36\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the ping, at the back</text><text x=\"524\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">next to leave</text><text x=\"30\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a full queue:</text><text x=\"200\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">100 × 1514 bytes × 8 = 1,211,200 bits</text><text x=\"30\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">to drain at 5 Mbit/s:</text><text x=\"200\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1,211,200 ÷ 5,000,000 = 0.242 s</text><text x=\"30\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">measured, five pings during the upload: 23 ms to 221 ms</text><rect x=\"30\" y=\"206\" width=\"12\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the upload's packets (iperf3)</text><rect x=\"260\" y=\"206\" width=\"12\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"278\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one ping</text></svg>", "caption": "One queue in front of a slow link. The ping is not slow; it is last in line, and the line is a quarter of a second long when it is full."}
```

Why is the queue full, rather than now and then? Because that is what TCP does. It sends faster and
faster until a packet is lost, slows down, and starts climbing again. So **a single upload keeps the
queue in front of a slow link topped up for as long as it runs.** A second upload, run in the foreground once
the first had finished, shows the losses in its summary, 163 retransmissions in five seconds:

```
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5 | tail -n 4
[  5]   0.00-5.00   sec  3.50 MBytes  5.87 Mbits/sec  163             sender
[  5]   0.00-5.03   sec  2.75 MBytes  4.59 Mbits/sec                  receiver

iperf Done.
```

A queue that stays full and adds a quarter of a second to everything behind it has a name,
**bufferbloat**, and on an office uplink it is the usual reason a call breaks up while somebody sends a
large file. The link is not out of capacity for the call; the call is stuck behind the file.

That also says what QoS can and cannot do. It cannot make the link faster, and it cannot empty the
queue for everybody. **What it can do is keep some packets out of that queue**, and it takes three
steps: recognise which packets matter, give them a queue of their own, and send from that queue first.
The rest of this lesson builds those three steps on this link.
