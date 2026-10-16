---
title: What the extra process costs
version: 1
---

Each pattern in this lesson adds something that runs on every request, and each costs something you
can measure:

| pattern | what it adds | the cost | worth it when |
| --- | --- | --- | --- |
| strangler facade | one proxy hop for every request | a little latency, one more thing that must stay up | there is a system to replace and it cannot stop |
| sidecar | one more process per service instance, one more hop on the way in | memory and CPU times the number of instances; in the lab each forwarded request took about 2 ms, service included | many services, in several languages, need the same cross-cutting work |
| ambassador | one more process beside each caller | the same, on the way out | one dependency needs special handling that several services would otherwise each implement |

The memory line is the one that grows quietly. A sidecar of 50 MB beside each of 200 service instances
is 10 GB of memory doing logging and TLS. That is one reason the mesh projects have been moving work out
of per-pod sidecars into a proxy per machine (Istio's ambient mode, Cilium's eBPF data plane): same
function, fewer copies.

The facade has a different cost: **it outlives the migration** if nobody plans its end. A strangler that
stops at "stock moved, the rest later" leaves a facade, a monolith and a new service, three things to run
where there used to be one. The migration is finished when the monolith is gone or deliberately kept,
and saying which is part of the plan from the first day.

When you are done, stop the lab:

```sh
docker compose down
```
