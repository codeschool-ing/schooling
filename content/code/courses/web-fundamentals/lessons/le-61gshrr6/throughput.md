---
title: Throughput is what you actually got
---

**Throughput** is the rate you really observe, and it usually sits below the bandwidth. The gap is where the real problem lives: congestion along the path, packet loss forcing resends, a slow server on the other end, or the protocol itself waiting for an acknowledgement.

An analogy that pays for itself: **bandwidth** is how many lanes the road has, **latency** is how long it takes to drive it, and **throughput** is how many cars actually arrived. A wide road with a traffic jam delivers little.

A practical diagnosis: if throughput is low **and** latency is normal, suspect the other end or packet loss. If latency is high, no amount of bandwidth will help — the problem is distance or queueing.
