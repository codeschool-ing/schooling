---
title: Equal subnets, unequal needs
version: 2
---

Lesson 12 cut a block into subnets with one mask, so every piece came out the same size. That works
when the networks are the same size, and real ones almost never are. **VLSM** (*Variable Length
Subnet Masking*) is the plain idea of giving each subnet the mask that fits it, and this lesson
plans, builds and breaks one.

The company in this lesson's lab has one block, 10.20.32.0/24, and four networks to put in it:

| network | hosts it needs |
|---|---|
| sales | 100 |
| engineering | 50 |
| operations | 20 |
| the link between the routers r1 and r2 | 2 |

The tempting first move is the one lesson 12 taught: four networks, so cut the /24 into four equal
pieces. Two bits of the host part go to the subnet number, which leaves a /26. This lesson runs on lesson 12's
network, `plan.sh`, built with `sudo bash ~/netlab/netlab.sh up plan`, and on hq1 `ipcalc` shows what
one of those pieces holds:

```
ana@hq1:~$ ipcalc -b 10.20.32.0/26
Address:   10.20.32.0           
Netmask:   255.255.255.192 = 26 
Wildcard:  0.0.0.63             
=>
Network:   10.20.32.0/26        
HostMin:   10.20.32.1           
HostMax:   10.20.32.62          
Broadcast: 10.20.32.63          
Hosts/Net: 62                    Class A, Private Internet

```

**62 hosts per subnet**, and that number decides everything. Sales needs 100, so sales does not fit,
and no rearrangement makes it fit while every piece is a /26. Meanwhile the other three each get 62
whether they need them or not:

| network | needs | a /26 gives | left unused |
|---|---|---|---|
| sales | 100 | 62 | does not fit |
| engineering | 50 | 62 | 12 |
| operations | 20 | 62 | 42 |
| r1–r2 link | 2 | 62 | 60 |

The link is the worst of them. **A cable between two routers has exactly two ends, and a /26 spends
62 host addresses on it**, so 60 sit in a range nobody will ever use, and they cannot be lent to
anybody else, because they belong to that subnet.

Fix the mask the other way and it is no better. With a /25 everywhere, sales fits, with room for
126, but a /24 holds only two /25s, and there are four networks. Four /25s are 512 addresses, twice
the block the company has. **A single mask either starves the biggest network or wastes the block on
the smallest ones**, and with these four needs it does both, depending on which way you round.

So each subnet gets its own size: a /25 for sales, a /26 for engineering, a /27 for operations and
a /30 for the link, which fill 228 of the 256 addresses and leave the rest in one piece for later.
The next section is the method that arrives at those four, and ipcalc does the same arithmetic to
check it.

One condition comes with variable masks, and it is about routing rather than arithmetic. **A router
that learns a route has to learn its mask with it**, or it cannot tell a /26 from a /27 that starts
at a different address. Every routing protocol in current use carries the mask with each route.
The first version of RIP did not, which is why it could not be used with VLSM; lesson 16 covers
RIP and the protocols beside it.
