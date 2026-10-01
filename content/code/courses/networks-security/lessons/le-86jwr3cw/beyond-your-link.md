---
title: What the building cannot absorb
version: 1
---

Everything so far happens on the defender's own equipment. Against a volumetric attack larger than
the link, none of it runs, because the packets are dropped before they reach the equipment. What
remains is decided upstream, and somebody has to arrange it **before** the attack:

| measure | how it works |
|---|---|
| the provider's filtering | the ISP drops traffic to the attacked address on its own, larger links |
| a scrubbing service | traffic is routed through a provider whose job is to absorb floods and forward only what looks legitimate |
| a CDN in front of the site | the public address belongs to a network of hundreds of locations; the flood is spread across all of them, and the origin server's address is never published |
| anycast | one address announced from many places, so each place receives only the part of the attack nearest to it |

**The common factor is capacity somebody else has.** A small company cannot buy a link bigger than an
attack; it can buy a service that has one. The decision to do so is made in a meeting, not during
an incident, and the number that decides it is what an hour of the service being down costs.

## Watching the table fill

On the equipment that is the defender's, the first sign of a protocol attack is the connection table.
Two numbers to watch, and two counters worth knowing where to find:

```
root@fw:~# conntrack -C; sysctl -n net.netfilter.nf_conntrack_max
9
262144
root@fw:~# conntrack -S | head -2
cpu=0   	found=0 invalid=0 insert=0 insert_failed=0 drop=0 early_drop=0 error=0 search_restart=0 clash_resolve=0 chaintoolong=0 
cpu=1   	found=0 invalid=0 insert=0 insert_failed=0 drop=0 early_drop=0 error=0 search_restart=0 clash_resolve=0 chaintoolong=0 
```

`conntrack -C` is how many entries exist now, against the maximum of 262,144. `conntrack -S` counts,
per processor, what happened to entries: **`drop` and `early_drop` climbing mean the table is full**
and new connections are being refused or old ones evicted to make room. Here they are 0. Graphed over
time, the first number is the one to put an alert on, long before it reaches the second.

A written plan belongs next to the graph: whom to call at the provider, how to switch on the
scrubbing service, which address to fail over to, and who decides. The first denial of service
somebody lives through is usually spent looking for a phone number.
