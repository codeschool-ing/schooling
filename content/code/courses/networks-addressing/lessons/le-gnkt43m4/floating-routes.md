---
title: A backup route, and what it cannot see
version: 2
---

The spare cable from r1 to r3 is a second way through. A **floating route** puts it to use: a second
static route for the same network, through the spare cable, with a worse metric, so it floats unused
above the primary until the primary goes away. Lesson 14 showed the kernel choosing the lowest metric
between two routes to the same prefix; here that rule is put to work:

```
root@r1:~# ip route add 10.20.3.0/24 via 10.20.13.2 metric 200
root@r3:~# ip route add 10.20.1.0/24 via 10.20.13.1 metric 200
root@r1:~# ip route show 10.20.3.0/24
10.20.3.0/24 via 10.20.12.2 dev eth1 
10.20.3.0/24 via 10.20.13.2 dev eth3 metric 200 
```

r1 now has two lines for `10.20.3.0/24`. The one without a metric shown has metric 0 and wins; the one
through `eth3` waits with `metric 200`. r3 got the mirror image for `10.20.1.0/24`.

On Cisco equipment the same idea is written with an administrative distance instead of a metric, a
number after the next hop such as `ip route 10.20.3.0 255.255.255.0 10.20.13.2 200`, and the name
*floating static route* comes from there. The mechanism differs and the purpose is the same.

## Pulling a cable

Then the cable from r1 to r2 was pulled, by setting r2's end of it down: `ip link set eth1 down` at a
root prompt on r2. r1 lost the signal on `eth1`, and its table changed on its own:

```
root@r1:~# ip route show 10.20.3.0/24
10.20.3.0/24 via 10.20.12.2 dev eth1 dead linkdown 
10.20.3.0/24 via 10.20.13.2 dev eth3 metric 200 
root@r1:~# ip route get 10.20.3.10
10.20.3.10 via 10.20.13.2 dev eth3 src 10.20.13.1 uid 0 
    cache 
```

**`dead linkdown`** is the kernel marking the primary unusable because the interface it leaves by has
no carrier. The route is still listed, so it comes back into use when the cable does, and `ip route get`
confirms that a packet for pc3 now leaves through `eth3`, over the spare cable. So far the backup is
doing its job.

Now ask r3 the same question about the way back:

```
root@r3:~# ip route get 10.20.1.10
10.20.1.10 via 10.20.23.1 dev eth2 src 10.20.23.2 uid 0 
    cache 
```

**r3 still sends replies to r2.** Nothing changed on r3: its cable to r2 has a signal, its route through
`10.20.23.1` is still the better one, and the backup through `10.20.13.1` waits behind it. r3 has no way
of knowing that the cable on the far side of r2 is gone.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 265\" role=\"img\" aria-label=\"The same three routers after the cable from r1 to r2 is pulled. pc1&#x27;s request goes from r1 over the spare cable to r3, because r1&#x27;s backup route took over. pc3&#x27;s reply goes from r3 to r2, because r3&#x27;s cable to r2 is still up and its route through r2 is still the best one it has. r2 has lost its link to r1, answers !N, network unreachable, and the reply never reaches pc1.\"><defs><marker id=\"chf-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"50\" width=\"100\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.10</text><rect x=\"150\" y=\"50\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"160\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.1.1</text><text x=\"160\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.12.1</text><text x=\"160\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.13.1</text><rect x=\"300\" y=\"50\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><text x=\"310\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.12.2</text><text x=\"310\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.23.1</text><rect x=\"450\" y=\"50\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><text x=\"460\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.23.2</text><text x=\"460\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.13.2</text><text x=\"460\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.3.1</text><rect x=\"610\" y=\"50\" width=\"100\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"620\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.3.10</text><path d=\"M110 87 L150 87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M268 87 L300 87\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M418 87 L450 87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M568 87 L610 87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"130\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"284\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.12.0/30</text><text x=\"434\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.23.0/30</text><text x=\"589\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><path d=\"M209 124 L209 190 L509 190 L509 124\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"359\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.13.0/30</text><text x=\"284\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cable pulled</text><path d=\"M284 24 L284 80\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"359\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">request: r1 uses its metric 200 route</text><path d=\"M520 50 L520 34 L370 34 L370 50\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#chf-ah)\"></path><text x=\"560\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">reply: r3 still routes via r2</text><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">r2 has no link to r1 any more and answers !N. pc1 sees only loss.</text></svg>", "caption": "The cable from r1 to r2 pulled. r1 noticed, because it was r1's own cable. r3 did not, because nothing it can see changed."}
```

The result:

```
ana@pc1:~$ ping -c 2 -W 1 10.20.3.10
PING 10.20.3.10 (10.20.3.10) 56(84) bytes of data.

--- 10.20.3.10 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1018ms

ana@pc3:~$ traceroute -n 10.20.1.10
traceroute to 10.20.1.10 (10.20.1.10), 30 hops max, 60 byte packets
 1  10.20.3.1  0.887 ms  0.427 ms  0.319 ms
 2  10.20.23.1  0.273 ms !N  0.307 ms !N *
```

The ping loses both packets with no error. The `traceroute` from pc3 shows where the replies go: to r3,
then to r2 at `10.20.23.1`, which answers **`!N`**, network unreachable. r2's own route to
`10.20.1.0/24` left by the dead cable, and r2 had no other. The third probe printed `*`, no answer at all.

## What this shows

**A static route reacts to its own router's cables and to nothing else.** r1 moved to the backup
because the failure was on r1's interface. r3 did not, because from where r3 stands every cable still
works. A floating route is a good backup for exactly one failure, the loss of the router's own link,
and it turns every other failure into the silent half-working state you just watched.

Three ways out of it, and only the first is this course's subject:

- *A routing protocol.* Routers tell each other what they can reach, so r2 would have told r3 it had
  lost pc1's network. Lesson 16 is this.
- *BFD* (*Bidirectional Forwarding Detection*), a small protocol that sends rapid hellos between two
  routers and can withdraw a static route when the neighbour stops answering, even with the signal up.
  It is named here and was not run in this lab.
- *Fewer paths.* A network with one way out has nothing to get wrong this way, which is the next
  section.
