---
title: Where QoS stops
version: 1
---

Every capture in this lesson was taken on the ISP's router, and every one of them showed the mark
arriving intact. That router read `tos 0xb8`, printed it, and treated the packet like any other. **DSCP
is a per-hop behaviour**: each router decides for itself what a mark means, and a router with no classes
configured decides that it means nothing.

On the public internet that is the normal case. A provider that honoured its customers' marks would be
giving priority away to whoever writes `0xb8`: the trust problem of the last section at the scale of a continent. So providers ignore the byte or reset it at their edge. The exception is a service
bought as such: a provider's MPLS VPN between a company's sites can carry a few classes by contract,
and then the contract, not the mark, is what the company is paying for.

So QoS works where you own the queue. On `hq`'s uplink the queue is `hq`'s, and everything in this lesson
worked. **The traffic coming down the same link is a different matter**: its queue is at the provider's
end, before the packets reach your router, and a large download fills a queue you cannot configure. The
usual answer is to shape your own side a little below the line's real speed, so that the queue forms in
your router, where your classes are, rather than in the provider's. That is lesson 20's subject.

| where the queue is | can you give it classes? |
|---|---|
| your router's uplink, going out | yes, this lesson |
| your LAN switches | yes, with the trust boundary at the access port |
| the provider's end of your line, coming in | no, only by shaping your side below its rate (lesson 20) |
| the internet between two sites | no, unless a contract says so |

One more tool deserves a name, because it attacks the problem from the other end. **A shorter queue helps
everybody, classes or not.** Active queue managers such as `fq_codel` drop or mark packets early, before
the queue grows to hundreds of milliseconds, and give each flow a queue of its own. They were not run in
this lab, whose queue was a plain `pfifo` on purpose, so that the damage would be visible. Classes decide
who suffers what is left, and on a link whose queue never grows there is much less left to decide.
