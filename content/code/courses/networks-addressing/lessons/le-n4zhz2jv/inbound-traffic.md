---
title: Steering the traffic that comes to you
version: 1
---

**Outbound traffic is your decision; inbound traffic is somebody else's.** edge chooses which provider to
use towards a1 by its own table, and can override that with local preference whenever it likes. Which
link a1's traffic uses to reach the company is chosen by ispa, from what ispa hears. All the company can
do is change what it says.

Here is what ispa hears about the company's block:

```
root@ispa:~# vtysh -c "show ip bgp 203.0.113.0/24"
BGP routing table entry for 203.0.113.0/24, version 3
Paths: (2 available, best #2, table default)
  Advertised to non peer-group peers:
  192.0.2.1 192.0.2.10
  64502 64500
    192.0.2.10 from 192.0.2.10 (192.0.2.6)
      Origin IGP, valid, external
      Last update: Tue Sep 29 08:49:59 2026
  64500
    192.0.2.1 from 192.0.2.1 (192.0.2.1)
      Origin IGP, metric 0, valid, external, best (AS Path)
      Last update: Tue Sep 29 08:50:05 2026
```

Two paths. **`64502 64500`**, from `192.0.2.10`, is the company's block as ispb passed it on.
**`64500`**, from `192.0.2.1`, is edge itself, and it is `best (AS Path)`: FRR names the step of the
tie-break list that decided, and it is the length of the path. The `Advertised to` line lists `192.0.2.1`
among the peers ispa passes the prefix to, which is the offer back that edge refuses.

Suppose the company wants a1's provider to send its traffic in through ispb, because the link to ispa is
the smaller one. **The lever is AS path prepending**: announcing to ispa a path made artificially longer
by repeating the company's own number.

```
root@edge:~# vtysh -c "configure terminal" -c "route-map TO-ISPA permit 10" -c "match ip address prefix-list OURS" -c "set as-path prepend 64500 64500" -c "exit" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.2 route-map TO-ISPA out"
```

A new route map, `TO-ISPA`, still permits only `OURS`, and adds `set as-path prepend 64500 64500`. It
replaces `TO-PROVIDER` towards ispa only. ispa's view afterwards:

```
root@ispa:~# vtysh -c "show ip bgp 203.0.113.0/24"
BGP routing table entry for 203.0.113.0/24, version 4
Paths: (2 available, best #1, table default)
  Advertised to non peer-group peers:
  192.0.2.1 192.0.2.10
  64502 64500
    192.0.2.10 from 192.0.2.10 (192.0.2.6)
      Origin IGP, valid, external, best (AS Path)
      Last update: Tue Sep 29 08:49:59 2026
  64500 64500 64500
    192.0.2.1 from 192.0.2.1 (192.0.2.1)
      Origin IGP, metric 0, valid, external
      Last update: Tue Sep 29 08:50:18 2026
```

The direct path now reads `64500 64500 64500`, three numbers, against `64502 64500`, two, and the
path through ispb is `best (AS Path)`. a1's traffic follows:

```
ana@a1:~$ traceroute -n 203.0.113.10
traceroute to 203.0.113.10 (203.0.113.10), 30 hops max, 60 byte packets
 1  198.51.100.1  0.697 ms  0.195 ms  0.152 ms
 2  192.0.2.10  0.505 ms  0.397 ms  0.133 ms
 3  192.0.2.5  0.129 ms  0.194 ms  0.097 ms
 4  203.0.113.10  0.475 ms  0.512 ms  0.152 ms
```

**Four hops instead of three**: ispa at `198.51.100.1`, then ispb at `192.0.2.10`, then edge at
`192.0.2.5`, its interface towards ispb, then the server. The traffic now enters through the other
provider.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Two panels, before and after the company prepends its AS number towards provider A. Before: ispa holds two paths to 203.0.113.0/24, 64500 directly and 64502 64500 through ispb, and picks the shorter, 64500; a1&#x27;s traffic goes from ispa straight to edge. After: the path from edge reads 64500 64500 64500, three numbers, against 64502 64500, two; ispa picks the path through ispb, and a1&#x27;s traffic goes from ispa to ispb and then to edge.\"><defs><marker id=\"bp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"340\" height=\"310\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">before the prepend</text><rect x=\"135\" y=\"46\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">edge</text><rect x=\"30\" y=\"140\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispa</text><rect x=\"240\" y=\"140\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"285\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispb</text><rect x=\"30\" y=\"214\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a1</text><path d=\"M75 214 L75 170\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><path d=\"M150 76 L90 140\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><path d=\"M210 76 L270 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120 155 L240 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"24\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ispa's paths to 203.0.113.0/24</text><text x=\"24\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">64500</text><text x=\"210\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">best</text><text x=\"24\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">64502 64500</text><rect x=\"370\" y=\"10\" width=\"340\" height=\"310\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"384\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">after the prepend</text><rect x=\"495\" y=\"46\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">edge</text><rect x=\"390\" y=\"140\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispa</text><rect x=\"600\" y=\"140\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispb</text><rect x=\"390\" y=\"214\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a1</text><path d=\"M435 214 L435 170\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><path d=\"M510 76 L450 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M570 76 L630 140\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><path d=\"M480 155 L600 155\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><text x=\"384\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ispa's paths to 203.0.113.0/24</text><text x=\"384\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">64500 64500 64500</text><text x=\"384\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">64502 64500</text><text x=\"570\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">best</text></svg>", "caption": "The company changed what it announced, and provider A chose differently. The thick line is the way a1's traffic arrives."}
```

## What you can and cannot make others do

Prepending is a request, and it worked here because ispa's configuration sets nothing ahead of the AS path
step. **Real providers set a higher local preference on routes learned from their customers than on routes
learned from other providers**, because customers pay them and peers do not, and local preference is
checked before path length. Against that policy a prepend changes nothing at the provider it was aimed at;
it only changes the choice of networks further away.

Three other levers exist, each named and none run in this lab:

- *MED* (*multi-exit discriminator*), a hint to one neighbour about which of several links to that same
  neighbour you prefer.
- *Communities*, tags attached to a route that the provider has published a meaning for, such as *lower
  my local preference* or *do not announce this to that peer*.
- *A more specific prefix* through one provider: two `/25`s through one link and the `/24` through both.
  Longest prefix wins, as lesson 14 showed, so the `/25`s draw the traffic; it also adds routes to every
  router on the internet, and many networks discard prefixes longer than a `/24`.

Nothing changed in edge's own choices: its table still sends traffic for `198.51.100.0/25` out through
ispa, so a1's requests now arrive through ispb and the replies leave through ispa. **Asymmetric paths are
normal in BGP**, and they are why a capture at one link sees only half a conversation.
